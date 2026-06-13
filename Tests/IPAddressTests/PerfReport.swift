//
//  PerfReport.swift
//
//  Self-contained performance-report rendering and writing for the
//  IPAddress performance tests.
//
//  This intentionally has **no** external package dependency. It reproduces
//  the bordered, padded table that the `Table` package used to render with
//  its `.roundedPadded` frame style, so existing reference results keep the
//  same visual format. The relevant `Table` algorithms (horizontal align /
//  cut, word packing, vertical align) are re-implemented here in a focused
//  form that only covers what these reports need.
//
//  Results are written to `<package-root>/performance/`, one file per
//  measured system configuration and build mode. That folder is git-ignored,
//  so committing a result is a deliberate action (`git add -f`).
//

import Foundation

// MARK: - Table model

enum PerfWrap { case char, word }
enum PerfHAlign { case left, right, center }
enum PerfVAlign { case top, bottom }

struct PerfColumn {
    let header: String
    /// Fixed column width, or `nil`/`<= 0` to size automatically from the cells.
    let width: Int?
    let headerHAlign: PerfHAlign
    let headerWrap: PerfWrap
    let cellHAlign: PerfHAlign
    let cellWrap: PerfWrap
    let cellVAlign: PerfVAlign
}

// MARK: - Renderer

enum PerfTable {

    /// Column layout matching the original `Table` configuration used by the
    /// IPAddress performance summary (widths 28(auto)/20/6/24).
    static func ipAddressColumns() -> [PerfColumn] {
        [
            PerfColumn(header: "IPAddress API", width: nil,
                       headerHAlign: .left,   headerWrap: .char,
                       cellHAlign: .left,     cellWrap: .char,   cellVAlign: .bottom),
            PerfColumn(header: "Measured performance invocations / sec", width: 20,
                       headerHAlign: .center, headerWrap: .char,
                       cellHAlign: .right,    cellWrap: .char,   cellVAlign: .bottom),
            PerfColumn(header: "Test data type", width: 6,
                       headerHAlign: .center, headerWrap: .word,
                       cellHAlign: .center,   cellWrap: .word,   cellVAlign: .bottom),
            PerfColumn(header: "Comment", width: 24,
                       headerHAlign: .center, headerWrap: .word,
                       cellHAlign: .left,     cellWrap: .word,   cellVAlign: .top),
        ]
    }

    /// Render `rows` as a rounded, padded, bordered table with a centered,
    /// possibly multi-line `title`.
    static func render(title: String, columns: [PerfColumn], rows: [[String]]) -> String {

        // Resolve column widths (auto columns size to their widest cell).
        var widths = columns.map { $0.width ?? 0 }
        for (ci, col) in columns.enumerated() where (col.width ?? 0) <= 0 {
            let widest = rows.map { ci < $0.count ? $0[ci].count : 0 }.max() ?? 0
            widths[ci] = max(widest, 1)
        }

        // `.roundedPadded` inside-vertical separator is " │ " (3 wide), which
        // is what the title spans across in addition to the column widths.
        let insideVerticalWidth = 3
        let titleWidth = widths.reduce(0, +) + max(0, columns.count - 1) * insideVerticalWidth

        func dashes(joinedBy junction: String) -> String {
            widths.map { String(repeating: "─", count: $0) }.joined(separator: junction)
        }
        func bodyRow(_ cells: [String]) -> String {
            "│ " + cells.joined(separator: " │ ") + " │\n"
        }

        var out = ""

        // Top frame: a single span because the table has a title.
        out += "╭─" + String(repeating: "─", count: titleWidth) + "─╮\n"

        // Title (each source line word-wrapped + centered to the full width).
        for line in renderTitle(title, width: titleWidth) {
            out += bodyRow([line])
        }

        // Divider between title and column headers (┬ junctions).
        out += "├─" + dashes(joinedBy: "─┬─") + "─┤\n"

        // Column headers.
        let headerLines = columns.enumerated().map { ci, col in
            wrap(col.header, col.headerWrap, widths[ci], col.headerHAlign)
        }
        let headerHeight = headerLines.map { $0.count }.max() ?? 1
        let headerCols = columns.enumerated().map { ci, col in
            valign(headerLines[ci], .bottom, height: headerHeight, width: widths[ci])
        }
        for r in 0 ..< headerHeight {
            out += bodyRow(headerCols.map { $0[r] })
        }

        // Divider between headers and data (┼ junctions).
        out += "├─" + dashes(joinedBy: "─┼─") + "─┤\n"

        // Data rows, separated by ┼ dividers.
        for (ri, row) in rows.enumerated() {
            let cellLines = columns.enumerated().map { ci, col -> [String] in
                wrap(ci < row.count ? row[ci] : "", col.cellWrap, widths[ci], col.cellHAlign)
            }
            let height = cellLines.map { $0.count }.max() ?? 1
            let cols = columns.enumerated().map { ci, col in
                valign(cellLines[ci], col.cellVAlign, height: height, width: widths[ci])
            }
            for r in 0 ..< height {
                out += bodyRow(cols.map { $0[r] })
            }
            if ri < rows.count - 1 {
                out += "├─" + dashes(joinedBy: "─┼─") + "─┤\n"
            }
        }

        // Bottom frame (┴ junctions).
        out += "╰─" + dashes(joinedBy: "─┴─") + "─╯\n"
        return out
    }

    // MARK: Alignment / wrapping primitives (ported from `Table`)

    /// Horizontally align (or hard-cut) a single line to `width`.
    /// Centering biases extra padding to the right, matching `Table`.
    private static func halignOrCut(_ s: String, _ align: PerfHAlign, _ width: Int) -> String {
        guard s.count < width else { return String(s.prefix(width)) }
        let pad = width - s.count
        switch align {
        case .left:   return s + String(repeating: " ", count: pad)
        case .right:  return String(repeating: " ", count: pad) + s
        case .center:
            let head = pad / 2
            return String(repeating: " ", count: head) + s + String(repeating: " ", count: pad - head)
        }
    }

    /// Character wrapping: cut every `width` characters, aligning each piece.
    /// (Inputs here contain no newlines, matching the reported strings.)
    private static func cutToWidth(_ s: String, _ width: Int, _ align: PerfHAlign) -> [String] {
        guard width > 0 else { return [] }
        let chars = Array(s)
        guard chars.isEmpty == false else { return [String(repeating: " ", count: width)] }
        var lines: [String] = []
        var i = 0
        while i < chars.count {
            let end = min(i + width, chars.count)
            lines.append(halignOrCut(String(chars[i ..< end]), align, width))
            i = end
        }
        return lines
    }

    /// Word wrapping: greedily pack space-separated words to `width`,
    /// hard-splitting any word wider than the column.
    private static func packWords(_ words: [String], _ width: Int, _ align: PerfHAlign) -> [String] {
        // Hard-split over-long words first.
        var pieces: [String] = []
        for word in words {
            let chars = Array(word)
            if chars.count <= width {
                pieces.append(word)
            } else {
                var i = 0
                while i < chars.count {
                    let end = min(i + width, chars.count)
                    pieces.append(String(chars[i ..< end]))
                    i = end
                }
            }
        }

        var frags: [String] = []
        var line = ""
        for word in pieces {
            if word.count == width {
                if line.isEmpty == false { frags.append(halignOrCut(line, align, width)); line = "" }
                frags.append(word)
                continue
            }
            if line.isEmpty == false {
                if line.count + word.count + 1 <= width {
                    line.append(" " + word)
                } else {
                    frags.append(halignOrCut(line, align, width))
                    line = word
                }
                continue
            }
            line = word
        }
        if line.isEmpty == false { frags.append(halignOrCut(line, align, width)) }
        return frags.isEmpty ? [String(repeating: " ", count: width)] : frags
    }

    private static func wrap(_ s: String, _ wrapping: PerfWrap, _ width: Int, _ align: PerfHAlign) -> [String] {
        guard s.isEmpty == false else { return [String(repeating: " ", count: width)] }
        switch wrapping {
        case .char:
            return cutToWidth(s, width, align)
        case .word:
            let words = s.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            return packWords(words, width, align)
        }
    }

    /// Pad a column's lines to `height`, biasing pad to the top (`.bottom`)
    /// or bottom (`.top`).
    private static func valign(_ lines: [String], _ align: PerfVAlign, height: Int, width: Int) -> [String] {
        let pad = max(0, height - lines.count)
        let blank = String(repeating: " ", count: width)
        switch align {
        case .top:    return lines + Array(repeating: blank, count: pad)
        case .bottom: return Array(repeating: blank, count: pad) + lines
        }
    }

    private static func renderTitle(_ title: String, width: Int) -> [String] {
        var lines: [String] = []
        for raw in title.split(separator: "\n", omittingEmptySubsequences: false) {
            let words = raw.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            if words.isEmpty {
                lines.append(String(repeating: " ", count: width))
            } else {
                lines.append(contentsOf: packWords(words, width, .center))
            }
        }
        return lines
    }
}

// MARK: - Report writing

struct PerfResultJSON: Encodable {
    let api: String
    let dataType: String
    let comment: String
    let invocations: UInt64
    let averageNanoseconds: Double
    let invocationsPerSecond: Double
    let invocationsPerSecondFormatted: String
}

private struct PerfReportJSON: Encodable {
    let build: String
    let swift: String
    let generated: String
    let system: String
    let systemHash: String
    let results: [PerfResultJSON]
}

enum PerfReport {

    /// Build configuration the test target was compiled with.
    static var buildConfiguration: String {
        #if DEBUG
        return "debug"
        #else
        return "release"
        #endif
    }

    /// Best-effort Swift language version (resolved at compile time).
    static var swiftVersion: String {
        #if swift(>=6.2)
        return "6.2 or newer"
        #elseif swift(>=6.1)
        return "6.1"
        #elseif swift(>=6.0)
        return "6.0"
        #elseif swift(>=5.10)
        return "5.10"
        #elseif swift(>=5.9)
        return "5.9"
        #elseif swift(>=5.8)
        return "5.8"
        #elseif swift(>=5.7)
        return "5.7"
        #elseif swift(>=5.6)
        return "5.6"
        #else
        return "5.5 or older"
        #endif
    }

    /// Stable (run-independent) FNV-1a hash, rendered as 8 hex digits.
    /// `Hasher` is intentionally not used as it is seeded per process.
    static func stableHash(_ s: String) -> String {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in s.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return String(format: "%08x", UInt32(truncatingIfNeeded: hash))
    }

    /// Directory the reports are written to: `<package-root>/performance`.
    static var directory: URL {
        URL(fileURLWithPath: #filePath)            // .../Tests/IPAddressTests/PerfReport.swift
            .deletingLastPathComponent()           // .../Tests/IPAddressTests
            .deletingLastPathComponent()           // .../Tests
            .deletingLastPathComponent()           // package root
            .appendingPathComponent("performance", isDirectory: true)
    }

    /// Render and write the `.txt` table report plus a `.json` sidecar for the
    /// current system configuration and build mode.
    @discardableResult
    static func write(table: String, system: String, results: [PerfResultJSON]) -> URL? {
        let hash = stableHash(system)
        let build = buildConfiguration
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let timestamp = formatter.string(from: Date())
        let base = "perf-\(hash)-\(build)"

        let header = """
            IPAddress — performance reference

            Build:     \(build)
            Swift:     \(swiftVersion)
            Generated: \(timestamp)
            Config:    \(hash)


            """

        let dir = directory
        let txtURL = dir.appendingPathComponent("\(base).txt")
        let jsonURL = dir.appendingPathComponent("\(base).json")

        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

            try (header + table).write(to: txtURL, atomically: true, encoding: .utf8)

            let report = PerfReportJSON(build: build, swift: swiftVersion, generated: timestamp,
                                        system: system, systemHash: hash, results: results)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let data = try encoder.encode(report)
            try data.write(to: jsonURL, options: .atomic)

            print("Performance report written to:")
            print("  \(txtURL.path)")
            print("  \(jsonURL.path)")
            return txtURL
        } catch {
            dump(error)
            return nil
        }
    }
}

import Foundation
import BigInt

/// Class representing Classless Inter-Domain Routing information
public class CIDR : Codable {
    /// Valid range for ipv4 bitmask values
    internal static let validV4Range:ClosedRange<Int> = (0...32)
    /// Valid range for ipv6 bitmask values
    internal static let validV6Range:ClosedRange<Int> = (0...128)
    /// Bitmask size
    public let bits:Int
    /// Ip address type associated to this cidr
    private (set) public var type:IPAddress.IPAddrType
    /// Cidr bytes as Data
    public lazy var bytes:Data = {
        let validRange:ClosedRange<Int>
        switch self.type {
        case .v4:
            validRange = Self.validV4Range
        case .v6:
            validRange = Self.validV6Range
        }
        let bitsByteCount = bits / 8
        var mask:Data = Data(repeating: 255, count: bitsByteCount)
        let tailCount = (validRange.upperBound / 8) - mask.count
        let tail = Data(repeating: 0, count: tailCount)
        mask.append(tail)
        let u8:UInt8 = ~(0xff >> (bits % 8))
        if (bits % 8) != 0 {
            mask[bitsByteCount] = u8
        }
        return mask
    }()
    /// A boolean value indicating wheter this cidr denotes a single endpoint
    public lazy var isSingleEndPoint:Bool = {
        switch type {
        case .v4: return bits == Self.validV4Range.upperBound
        case .v6: return bits == Self.validV6Range.upperBound
        }
    }()
    /// Maximum number of hosts in this network
    public lazy var hostCount:BigInt = {
        let p = type == .v4 ? 32 - bits : 128 - bits
        return _mult_two(times: UInt8(p))
    }()
    /// Maximum number of networks this cidr can represent
    public lazy var networkCount:BigInt = {
        return _mult_two(times: UInt8(bits))
    }()
    /// Initializes a cidr
    public init(for type:IPAddress.IPAddrType, bits:Int) {
        self.type = type
        switch type {
        case .v4:
            precondition(Self.validV4Range.contains(bits), "out of bounds error: '\(bits)' is out of range for '\(type)'. Valid range is \(Self.validV4Range)")
            self.bits = bits
        case .v6:
            precondition(Self.validV6Range.contains(bits), "out of bounds error: '\(bits)' is out of range for '\(type)'. Valid range is \(Self.validV6Range)")
            self.bits = bits
        }
    }
}
extension CIDR : Equatable {
    public static func ==(lhs:CIDR, rhs:CIDR) -> Bool {
        lhs.bits == rhs.bits && lhs.type == rhs.type
    }
}
extension CIDR : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(bits)
    }
}
extension CIDR : Comparable {
    public static func <(lhs:CIDR, rhs:CIDR) -> Bool {
        lhs.bits < rhs.bits
    }
}
extension CIDR {
    private func _mult_two(times n:UInt8) -> BigInt {
        let potentiallyBigNumber = (0..<n).reduce(BigInt(1), { a,_ in a * BigInt(2) })
        return potentiallyBigNumber
    }
}

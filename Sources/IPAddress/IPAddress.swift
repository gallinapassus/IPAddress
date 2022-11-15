import Foundation
import BigInt
import Parsing

/// Conrete type capable of encapsulating ipv4 and ipv6 addresses
public struct IPAddress : Codable {

    /// Ip address type enumeration
    public enum IPAddrType : UInt8, Codable { case v4 = 0, v6 = 1 /*, v8 = 2, v10 = 3 */ }

    /// Data storage for storing ipv6 address type and address bytes
    private let data:Data
    /// Data storage for storing an ipv4 address
    ///
    /// Value is stored in current system's endianness (on little endian systems
    /// value is stored as little endian and on big endian systems value is stored
    /// as big endian. Required conversions to network byte order (=big endian)
    /// will happen when needed.
    ///
    /// On both (big- and little endian) systems UInt32(1) will result to ipv4
    /// address 0.0.0.1 and UInt32.max will result in 255.255.255.255.
    private let sysendianIpv4:UInt32

    /// Classless Inter-Domain Routing information attached to this ip address
    public let cidr:CIDR

    /// Returns an enumeration value describing the contained ip address type
    public let type:IPAddrType

    /// Initializes an ipv4 address
    ///
    /// Initializes an ipv4 address from UInt32 value.
    ///
    /// Initializing IPAddress with UInt32(1) will result in 0.0.0.1 and
    /// with UInt32.max will result in 255.255.255.255.
    public init(_ u32: UInt32, cidr bits:Int = 32) {
        let u8bytes = Data([0]) + withUnsafeBytes(of: Self.systemIsLittleEndian ? u32.byteSwapped : u32, { Array($0) })
        self.data = Data(u8bytes)
        self.cidr = CIDR(for: .v4, bits: bits)
        self.type = .v4
        self.sysendianIpv4 = u32
    }

    /// Initializes an ipv4 or ipv6 address
    ///
    /// Initializes an ipv4 or ipv6 address from given UInt8 bytes.
    /// Bytes must be in big endian byte order (a.k.a. network byte order).
    public init?(_ bytes:[UInt8]) {
        switch bytes.count {
        case 4:
            let u8 = [IPAddrType.v4.rawValue] + bytes
            self.data = Data(u8)
            self.cidr = CIDR(for: .v4, bits: 32)
            self.type = .v4
            self.sysendianIpv4 = Self.systemIsLittleEndian ?
            UInt32(bytes[3]) | UInt32(bytes[2])<<8 | UInt32(bytes[1])<<16 | UInt32(bytes[0])<<24 :
            UInt32(bytes[0]) | UInt32(bytes[1])<<8 | UInt32(bytes[2])<<16 | UInt32(bytes[3])<<24
        case 16:
            let u8 = [IPAddrType.v6.rawValue] + bytes
            self.data = Data(u8)
            self.cidr = CIDR(for: .v6, bits: 128)
            self.type = .v6
            self.sysendianIpv4 = 0
        default: return nil
        }
    }

    /// Initializes an ipv4 or ipv6 address
    ///
    /// Initializes an ipv4 or ipv6 address from given String.
    public init?(_ string:String) {
        if string.contains(":") { // Just a small optimization
            // IPv6 first
            let parsedV6 = try? Parse { IPv6AddressParser<String>() }.parse(string)
            guard let validV6 = parsedV6 else {
                let parsedV4 = try? Parse { IPv4AddressParser<String>() }.parse(string)
                guard let validV4 = parsedV4 else {
                    return nil // was not v4 nor v6
                }
                self = validV4 // was v4
                return
            }
            self = validV6 // was v6
        }
        else {
            // IPv4 first
            let parsedV4 = try? Parse { IPv4AddressParser<String>() }.parse(string)
            guard let validV4 = parsedV4 else {
                let parsedV6 = try? Parse { IPv6AddressParser<String>() }.parse(string)
                guard let validV6 = parsedV6 else {
                    return nil // was not v4 nor v6
                }
                self = validV6 // was v6
                return
            }
            self = validV4 // was v4
        }
    }
    public var compactDescription:String {
        guard isv6 else {
            return description
        }
        let uint16bytes = data[1...].withUnsafeBytes({
            var tmp:[UInt16] = []
            for i in stride(from: $0.startIndex, to: $0.endIndex, by: 2) {
                let u16 = ($0.baseAddress! + i).assumingMemoryBound(to: UInt16.self).pointee
                tmp.append(Self.systemIsLittleEndian ? u16.byteSwapped : u16)
            }
            return tmp
        })
        if var s = uint16bytes.firstIndex(of: 0) {
            var pairs:[Range<Int>] = []
            var maxLen = 0
            var longestZeroStrikeAt = -1
            var len:Array<UInt16>.Index = 0
            var e = uint16bytes.startIndex
            while s < uint16bytes.endIndex {
                e = uint16bytes[s...].firstIndex(where: { $0 != 0 }) ?? uint16bytes.endIndex
                len = e - s
                if len > maxLen {
                    maxLen = len
                    longestZeroStrikeAt += 1
                }
                pairs.append((s..<e))
                s = uint16bytes[e...].firstIndex(of: 0) ?? uint16bytes.endIndex
            }
            if len > maxLen {
                maxLen = len
                longestZeroStrikeAt += 1
            }
            if longestZeroStrikeAt > -1 {
                let a = pairs[longestZeroStrikeAt]
                
                let h = uint16bytes[..<a.startIndex].map({
                    String(Self.systemIsLittleEndian ? $0 : $0.byteSwapped, radix: 16)
                }).joined(separator: ":") + ":"
                let t = ":" + uint16bytes[a.endIndex...].map({
                    String(Self.systemIsLittleEndian ? $0 : $0.byteSwapped, radix: 16)
                }).joined(separator: ":")
                
                return h + t
                
            }
            else {
                return "\(description)"
            }
        }
        return "\(description)"
    }
    public var compactDebugDescription:String {
        guard isv6 else {
            return compactDescription + "/\(cidr.bits)"
        }
        return compactDescription + "/\(cidr.bits)"
    }
}
extension IPAddress : Equatable {
    ///
    /// Returns a boolean value indicating if two IPAddress
    /// instances are representing exactly the same ip address
    /// and network mask.
    ///
    /// - Returns: Returns true only when both ip addresses are of
    ///  same type and their ip address and network mask (cidr) are equal.
    public static func ==(lhs:IPAddress, rhs:IPAddress) -> Bool {
        guard lhs.type == rhs.type else {
            return false
        }
        return lhs.type == .v4 ?
        lhs.sysendianIpv4 == rhs.sysendianIpv4 && lhs.cidr == rhs.cidr :
        lhs.data == rhs.data && lhs.cidr == rhs.cidr
    }
}
extension IPAddress : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
        hasher.combine(cidr)
    }
}
extension IPAddress : Comparable {
    public static func < (lhs: IPAddress, rhs: IPAddress) -> Bool {
        switch lhs.type {
        case .v4:
            switch rhs.type {
            case .v4: return lhs.sysendianIpv4 < rhs.sysendianIpv4
            case .v6: return true
            }
        case .v6:
            switch rhs.type {
            case .v4: return false
            case .v6:
                let llo = lhs.data[1..<9].withUnsafeBytes({
                    let u64 = $0.baseAddress!.assumingMemoryBound(to: UInt64.self).pointee
                    return Self.systemIsLittleEndian ? u64.byteSwapped : u64
                })
                let rlo = rhs.data[1..<9].withUnsafeBytes({
                    let u64 = $0.baseAddress!.assumingMemoryBound(to: UInt64.self).pointee
                    return Self.systemIsLittleEndian ? u64.byteSwapped : u64
                })
                if llo < rlo {
                    return true
                }
                else if llo > rlo {
                    return false
                }

                
                let lhi = lhs.data[9..<17].withUnsafeBytes({
                    let u64 = $0.baseAddress!.assumingMemoryBound(to: UInt64.self).pointee
                    return Self.systemIsLittleEndian ? u64.byteSwapped : u64
                })
                let rhi = rhs.data[9..<17].withUnsafeBytes({
                    let u64 = $0.baseAddress!.assumingMemoryBound(to: UInt64.self).pointee
                    return Self.systemIsLittleEndian ? u64.byteSwapped : u64
                })
                return lhi < rhi
            }
        }
    }
}
extension IPAddress : CustomStringConvertible {
    public var description: String {
        switch type {
        case .v4:
            return data[1...].map({ $0.description }).joined(separator: ".")
        case .v6:
            return data[1...].withUnsafeBytes({
                var tmp:[String] = []
                for i in stride(from: $0.startIndex, to: $0.endIndex, by: 2) {
                    let u16 = ($0.baseAddress! + i).assumingMemoryBound(to: UInt16.self).pointee
                    tmp.append(String(Self.systemIsLittleEndian ? u16.byteSwapped : u16, radix: 16))
                }
                return tmp.joined(separator: ":")
            })
        }
    }
}
extension IPAddress : CustomDebugStringConvertible {
    public var debugDescription: String {
        switch type {
        case .v4:
            return description + "/\(cidr.bits)"
        case .v6:
            return description + "/\(cidr.bits)"
        }
    }
}
extension IPAddress {
    public var rawAddressBytes:Data { return data[1...] }
    private var ipv4rawValue:UInt32? {
        guard cidr.bits <= 32, type == .v4 else { return nil }
        return data[1...].withUnsafeBytes({
            let u32 = $0.baseAddress!.assumingMemoryBound(to: UInt32.self).pointee
            return Self.systemIsLittleEndian ? u32.byteSwapped : u32
        })
    }
    /// A Boolean value indicating whether this is an ipv4 address.
    public var isv4:Bool {
        (data[0] & 0b11) == IPAddrType.v4.rawValue
    }
    /// A Boolean value indicating whether this is an ipv6 address.
    public var isv6:Bool {
        (data[0] & 0b11) == IPAddrType.v6.rawValue
    }
    /// Returns ip address's cidr mask binary representation as String
    public var cidrBitMaskDescription:String {
        mutating get {
            cidr.bytes.map({ $0 == 0 ? String(repeating: "0", count: 8) : String($0, radix: 2) }).joined(separator: ":")
        }
    }
    /// A Boolean value indicating whether this ip address is a loopback address
    public var isLoopbackAddress:Bool {
        switch type {
        case .v4: return (2130706432...2147483647).contains(ipv4rawValue!)
        case .v6: return data == Data([UInt8(1),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1])
        }
    }
    /// Network address of the network this ip address belongs to
    ///
    /// - Returns: Returns `nil` if ip address doesn't represent a network
    /// (is a single end point). Othervice returns network address of the network this ip belongs to with cidr set to
    /// the corresponding network.
    public var networkAddress:IPAddress? {
        let cb = cidr.bytes
        switch type {
        case .v4: return IPAddress(data[1] & cb[0], data[2] & cb[1], data[3] & cb[2], data[4] & cb[3], cidr: cidr.bits)!
        case .v6: return IPAddress(data: Data(zip(data[1...], cb).map({ $0 & $1 })), cidr: cidr.bits)
        }
    }
    /// Router address of the network this ip address belongs to
    ///
    /// - Returns: Returns `nil` if ip address doesn't represent a network
    /// (is a single end point). Othervice returns router's ip address of the network with cidr set to
    /// the corresponding network.
    public var routerAddress:IPAddress? {
        switch type {
        case .v4:
            guard cidr.bits != 32, let netAddr = networkAddress else {
                return nil
            }
            guard netAddr.ipv4rawValue != UInt32.max else {
                return netAddr
            }
            guard let rawNa = netAddr.ipv4rawValue else {
                return nil
            }
            return IPAddress(rawNa + 1, cidr: cidr.bits)
        case .v6:
            guard cidr.bits != 128, var netAddr = networkAddress?.data else {
                return nil
            }
            for i in stride(from: 16, through: 1, by: -1) {
                guard netAddr[i] != 255 else { continue }
                netAddr[i] = netAddr[i] + 1
                break
            }
            return IPAddress(data: netAddr[1...], cidr: cidr.bits)
        }
    }
    /// Broadcast address of the network this ip address belongs to
    ///
    /// - Returns: Returns `nil` if ip address doesn't represent a network
    /// (is a single end point). Othervice returns first ip address of the network with cidr set to
    /// the corresponding network.
    public var broadcastAddress:IPAddress? {
        switch type {
        case .v4:
            guard cidr.bits != 32, let rawValue = networkAddress?.ipv4rawValue else {
                return nil
            }
            let last = rawValue + UInt32(cidr.hostCount - 1)
            return IPAddress(last, cidr: networkAddress!.cidr.bits)
        case .v6:
            guard cidr.bits != 128, let na = networkAddress else {
                return nil
            }
            let orEd = Data(zip(data[1...], cidr.bytes.map({ ~$0 })).map { $0 | $1 })
            return IPAddress(data: orEd, cidr: na.cidr.bits)
        }
    }
    /// A boolean value indicating wheter this ip address contains the other ip address
    ///
    /// - Returns: Returns false when address types don't match.
    /// In case `self` or `other` are network addresses, returns true only if
    /// `self` contains `other` entirely.
    public func contains(_ other:IPAddress) -> Bool {
        
        guard type == other.type else {
            return false
        }
        guard cidr.isSingleEndPoint == false else {
            return self == other
        }
        guard other.cidr.isSingleEndPoint == true else {
            // "this ip address" is network
            // "other" is a network
            // return true if "this network" contains the "other" network entirely

            switch type {
            case .v4:
                guard let na = networkAddress?.ipv4rawValue,
                      let ba = broadcastAddress?.ipv4rawValue,
                      let oa = other.networkAddress?.ipv4rawValue else {
                    return false
                }
                let myRange = na...ba
                return myRange.contains(oa) &&
                myRange.contains(other.broadcastAddress!.ipv4rawValue!)
            case .v6:
                guard let ona = other.networkAddress,
                      let na = networkAddress,
                      let oba = other.broadcastAddress,
                      let ba = broadcastAddress else {
                    return false
                }
                return ona >= na && oba <= ba
            }
        }
        // "this ip address" is a network
        // "other" is a single end point
        // return true if "this network" contains that specific single ip address
        switch type {
        case .v4:
            // both are same type
            guard let oa = other.ipv4rawValue,
                  let na = networkAddress?.ipv4rawValue,
                  let ba = broadcastAddress?.ipv4rawValue else {
                return false
            }
            return oa >= na && oa <= ba
        case .v6:
            // both are same type
            guard let na = networkAddress, let ba = broadcastAddress else {
                return false
            }
            return other >= na && other <= ba
        }
    }
    /// Initializes an ipv4 address
    public init(_ a:UInt8, _ b:UInt8, _ c:UInt8, _ d:UInt8) {
        let u8 = [IPAddrType.v4.rawValue, a, b, c, d]
        self.data = Data(u8)
        self.cidr = CIDR(for: .v4, bits: CIDR.validV4Range.upperBound)
        self.type = .v4
        self.sysendianIpv4 = Self.systemIsLittleEndian ?
        UInt32(d) | UInt32(c)<<8 | UInt32(b)<<16 | UInt32(a)<<24 :
        UInt32(a) | UInt32(b)<<8 | UInt32(c)<<16 | UInt32(d)<<24
    }
    /// Initializes an ipv4 address
    public init?(_ a:UInt8, _ b:UInt8, _ c:UInt8, _ d:UInt8, cidr bits:Int = 32) {
        guard CIDR.validV4Range.contains(bits) else {
            return nil
        }
        let u8 = [IPAddrType.v4.rawValue, a, b, c, d]
        self.data = Data(u8)
        self.cidr = CIDR(for: .v4, bits: bits)
        self.type = .v4
        self.sysendianIpv4 = Self.systemIsLittleEndian ?
        UInt32(d) | UInt32(c)<<8 | UInt32(b)<<16 | UInt32(a)<<24 :
        UInt32(a) | UInt32(b)<<8 | UInt32(c)<<16 | UInt32(d)<<24
    }
    /// Initializes an ipv6 address
    public init(_ a:UInt16, _ b:UInt16, _ c:UInt16, _ d:UInt16, _ e:UInt16, _ f:UInt16, _ g:UInt16, _ h:UInt16) {
        self.cidr = CIDR(for: .v6, bits: CIDR.validV6Range.upperBound)
        if Self.systemIsLittleEndian {
            self.data = Data([IPAddrType.v6.rawValue & 0b11] +
                             [a.byteSwapped, b.byteSwapped, c.byteSwapped, d.byteSwapped,
                              e.byteSwapped, f.byteSwapped, g.byteSwapped, h.byteSwapped].withUnsafeBytes({ Array($0) }))
        }
        else {
            self.data = Data([IPAddrType.v6.rawValue & 0b11] + [a, b, c, d, e, f, g, h].withUnsafeBytes({ Array($0) }))
        }
        self.type = .v6
        self.sysendianIpv4 = 0
    }
    /// Initializes an ipv6 address
    public init?(_ a:UInt16, _ b:UInt16, _ c:UInt16, _ d:UInt16, _ e:UInt16, _ f:UInt16, _ g:UInt16, _ h:UInt16, cidr bits:Int = 128) {
        guard CIDR.validV6Range.contains(bits) else {
            return nil
        }
        self.cidr = CIDR(for: .v6, bits: bits)
        if Self.systemIsLittleEndian {
            self.data = Data([IPAddrType.v6.rawValue & 0b11] +
                             [a.byteSwapped, b.byteSwapped, c.byteSwapped, d.byteSwapped,
                              e.byteSwapped, f.byteSwapped, g.byteSwapped, h.byteSwapped].withUnsafeBytes({ Array($0) }))
        }
        else {
            self.data = Data([IPAddrType.v6.rawValue & 0b11] + [a, b, c, d, e, f, g, h].withUnsafeBytes({ Array($0) }))
        }
        self.type = .v6
        self.sysendianIpv4 = 0
    }
    /// Initializes an ipv4 or ipv6 address from Data
    public init?(data:Data, cidr bits:Int? = nil) {
        switch data.count {
        case 4:
            let b = bits ?? 32
            guard CIDR.validV4Range.contains(b) else {
                return nil
            }
            self.cidr = CIDR(for: .v4, bits: b)
            self.data = [IPAddrType.v4.rawValue & 0b11] + data
            self.type = .v4
        case 16:
            let b = bits ?? 128
            guard CIDR.validV6Range.contains(b) else {
                return nil
            }
            self.cidr = CIDR(for: .v6, bits: b)
            self.data = [IPAddrType.v6.rawValue & 0b11] + data
            self.type = .v6
        default: return nil
        }
        self.sysendianIpv4 = 0
    }
    /// A boolean value indicating wheter current system is little endian
    private static var systemIsLittleEndian:Bool {
        let a:UInt16 = 256
        return withUnsafeBytes(of: a) { (ptr) -> Bool in
            // 256 == 0x0100
            // a+0:01       a+0:00
            // a+1:00       a+1:01
            // big-endian   little-endian
            return ptr[0] < ptr[1] ? true : false
        }
    }
}

public struct IPAddressIterator : IteratorProtocol {
    public typealias Element = IPAddress

    private (set) public var address:IPAddress
    private let limit:IPAddress
    private lazy var isLittleEndian = {
        withUnsafeBytes(of: UInt16(256)) { (ptr) -> Bool in
            return ptr[0] < ptr[1] ? true : false
        }
    }()

    public init(address:IPAddress) {
        self.address = address.networkAddress ?? address
        self.limit = address.broadcastAddress ?? address
    }

    mutating public func next() -> Element? {
        switch address.type {
        case .v4:
            let u32 = address.rawAddressBytes.withUnsafeBytes({
                let p = $0.baseAddress!.assumingMemoryBound(to: UInt32.self).pointee
                return isLittleEndian ? p.byteSwapped : p
            })
            guard address <= limit else { return nil }
            defer {
                self.address = IPAddress(u32 + 1, cidr: address.cidr.bits)
            }
            return self.address
        case .v6:
            let hi = address.rawAddressBytes.withUnsafeBytes({
                let p = $0.baseAddress!.assumingMemoryBound(to: UInt64.self).pointee
                return isLittleEndian ? p.byteSwapped : p
            })
            let lo = address.rawAddressBytes.withUnsafeBytes({
                let p = $0.baseAddress!.advanced(by: MemoryLayout<UInt64>.size).assumingMemoryBound(to: UInt64.self).pointee
                return isLittleEndian ? p.byteSwapped : p
            })
            let newLo:UInt64
            let newHi:UInt64
            if lo < UInt64.max {
                newLo = lo + 1
                newHi = hi
            }
            else {
                if hi < UInt64.max {
                    newHi = hi + 1
                    newLo = 0
                }
                else {
                    // overflow
                    return nil
                }
            }
            var data = Data([address.type.rawValue])
            withUnsafeBytes(of: isLittleEndian ? newHi.byteSwapped : newHi, {
                for i in $0.indices {
                    let foo = $0[i]
                    data.append(foo)
                }
            })
            withUnsafeBytes(of: isLittleEndian ? newLo.byteSwapped : newLo, {
                for i in $0.indices {
                    let foo = $0[i]
                    data.append(foo)
                }
            })

            // Note: We could us (below)
            // let a = IPAddress(data: data[1...], cidr: address.cidr.bits)!
            // as above init will never fail because address is a valid ipv6
            // address.
            guard let nextAddress = IPAddress(data: data[1...], cidr: address.cidr.bits) else { return nil }
            guard address <= limit else { return nil }
            defer {
                self.address = nextAddress
            }
            return self.address
        }
    }
}
public struct IPAddressSequence: Sequence {
    public let startAddress: IPAddress
    public let endAddress: IPAddress
    public init(address:IPAddress) {
        self.startAddress = address.networkAddress ?? address
        self.endAddress = address.broadcastAddress ?? address
    }
    public func makeIterator() -> IPAddressIterator {
        IPAddressIterator(address: startAddress)
    }
    public var underestimatedCount: Int {
        guard startAddress.cidr.hostCount <= BigInt(Int.max) else {
            return Int.max
        }
        return Int(startAddress.cidr.hostCount)
    }
}

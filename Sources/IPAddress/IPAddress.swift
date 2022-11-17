import Foundation
import BigInt
import Parsing

/// Conrete type capable of encapsulating ipv4 and ipv6 addresses
public struct IPAddress : Codable {

    /// Ip address type enumeration
    public enum IPAddrType : UInt8, Codable { case v4 = 0, v6 = 1 }

    /// Data storage for storing ipv6 address type and address bytes
    internal let ipv6rhs:UInt64
    internal let ipv6lhs:UInt64

    /// Data storage for storing an ipv4 address
    ///
    /// Value is stored in current system's endianness (on little endian systems
    /// value is stored as little endian and on big endian systems value is stored
    /// as big endian. Required conversions to network byte order (=big endian)
    /// will happen when needed.
    ///
    /// On both (big- and little endian) systems UInt32(1) will result to ipv4
    /// address 0.0.0.1 and UInt32.max will result in 255.255.255.255.
    internal let sysendianIpv4:UInt32

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
        self.cidr = CIDR(for: .v4, bits: bits)
        self.type = .v4
        self.sysendianIpv4 = u32
        self.ipv6rhs = 0
        self.ipv6lhs = 0
    }

    /// Initializes an ipv4 or ipv6 address
    ///
    /// Initializes an ipv4 or ipv6 address from given UInt8 bytes.
    /// Bytes must be in big endian byte order (a.k.a. network byte order).
    public init?(_ bytes:[UInt8], cidr bits:Int? = nil) {
        switch bytes.count {
        case 4:
            let b = bits ?? 32
            self.cidr = CIDR(for: .v4, bits: b)
            self.type = .v4
            self.sysendianIpv4 = Self.systemIsLittleEndian ?
            UInt32(bytes[3]) | UInt32(bytes[2])<<8 | UInt32(bytes[1])<<16 | UInt32(bytes[0])<<24 :
            UInt32(bytes[0]) | UInt32(bytes[1])<<8 | UInt32(bytes[2])<<16 | UInt32(bytes[3])<<24
            self.ipv6rhs = 0
            self.ipv6lhs = 0
        case 16:
            let b = bits ?? 128
            self.cidr = CIDR(for: .v6, bits: b)
            self.type = .v6
            self.sysendianIpv4 = 0
            if Self.systemIsLittleEndian {
                self.ipv6lhs =
                UInt64(bytes[7])     | UInt64(bytes[6])<<8  | UInt64(bytes[5])<<16 | UInt64(bytes[4])<<24 |
                UInt64(bytes[3])<<32 | UInt64(bytes[2])<<40 | UInt64(bytes[1])<<48 | UInt64(bytes[0])<<56
                self.ipv6rhs =
                UInt64(bytes[15])     | UInt64(bytes[14])<<8  | UInt64(bytes[13])<<16 | UInt64(bytes[12])<<24 |
                UInt64(bytes[11])<<32 | UInt64(bytes[10])<<40 | UInt64(bytes[9])<<48  | UInt64(bytes[8])<<56
            } else {
                self.ipv6lhs =
                UInt64(bytes[0])     | UInt64(bytes[1])<<8  | UInt64(bytes[2])<<16 | UInt64(bytes[3])<<24 |
                UInt64(bytes[4])<<32 | UInt64(bytes[5])<<40 | UInt64(bytes[6])<<48 | UInt64(bytes[7])<<56
                self.ipv6rhs =
                UInt64(bytes[8])      | UInt64(bytes[9])<<8   | UInt64(bytes[10])<<16 | UInt64(bytes[11])<<24 |
                UInt64(bytes[12])<<32 | UInt64(bytes[13])<<40 | UInt64(bytes[14])<<48 | UInt64(bytes[15])<<56
            }
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
        guard type == .v6 else {
            return description
        }
        let uint16bytes:[UInt16]
        if Self.systemIsLittleEndian {
            uint16bytes = [
                UInt16(((ipv6lhs & 0xffff000000000000)>>48)),
                UInt16(((ipv6lhs & 0x0000ffff00000000)>>32)),
                UInt16(((ipv6lhs & 0x00000000ffff0000)>>16)),
                UInt16(((ipv6lhs & 0x000000000000ffff)<<0)),

                UInt16(((ipv6rhs & 0xffff000000000000)>>48)),
                UInt16(((ipv6rhs & 0x0000ffff00000000)>>32)),
                UInt16(((ipv6rhs & 0x00000000ffff0000)>>16)),
                UInt16(((ipv6rhs & 0x000000000000ffff)<<0)),
            ]
        }
        else {
            fatalError("not implemented")
        }
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
        lhs.ipv6lhs == rhs.ipv6lhs && lhs.ipv6rhs == rhs.ipv6rhs && lhs.cidr == rhs.cidr
    }
}
extension IPAddress : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type.rawValue)
        hasher.combine(networkOrderedAddressBytes)
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
                if lhs.ipv6lhs < rhs.ipv6lhs {
                    return true
                }
                else if rhs.ipv6lhs < lhs.ipv6lhs {
                    return false
                }
                else {
                    if lhs.ipv6rhs < rhs.ipv6rhs {
                        return true
                    }
                    else {
                        return false
                    }
                }
            }
        }
    }
}
extension IPAddress : CustomStringConvertible {
    public var description: String {
        switch type {
        case .v4:
            if Self.systemIsLittleEndian {
                return withUnsafeBytes(of: sysendianIpv4, { Array($0) })
                    .reversed()
                    .map({ $0.description })
                    .joined(separator: ".")
            }
            else {
                return withUnsafeBytes(of: sysendianIpv4, { Array($0) })
                    .reversed()
                    .map({ $0.description })
                    .joined(separator: ".")
            }
        case .v6:
            if Self.systemIsLittleEndian {
                let uint16bytes:[UInt16] = [
                        UInt16(((ipv6lhs & 0xffff000000000000)>>48)),
                        UInt16(((ipv6lhs & 0x0000ffff00000000)>>32)),
                        UInt16(((ipv6lhs & 0x00000000ffff0000)>>16)),
                        UInt16(((ipv6lhs & 0x000000000000ffff)<<0)),
                        
                        UInt16(((ipv6rhs & 0xffff000000000000)>>48)),
                        UInt16(((ipv6rhs & 0x0000ffff00000000)>>32)),
                        UInt16(((ipv6rhs & 0x00000000ffff0000)>>16)),
                        UInt16(((ipv6rhs & 0x000000000000ffff)<<0)),
                ]
                return uint16bytes.map({ String($0, radix: 16) }).joined(separator: ":")
            }
            else {
                fatalError("not implemented")
//                return (withUnsafeBytes(of: ipv6lhs, { Array($0) }) + withUnsafeBytes(of: ipv6rhs, { Array($0) }))
//                    .map({ $0.description })
//                    .joined(separator: ":")
            }
        }
    }
}
extension IPAddress : CustomDebugStringConvertible {
    public var debugDescription: String {
        return description + "/\(cidr.bits)"
    }
}
extension IPAddress {
    public static let ipv4localhost = IPAddress(2130706432)
    public static let ipv6localhost = IPAddress(0, 1)
    public static let ipv4unspecifiedAddress = IPAddress(0)
    public static let ipv6unspecifiedAddress = IPAddress(0, 0)
}
extension IPAddress {
    /// A Boolean value indicating whether this ip address is an unspecified address
    public var isUnspecified:Bool {
        type == .v4 ? sysendianIpv4 == 0 : ipv6lhs == 0 && ipv6rhs == 0
    }
    /// A Boolean value indicating whether this ip address is a loopback address
    public var isLoopback:Bool {
        type == .v4 ? (2130706432...2147483647).contains(sysendianIpv4) : ipv6lhs == 0 && ipv6rhs == 1
    }
    /// A Boolean value indicating whether this ip address is a non routable broadcast address
    public var isBroadcast:Bool {
        return type == .v4 ?
        sysendianIpv4 == 0xffffffff
        :
        ipv6lhs == ~0 && ipv6rhs == ~0
    }
    public var isPrivate:Bool {
        return type == .v4 ?
        IPAddress(192, 168, 0, 0, cidr: 16).contains(self) ||
        IPAddress(172, 168, 0, 0, cidr: 12).contains(self) ||
        IPAddress(10, 0, 0, 0, cidr: 8).contains(self)
        :
        IPAddress(0xfd00000000000000, 0, cidr: 8).contains(self)
    }
    public var isLinkLocal:Bool {
        return type == .v4 ?
        IPAddress(169, 254, 0, 0, cidr: 16).contains(self)
        :
        IPAddress(0xfe80000000000000, 0, cidr: 10).contains(self)
    }
    public var isGlobal:Bool {
        self.isUnspecified == false &&
        self.isPrivate == false &&
        self.isLoopback == false &&
        self.isLinkLocal == false &&
        self.isDocumentation == false &&
        self.isBroadcast == false
    }
    public var isMulticast:Bool {
        return type == .v4 ?
        IPAddress(224, 0, 0, 0, cidr: 4).contains(self)
        :
        IPAddress(0xff00000000000000, 0, cidr: 8).contains(self)
    }
    public var isDocumentation:Bool {
        return type == .v4 ?
        IPAddress(192, 0, 2, 0, cidr: 24).contains(self) ||
        IPAddress(198, 51, 100, 0, cidr: 24).contains(self) ||
        IPAddress(203, 0, 113, 0, cidr: 24).contains(self)
        :
        IPAddress(0x20010db800000000, 0, cidr: 32).contains(self)
    }
    // MARK: -
    public var networkOrderedAddressBytes:[UInt8] {
        switch type {
        case .v4:
            if Self.systemIsLittleEndian {
                return [
                    UInt8((sysendianIpv4 & 0xff000000)>>24),
                    UInt8((sysendianIpv4 & 0x00ff0000)>>16),
                    UInt8((sysendianIpv4 & 0x0000ff00)>>8),
                    UInt8(sysendianIpv4  & 0x000000ff)
                ]
            }
            else {
                return [
                    UInt8(sysendianIpv4  & 0x000000ff),
                    UInt8((sysendianIpv4 & 0x0000ff00)>>8),
                    UInt8((sysendianIpv4 & 0x00ff0000)>>16),
                    UInt8((sysendianIpv4 & 0xff000000)>>24)
                ]
            }
        case .v6:
            if Self.systemIsLittleEndian {
                return [
                    UInt8((ipv6lhs & 0xff00000000000000)>>56),
                    UInt8((ipv6lhs & 0x00ff000000000000)>>48),
                    UInt8((ipv6lhs & 0x0000ff0000000000)>>40),
                    UInt8((ipv6lhs & 0x000000ff00000000)>>32),
                    UInt8((ipv6lhs & 0x00000000ff000000)>>24),
                    UInt8((ipv6lhs & 0x0000000000ff0000)>>16),
                    UInt8((ipv6lhs & 0x000000000000ff00)>>8),
                    UInt8((ipv6lhs & 0x00000000000000ff)>>0),

                    UInt8((ipv6rhs & 0xff00000000000000)>>56),
                    UInt8((ipv6rhs & 0x00ff000000000000)>>48),
                    UInt8((ipv6rhs & 0x0000ff0000000000)>>40),
                    UInt8((ipv6rhs & 0x000000ff00000000)>>32),
                    UInt8((ipv6rhs & 0x00000000ff000000)>>24),
                    UInt8((ipv6rhs & 0x0000000000ff0000)>>16),
                    UInt8((ipv6rhs & 0x000000000000ff00)>>8),
                    UInt8((ipv6rhs & 0x00000000000000ff)>>0)
                ]
            }
            else {
                return [
                    UInt8((ipv6lhs & 0x00000000000000ff)),
                    UInt8((ipv6lhs & 0x000000000000ff00)>>8),
                    UInt8((ipv6lhs & 0x0000000000ff0000)>>16),
                    UInt8((ipv6lhs & 0x00000000ff000000)>>24),
                    UInt8((ipv6lhs & 0x000000ff00000000)>>32),
                    UInt8((ipv6lhs & 0x0000ff0000000000)>>40),
                    UInt8((ipv6lhs & 0x00ff000000000000)>>48),
                    UInt8((ipv6lhs & 0xff00000000000000)>>56),

                    UInt8((ipv6rhs & 0x00000000000000ff)),
                    UInt8((ipv6rhs & 0x000000000000ff00)>>8),
                    UInt8((ipv6rhs & 0x0000000000ff0000)>>16),
                    UInt8((ipv6rhs & 0x00000000ff000000)>>24),
                    UInt8((ipv6rhs & 0x000000ff00000000)>>32),
                    UInt8((ipv6rhs & 0x0000ff0000000000)>>40),
                    UInt8((ipv6rhs & 0x00ff000000000000)>>48),
                    UInt8((ipv6rhs & 0xff00000000000000)>>56),
                ]
            }
        }
    }
    public var rawAddressBytes:Data {
        return Data(networkOrderedAddressBytes)
    }
    private var ipv4rawValue:UInt32? {
        guard cidr.bits <= 32, type == .v4 else { return nil }
        return Self.systemIsLittleEndian ? sysendianIpv4 : sysendianIpv4.byteSwapped
    }
    /// Returns ip address's cidr mask binary representation as String
    public var cidrBitMaskDescription:String {
        mutating get {
            cidr.bytes.map({ $0 == 0 ? String(repeating: "0", count: 8) : String($0, radix: 2) }).joined(separator: ":")
        }
    }
    /// Network address of the network this ip address belongs to
    ///
    /// - Returns: Returns `nil` if ip address doesn't represent a network
    /// (is a single end point). Othervice returns network address of the network this ip belongs to with cidr set to
    /// the corresponding network.
    public var networkAddress:IPAddress? {
        let cb = cidr.bytes
        return IPAddress(zip(networkOrderedAddressBytes, cb).map({ $0 & $1 }), cidr: cidr.bits)
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
            guard netAddr.sysendianIpv4 != UInt32.max else { return netAddr }
            return IPAddress(netAddr.sysendianIpv4 + 1, cidr: cidr.bits)
        case .v6:
            guard cidr.bits != 128, var netAddrBytes = networkAddress?.networkOrderedAddressBytes else {
                return nil
            }
            for i in stride(from: 15, through: 0, by: -1) {
                guard netAddrBytes[i] != 255 else { continue }
                netAddrBytes[i] = netAddrBytes[i] + 1
                break
            }
            return IPAddress(netAddrBytes, cidr: cidr.bits)
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
            guard cidr.bits != 32, let rawValue = networkAddress else {
                return nil
            }
            let last = rawValue.sysendianIpv4 + UInt32(cidr.hostCount - 1)
            return IPAddress(last, cidr: rawValue.cidr.bits)
        case .v6:
            guard cidr.bits != 128, let na = networkAddress else {
                return nil
            }
            let orEd = zip(networkOrderedAddressBytes, cidr.bytes.map({ ~$0 })).map { $0 | $1 }
            return IPAddress(orEd, cidr: na.cidr.bits)
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
                guard let na = networkAddress?.sysendianIpv4,
                      let ba = broadcastAddress?.sysendianIpv4,
                      let oa = other.networkAddress?.sysendianIpv4 else {
                    return false
                }
                let myRange = na...ba
                return myRange.contains(oa) && myRange.contains(other.broadcastAddress!.sysendianIpv4)
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
            guard let na = networkAddress?.sysendianIpv4,
                  let ba = broadcastAddress?.sysendianIpv4 else {
                return false
            }
            return other.sysendianIpv4 >= na && other.sysendianIpv4 <= ba
        case .v6:
            // both are same type
            guard let na = networkAddress, let ba = broadcastAddress else {
                return false
            }
            return other >= na && other <= ba
        }
    }
    /// Initializes an ipv6 address
    internal init(_ lhs:UInt64, _ rhs:UInt64, cidr bits:Int = 128) {
        self.type = .v6
        self.sysendianIpv4 = 0
        self.ipv6lhs = lhs
        self.ipv6rhs = rhs
        self.cidr = CIDR(for: .v6, bits: bits)
    }
    /// Initializes an ipv4 address
    public init(_ a:UInt8, _ b:UInt8, _ c:UInt8, _ d:UInt8) {
        self.cidr = CIDR(for: .v4, bits: CIDR.validV4Range.upperBound)
        self.type = .v4
        self.sysendianIpv4 = Self.systemIsLittleEndian ?
        UInt32(d) | UInt32(c)<<8 | UInt32(b)<<16 | UInt32(a)<<24 :
        UInt32(a) | UInt32(b)<<8 | UInt32(c)<<16 | UInt32(d)<<24
        self.ipv6rhs = 0
        self.ipv6lhs = 0
    }
    /// Initializes an ipv4 address
    public init(_ a:UInt8, _ b:UInt8, _ c:UInt8, _ d:UInt8, cidr bits:Int = 32) {
        self.cidr = CIDR(for: .v4, bits: bits)
        self.type = .v4
        self.sysendianIpv4 = Self.systemIsLittleEndian ?
        UInt32(d) | UInt32(c)<<8 | UInt32(b)<<16 | UInt32(a)<<24 :
        UInt32(a) | UInt32(b)<<8 | UInt32(c)<<16 | UInt32(d)<<24
        self.ipv6rhs = 0
        self.ipv6lhs = 0
    }
    /// Initializes an ipv6 address
    public init(_ a:UInt16, _ b:UInt16, _ c:UInt16, _ d:UInt16, _ e:UInt16, _ f:UInt16, _ g:UInt16, _ h:UInt16) {
        self.cidr = CIDR(for: .v6, bits: CIDR.validV6Range.upperBound)
        if Self.systemIsLittleEndian {
            self.ipv6rhs =
            UInt64(h) | UInt64(g)<<16 |
            UInt64(f)<<32 | UInt64(e)<<48
            self.ipv6lhs =
            UInt64(d) | UInt64(c)<<16 |
            UInt64(b)<<32 | UInt64(a)<<48
        }
        else {
            self.ipv6rhs =
            UInt64(a.byteSwapped) | UInt64(b.byteSwapped)<<16 |
            UInt64(c.byteSwapped)<<32 | UInt64(d.byteSwapped)<<48
            self.ipv6lhs =
            UInt64(e.byteSwapped) | UInt64(f.byteSwapped)<<16 |
            UInt64(g.byteSwapped)<<32 | UInt64(h.byteSwapped)<<48
        }
        self.type = .v6
        self.sysendianIpv4 = 0
    }
    /// Initializes an ipv6 address
    public init(_ a:UInt16, _ b:UInt16, _ c:UInt16, _ d:UInt16, _ e:UInt16, _ f:UInt16, _ g:UInt16, _ h:UInt16, cidr bits:Int = 128) {
        self.cidr = CIDR(for: .v6, bits: bits)
        if Self.systemIsLittleEndian {
            self.ipv6rhs =
            UInt64(h) | UInt64(g)<<16 |
            UInt64(f)<<32 | UInt64(e)<<48
            self.ipv6lhs =
            UInt64(d) | UInt64(c)<<16 |
            UInt64(b)<<32 | UInt64(a)<<48
        }
        else {
            self.ipv6rhs =
            UInt64(a.byteSwapped) | UInt64(b.byteSwapped)<<16 |
            UInt64(c.byteSwapped)<<32 | UInt64(d.byteSwapped)<<48
            self.ipv6lhs =
            UInt64(e.byteSwapped) | UInt64(f.byteSwapped)<<16 |
            UInt64(g.byteSwapped)<<32 | UInt64(h.byteSwapped)<<48
        }
        self.sysendianIpv4 = 0
        self.type = .v6
    }
    /// Initializes an ipv4 or ipv6 address from Data
    public init?(data:Data, cidr bits:Int? = nil) {
        switch data.count {
        case 4:
            let b = bits ?? 32
            guard CIDR.validV4Range.contains(b) else {
                return nil
            }
            self.init(data.withUnsafeBytes({ Array($0) }), cidr: b)
        case 16:
            let b = bits ?? 128
            guard CIDR.validV6Range.contains(b) else {
                return nil
            }
            self.init(data.withUnsafeBytes({ Array($0) }), cidr: b)

        default: return nil
        }
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
//            let u32 = address.rawAddressBytes.withUnsafeBytes({
//                let p = $0.baseAddress!.assumingMemoryBound(to: UInt32.self).pointee
//                return isLittleEndian ? p.byteSwapped : p
//            })
            guard address <= limit else { return nil }
            defer {
                self.address = IPAddress(address.sysendianIpv4 + 1, cidr: address.cidr.bits)
            }
            return self.address
        case .v6:
            guard address <= limit else { return nil }
            if address.ipv6rhs == UInt64.max {
                if address.ipv6lhs == UInt64.max {
                    return nil
                }
                else {
                    defer {
                        self.address = IPAddress(address.ipv6lhs + 1, 0, cidr: address.cidr.bits)
                    }
                    return self.address
                }
            }
            else {
                defer {
                    self.address = IPAddress(address.ipv6lhs, address.ipv6rhs + 1, cidr: address.cidr.bits)
                }
                return self.address
            }
            /*
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

            // Note: We could use (below)
            // let a = IPAddress(data: data[1...], cidr: address.cidr.bits)!
            // as above init will never fail because address is a valid ipv6
            // address.
            guard let nextAddress = IPAddress(data: data[1...], cidr: address.cidr.bits) else { return nil }
            guard address <= limit else { return nil }
            defer {
                self.address = nextAddress
            }
            return self.address*/
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

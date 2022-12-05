import Foundation
import Parsing

/// Conrete type capable of encapsulating ipv4 and ipv6 addresses
public struct IPAddress : Codable {

    /// Ip address type enumeration
    public enum IPAddrType : UInt16, Codable { case v4 = 0, v6 = 1 }

    /// Parsing options
    public struct ParsingOptions : OptionSet {
        public let rawValue: Int
        public init(rawValue:Int) {
            self.rawValue = rawValue
        }
        public static let noLeadingZeros   = ParsingOptions(rawValue: 1 << Opts.noLeadingZeros.rawValue)
        public static let noZeroSupression = ParsingOptions(rawValue: 1 << Opts.noZeroSupression.rawValue)
        public static let noUppercase      = ParsingOptions(rawValue: 1 << Opts.noUppercase.rawValue)
        public static let ipv4Only         = ParsingOptions(rawValue: 1 << Opts.ipv4Only.rawValue)
        public static let ipv6Only         = ParsingOptions(rawValue: 1 << Opts.ipv6Only.rawValue)

        enum Opts : Int, CaseIterable {
            case noLeadingZeros
            case noZeroSupression
            case noUppercase
            case ipv4Only
            case ipv6Only
        }
        public static var allCases: [IPAddress.ParsingOptions] = Opts.allCases
            .filter({ $0.rawValue < (MemoryLayout<Int>.size * 8)})
            .map { ParsingOptions(rawValue: 1 << $0.rawValue) }
        public static func < (lhs: IPAddress.ParsingOptions, rhs: IPAddress.ParsingOptions) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
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
    public let cidrBits:Int
    public let networkMask:[UInt8]
    @inline(__always)
    private static func genv4MaskBytes(bits:Int) -> [UInt8] {
        let lhs = UInt32.max<<(32-bits)
        if Self.systemIsLittleEndian {
            return [
                UInt8((lhs & 0xff000000)>>24),
                UInt8((lhs & 0x00ff0000)>>16),
                UInt8((lhs & 0x0000ff00)>>8),
                UInt8((lhs & 0x000000ff)),
            ]
        }
        else {
            return [
                UInt8((lhs & 0x000000ff)),
                UInt8((lhs & 0x0000ff00)>>8),
                UInt8((lhs & 0x00ff0000)>>16),
                UInt8((lhs & 0xff000000)>>24),
            ]
        }
    }
    @inline(__always)
    private static func genv6MaskBytes(bits:Int) -> [UInt8] {
        var lhs:UInt64 = UInt64.max
        var rhs:UInt64 = UInt64.max
        let f = 128 - bits
        if f > 64 {
            rhs = 0
            lhs = lhs<<(f - 64)
        }
        else {
            rhs = rhs<<f
        }
        let returnValue:[UInt8]
        if Self.systemIsLittleEndian {
            returnValue =  [
                UInt8((lhs & 0xff00000000000000)>>56),
                UInt8((lhs & 0x00ff000000000000)>>48),
                UInt8((lhs & 0x0000ff0000000000)>>40),
                UInt8((lhs & 0x000000ff00000000)>>32),
                UInt8((lhs & 0x00000000ff000000)>>24),
                UInt8((lhs & 0x0000000000ff0000)>>16),
                UInt8((lhs & 0x000000000000ff00)>>8 ),
                UInt8((lhs & 0x00000000000000ff)),
                
                UInt8((rhs & 0xff00000000000000)>>56),
                UInt8((rhs & 0x00ff000000000000)>>48),
                UInt8((rhs & 0x0000ff0000000000)>>40),
                UInt8((rhs & 0x000000ff00000000)>>32),
                UInt8((rhs & 0x00000000ff000000)>>24),
                UInt8((rhs & 0x0000000000ff0000)>>16),
                UInt8((rhs & 0x000000000000ff00)>>8 ),
                UInt8(rhs & 0x00000000000000ff),
            ]
        }
        else {
            returnValue =  [
                UInt8((lhs & 0x00000000000000ff)),
                UInt8((lhs & 0x000000000000ff00)>>8 ),
                UInt8((lhs & 0x0000000000ff0000)>>16),
                UInt8((lhs & 0x00000000ff000000)>>24),
                UInt8((lhs & 0x000000ff00000000)>>32),
                UInt8((lhs & 0x0000ff0000000000)>>40),
                UInt8((lhs & 0x00ff000000000000)>>48),
                UInt8((lhs & 0xff00000000000000)>>56),
                
                UInt8(rhs & 0x00000000000000ff),
                UInt8((rhs & 0x000000000000ff00)>>8 ),
                UInt8((rhs & 0x0000000000ff0000)>>16),
                UInt8((rhs & 0x00000000ff000000)>>24),
                UInt8((rhs & 0x000000ff00000000)>>32),
                UInt8((rhs & 0x0000ff0000000000)>>40),
                UInt8((rhs & 0x00ff000000000000)>>48),
                UInt8((rhs & 0xff00000000000000)>>56),
            ]
        }
        return returnValue
    }
    /// Returns an enumeration value describing the contained ip address type
    public let type:IPAddrType

    /// Initializes an ipv4 address
    ///
    /// Initializes an ipv4 address from UInt32 value.
    ///
    /// Initializing IPAddress with UInt32(1) will result in 0.0.0.1 and
    /// with UInt32.max will result in 255.255.255.255.
    public init(_ u32: UInt32, cidr bits:Int = 32) {
        precondition(Self.validV4CIDRRange.contains(bits))
        self.cidrBits = bits
        self.type = .v4
        self.sysendianIpv4 = u32
        self.ipv6rhs = 0
        self.ipv6lhs = 0
        self.networkMask = Self.genv4MaskBytes(bits: bits)
    }

    /// Initializes an ipv4 or ipv6 address
    ///
    /// Initializes an ipv4 or ipv6 address from given UInt8 bytes.
    /// Bytes must be in big endian byte order (a.k.a. network byte order).
    public init?(bytes:[UInt8], cidr bits:Int? = nil) {
        switch bytes.count {
        case 4:
            let b = bits ?? Self.validV4CIDRRange.upperBound
            precondition(Self.validV4CIDRRange.contains(b))
            self.networkMask = Self.genv4MaskBytes(bits: b)
            self.cidrBits = b
            self.type = .v4
            self.sysendianIpv4 = Self.systemIsLittleEndian ?
            UInt32(bytes[3]) | UInt32(bytes[2])<<8 | UInt32(bytes[1])<<16 | UInt32(bytes[0])<<24 :
            UInt32(bytes[0]) | UInt32(bytes[1])<<8 | UInt32(bytes[2])<<16 | UInt32(bytes[3])<<24
            self.ipv6rhs = 0
            self.ipv6lhs = 0
        case 16:
            let b = bits ?? Self.validV6CIDRRange.upperBound
            precondition(Self.validV6CIDRRange.contains(b))
            self.networkMask = Self.genv6MaskBytes(bits: b)
            self.cidrBits = b
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
    public init?(_ string:String, options:ParsingOptions = ParsingOptions()) {
        guard let validAddress = parser(string, options: options) else {
            return nil
        }
        self = validAddress
    }
}
// MARK: -
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
        lhs.sysendianIpv4 == rhs.sysendianIpv4 && lhs.cidrBits == rhs.cidrBits :
        lhs.ipv6lhs == rhs.ipv6lhs && lhs.ipv6rhs == rhs.ipv6rhs && lhs.cidrBits == rhs.cidrBits
    }
}
extension IPAddress : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type.rawValue)
        hasher.combine(networkOrderedAddressBytes)
        hasher.combine(cidrBits)
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
            let str:String
            if Self.systemIsLittleEndian {
                str =
                UInt8((sysendianIpv4 & 0xff000000)>>24).description + "." +
                UInt8((sysendianIpv4 & 0x00ff0000)>>16).description + "." +
                UInt8((sysendianIpv4 & 0x0000ff00)>>8).description + "." +
                UInt8((sysendianIpv4 & 0x000000ff)).description
            }
            else {
                str =
                UInt8((sysendianIpv4 & 0x000000ff)).description + "." +
                UInt8((sysendianIpv4 & 0x0000ff00)>>8).description + "." +
                UInt8((sysendianIpv4 & 0x00ff0000)>>16).description + "." +
                UInt8((sysendianIpv4 & 0xff000000)>>24).description
            }
            return str
        case .v6:
            let str:String
            if Self.systemIsLittleEndian {
                str =
                String(UInt16(((ipv6lhs & 0xffff000000000000)>>48)), radix: 16) + ":" +
                String(UInt16(((ipv6lhs & 0x0000ffff00000000)>>32)), radix: 16) + ":" +
                String(UInt16(((ipv6lhs & 0x00000000ffff0000)>>16)), radix: 16) + ":" +
                String(UInt16(((ipv6lhs & 0x000000000000ffff)<<0)), radix: 16) + ":" +
                
                String(UInt16(((ipv6rhs & 0xffff000000000000)>>48)), radix: 16) + ":" +
                String(UInt16(((ipv6rhs & 0x0000ffff00000000)>>32)), radix: 16) + ":" +
                String(UInt16(((ipv6rhs & 0x00000000ffff0000)>>16)), radix: 16) + ":" +
                String(UInt16(((ipv6rhs & 0x000000000000ffff)<<0)), radix: 16)
            }
            else {
                str =
                String(UInt16(((ipv6lhs & 0x00000000000000ff)<<8)  | ((ipv6lhs & 0x000000000000ff00)>>8)), radix: 16) + ":" +
                String(UInt16(((ipv6lhs & 0x0000000000ff0000)>>8)  | ((ipv6lhs & 0x00000000ff000000)>>24)), radix: 16) + ":" +
                String(UInt16(((ipv6lhs & 0x000000ff00000000)>>16) | ((ipv6lhs & 0x0000ff0000000000)>>40)), radix: 16) + ":" +
                String(UInt16(((ipv6lhs & 0x00ff000000000000)>>40) | ((ipv6lhs & 0xff00000000000000)>>56)), radix: 16) + ":" +
                
                String(UInt16(((ipv6rhs & 0x00000000000000ff)<<8)  | ((ipv6rhs & 0x000000000000ff00)>>8)), radix: 16) + ":" +
                String(UInt16(((ipv6rhs & 0x0000000000ff0000)>>8)  | ((ipv6rhs & 0x00000000ff000000)>>24)), radix: 16) + ":" +
                String(UInt16(((ipv6rhs & 0x000000ff00000000)>>16) | ((ipv6rhs & 0x0000ff0000000000)>>40)), radix: 16) + ":" +
                String(UInt16(((ipv6rhs & 0x00ff000000000000)>>40) | ((ipv6rhs & 0xff00000000000000)>>56)), radix: 16)
            }
            return str
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
            uint16bytes = [
                UInt16(((ipv6lhs & 0x00000000000000ff)<<8)  | ((ipv6lhs & 0x000000000000ff00)>>8)),
                UInt16(((ipv6lhs & 0x0000000000ff0000)>>8)  | ((ipv6lhs & 0x00000000ff000000)>>24)),
                UInt16(((ipv6lhs & 0x000000ff00000000)>>16) | ((ipv6lhs & 0x0000ff0000000000)>>40)),
                UInt16(((ipv6lhs & 0x00ff000000000000)>>40) | ((ipv6lhs & 0xff00000000000000)>>56)),
                
                UInt16(((ipv6rhs & 0x00000000000000ff)<<8)  | ((ipv6rhs & 0x000000000000ff00)>>8)),
                UInt16(((ipv6rhs & 0x0000000000ff0000)>>8)  | ((ipv6rhs & 0x00000000ff000000)>>24)),
                UInt16(((ipv6rhs & 0x000000ff00000000)>>16) | ((ipv6rhs & 0x0000ff0000000000)>>40)),
                UInt16(((ipv6rhs & 0x00ff000000000000)>>40) | ((ipv6rhs & 0xff00000000000000)>>56)),
            ]
        }
        guard var s = uint16bytes.firstIndex(of: 0) else {
            return "\(description)"
        }
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
        guard longestZeroStrikeAt > -1 else {
            return "\(description)"
        }
        let a = pairs[longestZeroStrikeAt]
        
        let h = uint16bytes[..<a.startIndex].map({
            String(Self.systemIsLittleEndian ? $0 : $0.byteSwapped, radix: 16)
        }).joined(separator: ":") + ":"
        let t = ":" + uint16bytes[a.endIndex...].map({
            String(Self.systemIsLittleEndian ? $0 : $0.byteSwapped, radix: 16)
        }).joined(separator: ":")
        
        return h + t
    }
}
extension IPAddress : CustomDebugStringConvertible {
    public var debugDescription: String {
        return description + "/\(cidrBits)"
    }
    public var compactDebugDescription:String {
        return compactDescription + "/\(cidrBits)"
    }
}
// MARK: -
extension IPAddress {
    /// Valid range for ipv4 bitmask values
    internal static let validV4CIDRRange:ClosedRange<Int> = (0...32)
    /// Valid range for ipv6 bitmask values
    internal static let validV6CIDRRange:ClosedRange<Int> = (0...128)

    public static let ipv4localhost = IPAddress(2130706432)
    public static let ipv6localhost = IPAddress(0, 1)
    public static let ipv4unspecifiedAddress = IPAddress(0)
    public static let ipv6unspecifiedAddress = IPAddress(0, 0)
    // MARK: -
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
    public var underestimatedHostCount:Int {
        if type == .v4, Self.validV4CIDRRange.contains(cidrBits) {
            let v4:[Int] = [4294967296, 2147483648, 1073741824, 536870912, 268435456, 134217728, 67108864, 33554432, 16777216, 8388608, 4194304, 2097152, 1048576, 524288, 262144, 131072, 65536, 32768, 16384, 8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1]
            return cidrBits < v4.count ? v4[cidrBits] : Int.max
        }
        else {
            let v6:[Int] = [4611686018427387904, 2305843009213693952, 1152921504606846976, 576460752303423488, 288230376151711744, 144115188075855872, 72057594037927936, 36028797018963968, 18014398509481984, 9007199254740992, 4503599627370496, 2251799813685248, 1125899906842624, 562949953421312, 281474976710656, 140737488355328, 70368744177664, 35184372088832, 17592186044416, 8796093022208, 4398046511104, 2199023255552, 1099511627776, 549755813888, 274877906944, 137438953472, 68719476736, 34359738368, 17179869184, 8589934592, 4294967296, 2147483648, 1073741824, 536870912, 268435456, 134217728, 67108864, 33554432, 16777216, 8388608, 4194304, 2097152, 1048576, 524288, 262144, 131072, 65536, 32768, 16384, 8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1]
            let c = cidrBits - 66
            return (0..<v6.count).contains(c) ? v6[c] : Int.max
        }
    }

    // MARK: -
    /// Network address of the network this ip address belongs to
    ///
    /// - Returns: Returns `nil` if ip address doesn't represent a network
    /// (is a single end point). Othervice returns network address of the network this ip belongs to with cidr set to
    /// the corresponding network.
    public var networkAddress:IPAddress? {
        return IPAddress(bytes: zip(networkOrderedAddressBytes, networkMask).map({ $0 & $1 }), cidr: cidrBits)
    }
    /// Router address of the network this ip address belongs to
    ///
    /// - Returns: Returns `nil` if ip address doesn't represent a network
    /// (is a single end point). Othervice returns router's ip address of the network with cidr set to
    /// the corresponding network.
    public var routerAddress:IPAddress? {
        switch type {
        case .v4:
            guard cidrBits != Self.validV4CIDRRange.upperBound, let netAddr = networkAddress else {
                return nil
            }
            guard netAddr.sysendianIpv4 != UInt32.max else { return netAddr }
            return IPAddress(netAddr.sysendianIpv4 + 1, cidr: cidrBits)
        case .v6:
            guard cidrBits != Self.validV6CIDRRange.upperBound, var netAddrBytes = networkAddress?.networkOrderedAddressBytes else {
                return nil
            }
            for i in stride(from: 15, through: 0, by: -1) {
                guard netAddrBytes[i] != 255 else { continue }
                netAddrBytes[i] = netAddrBytes[i] + 1
                break
            }
            return IPAddress(bytes: netAddrBytes, cidr: cidrBits)
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
            guard cidrBits != Self.validV4CIDRRange.upperBound, let networkAddress = networkAddress else {
                return nil
            }
            let last = networkAddress.sysendianIpv4 + UInt32(underestimatedHostCount - 1)
            return IPAddress(last, cidr: networkAddress.cidrBits)
        case .v6:
            guard cidrBits != Self.validV6CIDRRange.upperBound, let na = networkAddress else {
                return nil
            }
            let bytes = zip(networkOrderedAddressBytes, networkMask.map({ ~$0 })).map { $0 | $1 }
            return IPAddress(bytes: bytes, cidr: na.cidrBits)
        }
    }
    // MARK: -
    /// A boolean value indicating wheter this ip address contains the other ip address
    ///
    /// - Returns: Returns false when address types don't match.
    /// In case `self` or `other` are network addresses, returns true only if
    /// `self` contains `other` entirely.
    public func contains(_ other:IPAddress) -> Bool {
        guard self != other else {
            return true
        }
        guard type == other.type else {
            return false
        }
        guard let na = networkAddress,
              let ba = broadcastAddress else {
            return false
        }
        guard let ona = other.networkAddress,
              let oba = other.broadcastAddress else {
            return other >= na && other <= ba
        }
        return ona >= na && oba <= ba
    }
    /// Returns a ip address that is offset the specified distance from this ip address.
    ///
    /// - Returns: When clamping is `false`, returns an ip address (with single
    ///  endpoint cidr) that is offset the specified distance from this ip address.
    ///  Returns `nil` if offset overflows the ip's addressable range.
    ///  When clamping is `true`, returns an ip address (with same cidr as original
    ///  ip address) that is offset the specified distance from this ip address
    ///  or `nil`if offset overflows the original ip addresse's network range.
    ///
    /// Example
    ///
    ///     // unclamped
    ///     let ip = IPAddress(192, 0, 2, 0, cidr: 24)
    ///     let offsetted = ip.advanced(by: -1) // 192.0.1.255/32
    ///
    ///     // clamped
    ///     let ip = IPAddress(192, 0, 2, 0, cidr: 24)
    ///     let next = ip.advanced(by: 1, clamped: true) // 192.0.2.1/24
    ///     let prev = ip.advanced(by: -1, clamped: true) // nil
    ///
    public func advanced(by: Int, clamped:Bool = false) -> IPAddress? {
        guard by != 0 else { return self } // return quickly
        if type == .v4 {
            guard let u32 = UInt32(exactly: Int(sysendianIpv4) + by) else { return nil }
            let newIp = IPAddress(u32, cidr: cidrBits)
            guard clamped == true, let na = networkAddress else {
                return IPAddress(u32, cidr: Self.validV4CIDRRange.upperBound)
            }
            guard na.contains(newIp) else {
                return nil
            }
            return newIp
        }
        else {
            guard by != Int.min else { return nil } // -Int.min would overflow
            let (r,ro) = by.signum() > 0 ? ipv6rhs.addingReportingOverflow(UInt64(by)) : ipv6rhs.subtractingReportingOverflow(UInt64(-by))
            guard ro == false else {
                let (l,lo) = by.signum() > 0 ? ipv6lhs.addingReportingOverflow(1) : ipv6lhs.subtractingReportingOverflow(1)
                guard lo == false else {
                    return nil
                }
                let newIp = IPAddress(l, r, cidr: Self.validV6CIDRRange.upperBound)
                guard clamped == true, let na = networkAddress else {
                    return newIp
                }
                guard na.contains(newIp) else {
                    return nil
                }
                return newIp
            }
            let newIp = IPAddress(ipv6lhs, r, cidr: cidrBits)
            guard clamped == true, let na = networkAddress else {
                return newIp
            }
            guard na.contains(newIp) else {
                return nil
            }
            return newIp
        }
    }
    // MARK: -
    /// Initializes an ipv6 address
    internal init(_ lhs:UInt64, _ rhs:UInt64, cidr bits:Int = 128) {
        precondition(Self.validV6CIDRRange.contains(bits))
        self.type = .v6
        self.sysendianIpv4 = 0
        self.ipv6lhs = lhs
        self.ipv6rhs = rhs
        self.cidrBits = bits
        self.networkMask = Self.genv6MaskBytes(bits: bits)
    }
    /// Initializes an ipv4 address
    public init(_ a:UInt8, _ b:UInt8, _ c:UInt8, _ d:UInt8) {
        self.cidrBits = Self.validV4CIDRRange.upperBound
        self.type = .v4
        self.sysendianIpv4 = Self.systemIsLittleEndian ?
        UInt32(d) | UInt32(c)<<8 | UInt32(b)<<16 | UInt32(a)<<24 :
        UInt32(a) | UInt32(b)<<8 | UInt32(c)<<16 | UInt32(d)<<24
        self.ipv6rhs = 0
        self.ipv6lhs = 0
        self.networkMask = Self.genv4MaskBytes(bits: Self.validV4CIDRRange.upperBound)
    }
    /// Initializes an ipv4 address
    public init(_ a:UInt8, _ b:UInt8, _ c:UInt8, _ d:UInt8, cidr bits:Int = 32) {
        precondition(Self.validV4CIDRRange.contains(bits))
        self.cidrBits = bits
        self.type = .v4
        self.sysendianIpv4 = Self.systemIsLittleEndian ?
        UInt32(d) | UInt32(c)<<8 | UInt32(b)<<16 | UInt32(a)<<24 :
        UInt32(a) | UInt32(b)<<8 | UInt32(c)<<16 | UInt32(d)<<24
        self.ipv6rhs = 0
        self.ipv6lhs = 0
        self.networkMask = Self.genv4MaskBytes(bits: bits)
    }
    /// Initializes an ipv6 address
    public init(_ a:UInt16, _ b:UInt16, _ c:UInt16, _ d:UInt16, _ e:UInt16, _ f:UInt16, _ g:UInt16, _ h:UInt16) {
        self.cidrBits = Self.validV6CIDRRange.upperBound
        self.networkMask = Self.genv6MaskBytes(bits: Self.validV6CIDRRange.upperBound)
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
        precondition(Self.validV6CIDRRange.contains(bits))
        self.cidrBits = bits
        self.networkMask = Self.genv6MaskBytes(bits: bits)
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
        self.init(bytes: data.withUnsafeBytes({ Array($0) }), cidr: bits)
    }
    /// A boolean value indicating wheter current system is little endian
    private static var systemIsLittleEndian:Bool {
        UInt16(256).littleEndian & 0x00ff == 0
    }
}
// MARK: -
/// An iterator over the elements of type IPAddress
public struct IPAddressIterator : IteratorProtocol {
    public typealias Element = IPAddress

    private (set) public var address:IPAddress?
    private let limit:IPAddress
    private let clamped:Bool
    private lazy var isLittleEndian = {
        UInt16(256).littleEndian & 0x00ff == 0
    }()

    public init(address:IPAddress, clamped:Bool = false) {
        self.address = address.networkAddress ?? address
        self.limit = address.broadcastAddress ?? address
        self.clamped = clamped
    }

    mutating public func next() -> Element? {
        guard let address = self.address else {
            return nil
        }
        switch address.type {
        case .v4:
            guard address <= limit || clamped == false else { return nil }
            if address.sysendianIpv4 == UInt32.max {
                defer {
                    self.address = nil
                }
                return self.address
            }
            defer {
                self.address = IPAddress(address.sysendianIpv4 + 1, cidr: address.cidrBits)
            }
            return self.address
        case .v6:
            guard address <= limit || clamped == false else {
                return nil
            }
            if address.ipv6rhs == UInt64.max {
                if address.ipv6lhs == UInt64.max {
                    defer {
                        self.address = nil
                    }
                    return self.address
                }
                else {
                    defer {
                        self.address = IPAddress(address.ipv6lhs + 1, 0, cidr: address.cidrBits)
                    }
                    return self.address
                }
            }
            else {
                defer {
                    self.address = IPAddress(address.ipv6lhs, address.ipv6rhs + 1, cidr: address.cidrBits)
                }
                return self.address
            }
        }
    }
}
// MARK: -
/// A type providing sequential, iterated access to IPAddress elements.
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
        startAddress.underestimatedHostCount
    }
}

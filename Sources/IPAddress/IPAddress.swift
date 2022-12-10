import Foundation

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
        /// Don't aallow leading zeroes on ipv6 addresses
        ///
        /// Example
        ///
        ///     IPAddress("0abc", options: .noLeadingZeros) // nil
        public static let noLeadingZeros = ParsingOptions(rawValue: 1 << Opts.noLeadingZeros.rawValue)
        /// Don't allow zero suppression on ipv6 addresses
        ///
        /// Example
        ///
        ///     IPAddress("ffff::", options: .noZeroSupression) // nil
        public static let noZeroSupression = ParsingOptions(rawValue: 1 << Opts.noZeroSupression.rawValue)
        /// Don't allow uppercase letters in ipv6 addresses
        ///
        /// Example
        ///
        ///     IPAddress("ABCD::", options: .noUppercase) // nil
        public static let noUppercase = ParsingOptions(rawValue: 1 << Opts.noUppercase.rawValue)
        /// Parse ipv4 addresses only (discards all ipv6 addresses)
        ///
        /// Example
        ///
        ///     IPAddress("::1", options: .ipv4Only) // nil
        public static let ipv4Only = ParsingOptions(rawValue: 1 << Opts.ipv4Only.rawValue)
        /// Parse ipv6 addresses only (discards all ipv4 addresses)
        ///
        /// Example
        ///
        ///     IPAddress("192.168.5.4", options: .ipv6Only) // nil
        public static let ipv6Only = ParsingOptions(rawValue: 1 << Opts.ipv6Only.rawValue)

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
    /// Data storage for storing ipv6 address type and address bytes (rhs)
    internal let ipv6rhs:UInt64
    /// Data storage for storing ipv6 address type and address bytes (lhs)
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

    /// Classless Inter-Domain Routing (CIDR) information attached to this ip address
    ///
    /// ## SeeAlso
    ///
    /// More information about CIDR, see [Wikipedia article](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
    ///
    public let cidrBits:Int
    /// Network mask (as bytes)
    public let networkMask:[UInt8]
    @inline(__always)
    private static func genv4MaskBytes(bits:Int) -> [UInt8] {
        let lhs = UInt32.max<<(32 - bits)
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
            lhs = lhs << (f - 64)
        }
        else {
            rhs = rhs << f
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
    /// - Parameters:
    ///     - u32: `UInt32`value defining an ipv4 address
    ///     - cidr: Classless Inter-Domain Routing value (defining the network mask
    ///     for this address)
    /// Initializing IPAddress with UInt32(1) will result in 0.0.0.1 and
    /// with UInt32.max will result in 255.255.255.255.
    /// - Note: Out of bounds `cidr` values will be clamped to `IPAddress.validV4CIDRRange`
    /// boundaries.
    public init(_ u32: UInt32, cidr bits:Int = 32) {
        self.cidrBits = Self.validV4CIDRRange.contains(bits) ? bits : bits < 0 ? 0 : Self.validV4CIDRRange.upperBound
        self.type = .v4
        self.sysendianIpv4 = u32
        self.ipv6rhs = 0
        self.ipv6lhs = 0
        self.networkMask = Self.genv4MaskBytes(bits: bits)
    }

    /// Initializes an ipv4 or ipv6 address
    ///
    /// Initializes an ipv4 or ipv6 address from given UInt8 bytes.
    /// - Parameters:
    ///     - bytes: `Array<UInt8>`of bytes (in network byte order) defining the ip address
    ///     - cidr: Classless Inter-Domain Routing value (defining the network mask
    ///     for this address)
    /// - Returns: `IPAddress` instance or `nil`
    /// - Note: Out of bounds `cidr` values will be clamped to `IPAddress.validV4CIDRRange`
    /// boundaries. Cidr value of `nil` will result to a single host ip address.
    public init?(bytes:[UInt8], cidr bits:Int? = nil) {
        switch bytes.count {
        case 4:
            let b = bits ?? Self.validV4CIDRRange.upperBound
            self.networkMask = Self.genv4MaskBytes(bits: b)
            self.cidrBits = Self.validV4CIDRRange.contains(b) ? b : b < 0 ? 0 : Self.validV4CIDRRange.upperBound
            self.type = .v4
            self.sysendianIpv4 = Self.systemIsLittleEndian ?
            UInt32(bytes[3]) | UInt32(bytes[2])<<8 | UInt32(bytes[1])<<16 | UInt32(bytes[0])<<24 :
            UInt32(bytes[0]) | UInt32(bytes[1])<<8 | UInt32(bytes[2])<<16 | UInt32(bytes[3])<<24
            self.ipv6rhs = 0
            self.ipv6lhs = 0
        case 16:
            let b = bits ?? Self.validV6CIDRRange.upperBound
            self.networkMask = Self.genv6MaskBytes(bits: b)
            self.cidrBits = Self.validV6CIDRRange.contains(b) ? b : b < 0 ? 0 : Self.validV6CIDRRange.upperBound
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
    /// Initializes an ipv4 or ipv6 address from a given String. String may contain
    /// network mask information (cidr) separated with slash (/) character.
    /// Ip address is initialized as a single host, if network mask is omitted.
    ///
    /// - Parameters:
    ///     - string: `String` value describing an ip address
    ///     - options: `ParsingOptions` to control parsing
    ///
    /// - Returns: `IPAddress` instance or `nil` if address parsing fails.
    ///
    /// Examples:
    ///
    ///     IPAddress("::1") // 0:0:0:0:0:0:0:1/128
    ///     IPAddress("192.168.5.4") // 192.168.5.4/32
    ///     IPAddress("192.168.5.4/28") // 192.168.5.4/28
    ///     IPAddress("abc/64") // nil (ambiguous)
    ///     IPAddress("ABCD::", options: .noUppercase) // nil
    public init?(_ string:String, options:ParsingOptions = ParsingOptions()) {
        guard let validAddress = parser(string, options: options) else {
            return nil
        }
        self = validAddress
    }
}
// MARK: -
// MARK: Equatable, Hashable, Comparable
extension IPAddress : Equatable, Hashable, Comparable {
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
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type.rawValue)
        hasher.combine(networkOrderedAddressBytes)
        hasher.combine(cidrBits)
    }
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
// MARK: -
// MARK: CustomStringConvertible, CustomDebugStringConvertible
extension IPAddress : CustomStringConvertible, CustomDebugStringConvertible {
    /// Description of the ip address
    ///
    /// Address representation doesn't include cidr notation. Use `debugDescription` to include cidr notation.
    ///
    /// - Note: Suppresses leading zeroes from ipv6 address segments.
    ///
    /// Example:
    ///
    ///     let ipv4 = IPAddress(192, 0, 2, 1)
    ///     ipv4.description // 192.0.2.1
    ///     let ipv6 = IPAddress(0x2001, 0x0db8, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001)
    ///     ipv6.description // 2001:db8:0:0:0:0:0:1
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
    /// Compact description of the ip address
    ///
    /// Suppresses leading zeroes from ipv6 addresses and uses double colon (::) to
    /// shorten the address representation when address has multiple consecutive
    /// all zeroes parts.
    ///
    /// Example:
    ///
    ///     let ip = IPAddress(0x2001, 0xdb8, 0, 0, 0, 0, 0, 1)
    ///     ip.description // 2001:db8:0:0:0:0:0:1
    ///     ip.compactDescription // 2001:db8::1
    ///
    /// For ipv4 addresses `compactDescription` returns a value equal to `description`
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
    /// Debug description of the ip address
    ///
    /// Address representation including the cidr notation. Use `description` to get plain address without cidr notation.
    ///
    /// - Note: Suppresses leading zeroes from ipv6 address segments.
    ///
    /// Example:
    ///
    ///     let ipv4 = IPAddress(192, 0, 2, 1)
    ///     ipv4.debugDescription // 192.0.2.1/32
    ///     let ipv6 = IPAddress(0x2001, 0x0db8, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001)
    ///     ipv6.debugDescription // 2001:db8:0:0:0:0:0:1/128
    public var debugDescription: String {
        return description + "/\(cidrBits)"
    }
    /// Compact debug description of the ip address
    ///
    /// Address representation including the cidr notation. Suppresses leading zeroes
    /// from ipv6 addresses and uses double colon (::) to shorten the address
    /// representation when address has multiple consecutive all zeroes parts.
    ///
    /// Example:
    ///
    ///     let ip = IPAddress(0x2001, 0xdb8, 0, 0, 0, 0, 0, 1)
    ///     ip.debugDescription // 2001:db8:0:0:0:0:0:1/128
    ///     ip.compactDebugDescription // 2001:db8::1/128
    ///
    /// For ipv4 addresses `compactDescription` returns a value equal to `description`
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
    /// Ipv4 localhost instance
    ///
    /// - Returns: `IPAddress` instance representing 127.0.0.1/32
    ///
    /// Example:
    ///
    ///     IPAddress.ipv4localhost // 127.0.0.1/32
    public static let ipv4localhost = IPAddress(2130706433)
    /// Ipv6 localhost instance
    ///
    /// - Returns: `IPAddress` instance representing 0:0:0:0:0:0:0:1/128
    ///
    /// Example:
    ///
    ///     IPAddress.ipv6localhost // 0:0:0:0:0:0:0:1/128
    public static let ipv6localhost = IPAddress(0, 1)
    /// A Boolean value indicating whether this ip address is a localhost address
    ///
    /// - Note: Only the address part is used in evaluation (cidr value is *ignored*).
    /// Use `ip.isLocalhost && ip.isSingleEndPoint`
    /// instead of `isLocalhost` if cidr comparison is required by your application.
    public var isLocalhost:Bool {
        type == .v4 ? sysendianIpv4 == 2130706433 : ipv6lhs == 0 && ipv6rhs == 1
    }
    /// Ipv4 unspecified address instance
    ///
    /// - Returns: `IPAddress` instance representing 0.0.0.0/32
    ///
    /// Example:
    ///
    ///     IPAddress.ipv4unspecifiedAddress // 0.0.0.0/32
    public static let ipv4unspecifiedAddress = IPAddress(0)
    /// Ipv6 unspecified instance
    ///
    /// - Returns: `IPAddress` instance representing 0:0:0:0:0:0:0:0/128
    ///
    /// Example:
    ///
    ///     IPAddress.ipv6unspecifiedAddress // 0:0:0:0:0:0:0:0/128
    public static let ipv6unspecifiedAddress = IPAddress(0, 0)
    // MARK: -
    /// A Boolean value indicating whether this ip address is an unspecified address
    ///
    /// - Note: Only the address part is used in evaluation (cidr value is *ignored*).
    public var isUnspecified:Bool {
        type == .v4 ? sysendianIpv4 == 0 : ipv6lhs == 0 && ipv6rhs == 0
    }
    /// A Boolean value indicating whether this ip address is a loopback address
    ///
    /// - Returns: `true` when address (single end point) belongs to loopback network
    /// block or when address represents a network and the network is completely contained by
    /// the loopback address block (ipv4).
    ///
    /// - Note: Only the address part is used in evaluation (cidr value is *ignored*).
    public var isLoopback:Bool {
        type == .v4 ? (2130706432...2147483647).contains(sysendianIpv4) : ipv6lhs == 0 && ipv6rhs == 1
    }
    /// A Boolean value indicating whether this ip address is a non routable broadcast address
    ///
    /// - Note: Only the address part is used in evaluation (cidr value is *ignored*).
    public var isBroadcast:Bool {
        return type == .v4 ?
        sysendianIpv4 == 0xffffffff
        :
        ipv6lhs == ~0 && ipv6rhs == ~0
    }
    /// A Boolean value indicating whether this ip address is a private address
    ///
    /// - Returns: `true` when address (single end point) belongs to private network
    /// block or when address represents a network and the network is completely contained by
    /// the private address block.
    ///
    /// ## SeeAlso
    ///
    /// [Reserved IP addresses](https://en.wikipedia.org/wiki/Reserved_IP_addresses)
    public var isPrivate:Bool {
        return type == .v4 ?
        IPAddress(192, 168, 0, 0, cidr: 16).contains(self) ||
        IPAddress(172, 168, 0, 0, cidr: 12).contains(self) ||
        IPAddress(10, 0, 0, 0, cidr: 8).contains(self)
        :
        IPAddress(0xfd00000000000000, 0, cidr: 8).contains(self)
    }
    /// A Boolean value indicating whether this ip address is a link local address
    ///
    /// - Returns: `true` when address (single end point) belongs to link local network
    /// block or when address represents a network and the network is completely contained by
    /// the link local block.
    ///
    /// ## SeeAlso
    ///
    /// [Link local address](https://en.wikipedia.org/wiki/Link-local_address)
    public var isLinkLocal:Bool {
        return type == .v4 ?
        IPAddress(169, 254, 0, 0, cidr: 16).contains(self)
        :
        IPAddress(0xfe80000000000000, 0, cidr: 10).contains(self)
    }
    /// A Boolean value indicating whether this ip address is a global address (routable address)
    public var isGlobal:Bool {
        self.isUnspecified == false &&
        self.isPrivate == false &&
        self.isLoopback == false &&
        self.isLinkLocal == false &&
        self.isDocumentation == false &&
        self.isBroadcast == false
    }
    /// A Boolean value indicating whether this ip address is a multicast address
    ///
    /// - Returns: `true` when address (single end point) belongs to multicast network
    /// block or when address represents a network and the network is completely contained by
    /// the multicast block.
    ///
    /// ## SeeAlso
    ///
    /// [Reserved IP addresses](https://en.wikipedia.org/wiki/Reserved_IP_addresses)
    ///
    /// - Note: Cidr value is taken into account when evaluating this value.
    public var isMulticast:Bool {
        return type == .v4 ?
        IPAddress(224, 0, 0, 0, cidr: 4).contains(self)
        :
        IPAddress(0xff00000000000000, 0, cidr: 8).contains(self)
    }
    /// A Boolean value indicating whether this ip address belongs to a network block
    /// which is reserved for documentation purposes
    ///
    /// - Returns: `true` when address (single end point) belongs to documentation network
    /// block or when address represents a network and the network is completely contained by
    /// the documentation block.
    ///
    /// Example:
    ///
    ///     IPAddress(192, 0, 2, 0, cidr: 25).isDocumentation // true
    ///     IPAddress(192, 0, 1, 255).isDocumentation // false
    ///     IPAddress(192, 0, 2, 0, cidr: 23).isDocumentation // false
    ///
    /// ## SeeAlso
    ///
    /// [Reserved IP addresses](https://en.wikipedia.org/wiki/Reserved_IP_addresses)
    ///
    /// - Note: Cidr value is taken into account when evaluating this value.
    public var isDocumentation:Bool {
        return type == .v4 ?
        IPAddress(192, 0, 2, 0, cidr: 24).contains(self) ||
        IPAddress(198, 51, 100, 0, cidr: 24).contains(self) ||
        IPAddress(203, 0, 113, 0, cidr: 24).contains(self)
        :
        IPAddress(0x20010db800000000, 0, cidr: 32).contains(self)
    }
    /// A Boolean value indicating whether this ip address is a single end point address
    /// (single host address)
    ///
    /// ## SeeAlso
    ///
    /// More information about CIDR, see [Wikipedia article](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
    public var isSingleEndPoint:Bool {
        type == .v4 && cidrBits == Self.validV4CIDRRange.upperBound ||
        type == .v6 && cidrBits == Self.validV6CIDRRange.upperBound
    }
    // MARK: -
    /// Ip address bytes in network byte order
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
    /// Ip address Data (in network byte order)
    public var rawAddressData:Data {
        return Data(networkOrderedAddressBytes)
    }
    /// Underestimated host count of this address
    ///
    /// - Returns: Understimated host count of the network
    ///
    /// - Note: Returns correct host count for all ipv4 cidr values.
    /// Returns Int.max for ipv6 addresses with cidr value smaller than 66.
    public var underestimatedHostCount:Int {
        if type == .v4, Self.validV4CIDRRange.contains(cidrBits) {
            return Int(1) << (Self.validV4CIDRRange.upperBound - cidrBits)
        }
        else {
            return (cidrBits < 66) ? Int.max : Int(1) << (Self.validV6CIDRRange.upperBound - cidrBits)
        }
    }

    // MARK: -
    /// Network address of the network this ip address belongs to
    ///
    /// Example:
    ///
    ///     let ip = IPAddress(192, 0, 2, 123, cidr: 24)
    ///     ip.networkAddress // 192.0.2.0
    ///
    /// - Returns: Returns `nil` if ip address doesn't represent a network block
    /// (is a single end point). Othervice returns network address of the network
    ///  block this ip belongs to
    public var networkAddress:IPAddress? {
        return IPAddress(bytes: zip(networkOrderedAddressBytes, networkMask).map({ $0 & $1 }), cidr: cidrBits)
    }
    /// Router address of the network this ip address belongs to
    ///
    /// Example:
    ///
    ///     let ip = IPAddress(192, 0, 2, 123, cidr: 24)
    ///     ip.routerAddress // 192.0.2.1
    ///
    /// - Returns: Returns `nil` if ip address doesn't represent a network block
    /// (is a single end point). Othervice returns router's ip address of the network block
    /// this ip address belongs to
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
    /// Example:
    ///
    ///     let ip = IPAddress(192, 0, 2, 123, cidr: 24)
    ///     ip.broadcastAddress // 192.0.2.255
    ///
    /// - Returns: Returns `nil` if ip address doesn't represent a network block
    /// (is a single end point). Othervice returns last ip address of the network block
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
    /// A boolean value indicating wheter this ip address instance contains the other ip address entirely
    ///
    /// Examples:
    ///
    ///     IPAddress(192, 168, 5, 4, cidr: 22).contains(IPAddress(192, 168, 4, 0)) // true
    ///     IPAddress(192, 168, 5, 4, cidr: 22).contains(IPAddress(192, 168, 7, 255)) // true
    ///     IPAddress(192, 168, 5, 4, cidr: 22).contains(IPAddress(192, 168, 3, 255)) // false
    ///     IPAddress(192, 168, 5, 4, cidr: 22).contains(IPAddress(192, 168, 8, 0)) // false
    ///
    /// - Parameters:
    ///     - other: `IPAddress` instance
    /// - Returns: Returns false when address types don't match.
    /// When `self` or `other` are network addresses, returns true only if
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
    /// Returns an ip address that is offset the specified distance from this ip address.
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
    ///
    /// - Note: Out of bounds `cidr` values will be clamped to `IPAddress.validV6CIDRRange`
    /// boundaries.
    ///
    /// Example
    ///
    ///     IPAddress(0x2001_0db8_0000_0000, 1) // 2001:db8::1/128
    internal init(_ lhs:UInt64, _ rhs:UInt64, cidr bits:Int = 128) {
        self.cidrBits = Self.validV6CIDRRange.contains(bits) ? bits : bits < 0 ? 0 : Self.validV6CIDRRange.upperBound
        self.type = .v6
        self.sysendianIpv4 = 0
        self.ipv6lhs = lhs
        self.ipv6rhs = rhs
        self.networkMask = Self.genv6MaskBytes(bits: bits)
    }
    /// Initializes an ipv4 address
    ///
    /// - Note: Out of bounds `cidr` values will be clamped to `IPAddress.validV4CIDRRange`
    /// boundaries.

    /// Example
    ///
    ///     IPAddress(192, 168, 5, 4) // 192.168.5.4/32
    public init(_ a:UInt8, _ b:UInt8, _ c:UInt8, _ d:UInt8, cidr bits:Int = 32) {
        self.cidrBits = Self.validV4CIDRRange.contains(bits) ? bits : bits < 0 ? 0 : Self.validV4CIDRRange.upperBound
        self.type = .v4
        self.sysendianIpv4 = Self.systemIsLittleEndian ?
        UInt32(d) | UInt32(c)<<8 | UInt32(b)<<16 | UInt32(a)<<24 :
        UInt32(a) | UInt32(b)<<8 | UInt32(c)<<16 | UInt32(d)<<24
        self.ipv6rhs = 0
        self.ipv6lhs = 0
        self.networkMask = Self.genv4MaskBytes(bits: bits)
    }
    /// Initializes an ipv6 address
    ///
    /// Example
    ///
    ///     IPAddress(0x2001, 0xdb8, 0, 0, 0, 0, 0, 1) // 2001:db8::1/128
    public init(_ a:UInt16, _ b:UInt16, _ c:UInt16, _ d:UInt16, _ e:UInt16, _ f:UInt16, _ g:UInt16, _ h:UInt16, cidr bits:Int = 128) {
        self.cidrBits = Self.validV6CIDRRange.contains(bits) ? bits : bits < 0 ? 0 : Self.validV6CIDRRange.upperBound
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
    /// Initializes an ipv4 or ipv6 address from Data.
    ///
    /// - Parameters:
    ///     - data: `Data` bytes representing the ip address in network byte order
    ///     - cidr: Optional `Int` value Network mask bits
    /// - Returns: Ipv4 or ipv6 address instance or `nil` if data `count`
    /// is not 4 or 16
    /// - Note: Data bytes (representing an ip address) must be in network
    /// byte order
    public init?(data:Data, cidr bits:Int? = nil) {
        self.init(bytes: data.withUnsafeBytes({ Array($0) }), cidr: bits)
    }
    /// Initializes an ip address from other instance of an ip address
    ///
    /// - Parameters:
    ///     - other: `IPAddress` instance to use as base
    ///     - cidr: Network mask bits
    /// - Returns: IPAddress instance
    /// byte order
    public init(_ other:IPAddress, cidr bits:Int? = nil) {
        if other.type == .v4 {
            self.init(other.sysendianIpv4, cidr: bits ?? Self.validV4CIDRRange.upperBound)
        }
        else {
            self.init(other.ipv6lhs, other.ipv6rhs, cidr: bits ?? Self.validV6CIDRRange.upperBound)
        }
    }
    /// A boolean value indicating wheter current system is little endian
    private static var systemIsLittleEndian:Bool {
        UInt16(256) & 0x00ff == 0
    }
}
// MARK: -
extension IPAddress : Strideable {
    public typealias Stride = Int
    public func distance(to other: IPAddress) -> Int {
        precondition(type == other.type, "\(#function) requires ip address types to be equal, got \(type) and \(other.type)")
        precondition(type == .v4, "\(#function) not available for \(IPAddress.IPAddrType.v6) ip addresses")
        return Int(other.sysendianIpv4) - Int(sysendianIpv4)
    }
    public func advanced(by n: Int) -> IPAddress {
        if type == .v4 {
            return n.signum() == -1 ?
            advanced(by: n, clamped: false) ?? IPAddress(0, cidr: cidrBits)
            :
            advanced(by: n, clamped: false) ?? IPAddress(UInt32.max, cidr: cidrBits)
        }
        else {
            return n.signum() == -1 ?
            advanced(by: n, clamped: false) ?? IPAddress(0, 0, cidr: cidrBits)
            :
            advanced(by: n, clamped: false) ?? IPAddress(UInt64.max, UInt64.max, cidr: cidrBits)
        }
    }
}
// MARK: -
/// An iterator over the elements of type IPAddress
///
/// Iterates over a defined network or the whole addressable range.
///
/// Example: Iterate over all ipv4 addresses of a specific network
///
///     let network = IPAddress(192, 168, 5, 16, cidr: 30)
///     var iterator = IPAddressIterator(address: network, clamped: true)
///     while let ip = iterator.next() {
///         print(ip.debugDescription) // 192.168.5.16/30, 192.168.5.17/30, 192.168.5.18/30, 192.168.5.19/30
///     }
///
/// Example: Iterate over the whole ipv4 adressable range
///
///     var iterator = IPAddressIterator(address: IPAddress(0, 0, 0, 0))
///     while let ip = iterator.next() {
///         print(ip.debugDescription) // 0.0.0.0/32, ... 255.255.255.255/32
///     }
public struct IPAddressIterator : IteratorProtocol {
    public typealias Element = IPAddress

    private var address:IPAddress?
    private let limit:IPAddress
    private let isRange:Bool

    /// Initializes an IPAddressIterator for iterating over a specific network block
    ///
    /// - Parameters:
    ///     - network: `IPAddress` instance defining the network block
    /// - Returns: `IPAddressIterator` instance
    public init(network:IPAddress) {
        self.isRange = false
        self.address = network.networkAddress ?? network
        self.limit = network.broadcastAddress ?? network
    }

    /// Initializes an IPAddressIterator for iterating over a specific range of ip addresses
    ///
    /// - Parameters:
    ///     - range: `ClosedRange<IPAddress>` instance defining the range for iteration
    /// - Returns: `IPAddressIterator` instance
    public init(range:ClosedRange<IPAddress>) {
        self.isRange = true
        self.address = range.lowerBound
        self.limit = range.upperBound
    }

    /// Get next IPAddress instance
    ///
    /// - Returns: IPAddress instance or `nil` when there are no more ip addresses
    /// for the defined network (clamped) or there are no more ip addresses for the
    /// addressable range.
    ///
    /// Example: Iterate over all ipv4 addresses of a specific network
    ///
    ///     let network = IPAddress(192, 168, 5, 16, cidr: 30)
    ///     var iterator = IPAddressIterator(network: network)
    ///     while let ip = iterator.next() {
    ///         print(ip.debugDescription) // 192.168.5.16/30, 192.168.5.17/30, 192.168.5.18/30, 192.168.5.19/30
    ///     }
    ///
    /// Example: Iterate over the whole ipv4 adressable range
    ///
    ///     var iterator = IPAddressIterator(range: IPAddress(0, 0, 0, 0)...IPAddress(255, 255, 255, 255))
    ///     while let ip = iterator.next() {
    ///         print(ip.debugDescription) // 0.0.0.0/32, ... 255.255.255.255/32
    ///     }
    mutating public func next() -> Element? {
        guard let address = self.address else {
            return nil
        }
        switch address.type {
        case .v4:
            guard address <= limit else { return nil }
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
            guard address <= limit else {
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
/// A type providing sequential, iterated access to IPAddress elements
public struct IPAddressSequence: Sequence {
    /// First ip address in the sequence
    public let startAddress: IPAddress
    /// Last ip address in the sequence
    public let endAddress: IPAddress
    private let isRange:Bool
    /// Initializes IPAddressSequence instance
    ///
    /// - Parameters:
    ///     - network: IPAddress instance defining the network block as
    ///     target for this sequence
    /// - Returns: IPAddressSequence instance providing sequential,
    /// iterated access to all IPAddress elements of this network block
    public init(network:IPAddress) {
        self.isRange = false
        self.startAddress = network.networkAddress ?? network
        self.endAddress = network.broadcastAddress ?? network
    }
    /// Initializes IPAddressSequence instance
    ///
    /// Provides a sequence of all ip addresses defined by the range.
    /// - Parameters:
    ///     - range: IPAddress range defining the lower and upper bounds of this sequence
    /// - Returns: IPAddressSequence instance providing sequential, iterated access to all
    /// IPAddress elements defined by the range
    /// - Note: Sequence elements are returned as single host ip addresses (cidr = 32 for
    /// ipv4 addresses and cidr = 128 for ipv6 addresses).
    public init(range:ClosedRange<IPAddress>) {
        precondition(range.lowerBound.type == range.upperBound.type)
        self.isRange = true
        if range.lowerBound.type == .v4 {
            self.startAddress = IPAddress(range.lowerBound, cidr: IPAddress.validV4CIDRRange.upperBound)
            self.endAddress = IPAddress(range.upperBound, cidr: IPAddress.validV4CIDRRange.upperBound)
        }
        else {
            self.startAddress = IPAddress(range.lowerBound, cidr: IPAddress.validV6CIDRRange.upperBound)
            self.endAddress = IPAddress(range.upperBound, cidr: IPAddress.validV6CIDRRange.upperBound)
        }
    }
    /// Initializes `IPAddressIterator` instance
    ///
    /// - Returns: An iterator over the elements of type IPAddress
    public func makeIterator() -> IPAddressIterator {
        self.isRange ? IPAddressIterator(range: startAddress...endAddress) : IPAddressIterator(network: startAddress)
    }
    /// A value less than or equal to the number of elements in the sequence,
    /// calculated nondestructively.
    public var underestimatedCount: Int {
        guard isRange else {
            return startAddress.underestimatedHostCount
        }
        if self.startAddress.type == .v4 {
            return Int(endAddress.sysendianIpv4 - startAddress.sysendianIpv4) + 1
        }
        else {
            let s = endAddress.ipv6rhs - startAddress.ipv6rhs
            if s < UInt64(Int.max), startAddress.ipv6lhs == endAddress.ipv6lhs {
                return Int(s) + 1
            }
        }
        return Int.max
    }
}

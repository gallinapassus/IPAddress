import Foundation
import BigInt
import Parsing

/// Conrete type capable of encapsulating ipv4 and ipv6 addresses
public struct IPAddress : Codable {

    /// Ip address type enumeration
    public enum IPAddrType : UInt8, Codable { case v4 = 0, v6 = 1 /*, v8 = 2, v10 = 3 */ }

    /// Data storage for storing ip address type and address bytes
    private var data:Data

    /// Classless Inter-Domain Routing information attached to this ip address
    public var cidr:CIDR

    /// Initializes an ipv4 address
    ///
    /// Initializes an ipv4 address from an UInt32 value.
    public init(_ u32: UInt32, cidr bits:Int = 32) {
        let u8bytes = Data([0]) + withUnsafeBytes(of: Self.systemIsLittleEndian ? u32.byteSwapped : u32, { Array($0) })
        self.data = Data(u8bytes)
        self.cidr = CIDR(for: .v4, bits: bits)
    }

    /// Initializes an ipv4 or ipv6 address
    ///
    /// Initializes an ipv4 or ipv6 address from given UInt8 bytes.
    public init?(_ bytes:[UInt8]) {
        switch bytes.count {
        case 4:
            let u8 = [IPAddrType.v4.rawValue] + bytes
            self.data = Data(u8)
            self.cidr = CIDR(for: .v4, bits: 32)
        case 16:
            let u8 = [IPAddrType.v6.rawValue] + bytes
            self.data = Data(u8)
            self.cidr = CIDR(for: .v6, bits: 128)
        default: return nil
        }
    }

    /// Initializes an ipv4 or ipv6 address
    ///
    /// Initializes an ipv4 or ipv6 address from given String.
    public init?(_ string:String) {
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
extension IPAddress : Equatable {
    public static func ==(lhs:IPAddress, rhs:IPAddress) -> Bool {
        return lhs.data == rhs.data && lhs.cidr == rhs.cidr
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
            case .v4: return lhs.ipv4rawValue! < rhs.ipv4rawValue!
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
        guard cidr.bits <= 32 else { return nil }
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
    /// Returns an enumeration value describing the contained ip address type
    public var type:IPAddrType {
        IPAddrType(rawValue: data[0] & 0b11)!
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
    /// Returns the ip address´s network address
    public var networkAddress:IPAddress {
        let cb = cidr.bytes
        switch type {
        case .v4: return IPAddress(data[1] & cb[0], data[2] & cb[1], data[3] & cb[2], data[4] & cb[3], cidr: cidr.bits)!
        case .v6:
            let arr:[UInt8] = zip(data[1...], cb).map({ $0 & $1 })
            var addr = IPAddress(arr)!
            addr.cidr = CIDR(for: .v6, bits: cidr.bits)
            return addr
        }
    }
    /// Returns the router address of the network this ip address belongs to
    public var routerAddress:IPAddress? {
        var nwa = networkAddress
        switch type {
        case .v4:
            guard cidr.bits != 32 else {
                return nil
            }
            guard networkAddress.ipv4rawValue != UInt32.max else {
                return networkAddress
            }
            nwa = IPAddress(nwa.ipv4rawValue! + 1, cidr: networkAddress.cidr.bits)
        case .v6:
            guard cidr.bits != 128 else {
                return nil
            }
            for i in stride(from: 16, through: 1, by: -1) {
                guard nwa.data[i] != 255 else { continue }
                nwa.data[i] = nwa.data[i] + 1
                break
            }
        }
        return nwa
    }
    /// Returns the broadcast address of the network this ip address belongs to
    public var broadcastAddress:IPAddress? {
        switch type {
        case .v4:
            guard cidr.bits != 32 else {
                return nil
            }
            let next = networkAddress.ipv4rawValue! + UInt32(cidr.hostCount - 1)
            return IPAddress(next, cidr: networkAddress.cidr.bits)
        case .v6:
            guard cidr.bits != 128 else {
                return nil
            }
            let orEd = Data(zip(data[1...], cidr.bytes.map({ ~$0 })).map { $0 | $1 })
//            print("ip  ", data[1...].map({ $0 }))
//            print("cidr", cidr.bytes.map({ $0 }))
//            print("ored", orEd.map({ $0 }))
            return IPAddress(data: orEd, cidr: networkAddress.cidr.bits)
        }
    }
    /// A boolean value indicating wheter this ip address contains the other ip address
    public func contains(_ other:IPAddress) -> Bool {
        guard cidr.isSingleEndPoint == false else {
            return self == other
        }
        guard other.cidr.isSingleEndPoint == true else {
            // "this ip address" is network
            // "other" is a network
            // return true if "this network" contains the "other" network entirely

            //print(debugDescription, other.debugDescription, other.networkAddress.debugDescription, other.broadcastAddress)
            switch type {
            case .v4:
                let myRange = networkAddress.ipv4rawValue!...broadcastAddress!.ipv4rawValue!
                return myRange.contains(other.networkAddress.ipv4rawValue!) &&
                myRange.contains(other.broadcastAddress!.ipv4rawValue!)
            case .v6:
                return other.networkAddress >= networkAddress && other.broadcastAddress! <= broadcastAddress!
            }
        }
        //print(debugDescription, "contains(", other.debugDescription, ")")
        // "this ip address" is a network
        // "other" is a single end point
        // return true if "this network" contains that specific single ip address
        switch type {
        case .v4:
            return other.ipv4rawValue! >= networkAddress.ipv4rawValue! && other.ipv4rawValue! <= broadcastAddress!.ipv4rawValue!
        case .v6:
            return other >= networkAddress && other <= broadcastAddress!
        }
    }
    /// Initializes an ipv4 address
    public init(_ a:UInt8, _ b:UInt8, _ c:UInt8, _ d:UInt8) {
        let u8 = [IPAddrType.v4.rawValue, a, b, c, d]
        self.data = Data(u8)
        self.cidr = CIDR(for: .v4, bits: CIDR.validV4Range.upperBound)
    }
    /// Initializes an ipv4 address
    public init?(_ a:UInt8, _ b:UInt8, _ c:UInt8, _ d:UInt8, cidr bits:Int = 32) {
        guard CIDR.validV4Range.contains(bits) else {
            return nil
        }
        let u8 = [IPAddrType.v4.rawValue, a, b, c, d]
        self.data = Data(u8)
        self.cidr = CIDR(for: .v4, bits: bits)
    }
    /// Initializes an ipv6 address
    public init(_ a:UInt16, _ b:UInt16, _ c:UInt16, _ d:UInt16, _ e:UInt16, _ f:UInt16, _ g:UInt16, _ h:UInt16) {
        self.data = Data([IPAddrType.v6.rawValue])
        self.cidr = CIDR(for: .v6, bits: CIDR.validV6Range.upperBound)
        if Self.systemIsLittleEndian {
            self.data.append(Data([a.byteSwapped, b.byteSwapped, c.byteSwapped,
                                   d.byteSwapped, e.byteSwapped, f.byteSwapped,
                                   g.byteSwapped, h.byteSwapped].withUnsafeBytes({ Array($0) })))
        }
        else {
            self.data.append(Data([a, b, c, d, e, f, g, h].withUnsafeBytes({ Array($0) })))
        }
    }
    /// Initializes an ipv6 address
    public init?(_ a:UInt16, _ b:UInt16, _ c:UInt16, _ d:UInt16, _ e:UInt16, _ f:UInt16, _ g:UInt16, _ h:UInt16, cidr bits:Int = 128) {
        guard CIDR.validV6Range.contains(bits) else {
            return nil
        }
        self.data = Data([IPAddrType.v6.rawValue])
        self.cidr = CIDR(for: .v6, bits: bits)
        if Self.systemIsLittleEndian {
            self.data.append(Data([a.byteSwapped, b.byteSwapped, c.byteSwapped,
                                   d.byteSwapped, e.byteSwapped, f.byteSwapped,
                                   g.byteSwapped, h.byteSwapped].withUnsafeBytes({ Array($0) })))
        }
        else {
            self.data.append(Data([a, b, c, d, e, f, g, h].withUnsafeBytes({ Array($0) })))
        }
    }
    /// Initializes an ipv4 or ipv6 address from Data
    public init?(data:Data, cidr bits:Int? = nil) {
        let cidr:CIDR
        switch data.count {
        case 4:
            let b = bits ?? 32
            guard b >= 0, b <= 32 else {
                return nil
            }
            cidr = CIDR(for: .v4, bits: b)
        case 16:
            let b = bits ?? 128
            guard b >= 0, b <= 128 else {
                return nil
            }
            cidr = CIDR(for: .v6, bits: b)
        default: return nil
        }
        self.init(data.withUnsafeBytes({ Array($0) }))
        self.cidr = cidr
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

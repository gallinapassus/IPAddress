import Foundation
import Parsing

fileprivate enum err : Error {
    case overflow(Substring), nonhex(Substring), syntax(Substring)
}
internal struct IPv4AddressParser<Input:Collection> : Parser {
    public typealias Input = Substring
    public typealias Output = IPAddress?
    @inlinable
    public init() {}
    public func parse(_ input: inout Substring) throws -> Output {
        guard input.count > 6, input.contains(".") else { return nil }
        let ipv4elementParser = Many {
            Prefix { $0.isNumber }.map { UInt8($0, radix: 10) }
        } separator: {
            "."
        }
        let ipv4Parser = Parse {
            ipv4elementParser
            Optionally {
                "/"
                Prefix(1...2) { $0.isNumber }.map { UInt8($0, radix: 10) }
            }
            End()
        }.map({ result in
            let (abcd,cidr) = result
            let elements = abcd.compactMap({ $0 })
            guard elements.count == 4 else {
                return Optional<IPAddress>(nil)
            }
            if let opt = cidr, let cidrBits = opt {
                return IPAddress(elements[0], elements[1], elements[2], elements[3], cidr: Int(cidrBits))
            }
            else {
                return IPAddress(elements[0], elements[1], elements[2], elements[3])
            }
        })
        let oneOf = Parse {
            Skip { Optionally { Whitespace() } }
            ipv4Parser
            Skip { Optionally { Whitespace() } }
        }
        return try oneOf.parse(&input)
    }
}
internal struct IPv6AddressParser<Input:Collection> : Parser {
    public typealias Input = Substring
    public typealias Output = IPAddress?
    @inlinable
    public init() {}
    public func parse(_ input: inout Substring) throws -> Output {
        
        /*
         - The hexadecimal digits are always compared in case-insensitive
           manner, but IETF recommendations suggest the use of only lower
           case letters. For example, 2001:db8::1 is preferred over 2001:DB8::1;
         - Leading zeros in each 16-bit field are suppressed, but each group
           must retain at least one digit. For example, 2001:0db8::0001:0000
           is rendered as 2001:db8::1:0;
         - The longest sequence of consecutive all-zero fields is replaced with
           two colons (::). If the address contains multiple runs of all-zero
           fields of the same size, to prevent ambiguities, it is the leftmost
           that is compressed. For example, 2001:db8:0:0:1:0:0:1 is rendered as
           2001:db8::1:0:0:1 rather than as 2001:db8:0:0:1::1. :: is not used
           to represent just a single all-zero field. For example,
           2001:db8:0:0:0:0:2:1 is shortened to 2001:db8::2:1,
           but 2001:db8:0000:1:1:1:1:1 is rendered as 2001:db8:0:1:1:1:1:1.
         */
        guard input.count > 1, input.count < 40, input.contains(":") else { return nil } // fail early
        let ipv6elementParser = Many {
            Prefix(...4) { $0.isHexDigit }
        } separator: {
            ":"
        }.map { // $0 => [Substring]
            return  $0.map({
                // $0 => Substring
                return UInt16($0, radix: 16)
            })
        }
        let ipv6Parser = Parse {
            ipv6elementParser
            Optionally {
                "/"
                Prefix(1...3) { $0.isNumber }.map { UInt8($0, radix: 10) }
            }
        }.map({ result in
            // Initial (and limited) implementation of ipv6 address parsing
            let (abcdefgh,cidr) = result
            guard abcdefgh.isEmpty == false, abcdefgh.count < 9 else { return Optional<IPAddress>(nil) } // fail early
            let startsWithNil = abcdefgh.first! == nil
            let endsWithNil = abcdefgh.last! == nil
            // Try to take the quick wins
            // Admittedly this code is not that clear
            switch (startsWithNil, endsWithNil) {
            case (false,false):
                if abcdefgh.count == 8 {
                    if let opt = cidr, let cidrBits = opt {
                        return IPAddress(abcdefgh[0]!, abcdefgh[1]!, abcdefgh[2]!, abcdefgh[3]!,
                                         abcdefgh[4]!, abcdefgh[5]!, abcdefgh[6]!, abcdefgh[7]!,
                                         cidr: Int(cidrBits))
                    }
                    else {
                        return IPAddress(abcdefgh[0]!, abcdefgh[1]!, abcdefgh[2]!, abcdefgh[3]!,
                                         abcdefgh[4]!, abcdefgh[5]!, abcdefgh[6]!, abcdefgh[7]!)
                    }
                }
                else if abcdefgh.count == 3, abcdefgh[1] == nil {
                    if abcdefgh[1] == nil {
                        if let opt = cidr, let cidrBits = opt {
                            return IPAddress(abcdefgh[0]!, 0, 0, 0, 0, 0, 0, abcdefgh[2]!, cidr: Int(cidrBits))
                        }
                        else {
                            return IPAddress(abcdefgh[0]!, 0, 0, 0, 0, 0, 0, abcdefgh[2]!)
                        }
                    }
                    else {
                        return Optional<IPAddress>(nil)
                    }
                }
                else if abcdefgh.filter({ $0 == nil }).count != 1 {
                    return Optional<IPAddress>(nil)
                }
            case (false,true):
                if abcdefgh.count == 2 {
                    if let opt = cidr, let cidrBits = opt {
                        return IPAddress(abcdefgh[0]!, 0, 0, 0, 0, 0, 0, 0, cidr: Int(cidrBits))
                    }
                    else {
                        return IPAddress(abcdefgh[0]!, 0, 0, 0, 0, 0, 0, 0)
                    }
                }
                else if abcdefgh.count == 3 {
                    if let opt = cidr, let cidrBits = opt {
                        return IPAddress(abcdefgh[0]!, abcdefgh[1] ?? 0, 0, 0, 0, 0, 0, 0, cidr: Int(cidrBits))
                    }
                    else {
                        return IPAddress(abcdefgh[0]!, abcdefgh[1] ?? 0, 0, 0, 0, 0, 0, 0)
                    }
                }
            case (true,false):
                if abcdefgh.count == 2 {
                    if let opt = cidr, let cidrBits = opt {
                        return IPAddress(0, 0, 0, 0, 0, 0, 0, abcdefgh[1]!, cidr: Int(cidrBits))
                    }
                    else {
                        return IPAddress(0, 0, 0, 0, 0, 0, 0, abcdefgh[1]!)
                    }
                }
                else if abcdefgh.count == 3 {
                    if let opt = cidr, let cidrBits = opt {
                        return IPAddress(0, 0, 0, 0, 0, 0, abcdefgh[1] ?? 0, abcdefgh[2]!, cidr: Int(cidrBits))
                    }
                    else {
                        return IPAddress(0, 0, 0, 0, 0, 0, abcdefgh[1] ?? 0, abcdefgh[2]!)
                    }
                }

            case (true,true):
                if abcdefgh.count == 2 {
                    return nil
                }
                else if abcdefgh.count == 3 {
                    if let opt = cidr, let cidrBits = opt {
                        return abcdefgh[1] == nil ? IPAddress(0, 0, 0, 0, 0, 0, 0, 0, cidr: Int(cidrBits)) : nil
                    }
                    else {
                        return abcdefgh[1] == nil ? IPAddress(0, 0, 0, 0, 0, 0, 0, 0) : nil
                    }
                }
                else if abcdefgh.count == 8 {
                    let nn = abcdefgh.filter({ $0 == nil }).count
                    if nn == 2 {
                        if let opt = cidr, let cidrBits = opt {
                            return IPAddress(0, abcdefgh[1]!, abcdefgh[2]!, abcdefgh[3]!, abcdefgh[4]!, abcdefgh[5]!, abcdefgh[6]!, 0, cidr: Int(cidrBits))
                        }
                        else {
                            return IPAddress(0, abcdefgh[1]!, abcdefgh[2]!, abcdefgh[3]!, abcdefgh[4]!, abcdefgh[5]!, abcdefgh[6]!, 0)
                        }
                    }
                    else if nn == 3 && (abcdefgh[1] != nil || abcdefgh[6] != nil) {
                        return nil
                    }
                }
            }

            let ec = abcdefgh.filter({ $0 != nil }).count
//            print(#line, "slowpath ->", abcdefgh, ec, "nilcount = \(abcdefgh.filter({ $0 == nil }).count)")
            guard abcdefgh.count - ec < 4, ec <= 8 else {
                return nil
            }

            if abcdefgh.count - ec == 1 {
                let insertionPoint = abcdefgh.firstIndex(of: nil)!
                let pad = Array<UInt16>(repeating: 0, count: 8 - ec - 1)
                var e = abcdefgh
                e[insertionPoint] = 0
                e.insert(contentsOf: pad, at: insertionPoint)
                if let opt = cidr, let cidrBits = opt {
                    return IPAddress(e[0]!, e[1]!, e[2]!, e[3]!, e[4]!, e[5]!, e[6]!, e[7]!, cidr: Int(cidrBits))
                }
                else {
                    return IPAddress(e[0]!, e[1]!, e[2]!, e[3]!, e[4]!, e[5]!, e[6]!, e[7]!)
                }
            }
            else if abcdefgh.count - ec == 2 {
                var e = abcdefgh
                let singleInsertionPoint = e.lastIndex(of: nil)!
                e[singleInsertionPoint] = 0
                let padInsertionPoint = abcdefgh.firstIndex(of: nil)!
                let pad = Array<UInt16>(repeating: 0, count: 8 - e.count)
                e[padInsertionPoint] = 0
                e.insert(contentsOf: pad, at: padInsertionPoint)
                if let opt = cidr, let cidrBits = opt {
                    return IPAddress(e[0]!, e[1]!, e[2]!, e[3]!, e[4]!, e[5]!, e[6]!, e[7]!, cidr: Int(cidrBits))
                }
                else {
                    return IPAddress(e[0]!, e[1]!, e[2]!, e[3]!, e[4]!, e[5]!, e[6]!, e[7]!)
                }
            }
            else if abcdefgh.count - ec == 3 {
                if abcdefgh.lastIndex(of: nil)! - abcdefgh.firstIndex(of: nil)! == 2 {
                    return nil
                }
                var e = abcdefgh
                let lastInsertionPoint = e.lastIndex(of: nil)!
                e[lastInsertionPoint] = 0
                let secondlastInsertionPoint = e.lastIndex(of: nil)!
                e[secondlastInsertionPoint] = 0
                let padInsertionPoint = e.lastIndex(of: nil)!
                let pad = Array<UInt16>(repeating: 0, count: 8 - e.count)
                e[padInsertionPoint] = 0
                e.insert(contentsOf: pad, at: padInsertionPoint)
                if let opt = cidr, let cidrBits = opt {
                    return IPAddress(e[0]!, e[1]!, e[2]!, e[3]!, e[4]!, e[5]!, e[6]!, e[7]!, cidr: Int(cidrBits))
                }
                else {
                    return IPAddress(e[0]!, e[1]!, e[2]!, e[3]!, e[4]!, e[5]!, e[6]!, e[7]!)
                }
            }
            else {
                fatalError()
//                return nil // returning nil would be safer than fatalError()
            }
        })
        let ipv6AddressParser = Parse {
            Skip { Optionally { Whitespace() } }
            ipv6Parser
            Skip { Optionally { Whitespace() } }
        }
        return try? ipv6AddressParser.parse(&input)
    }
}

internal func alt_parser(_ str:String) -> IPAddress? {
    let iii = str.indices
    var headDigitStack:[UInt8] = []
    var u16:[UInt16] = Array(repeating: 0, count: 8)
    var digitCount:Int = 0
    var ccc:Int = 0 // consecutive colon count
    var sc:Int = 0 // segment count
    // var atype:UInt16? = nil
    var insertionPoint:Int = -1
    //var zeroBit:Bool = false
    let relaxed:Bool = true
    var cidr:UInt8? = nil
    let maskAddressType:UInt16 =    0b0000_0000_0000_0011
    let maskZeroBit:UInt16 =        0b0000_0000_0000_0100
    let maskRelaxed:UInt16 =        0b0000_0000_0000_1000
    let maskInsertionPoint:UInt16 = 0b0000_0000_1111_0000
    let maskCidr:UInt16 =           0b1111_1111_0000_0000
    var bm:UInt16 = maskAddressType

    //     ┌─────────────── cidr
    // ┌───┴───┐ ┌──┬────── insertion point
    // 0000.0000.0000.0000
    //                ││└┴─ addressType
    //                │└─── zeroBit
    //                └──── relaxed

//    bm |= maskZeroBit // set true
//    bm ^= maskZeroBit // toggle

    for i in iii {
        if let hd = str[i].asciiValue, hd > 45, hd < 103 {
            // :
            if hd == 58 {
                //zeroBit = false
                bm &= ~maskZeroBit // set false
                if /*atype == nil*/ (bm & maskAddressType) == maskAddressType {
                    //atype = 1 // v6
                    bm = (bm & ~maskAddressType) | 1
                }
                guard headDigitStack.count < 5 else {
                    //print("invalid format, too many digits", #line)
                    return nil
                }
                for hd in headDigitStack {
                    u16[sc] = (u16[sc] << 4) + UInt16(hd)
                }
                headDigitStack.removeAll(keepingCapacity: true)
                digitCount = 0
                ccc += 1
                if ccc == 2 {
                    if insertionPoint != -1 {
//                    if outi != str.indices.endIndex {
                        //print("multiple ::", #line)
                        return nil
                    }
                    //outi = i
                    insertionPoint = sc
                }
                else if ccc > 2 {
                    //print("invalid format", #line)
                    return nil
                }
                if i == iii.index(before: str.endIndex), ccc != 2 {
                    //print("invalid format", #line)
                    return nil
                }
            }
            // .
            else if hd == 46 {
                //zeroBit = false
                bm &= ~maskZeroBit // set false
                if /*atype == nil*/ (bm & maskAddressType) == maskAddressType {
                    // atype = 0 // v4
                    bm = bm & ~maskAddressType
                }
                guard headDigitStack.count < 4 else {
                    //print("invalid format, too many digits", #line)
                    return nil
                }
                for (i,hd) in headDigitStack.reversed().enumerated() {
                    var p:UInt16 = 1
                    for _ in 0..<i {
                        p = p * 10
                    }
                    u16[sc] += (p * UInt16(hd))
                }
                guard u16[sc] < 256 else {
                    //print("overflow '\(u16[sc])'", #line)
                    return nil
                }
                digitCount = 0
                ccc += 1
                if ccc == 2 {
                    if insertionPoint != -1 {
//                    if outi != str.indices.endIndex {
                        //print("multiple ..", #line)
                        return nil
                    }
//                    outi = i
                    insertionPoint = sc
                    //print("breaking out", #line)
                    break
                }
                headDigitStack.removeAll(keepingCapacity: true)
            }
            // /
            else if hd == 47 {
                guard ccc == 0 || ccc == 2 else {
                    //print("invalid format", #line)
                    return nil
                }
                guard let c = UInt8(str[iii.index(after: i)...]) else {
                    //print("invalid cidr '\(str[iii.index(after: i)...])'")
                    return nil
                }
                cidr = c
                //print("cidr", UInt8(str[iii.index(after: i)...]) as Any)
                //zeroBit = false
                bm &= ~maskZeroBit // set false
                digitCount = 0
                break
            }
            // 0 - 9
            else if hd < 58 {
                // :1234 must fail
                if i == iii.index(after: iii.startIndex), ccc == 1 {
                    //print("invalid format", #line)
                    return nil
                }
                if /*zeroBit*/ (bm & maskZeroBit) > 0 {
                    //print("invalid leading zero", #line)
                    return nil
                }
                //zeroBit = hd == 48 && digitCount == 0
                bm = (hd == 48 && digitCount == 0) ? (bm | maskZeroBit) : (bm & ~maskZeroBit)
                headDigitStack.append(hd - 48)
                digitCount += 1
                ccc = 0
            }
            // a-f
            else if hd > 96 {
                // :abcd must fail
                if i == iii.index(after: iii.startIndex), ccc == 1 {
                    //print("invalid format", #line)
                    return nil
                }
                if /*zeroBit*/ (bm & maskZeroBit) > 0 {
                    //print("invalid leading zero", #line)
                    return nil
                }
                headDigitStack.append(hd - 87)
                digitCount += 1
                bm = (bm & ~maskAddressType) | 1 // atype = 1
                ccc = 0
            }
            else if relaxed, (65...70).contains(hd) {
                // :ABCD must fail
                if i == iii.index(after: iii.startIndex), ccc == 1 {
                    //print("invalid format", #line)
                    return nil
                }
                if /*zeroBit*/ (bm & maskZeroBit) > 0 {
                    //print("invalid leading zero", #line)
                    return nil
                }
                
                headDigitStack.append(hd - 55)
                digitCount += 1
                bm = (bm & ~maskAddressType) | 1 // atype = 1
                ccc = 0
            }
            else {
                //print("invalid char '\(str[i])'", #line)
                return nil
            }
            if /*atype == nil*/ (bm & maskAddressType) == maskAddressType {
                if hd > 96 {
                    // addresstype had not yet been resolved and we've got a|b|c|d|e|f
                    // from now on, let's assume this is a v6 address
                    //print("looks like an v6 address")
                    bm = (bm & ~maskAddressType) | 1 // atype = 1
                } // else ... we don't know yet
            }
            if digitCount == 0, i != iii.first {
                sc += 1
                if /*atype == 1*/(bm & maskAddressType) == 1, sc > 7 {
                    //print("too many segments", #line)
                    return nil
                }
                else if /*atype == 0*/(bm & maskAddressType) == 0, sc > 3 {
                    //print("too many segments", #line)
                    return nil
                }
            }
        }
        else {
            //print("invalid char '\(str[i])'", #line)
            return nil
        }
        //print("parsing head[dc=\(digitCount),zb=\(zeroBit),ccc=\(ccc)]:    '\(str[i])'    /\(cidr)    \(sc)    \(wildcard == nil ? "_":"*")    \(addressType == nil ? "??" : addressType! == 0 ? "v4":"v6")    \(u16)    \(headDigitStack)")
    }
    // process remaining last segment
    if /*let addressType = atype*/ (bm & maskAddressType) != maskAddressType { // maybe this is not needed at all
        if /*addressType == 1*/(bm & maskAddressType) == 1 {
            for hd in headDigitStack {
                u16[sc] = (u16[sc] << 4) + UInt16(hd)
            }
        }
        else if /*addressType == 0*/(bm & maskAddressType) == 0 {
            for (i,hd) in headDigitStack.reversed().enumerated() {
                var p:UInt16 = 1
                for _ in 0..<i {
                    p = p * 10
                }
                u16[sc] += (p * UInt16(hd))
            }
            guard u16[sc] < 256 else {
                //print("overflow '\(u16[sc])'", #line)
                return nil
            }
        }
        else {
            return nil
        }
    }
    if str.isEmpty == false {
        let li = iii.index(before: iii.endIndex)
        if (48...57).contains(str[li].asciiValue ?? 0) ||
            (97...102).contains(str[li].asciiValue ?? 0) ||
            ((65...70).contains(str[li].asciiValue ?? 0) && relaxed) {
            sc += 1
        }
    }

    if /*let addressType = atype*/ (bm & maskAddressType) != maskAddressType {
        if /*addressType*/(bm & maskAddressType) == 0 {
            if sc == 4 {
                let u8 = u16.prefix(4).map({ UInt8($0) })
                //print("return: IPAddress(bytes: \(u8))")
                return IPAddress(bytes: u8, cidr: Int(cidr ?? 32))
            }
            else {
                //print("invalid format", #line)
                return nil
            }
        }
        else if /*addressType == 1*/(bm & maskAddressType) == 1 {
            if sc == 8 {
                //print("return: IPAddress(abcdefgh:)")
                return IPAddress(u16[0], u16[1], u16[2], u16[3], u16[4], u16[5], u16[6], u16[7], cidr: Int(cidr ?? 128))
            }
            else {
                if insertionPoint == -1 {
                    //print("invalid format", #line)
                    return nil
                }
                else {
                    let insert = Array(repeating: UInt16(0), count: 8 - sc)
                    //print("xxx", sc, insert,insertionPoint)
                    u16.insert(contentsOf: insert, at: insertionPoint)
                    //print("u16:", u16)
                    return IPAddress(u16[0], u16[1], u16[2], u16[3], u16[4], u16[5], u16[6], u16[7], cidr: Int(cidr ?? 128))
                }
            }
        }
    }
    //print("failing parsing", #line)
    return nil
}

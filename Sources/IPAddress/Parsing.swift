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

internal func alt_parser(_ str:String, options:IPAddress.ParsingOptions? = nil) -> IPAddress? {
    let opts = options ?? IPAddress.ParsingOptions()
    let iii = str.indices
    var digitStack:[UInt8] = []
    var u16Stack:[UInt16] = []
    var consecutiveSeparatorCount:Int = 0
    let maskAddressType:UInt16 =    0b0000_0000_0000_0011
    let maskZeroBit:UInt16 =        0b0000_0000_0000_0100
    let maskInsertionPoint:UInt16 = 0b0000_0000_1111_0000
    let maskCidr:UInt16 =           0b1111_1111_0000_0000
    
    var bm:UInt16 = maskAddressType | 0b0000_0000_1000_0000 | maskCidr
    
    //     ┌─────────────── cidr
    // ┌───┴───┐ ┌──┬────── insertion point
    // 0000.0000.0000.0000
    //                ││└┴─ addressType
    //                │└─── zeroBit
    //                └──── reserved for future use

    for i in iii {
        guard let hd = str[i].asciiValue, hd > 45, hd < 103 else {
            // invalid character
            return nil
        }
        // Colon ':'
        if hd == 58 {
            // Set zeroBit to false
            bm &= ~maskZeroBit
            // Set addressType to ipv6
            bm = (bm & ~maskAddressType) | IPAddress.IPAddrType.v6.rawValue
            // Check for ipv6 digit overflow
            guard digitStack.count < 5 else {
                return nil // too many digits for ipv6
            }
            // Set the u16 value
            var u16:UInt16 = 0
            for digit in digitStack {
                u16 = (u16 << 4) + UInt16(digit)
            }
            // Increment the consecutive separator counter
            consecutiveSeparatorCount += 1
            // Check if we have '::'
            if consecutiveSeparatorCount == 2 {
                // Have we already seen '::' before?
                guard (bm & maskInsertionPoint) == 0b1000_0000 else {
                    return nil // Yes, this is now a subsequent '::', only one '::' is allowed
                }
                // Save the insertion point
                bm = (bm & ~maskInsertionPoint) | (UInt16(u16Stack.count) << 4)
            }
            // Check if we have ':::' (or more)
            else if consecutiveSeparatorCount > 2 {
                // More than two colons are not allowed
                return nil
            }
            // Check if we have a single ':' at the end
            if i == iii.index(before: str.endIndex), consecutiveSeparatorCount != 2 {
                // Yes, address ends with single ':'. Single ':' at the end is not allowed.
                return nil
            }
            // Reset the digit stack, keep capacity
            digitStack.removeAll(keepingCapacity: true)
            // append segment value
            u16Stack.append(u16)
        }
        // Dot '.'
        else if hd == 46 {
            // Set zeroBit to false
            bm &= ~maskZeroBit
            // Set addressType to ipv4
            bm = bm & ~maskAddressType
            // Check for ipv4 digit overflow
            guard digitStack.count < 4 else {
                return nil // too many digits for ipv4
            }
            // Set the u16 value
            var u16:UInt16 = 0
            for (i,hd) in digitStack.reversed().enumerated() {
                var p:UInt16 = 1
                for _ in 0..<i {
                    p = p * 10
                }
                u16 += (p * UInt16(hd))
            }
            // Check that the ipv4 segment value is 0-255
            guard u16 < 256 else {
                // ipv4 segement overflow
                return nil
            }
            // Increment the consecutive separator counter
            consecutiveSeparatorCount += 1
            // Check if we have '..' (or more)
            guard consecutiveSeparatorCount < 2 else {
                // We have more than one consecutive colons, this is not allowed for ipv4 addresses
                return nil
            }
            // Set address type
            bm = (bm & ~maskAddressType) | IPAddress.IPAddrType.v4.rawValue
            // Reset the digit stack, keep capacity
            digitStack.removeAll(keepingCapacity: true)
            // append segment value
            u16Stack.append(u16)
        }
        // Slash '/'
        else if hd == 47 {
            // Make sure (ipv4 or ipv6) address part ends with digit segment
            // or with '::'
            guard consecutiveSeparatorCount == 0 || consecutiveSeparatorCount == 2 else {
                // Invalid address format, a well formed digit segment or '::' must precede cidr
                return nil
            }
            // Convert the cidr value from String to UInt8
            guard let c = UInt8(str[iii.index(after: i)...]) else {
                // Invalid cidr format
                return nil
            }
            // Set the cidr value
            bm = (bm & ~maskCidr) | UInt16(c) << 8
            // We're done here, break out and ignore the rest of the string
            break
        }
        // Digits '0 - 9'
        else if hd < 58 {
            // Check if we have a single separator in front of the first digit segment
            // ipv6 address :1234...
            //              └┴─ must fail
            // ipv6 address ::1234...
            //              └─┴─ must succeed
            // ipv6 address 1234:1234...
            //                  └┴─ must succeed
            // ipv4 address .168.5.4
            //              └┴─ must fail
            guard (i == iii.index(after: iii.startIndex) && consecutiveSeparatorCount == 1) == false else {
                // Yes, single separator in front of digit(s), not allowed
                return nil
            }
            if opts.contains(.noLeadingZeros) {
                // Check if we have a leading zero
                guard (bm & maskZeroBit) == 0 else {
                    // Previous digit was zero and options has noLeadingZeros set, fail
                    return nil
                }
                // Set zeroBit accordingly
                bm = (hd == 48 && digitStack.count == 0) ? (bm | maskZeroBit) : (bm & ~maskZeroBit)
            }
            // append digit value
            digitStack.append(hd - 48)
            // reset consecutive separator count
            consecutiveSeparatorCount = 0
        }
        // a-f
        else if hd > 96 {
            // :abcd must fail
            if i == iii.index(after: iii.startIndex), consecutiveSeparatorCount == 1 {
                return nil
            }
            if (bm & maskZeroBit) > 0 {
                return nil
            }
            // append digit value
            digitStack.append(hd - 87)
            // set address type
            bm = (bm & ~maskAddressType) | IPAddress.IPAddrType.v6.rawValue
            // reset consecutive separator count
            consecutiveSeparatorCount = 0
        }
        // A-F
        else if opts.contains(.noUppercase) == false, (65...70).contains(hd) {
            // :ABCD must fail
            if i == iii.index(after: iii.startIndex), consecutiveSeparatorCount == 1 {
                //print("invalid format", #line)
                return nil
            }
            if (bm & maskZeroBit) > 0 {
                return nil
            }
            // append digit value
            digitStack.append(hd - 55)
            // set address type
            bm = (bm & ~maskAddressType) | IPAddress.IPAddrType.v6.rawValue
            // reset consecutive separator count
            consecutiveSeparatorCount = 0
        }
        else {
            // invalid character
            return nil
        }
    }

    // process remaining last segment
    if (bm & maskAddressType) == IPAddress.IPAddrType.v6.rawValue {
        // Check for digit and segment overflow
        guard (digitStack.isEmpty == false || bm & maskInsertionPoint != maskInsertionPoint), digitStack.count < 5, u16Stack.count < 8 else {
            return nil
        }
        // Set address segment values
        var u16:UInt16 = 0
        for hd in digitStack {
            u16 = (u16 << 4) + UInt16(hd)
        }
        u16Stack.append(u16)
    }
    else if (bm & maskAddressType) == IPAddress.IPAddrType.v4.rawValue {
        // Check for digit and segment overflow
        guard digitStack.isEmpty == false, digitStack.count < 4, u16Stack.count < 4 else {
            return nil
        }
        // Set address segment values
        var u16:UInt16 = 0
        for (i,hd) in digitStack.reversed().enumerated() {
            var p:UInt16 = 1
            for _ in 0..<i {
                p = p * 10
            }
            u16 += (p * UInt16(hd))
        }
        // Check for ipv4 segment value overflow
        guard u16 < 256 else {
            return nil
        }
        u16Stack.append(u16)
    }
    else {
        // unknown address type
        return nil
    }

    // Check address segment counts and fill in the blanks if needed
    if (bm & maskAddressType) == IPAddress.IPAddrType.v4.rawValue {
        // Do we have all required 4 segments of an ipv4 address
        guard u16Stack.count == 4 else {
            return nil
        }
        // Map values to UInt8
        let u8 = u16Stack.prefix(4).map({ UInt8($0) })
        // Initialize ipv4 address
        let cidr = (bm & maskCidr) == maskCidr ?
        IPAddress.validV4CIDRRange.upperBound
        :
        Int((bm & maskCidr) >> 8)
        return IPAddress(bytes: u8, cidr: cidr)
    }
    else if (bm & maskAddressType) == IPAddress.IPAddrType.v6.rawValue {
        // Do we have all required 8 segments of an ipv4 address
        let cidr = (bm & maskCidr) == maskCidr ?
        IPAddress.validV6CIDRRange.upperBound
        :
        Int((bm & maskCidr) >> 8)
        guard u16Stack.count == 8 else {
            // Was there a wildcard '::'
            guard (bm & maskInsertionPoint) != 0b1000_0000 else {
                return nil // No wildcard '::' and we don't have enough segments
            }
            // Insertion elements
            let insert = Array(repeating: UInt16(0), count: Swift.max(0, 8 - /*segmentIndex*/u16Stack.count))
            // Insert
            u16Stack.insert(contentsOf: insert, at: /*insertionPoint*/ Int((bm & maskInsertionPoint) >> 4))
            // Initialize ipv6 address
            return IPAddress(u16Stack[0], u16Stack[1], u16Stack[2], u16Stack[3], u16Stack[4], u16Stack[5], u16Stack[6], u16Stack[7], cidr: Int(cidr))
        }
        // Initialize ipv6 address
        return IPAddress(u16Stack[0], u16Stack[1], u16Stack[2], u16Stack[3], u16Stack[4], u16Stack[5], u16Stack[6], u16Stack[7], cidr: Int(cidr))
    }
    return nil
}

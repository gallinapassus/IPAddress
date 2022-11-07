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
fileprivate enum errx : Error {
    case compressed
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

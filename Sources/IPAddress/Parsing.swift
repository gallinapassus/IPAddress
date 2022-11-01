import Foundation
import Parsing

internal struct IPv4AddressParser<Input:Collection> : Parser {
    public typealias Input = Substring
    public typealias Output = IPAddress?
    @inlinable
    public init() {}
    public func parse(_ input: inout Substring) throws -> Output {
        let ipv4elementParser = Many {
            Prefix { $0.isNumber }.map { UInt8($0, radix: 10) }
        } separator: {
            "."
        }
        let ipv4Parser = Parse {
            ipv4elementParser
            Optionally {
                "/"
                Prefix { $0.isNumber }.map { UInt8($0, radix: 10) }
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
        let ipv6elementParser = Many {
            Prefix { $0.isNumber || "abcdef".contains($0) }.map { UInt16($0, radix: 16) }
        } separator: {
            ":"
        }
        let ipv6Parser = Parse {
            ipv6elementParser
            Optionally {
                "/"
                Prefix { $0.isNumber }.map { UInt8($0, radix: 10) }
            }
            End()
        }.map({ result in
            
            // Initial (and limited) implementation of ipv6 address parsing
            let (abcdefgh,cidr) = result
            let elements:[UInt16] = abcdefgh.compactMap({ $0 })
            guard elements.count <= 8 else {
                return Optional<IPAddress>(nil)
            }
            let nonNilCount = abcdefgh.filter({ $0 != nil }).count
            let pad = Array<UInt16>(repeating: 0, count: 8 - nonNilCount)
            var new = elements
            let insertionPoint = abcdefgh.firstIndex(of: nil)
            if let ipoint = insertionPoint {
                new.insert(contentsOf: pad, at: ipoint)
            }
            new = new.compactMap({ $0 })
            guard new.count == 8 else {
                return Optional<IPAddress>(nil)
            }
            if let opt = cidr, let cidrBits = opt {
                return IPAddress(new[0], new[1], new[2], new[3], new[4], new[5], new[6], new[7], cidr: Int(cidrBits))
            }
            else {
                return IPAddress(new[0], new[1], new[2], new[3], new[4], new[5], new[6], new[7])
            }
        })
        let oneOf = Parse {
            Skip { Optionally { Whitespace() } }
            ipv6Parser
            Skip { Optionally { Whitespace() } }
        }
        return try oneOf.parse(&input)
    }
}

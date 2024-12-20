public struct IPAddressAndPort : Codable, CustomStringConvertible {
    public enum IPAddressAndPortError : Error {
        case msg(String)
    }
    public var description: String {
        "\(ip.description):\(port)"
    }
    enum CodingKeys : CodingKey {
        case ip, port, ipProtocol
    }
    public enum IPProtocol : String, Codable { case tcp, udp }
    public let ip:IPAddress
    public let port:Int
    public let ipProtocol:IPProtocol
    
    public init(ip:IPAddress, port:Int, ipProtocol:IPProtocol = .tcp) {
        self.ip = ip
        self.port = port
        self.ipProtocol = ipProtocol
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tmp = try container.decode(String.self, forKey: .ip)
        if let valid = IPAddress(tmp) {
            self.ip = valid
        }
        else {
            throw IPAddressAndPortError.msg("Invalid IP address")
        }
        self.port = try container.decode(Int.self, forKey: .port)
        self.ipProtocol = try container.decode(IPProtocol.self, forKey: .ipProtocol)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ip.description, forKey: .ip)
        try container.encode(port, forKey: .port)
        try container.encode(ipProtocol, forKey: .ipProtocol)
    }
}
#if canImport(ArgumentParser)
import ArgumentParser

extension IPAddressAndPort : ExpressibleByArgument {
    public init?(argument:String) {
        
        guard let idx = argument.lastIndex(of: ":") else {
            // Can't be IPv6 & doesn't have port -> IPv4 without port
            guard let valid = IPAddress(argument) else {
                return nil
            }
            self.ip = valid
            self.port = 80
            self.ipProtocol = .tcp
            return
        }

        let after = argument.index(after: idx)
        let p = argument[(after..<argument.endIndex)]
        let addr = argument[(..<idx)]

        // Port must not be empty
        guard p.isEmpty == false else {
            return nil
        }

        guard let valid = IPAddress(String(addr)), let port = Int(p) else {
            return nil
        }
        self.ip = valid
        self.port = port
        self.ipProtocol = .tcp
    }
}
#endif

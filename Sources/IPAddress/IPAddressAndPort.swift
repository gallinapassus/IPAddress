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
    public let port:UInt16
    public let ipProtocol:IPProtocol
    
    public init(ip:IPAddress, port:UInt16, ipProtocol:IPProtocol = .tcp) {
        self.ip = ip
        self.port = port
        self.ipProtocol = ipProtocol
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ip.description, forKey: .ip)
        try container.encode(port, forKey: .port)
        try container.encode(ipProtocol, forKey: .ipProtocol)
    }
}

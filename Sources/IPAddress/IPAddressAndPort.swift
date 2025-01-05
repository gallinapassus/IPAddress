public struct IPAddressAndPort : Codable {

    public enum IPAddressAndPortError : Error {
        case msg(String)
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
}
// MARK: -
extension IPAddressAndPort : Equatable {
    public static func == (lhs: IPAddressAndPort, rhs: IPAddressAndPort) -> Bool {
        lhs.ip == rhs.ip && lhs.port == rhs.port && lhs.ipProtocol == rhs.ipProtocol
    }
}
// MARK: -
extension IPAddressAndPort : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ip)
        hasher.combine(port)
        hasher.combine(ipProtocol)
    }
}

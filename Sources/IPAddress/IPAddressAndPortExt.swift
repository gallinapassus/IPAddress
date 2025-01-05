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
        
        guard let valid = IPAddress(String(addr)), let port = UInt16(p) else {
            return nil
        }
        self.ip = valid
        self.port = port
        self.ipProtocol = .tcp
    }
}
#endif


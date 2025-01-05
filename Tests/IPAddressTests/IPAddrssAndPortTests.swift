import Foundation
import XCTest
import IPAddress

final class IPAddressAndPortTests: XCTestCase {
    func test_codable() async throws {
        
        let ipa = IPAddressAndPort(
            ip: IPAddress(127, 0, 0, 1),
            port: 53,
            ipProtocol: .udp
        )
        
        XCTAssertTrue(ipa.ip.cidrBits == 32)
        XCTAssertTrue(ipa.ip.networkMask == [255,255,255,255])
        XCTAssertTrue(ipa.ip.networkAddress == IPAddress(127, 0, 0, 1))
        XCTAssertTrue(ipa.ip.rawAddressData == Data([127, 0, 0, 1]))
        XCTAssertTrue(ipa.ip.isLoopback == true)
        XCTAssertTrue(ipa.port == 53)
        XCTAssertTrue(ipa.ipProtocol == .udp)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let jsonData = try encoder.encode(ipa)
        let decoder = JSONDecoder()
        let decodedIPA = try decoder.decode(IPAddressAndPort.self, from: jsonData)
        
        XCTAssertTrue(decodedIPA.ip.cidrBits == 32)
        XCTAssertTrue(decodedIPA.ip.networkMask == [255,255,255,255])
        XCTAssertTrue(decodedIPA.ip.networkAddress == IPAddress(127, 0, 0, 1))
        XCTAssertTrue(decodedIPA.ip.rawAddressData == Data([127, 0, 0, 1]))
        XCTAssertTrue(decodedIPA.ip.isLoopback == true)
        XCTAssertTrue(decodedIPA.port == 53)
        XCTAssertTrue(decodedIPA.ipProtocol == .udp)
        XCTAssertTrue(ipa == decodedIPA)
    }
}

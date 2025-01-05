import Foundation
import Testing
import IPAddress

@Test
func test_codable() async throws {

    let ipa = IPAddressAndPort(
        ip: IPAddress(127, 0, 0, 1),
        port: 53,
        ipProtocol: .udp
    )

    #expect(ipa.ip.cidrBits == 32)
    #expect(ipa.ip.networkMask == [255,255,255,255])
    #expect(ipa.ip.networkAddress == IPAddress(127, 0, 0, 1))
    #expect(ipa.ip.rawAddressData == Data([127, 0, 0, 1]))
    #expect(ipa.ip.isLoopback == true)
    #expect(ipa.port == 53)
    #expect(ipa.ipProtocol == .udp)

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    let jsonData = try encoder.encode(ipa)
    let decoder = JSONDecoder()
    let decodedIPA = try decoder.decode(IPAddressAndPort.self, from: jsonData)

    #expect(decodedIPA.ip.cidrBits == 32)
    #expect(decodedIPA.ip.networkMask == [255,255,255,255])
    #expect(decodedIPA.ip.networkAddress == IPAddress(127, 0, 0, 1))
    #expect(decodedIPA.ip.rawAddressData == Data([127, 0, 0, 1]))
    #expect(decodedIPA.ip.isLoopback == true)
    #expect(decodedIPA.port == 53)
    #expect(decodedIPA.ipProtocol == .udp)
    #expect(ipa == decodedIPA)
}

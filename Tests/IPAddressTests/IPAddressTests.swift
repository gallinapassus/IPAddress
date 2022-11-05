import XCTest
@testable import IPAddress
import BigInt

final class IPAddressTests: XCTestCase {
    func test_IPAddress_init() {
        // Failable
        // init?(_ bytes:[UInt8])
        for i in CIDR.validV4Range {
            switch i {
            case 4, 16:
                XCTAssertNotNil(IPAddress(Array<UInt8>(repeating: 0, count: i)), "\(i)")
            default:
                XCTAssertNil(IPAddress(Array<UInt8>(repeating: 0, count: i)))
            }
        }
        // init?(_ string:String)
        do {
            let arr:[(String, IPAddress?)] = [
                ("1.2.3.4/0", IPAddress(1, 2, 3, 4, cidr: 0)!),
                ("192.168.0.1", IPAddress(192, 168, 0, 1, cidr: 32)!),
                ("1:2:3:4:5:6:7:8/18", IPAddress(1, 2, 3, 4, 5, 6, 7, 8, cidr: 18)),
                ("1:2:3:4:5:6:7:dead/18", IPAddress(1, 2, 3, 4, 5, 6, 7, 57005, cidr: 18)),
                ("::1/128", IPAddress(0, 0, 0, 0, 0, 0, 0, 1, cidr: 128)),
                ("dead:beef:1/128", nil),
                ("dead::beef:1/64", IPAddress(57005, 0, 0, 0, 0, 0, 48879, 1, cidr: 64)),
                //("deadbeef::ff/64", nil), // TODO: This should fail => nil
                ("[8.8.8.8]", nil),
                ("x", nil),
                ("", nil),
            ]
            for (str,expected) in arr {
                XCTAssertEqual(IPAddress(str), expected)
            }
        }

        // Non-failable
        // ipv4
        // init(_ a:UInt8, _ b:UInt8, _ c:UInt8, _ d:UInt8, cidr bits:Int = 32)
        do {
            let v4 = IPAddress(1, 2, 3, 4)
            XCTAssertEqual(v4.cidr.bits, 32)
            XCTAssertEqual(v4.type, .v4)
            XCTAssertEqual(v4.isv4, true)
            XCTAssertEqual(v4.isv6, false)
            XCTAssertEqual(v4.isLoopbackAddress, false)
            XCTAssertEqual(v4.rawAddressBytes, Data([1, 2, 3, 4]))
            XCTAssertEqual(v4.networkAddress, IPAddress(1, 2, 3, 4))
            XCTAssertEqual(IPAddress(0, 0, 0, 0).isLoopbackAddress, false)
            XCTAssertEqual(IPAddress(126, 255, 255, 255).isLoopbackAddress, false)
            XCTAssertEqual(IPAddress(127, 0, 0, 0).isLoopbackAddress, true)
            XCTAssertEqual(IPAddress(127, 0, 0, 1).isLoopbackAddress, true)
            XCTAssertEqual(IPAddress(127, 255, 255, 255).isLoopbackAddress, true)
            XCTAssertEqual(IPAddress(128, 0, 0, 0).isLoopbackAddress, false)
            XCTAssertEqual(IPAddress(255, 255, 255, 255).isLoopbackAddress, false)
        }
        do {
            let v6 = IPAddress(1, 2, 3, 4, 5, 6, 7, 8)
            XCTAssertEqual(v6.cidr.bits, 128)
            XCTAssertEqual(v6.type, .v6)
            XCTAssertEqual(v6.isv4, false)
            XCTAssertEqual(v6.isv6, true)
            XCTAssertEqual(v6.rawAddressBytes, Data([0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8]), "\(v6.rawAddressBytes.withUnsafeBytes({ Array($0) }))")
            XCTAssertEqual(v6.networkAddress, v6)
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 0).isLoopbackAddress, false)
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 1).isLoopbackAddress, true)
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 2).isLoopbackAddress, false)
            XCTAssertEqual(IPAddress(255, 255, 255, 255, 255, 255, 255, 255).isLoopbackAddress, false)
        }
    }
    func test_networkAddress() {
        do { // v4
            let expectedNetworkAddress = [
                IPAddress(0, 0, 0, 0, cidr: 0),
                IPAddress(0, 0, 0, 0, cidr: 1),
                IPAddress(0, 0, 0, 0, cidr: 2),
                IPAddress(0, 0, 0, 0, cidr: 3),
                IPAddress(0, 0, 0, 0, cidr: 4),
                IPAddress(0, 0, 0, 0, cidr: 5),
                IPAddress(0, 0, 0, 0, cidr: 6),
                IPAddress(0, 0, 0, 0, cidr: 7),

                IPAddress(1, 0, 0, 0, cidr: 8),
                IPAddress(1, 0, 0, 0, cidr: 9),
                IPAddress(1, 0, 0, 0, cidr: 10),
                IPAddress(1, 0, 0, 0, cidr: 11),
                IPAddress(1, 0, 0, 0, cidr: 12),
                IPAddress(1, 0, 0, 0, cidr: 13),
                IPAddress(1, 0, 0, 0, cidr: 14),

                IPAddress(1, 2, 0, 0, cidr: 15),
                IPAddress(1, 2, 0, 0, cidr: 16),
                IPAddress(1, 2, 0, 0, cidr: 17),
                IPAddress(1, 2, 0, 0, cidr: 18),
                IPAddress(1, 2, 0, 0, cidr: 19),
                IPAddress(1, 2, 0, 0, cidr: 20),
                IPAddress(1, 2, 0, 0, cidr: 21),
                IPAddress(1, 2, 0, 0, cidr: 22),

                IPAddress(1, 2, 2, 0, cidr: 23),
                
                IPAddress(1, 2, 3, 0, cidr: 24),
                IPAddress(1, 2, 3, 0, cidr: 25),
                IPAddress(1, 2, 3, 0, cidr: 26),
                IPAddress(1, 2, 3, 0, cidr: 27),
                IPAddress(1, 2, 3, 0, cidr: 28),
                IPAddress(1, 2, 3, 0, cidr: 29),
                
                IPAddress(1, 2, 3, 4, cidr: 30),
                IPAddress(1, 2, 3, 4, cidr: 31),
                IPAddress(1, 2, 3, 4, cidr: 32),
                ]
            for (i,expected) in zip(CIDR.validV4Range, expectedNetworkAddress) {
                    let v4 = IPAddress(1, 2, 3, 4, cidr: i)
                XCTAssertEqual(v4?.networkAddress, expected, "\(i): \(String(describing: v4?.networkAddress))")
                    XCTAssertEqual(v4?.networkAddress.debugDescription, expected!.debugDescription)
            }
        }
        do { // v6
            let expectedNetworkAddress = [
                IPAddress(0, 0, 0, 0, 0, 0, 0, 0, cidr: 0)!,
                IPAddress(1, 2, 0, 0, 0, 0, 0, 0, cidr: 32)!,
                IPAddress(1, 2, 3, 4, 0, 0, 0, 0, cidr: 64)!,
                IPAddress(1, 2, 3, 4, 5, 6, 0, 0, cidr: 96)!,
                IPAddress(1, 2, 3, 4, 5, 6, 6, 0, cidr: 111)!,
                IPAddress(1, 2, 3, 4, 5, 6, 7, 0, cidr: 112)!,
                IPAddress(1, 2, 3, 4, 5, 6, 7, 8, cidr: 128)!,
            ]
            for (i,expected) in zip(0..<expectedNetworkAddress.count, expectedNetworkAddress) {
                let v6 = IPAddress(1, 2, 3, 4, 5, 6, 7, 8, cidr: expected.cidr.bits)!
                XCTAssertEqual(v6.networkAddress, expected, "\(i): \(v6.networkAddress)")
                XCTAssertEqual(v6.networkAddress.debugDescription, expected.debugDescription)
            }
            XCTAssertEqual(IPAddress(0xff0a, 2, 3, 4, 5, 6, 7, 8, cidr: 65)!.networkAddress,
                           IPAddress(0xff0a, 2, 3, 4, 0, 0, 0, 0, cidr: 65)!)
            XCTAssertEqual(IPAddress(0xff0a, 2, 3, 4, 5, 6, 7, 8, cidr: 65)!.networkAddress,
                           IPAddress(0xff0a, 2, 3, 4, 0, 0, 0, 0, cidr: 65)!)
            XCTAssertEqual(IPAddress(0xff0a, 2, 3, 4, 5, 6, 7, 8, cidr: 65)!.networkAddress.rawAddressBytes,
                           IPAddress(0xff0a, 2, 3, 4, 0, 0, 0, 0, cidr: 65)!.rawAddressBytes)
        }
    }
    func test_routerAddress() {
        do {
            XCTAssertEqual(IPAddress(0, 0, 0, 0, cidr: 0)!.routerAddress, IPAddress(0, 0, 0, 1, cidr: 0))
            XCTAssertEqual(IPAddress(0, 0, 0, 0, cidr: 22)!.routerAddress, IPAddress(0, 0, 0, 1, cidr: 22))
            XCTAssertEqual(IPAddress(0, 0, 0, 0, cidr: 32)!.routerAddress, nil)
            XCTAssertEqual(IPAddress(172, 16, 17, 10, cidr: 22)!.routerAddress, IPAddress(172, 16, 16, 1, cidr: 22))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 22)!.routerAddress, IPAddress(255, 255, 252, 1, cidr: 22))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 30)!.routerAddress, IPAddress(255, 255, 255, 253, cidr: 30))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 31)!.routerAddress, IPAddress(255, 255, 255, 255, cidr: 31))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 32)!.routerAddress, nil)
        }
        do {
            XCTAssertEqual(IPAddress(1, 2, 3, 4, 5, 6, 7, 8, cidr: 95)!.routerAddress, IPAddress(1, 2, 3, 4, 5, 6, 0, 1, cidr: 95))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, 255, 255, 255, 255, cidr: 95)!.routerAddress, IPAddress(255, 255, 255, 255, 255, 254, 0, 1, cidr: 95))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, 255, 255, 255, 255, cidr: 128)!.routerAddress, nil)
            XCTAssertEqual(IPAddress(65534, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 128)!.routerAddress, nil)
            XCTAssertEqual(IPAddress(65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 128)!.routerAddress, nil)
            XCTAssertEqual(IPAddress(255, 255, 255, 255, 255, 255, 255, 255, cidr: 127)!.routerAddress,
                           IPAddress(255, 255, 255, 255, 255, 255, 255, 255, cidr: 127))
            XCTAssertEqual(IPAddress(65534, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 127)!.routerAddress,
                           IPAddress(65534, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 127))
            XCTAssertEqual(IPAddress(65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 127)!.routerAddress,
                           IPAddress(65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 127))
        }
    }
    func test_broadcastAddress() {
        do {
            XCTAssertEqual(IPAddress(0, 0, 0, 0, cidr: 0)!.broadcastAddress, IPAddress(255, 255, 255, 255, cidr: 0))
            XCTAssertEqual(IPAddress(0, 0, 0, 0, cidr: 22)!.broadcastAddress, IPAddress(0, 0, 3, 255, cidr: 22))
            XCTAssertEqual(IPAddress(0, 0, 0, 0, cidr: 32)!.broadcastAddress, nil)
            XCTAssertEqual(IPAddress(172, 16, 17, 10, cidr: 22)!.broadcastAddress, IPAddress(172, 16, 19, 255, cidr: 22))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 22)!.broadcastAddress, IPAddress(255, 255, 255, 255, cidr: 22))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 30)!.broadcastAddress, IPAddress(255, 255, 255, 255, cidr: 30))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 31)!.broadcastAddress, IPAddress(255, 255, 255, 255, cidr: 31))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 32)!.broadcastAddress, nil)
        }
        do {
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 0, cidr: 128)!.broadcastAddress,
                           nil)
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 0, cidr: 127)!.broadcastAddress,
                           IPAddress(0, 0, 0, 0, 0, 0, 0, 1, cidr: 127))
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 0, cidr: 126)!.broadcastAddress,
                           IPAddress(0, 0, 0, 0, 0, 0, 0, 3, cidr: 126))
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 0, cidr: 125)!.broadcastAddress,
                           IPAddress(0, 0, 0, 0, 0, 0, 0, 7, cidr: 125))
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 0, cidr: 119)!.broadcastAddress,
                           IPAddress(0, 0, 0, 0, 0, 0, 0, 511, cidr: 119))
            XCTAssertEqual(IPAddress(1, 2, 3, 4, 5, 6, 7, 8, cidr: 126)!.broadcastAddress,
                           IPAddress(1, 2, 3, 4, 5, 6, 7, 11, cidr: 126))
            XCTAssertEqual(IPAddress(1, 2, 3, 4, 5, 6, 7, 5, cidr: 95)!.broadcastAddress,
                           IPAddress(1, 2, 3, 4, 5, 7, 65535, 65535, cidr: 95))
            XCTAssertEqual(IPAddress(65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 127)!.broadcastAddress,
                           IPAddress(65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 127))
            XCTAssertEqual(IPAddress(65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 128)!.broadcastAddress,
                           nil)
        }
    }
    func test_comparable() {
        do {
            
        }
        do {
            let v6host_a = IPAddress(1, 2, 3, 4, 5, 6, 7, 7)
            let v6host_b = IPAddress(1, 2, 3, 4, 5, 6, 7, 8)
            let v6host_c = IPAddress(1, 2, 3, 4, 5, 6, 7, 9)
            
            XCTAssertTrue(v6host_a < v6host_b)
            XCTAssertTrue(v6host_b < v6host_c)
            XCTAssertTrue(v6host_a < v6host_c)

            XCTAssertFalse(v6host_b < v6host_a)
            XCTAssertFalse(v6host_c < v6host_b)
            XCTAssertFalse(v6host_c < v6host_a)

            XCTAssertFalse(v6host_a < v6host_a)
            
            XCTAssertFalse(IPAddress(1, 2, 3, 4, 5, 6, 7, 8) > IPAddress(1, 2, 3, 4, 5, 0x100, 0, 0))
        }
    }
    func test_contains() {
        // TODO: make tests between different ip address types v4.contains(v6) and v6.contains(v4)
        do {
            
            let v4network = IPAddress(192, 168, 9, 224, cidr: 28)!
            let v4host_below = IPAddress(192, 168, 9, 223)
            let v4host_above = IPAddress(192, 168, 9, 240)
            let v4host_inrange:ClosedRange<UInt8> = (224...239)
            
            XCTAssertFalse(v4network.contains(v4host_below))
            for d in v4host_inrange {
                let other = IPAddress(192, 168, 9, d)
                XCTAssertTrue(v4network.contains(other))
                XCTAssertTrue(IPAddress(0, 0, 0, 0, cidr: 0)!.contains(other))
                XCTAssertTrue(IPAddress(255, 255, 255, 255, cidr: 0)!.contains(other))
                XCTAssertFalse(IPAddress(255, 255, 255, 255, cidr: 30)!.contains(other))
                XCTAssertFalse(IPAddress(255, 255, 255, 255, cidr: 32)!.contains(other))
            }
            XCTAssertFalse(v4network.contains(v4host_above))
            
            let v4 = IPAddress(172, 16, 16, 0, cidr: 22)!
            XCTAssertFalse(v4.contains(IPAddress(172, 16, 15, 255)))
            XCTAssertFalse(v4.contains(IPAddress(172, 16, 20, 0)))
            XCTAssertTrue(v4.contains(IPAddress(172, 16, 16, 0)))
            XCTAssertTrue(v4.contains(IPAddress(172, 16, 19, 255)))
            for i in UInt8(16)...19 {
                for j in UInt8(0)...255 {
                    let addr = IPAddress(172, 16, i, j)
                    XCTAssertTrue(v4.contains(addr))
                }
            }
            XCTAssertFalse(IPAddress(172, 16, 16, 0, cidr: 22)!.contains(IPAddress(172, 16, 17, 1, cidr: 21)!))
            XCTAssertTrue(IPAddress(172, 16, 16, 0, cidr: 22)!.contains(IPAddress(172, 16, 17, 1, cidr: 22)!))
            XCTAssertTrue(IPAddress(172, 16, 16, 0, cidr: 22)!.contains(IPAddress(172, 16, 17, 1, cidr: 23)!))
        }
        do {
            let v6network = IPAddress(1, 2, 3, 4, 5, 6, 7, 8, cidr: 88)!
            let v6host_below = IPAddress(1, 2, 3, 4, 4, 65535, 65535, 65535)
            let v6host_above = IPAddress(1, 2, 3, 4, 5, 256, 0, 0)
            let v6host_inrange = [
                IPAddress(1, 2, 3, 4, 5, 6, 7, 8),
                IPAddress(1, 2, 3, 4, 5, 6, 7, 9),
                IPAddress(1, 2, 3, 4, 5, 255, 65535, 65535),
            ]
            
            XCTAssertFalse(v6network.contains(v6host_below))
            for other in v6host_inrange {
                var oo = other
                oo.cidr = CIDR(for: .v6, bits: v6network.cidr.bits)
                let msg = [
                    "ip\(v6network.type) network \(v6network.networkAddress.debugDescription)",
                    "(range \(v6network.routerAddress!.debugDescription)",
                    "...",
                    "\(v6network.broadcastAddress!.debugDescription))",
                    "does not contain \(other.debugDescription)",
                ].joined(separator: " ")
                XCTAssertTrue(v6network.contains(other), msg)
                XCTAssertTrue(IPAddress(data: Data(repeating: 0, count: 16), cidr: 0)!.contains(other), msg)
                XCTAssertFalse(IPAddress(data: Data(repeating: 0, count: 16), cidr: 128)!.contains(other), msg)
            }
            XCTAssertFalse(v6network.contains(v6host_above))

            let a = IPAddress(data: Data(repeating: 0, count: 16), cidr: 128)!
            let b = IPAddress(data: Data(repeating: 0, count: 16), cidr: 127)!
            let c = IPAddress(data: Data(repeating: 0, count: 16), cidr: 126)!
            XCTAssertTrue(a.contains(a))
            XCTAssertFalse(a.contains(b))
            XCTAssertFalse(a.contains(c))
            XCTAssertTrue(b.contains(a))
            XCTAssertTrue(b.contains(b))
            XCTAssertFalse(b.contains(c))
            XCTAssertTrue(b.contains(IPAddress(data: Data(repeating: 0, count: 16), cidr: 128)!))
            XCTAssertTrue(c.contains(a))
            XCTAssertTrue(c.contains(b))
            XCTAssertTrue(c.contains(c))
            
            XCTAssertFalse(IPAddress(172, 16, 16, 0, cidr: 22)!.contains(IPAddress(172, 16, 17, 1, cidr: 21)!))
            XCTAssertTrue(IPAddress(172, 16, 16, 0, cidr: 22)!.contains(IPAddress(172, 16, 17, 1, cidr: 22)!))
            XCTAssertTrue(IPAddress(172, 16, 16, 0, cidr: 22)!.contains(IPAddress(172, 16, 17, 1, cidr: 23)!))

        }
    }
    func test_ipv4_init_performance() {
        measure {
            let t0 = DispatchTime.now().uptimeNanoseconds
            for i in UInt32(0)..<UInt32(UInt16.max) {
                let _ = IPAddress(i)
            }
            let t1 = DispatchTime.now().uptimeNanoseconds
            print("Initialized \(UInt16.max) ipv4 addresses in", Double(t1 - t0)/1_000_000, "ms =>", (Double(t1 - t0) / Double(UInt16.max))/1000.0, "µs/init")
        }
    }
    func test_ipv6_init_performance() {
        measure {
            let t0 = DispatchTime.now().uptimeNanoseconds
            for i in UInt16(0)..<UInt16.max {
                let _ = IPAddress(0, 0, 0, 0, 0, 0, 0, i)
            }
            let t1 = DispatchTime.now().uptimeNanoseconds
            print("Initialized \(UInt16.max) ipv6 addresses in", Double(t1 - t0)/1_000_000, "ms =>", (Double(t1 - t0) / Double(UInt16.max))/1000.0, "µs/init")
        }
    }
    func test_init_from_string_performance() {
        print("Generating test strings...", terminator: "")
        var a:[String] = []
        (UInt32(0)..<UInt32(UInt16.max/32)).forEach({ i in
            a.append(IPAddress(i).description)
            a.append(IPAddress(i).debugDescription)
            a.append(IPAddress(0, 0, 0, 0, 0, 0, 0, UInt16(i)).description)
            a.append(IPAddress(0, 0, 0, 0, 0, 0, 0, UInt16(i)).debugDescription)
            a.append("1:2:3::6::ffff/32")
            a.append("1:2:3::6:ffffx/32") // <= fails intentionally
            a.append("::1/32")
            a.append("f00d::1")
        })
        print("done")
        measure {
            let t0 = DispatchTime.now().uptimeNanoseconds
            for str in a {
                let _ = IPAddress(str)
            }
            let t1 = DispatchTime.now().uptimeNanoseconds
            print("Initialized \(a.count) ipv4/ipv6 addresses in", Double(t1 - t0)/1_000_000, "ms =>", (Double(t1 - t0) / Double(a.count))/1000.0, "µs/init")
        }
    }
}
final class CIDRTests: XCTestCase {
    func test_CIDR_init() {
        // v4
        for i in 0...32 {
            let cidr = CIDR(for: .v4, bits: i)
            XCTAssertEqual(cidr.bits, i)
            XCTAssertEqual(cidr.type, .v4)
        }
        // v6
        for i in 0...128 {
            let cidr = CIDR(for: .v6, bits: i)
            XCTAssertEqual(cidr.bits, i)
            XCTAssertEqual(cidr.type, .v6)
        }
    }
    func test_CIDR_isSingleEndPoint() {
        // v4
        for i in 0...32 {
            let cidr = CIDR(for: .v4, bits: i)
            XCTAssertEqual(cidr.isSingleEndPoint, i == 32)
        }
        // v6
        for i in 0...128 {
            let cidr = CIDR(for: .v6, bits: i)
            XCTAssertEqual(cidr.isSingleEndPoint, i == 128)
        }
    }
    func test_CIDR_networkCount() {
        let expectedV4:[BigInt] = [
            1, 2, 4, 8, 16, 32, 64, 128,
            256, 512, 1024, 2048, 4096, 8192, 16384, 32768,
            65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608,
            16777216, 33554432, 67108864, 134217728, 268435456, 536870912, 1073741824, 2147483648,
            4294967296
        ]
        let expectedV6:[BigInt] = [
            BigInt("1"), BigInt("2"), BigInt("4"), BigInt("8"), BigInt("16"), BigInt("32"), BigInt("64"), BigInt("128"),
            BigInt("256"), BigInt("512"), BigInt("1024"), BigInt("2048"), BigInt("4096"), BigInt("8192"), BigInt("16384"), BigInt("32768"),
            BigInt("65536"), BigInt("131072"), BigInt("262144"), BigInt("524288"),
            BigInt("1048576"), BigInt("2097152"), BigInt("4194304"), BigInt("8388608"),
            BigInt("16777216"), BigInt("33554432"), BigInt("67108864"), BigInt("134217728"),
            BigInt("268435456"), BigInt("536870912"), BigInt("1073741824"), BigInt("2147483648"),
            BigInt("4294967296"), BigInt("8589934592"), BigInt("17179869184"), BigInt("34359738368"),
            BigInt("68719476736"), BigInt("137438953472"), BigInt("274877906944"), BigInt("549755813888"),
            BigInt("1099511627776"), BigInt("2199023255552"), BigInt("4398046511104"), BigInt("8796093022208"),
            BigInt("17592186044416"), BigInt("35184372088832"), BigInt("70368744177664"), BigInt("140737488355328"),
            BigInt("281474976710656"), BigInt("562949953421312"), BigInt("1125899906842624"), BigInt("2251799813685248"),
            BigInt("4503599627370496"), BigInt("9007199254740992"), BigInt("18014398509481984"), BigInt("36028797018963968"),
            BigInt("72057594037927936"), BigInt("144115188075855872"), BigInt("288230376151711744"), BigInt("576460752303423488"),
            BigInt("1152921504606846976"), BigInt("2305843009213693952"), BigInt("4611686018427387904"), BigInt("9223372036854775808"),
            BigInt("18446744073709551616"), BigInt("36893488147419103232"), BigInt("73786976294838206464"), BigInt("147573952589676412928"),
            BigInt("295147905179352825856"), BigInt("590295810358705651712"), BigInt("1180591620717411303424"), BigInt("2361183241434822606848"),
            BigInt("4722366482869645213696"), BigInt("9444732965739290427392"),
            BigInt("18889465931478580854784"), BigInt("37778931862957161709568"),
            BigInt("75557863725914323419136"), BigInt("151115727451828646838272"),
            BigInt("302231454903657293676544"), BigInt("604462909807314587353088"),
            BigInt("1208925819614629174706176"), BigInt("2417851639229258349412352"),
            BigInt("4835703278458516698824704"), BigInt("9671406556917033397649408"),
            BigInt("19342813113834066795298816"), BigInt("38685626227668133590597632"),
            BigInt("77371252455336267181195264"), BigInt("154742504910672534362390528"),
            BigInt("309485009821345068724781056"), BigInt("618970019642690137449562112"),
            BigInt("1237940039285380274899124224"), BigInt("2475880078570760549798248448"),
            BigInt("4951760157141521099596496896"), BigInt("9903520314283042199192993792"),
            BigInt("19807040628566084398385987584"), BigInt("39614081257132168796771975168"),
            BigInt("79228162514264337593543950336"), BigInt("158456325028528675187087900672"),
            BigInt("316912650057057350374175801344"), BigInt("633825300114114700748351602688"),
            BigInt("1267650600228229401496703205376"), BigInt("2535301200456458802993406410752"),
            BigInt("5070602400912917605986812821504"), BigInt("10141204801825835211973625643008"),
            BigInt("20282409603651670423947251286016"), BigInt("40564819207303340847894502572032"),
            BigInt("81129638414606681695789005144064"), BigInt("162259276829213363391578010288128"),
            BigInt("324518553658426726783156020576256"), BigInt("649037107316853453566312041152512"),
            BigInt("1298074214633706907132624082305024"), BigInt("2596148429267413814265248164610048"),
            BigInt("5192296858534827628530496329220096"), BigInt("10384593717069655257060992658440192"),
            BigInt("20769187434139310514121985316880384"), BigInt("41538374868278621028243970633760768"),
            BigInt("83076749736557242056487941267521536"), BigInt("166153499473114484112975882535043072"),
            BigInt("332306998946228968225951765070086144"), BigInt("664613997892457936451903530140172288"),
            BigInt("1329227995784915872903807060280344576"), BigInt("2658455991569831745807614120560689152"),
            BigInt("5316911983139663491615228241121378304"), BigInt("10633823966279326983230456482242756608"),
            BigInt("21267647932558653966460912964485513216"), BigInt("42535295865117307932921825928971026432"),
            BigInt("85070591730234615865843651857942052864"), BigInt("170141183460469231731687303715884105728"),
            BigInt("340282366920938463463374607431768211456")
            ]
        // v4
        for (i,expected) in zip(0..<expectedV4.count, expectedV4) {
            let cidr = CIDR(for: .v4, bits: i)
            XCTAssertEqual(cidr.networkCount, expected)
        }
        // v6
        for (i,expected) in zip(0..<expectedV6.count, expectedV6) {
            let cidr = CIDR(for: .v6, bits: i)
            XCTAssertEqual(cidr.networkCount, expected)
        }
    }
    func test_CIDR_hostCount() {
        let expectedV4:[BigInt] = [
            1, 2, 4, 8, 16, 32, 64, 128,
            256, 512, 1024, 2048, 4096, 8192, 16384, 32768,
            65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608,
            16777216, 33554432, 67108864, 134217728, 268435456, 536870912, 1073741824, 2147483648,
            4294967296
        ]
        let expectedV6:[BigInt] = [
            BigInt("1"), BigInt("2"), BigInt("4"), BigInt("8"), BigInt("16"), BigInt("32"), BigInt("64"), BigInt("128"),
            BigInt("256"), BigInt("512"), BigInt("1024"), BigInt("2048"), BigInt("4096"), BigInt("8192"), BigInt("16384"), BigInt("32768"),
            BigInt("65536"), BigInt("131072"), BigInt("262144"), BigInt("524288"),
            BigInt("1048576"), BigInt("2097152"), BigInt("4194304"), BigInt("8388608"),
            BigInt("16777216"), BigInt("33554432"), BigInt("67108864"), BigInt("134217728"),
            BigInt("268435456"), BigInt("536870912"), BigInt("1073741824"), BigInt("2147483648"),
            BigInt("4294967296"), BigInt("8589934592"), BigInt("17179869184"), BigInt("34359738368"),
            BigInt("68719476736"), BigInt("137438953472"), BigInt("274877906944"), BigInt("549755813888"),
            BigInt("1099511627776"), BigInt("2199023255552"), BigInt("4398046511104"), BigInt("8796093022208"),
            BigInt("17592186044416"), BigInt("35184372088832"), BigInt("70368744177664"), BigInt("140737488355328"),
            BigInt("281474976710656"), BigInt("562949953421312"), BigInt("1125899906842624"), BigInt("2251799813685248"),
            BigInt("4503599627370496"), BigInt("9007199254740992"), BigInt("18014398509481984"), BigInt("36028797018963968"),
            BigInt("72057594037927936"), BigInt("144115188075855872"), BigInt("288230376151711744"), BigInt("576460752303423488"),
            BigInt("1152921504606846976"), BigInt("2305843009213693952"), BigInt("4611686018427387904"), BigInt("9223372036854775808"),
            BigInt("18446744073709551616"), BigInt("36893488147419103232"), BigInt("73786976294838206464"), BigInt("147573952589676412928"),
            BigInt("295147905179352825856"), BigInt("590295810358705651712"), BigInt("1180591620717411303424"), BigInt("2361183241434822606848"),
            BigInt("4722366482869645213696"), BigInt("9444732965739290427392"),
            BigInt("18889465931478580854784"), BigInt("37778931862957161709568"),
            BigInt("75557863725914323419136"), BigInt("151115727451828646838272"),
            BigInt("302231454903657293676544"), BigInt("604462909807314587353088"),
            BigInt("1208925819614629174706176"), BigInt("2417851639229258349412352"),
            BigInt("4835703278458516698824704"), BigInt("9671406556917033397649408"),
            BigInt("19342813113834066795298816"), BigInt("38685626227668133590597632"),
            BigInt("77371252455336267181195264"), BigInt("154742504910672534362390528"),
            BigInt("309485009821345068724781056"), BigInt("618970019642690137449562112"),
            BigInt("1237940039285380274899124224"), BigInt("2475880078570760549798248448"),
            BigInt("4951760157141521099596496896"), BigInt("9903520314283042199192993792"),
            BigInt("19807040628566084398385987584"), BigInt("39614081257132168796771975168"),
            BigInt("79228162514264337593543950336"), BigInt("158456325028528675187087900672"),
            BigInt("316912650057057350374175801344"), BigInt("633825300114114700748351602688"),
            BigInt("1267650600228229401496703205376"), BigInt("2535301200456458802993406410752"),
            BigInt("5070602400912917605986812821504"), BigInt("10141204801825835211973625643008"),
            BigInt("20282409603651670423947251286016"), BigInt("40564819207303340847894502572032"),
            BigInt("81129638414606681695789005144064"), BigInt("162259276829213363391578010288128"),
            BigInt("324518553658426726783156020576256"), BigInt("649037107316853453566312041152512"),
            BigInt("1298074214633706907132624082305024"), BigInt("2596148429267413814265248164610048"),
            BigInt("5192296858534827628530496329220096"), BigInt("10384593717069655257060992658440192"),
            BigInt("20769187434139310514121985316880384"), BigInt("41538374868278621028243970633760768"),
            BigInt("83076749736557242056487941267521536"), BigInt("166153499473114484112975882535043072"),
            BigInt("332306998946228968225951765070086144"), BigInt("664613997892457936451903530140172288"),
            BigInt("1329227995784915872903807060280344576"), BigInt("2658455991569831745807614120560689152"),
            BigInt("5316911983139663491615228241121378304"), BigInt("10633823966279326983230456482242756608"),
            BigInt("21267647932558653966460912964485513216"), BigInt("42535295865117307932921825928971026432"),
            BigInt("85070591730234615865843651857942052864"), BigInt("170141183460469231731687303715884105728"),
            BigInt("340282366920938463463374607431768211456")
        ]
        // v4
        for (i,expected) in zip(stride(from: expectedV4.count - 1, through: 0, by: -1), expectedV4) {
            let cidr = CIDR(for: .v4, bits: i)
            XCTAssertEqual(cidr.hostCount, expected)
        }
        // v6
        for (i,expected) in zip(stride(from: expectedV6.count - 1, through: 0, by: -1), expectedV6) {
            let cidr = CIDR(for: .v6, bits: i)
            XCTAssertEqual(cidr.hostCount, expected)
        }
    }
    func test_CIDR_Equatable() {
        XCTAssertEqual(CIDR(for: .v4, bits: 0), CIDR(for: .v4, bits: 0))
        XCTAssertEqual(CIDR(for: .v4, bits: 32), CIDR(for: .v4, bits: 32))
        XCTAssertEqual(CIDR(for: .v6, bits: 0), CIDR(for: .v6, bits: 0))
        XCTAssertEqual(CIDR(for: .v6, bits: 128), CIDR(for: .v6, bits: 128))

        XCTAssertFalse(CIDR(for: .v4, bits: 0) == CIDR(for: .v6, bits: 0))
        XCTAssertFalse(CIDR(for: .v4, bits: 32) == CIDR(for: .v6, bits: 32))
    }
    func test_CIDR_Comparable() {
        XCTAssertFalse(CIDR(for: .v4, bits: 0) < CIDR(for: .v4, bits: 0))
        XCTAssertFalse(CIDR(for: .v4, bits: 32) < CIDR(for: .v4, bits: 32))

        XCTAssertFalse(CIDR(for: .v6, bits: 0) < CIDR(for: .v6, bits: 0))
        XCTAssertFalse(CIDR(for: .v6, bits: 32) < CIDR(for: .v6, bits: 32))

        XCTAssertFalse(CIDR(for: .v4, bits: 0) < CIDR(for: .v6, bits: 0))
        XCTAssertFalse(CIDR(for: .v4, bits: 32) < CIDR(for: .v6, bits: 32))
        XCTAssertTrue(CIDR(for: .v4, bits: 0) < CIDR(for: .v6, bits: 128))
        XCTAssertTrue(CIDR(for: .v4, bits: 32) < CIDR(for: .v6, bits: 128))

        XCTAssertTrue(CIDR(for: .v6, bits: 0) < CIDR(for: .v4, bits: 32))
        XCTAssertTrue(CIDR(for: .v6, bits: 31) < CIDR(for: .v4, bits: 32))
    }
    func test_CIDR_Hashable() {
        do {
            var dict:[CIDR:Int] = [:]
            for i in stride(from: 32, through: 0, by: -1) {
                dict[CIDR(for: .v4, bits: i)] = i
            }
            XCTAssertEqual(dict.count, 33)
            XCTAssertEqual((0...32).map({ $0 }), dict.sorted(by: { $0.value < $1.value }).map({ $0.value }))
        }
        do {
            var dict:[CIDR:Int] = [:]
            for i in stride(from: 128, through: 0, by: -1) {
                dict[CIDR(for: .v6, bits: i)] = i
            }
            XCTAssertEqual(dict.count, 129)
            XCTAssertEqual((0...128).map({ $0 }), dict.sorted(by: { $0.value < $1.value }).map({ $0.value }))
        }
    }
}

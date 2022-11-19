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
            // v4
            for (str, expected, _) in ipv4ParsingZoo {
                //print("IPAddress.init(\"\(str)\") => ", terminator: "")
                let initialized = IPAddress(str)
                if expected == nil {
                    //print(initialized as Any, initialized == nil ? "SUCCESS" : "FAILED")
                    XCTAssertNil(initialized)
                }
                else {
                    //print(initialized.debugDescription, initialized != nil ? "SUCCESS" : "FAILED")
                    XCTAssertEqual(initialized, expected)
                }
            }
        }
        do {
            // v6
            for (str, expected, _) in ipv6ParsingZoo {
                //print("IPAddress.init(\"\(str)\") => ", terminator: "")
                let initialized = IPAddress(str)
                if expected == nil {
                    //print(initialized as Any, initialized == nil ? "SUCCESS" : "FAILED")
                    XCTAssertNil(initialized)
                }
                else {
                    //print(initialized.debugDescription, initialized != nil ? "SUCCESS" : "FAILED")
                    XCTAssertEqual(initialized, expected)
                }
            }
        }

        // Non-failable
        // ipv4
        // init(_ a:UInt8, _ b:UInt8, _ c:UInt8, _ d:UInt8, cidr bits:Int = 32)
        do {
            let v4 = IPAddress(1, 2, 3, 4)
            XCTAssertEqual(v4.cidr.bits, 32)
            XCTAssertEqual(v4.type, .v4)
            XCTAssertEqual(v4.isLoopback, false)
            XCTAssertEqual(v4.rawAddressBytes, Data([1, 2, 3, 4]))
            XCTAssertEqual(v4.networkAddress, IPAddress(1, 2, 3, 4))
            XCTAssertEqual(IPAddress(0, 0, 0, 0).isLoopback, false)
            XCTAssertEqual(IPAddress(126, 255, 255, 255).isLoopback, false)
            XCTAssertEqual(IPAddress(127, 0, 0, 0).isLoopback, true)
            XCTAssertEqual(IPAddress(127, 0, 0, 1).isLoopback, true)
            XCTAssertEqual(IPAddress(127, 255, 255, 255).isLoopback, true)
            XCTAssertEqual(IPAddress(128, 0, 0, 0).isLoopback, false)
            XCTAssertEqual(IPAddress(255, 255, 255, 255).isLoopback, false)
        }
        do {
            let v6 = IPAddress(1, 2, 3, 4, 5, 6, 7, 8)
            XCTAssertEqual(v6.cidr.bits, 128)
            XCTAssertEqual(v6.type, .v6)
            XCTAssertEqual(v6.rawAddressBytes, Data([0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8]), "\(v6.rawAddressBytes.withUnsafeBytes({ Array($0) }))")
            XCTAssertEqual(v6.networkAddress, v6)
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 0).isLoopback, false)
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 1).isLoopback, true)
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 2).isLoopback, false)
            XCTAssertEqual(IPAddress(255, 255, 255, 255, 255, 255, 255, 255).isLoopback, false)
        }
    }
    func test_networkOrderedAddressBytes() {
        let v4 = IPAddress(127, 0, 0, 1)
        XCTAssertEqual(v4.networkOrderedAddressBytes, [127, 0, 0, 1])
        let v6 = IPAddress(0x201, 0, 0, 0xaa, 0xbb00, 0, 0, 0x301)
        XCTAssertEqual(v6.networkOrderedAddressBytes, [2, 1, 0, 0, 0, 0, 0, 0xaa, 0xbb, 0, 0, 0, 0, 0, 3, 1])
    }
    func test_rawAddressBytes() {
        let v4 = IPAddress(127, 0, 0, 1)
        XCTAssertEqual(v4.networkOrderedAddressBytes, [127, 0, 0, 1])
        let v6 = IPAddress(0x201, 0, 0, 0, 0, 0, 0, 1)
        XCTAssertEqual(v6.networkOrderedAddressBytes, [2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1])
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
                XCTAssertEqual(v4.networkAddress, expected, "\(i): \(String(describing: v4.networkAddress))")
                guard let na = v4.networkAddress else {
                    XCTFail()
                    return
                }
                XCTAssertEqual(na.debugDescription, expected.debugDescription)
            }
        }
        do { // v6
            let expectedNetworkAddress = [
                IPAddress(0, 0, 0, 0, 0, 0, 0, 0, cidr: 0),
                IPAddress(1, 2, 0, 0, 0, 0, 0, 0, cidr: 32),
                IPAddress(1, 2, 3, 4, 0, 0, 0, 0, cidr: 64),
                IPAddress(1, 2, 3, 4, 5, 6, 0, 0, cidr: 96),
                IPAddress(1, 2, 3, 4, 5, 6, 6, 0, cidr: 111),
                IPAddress(1, 2, 3, 4, 5, 6, 7, 0, cidr: 112),
                IPAddress(1, 2, 3, 4, 5, 6, 7, 8, cidr: 128),
            ]
            for (_,expected) in zip(0..<expectedNetworkAddress.count, expectedNetworkAddress) {
                let v6 = IPAddress(1, 2, 3, 4, 5, 6, 7, 8, cidr: expected.cidr.bits)
                XCTAssertEqual(v6.networkAddress, expected)
                XCTAssertEqual(v6.networkAddress!.debugDescription, expected.debugDescription)
            }
            XCTAssertEqual(IPAddress(0xff0a, 2, 3, 4, 5, 6, 7, 8, cidr: 65).networkAddress,
                           IPAddress(0xff0a, 2, 3, 4, 0, 0, 0, 0, cidr: 65))
            XCTAssertEqual(IPAddress(0xff0a, 2, 3, 4, 5, 6, 7, 8, cidr: 65).networkAddress,
                           IPAddress(0xff0a, 2, 3, 4, 0, 0, 0, 0, cidr: 65))
            XCTAssertEqual(IPAddress(0xff0a, 2, 3, 4, 5, 6, 7, 8, cidr: 65).networkAddress!.rawAddressBytes,
                           IPAddress(0xff0a, 2, 3, 4, 0, 0, 0, 0, cidr: 65).rawAddressBytes)
        }
    }
    func test_isLoopback() {
        do { // v4
            XCTAssertTrue(IPAddress(127, 0, 0, 0).isLoopback)
            XCTAssertTrue(IPAddress(127, 0, 0, 1).isLoopback)
            XCTAssertTrue(IPAddress(127, 255, 255, 255).isLoopback)
            XCTAssertFalse(IPAddress(128, 0, 0, 1).isLoopback)
        }
        do { // v6
            XCTAssertTrue(IPAddress(0, 0, 0, 0, 0, 0, 0, 1).isLoopback)
            XCTAssertFalse(IPAddress(0, 0, 0, 0, 0, 0, 0, 2).isLoopback)
        }
    }
    func test_isUnspecified() {
        do { // v4
            XCTAssertTrue(IPAddress(0, 0, 0, 0).isUnspecified)
            XCTAssertFalse(IPAddress(0, 0, 0, 1).isUnspecified)
        }
        do { // v6
            XCTAssertTrue(IPAddress(0, 0, 0, 0, 0, 0, 0, 0).isUnspecified)
            XCTAssertFalse(IPAddress(0, 0, 0, 0, 0, 0, 0, 1).isUnspecified)
        }
    }
    func test_isBroadcast() {
        do { // v4
            XCTAssertTrue(IPAddress(~0).isBroadcast)
            XCTAssertTrue(IPAddress(~0, cidr: 16).isBroadcast)
            XCTAssertFalse(IPAddress(0).isBroadcast)
            XCTAssertFalse(IPAddress(0, cidr: 0).isBroadcast)
        }
        do { // v6
            XCTAssertTrue(IPAddress(~0, ~0).isBroadcast)
            XCTAssertTrue(IPAddress(~0, ~0, cidr: 64).isBroadcast)
            XCTAssertFalse(IPAddress(0, 0).isBroadcast)
            XCTAssertFalse(IPAddress(0, 0, cidr: 0).isBroadcast)
        }
    }
    func test_isGlobal() {
        do { // v4
            XCTAssertTrue(IPAddress(0, 0, 0, 1, cidr: 16).isGlobal)
            XCTAssertFalse(IPAddress(0, 0, 0, 0).isGlobal)
            XCTAssertFalse(IPAddress(192, 168, 0, 0, cidr: 16).isGlobal)
            XCTAssertFalse(IPAddress(169, 254, 0, 0, cidr: 16).isGlobal)
        }
        do { // v6
            print(IPAddress(0, 2, cidr: 16).compactDebugDescription)
            XCTAssertTrue(IPAddress(1, 0, cidr: 16).isGlobal)
            XCTAssertTrue(IPAddress(0, 2, cidr: 16).isGlobal)
            XCTAssertFalse(IPAddress(0xfd00000000000000, 0).isGlobal)
            XCTAssertFalse(IPAddress(0xfe80000000000000, 0).isGlobal)
            XCTAssertFalse(IPAddress(~0, ~0).isGlobal)
            XCTAssertFalse(IPAddress(0, 0).isGlobal)
        }
    }
    func test_isPrivate() {
        do { // v4
            XCTAssertTrue(IPAddress(192, 168, 0, 0, cidr: 16).isPrivate)
            XCTAssertTrue(IPAddress(192, 168, 0, 0).isPrivate)
            XCTAssertTrue(IPAddress(192, 168, 255, 255).isPrivate)
            XCTAssertFalse(IPAddress(192, 167, 255, 255).isPrivate)
            XCTAssertFalse(IPAddress(192, 169, 0, 9).isPrivate)

            XCTAssertTrue(IPAddress(172, 168, 0, 0, cidr: 12).isPrivate)
            XCTAssertTrue(IPAddress(172, 160, 0, 0).isPrivate)
            XCTAssertTrue(IPAddress(172, 175, 0, 0).isPrivate)
            XCTAssertFalse(IPAddress(172, 159, 255, 255).isPrivate)
            XCTAssertFalse(IPAddress(172, 176, 0, 0).isPrivate)

            XCTAssertTrue(IPAddress(10, 0, 0, 0, cidr: 8).isPrivate)
            XCTAssertTrue(IPAddress(10, 0, 0, 0).isPrivate)
            XCTAssertTrue(IPAddress(10, 255, 255, 255).isPrivate)
            XCTAssertFalse(IPAddress(9, 255, 255, 255).isPrivate)
            XCTAssertFalse(IPAddress(11, 0, 0, 0).isPrivate)
        }
        do { // v6
            XCTAssertTrue (IPAddress(0xfd00000000000000, 0, cidr: 8).isPrivate)
            XCTAssertTrue (IPAddress(0xfd00000000000000, 0).isPrivate)
            XCTAssertTrue (IPAddress(0xfdffffffffffffff, 0).isPrivate)
            XCTAssertFalse(IPAddress(0xfcffffffffffffff, 0).isPrivate)
            XCTAssertFalse(IPAddress(0xfe00000000000000, 0).isPrivate)
        }
    }
    func test_isLinkLocal() {
        do { // v4
            XCTAssertTrue(IPAddress(169, 254, 0, 0, cidr: 16).isLinkLocal)
            XCTAssertTrue(IPAddress(169, 254, 255, 255).isLinkLocal)
            XCTAssertFalse(IPAddress(169, 253, 255, 255).isLinkLocal)
            XCTAssertFalse(IPAddress(169, 255, 0, 0).isLinkLocal)
        }
        do { // v6
            XCTAssertTrue (IPAddress(0xfe80000000000000, 0, cidr: 10).isLinkLocal)
            XCTAssertTrue (IPAddress(0xfe8fffffffffffff, 0xffffffffffffffff).isLinkLocal)
            XCTAssertFalse(IPAddress(0xfe7fffffffffffff, 0xffffffffffffffff).isLinkLocal)
            XCTAssertFalse(IPAddress(0xfc00000000000000, 0).isLinkLocal)
        }
    }
    func test_isMulticast() {
        do { // v4
            XCTAssertTrue(IPAddress(224, 0, 0, 0, cidr: 4).isMulticast)
            XCTAssertTrue(IPAddress(239, 255, 255, 255).isMulticast)
            XCTAssertFalse(IPAddress(223, 255, 255, 255).isMulticast)
            XCTAssertFalse(IPAddress(240, 0, 0, 0).isMulticast)
        }
        do { // v6
            XCTAssertTrue(IPAddress(0xff00000000000000, 0, cidr: 8).isMulticast)
            XCTAssertTrue(IPAddress(0xffffffffffffffff, 0xffffffffffffffff).isMulticast)
            XCTAssertFalse(IPAddress(0xfeffffffffffffff, 0).isMulticast)
        }
    }
    func test_isDocumentation() {
        do { // v4
            XCTAssertTrue(IPAddress(192, 0, 2, 0, cidr: 24).isDocumentation)
            XCTAssertTrue(IPAddress(192, 0, 2, 0, cidr: 25).isDocumentation)
            XCTAssertFalse(IPAddress(192, 0, 1, 255).isDocumentation)
            XCTAssertFalse(IPAddress(192, 0, 3, 0).isDocumentation)
            XCTAssertFalse(IPAddress(192, 0, 2, 0, cidr: 23).isDocumentation)

            XCTAssertTrue(IPAddress(198, 51, 100, 0, cidr: 24).isDocumentation)
            XCTAssertTrue(IPAddress(198, 51, 100, 0, cidr: 25).isDocumentation)
            XCTAssertFalse(IPAddress(198, 51, 99, 255).isDocumentation)
            XCTAssertFalse(IPAddress(198, 51, 101, 0).isDocumentation)
            XCTAssertFalse(IPAddress(198, 51, 100, 0, cidr: 23).isDocumentation)
            
            XCTAssertTrue(IPAddress(203, 0, 113, 0, cidr: 24).isDocumentation)
            XCTAssertTrue(IPAddress(203, 0, 113, 0, cidr: 25).isDocumentation)
            XCTAssertFalse(IPAddress(203, 0, 112, 255).isDocumentation)
            XCTAssertFalse(IPAddress(203, 0, 114, 0).isDocumentation)
            XCTAssertFalse(IPAddress(203, 0, 113, 0, cidr: 23).isDocumentation)
        }
        do { // v6
            XCTAssertTrue(IPAddress(0x20010db800000000, 0, cidr: 32).isDocumentation)
            XCTAssertTrue(IPAddress(0x20010db800000000, 0).isDocumentation)
            XCTAssertTrue(IPAddress(0x2001, 0xdb8, 0, 0, 0, 0, 0, 1).isDocumentation)
            XCTAssertTrue(IPAddress(0x2001, 0xdb8, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff).isDocumentation)
            XCTAssertFalse(IPAddress(0x20010db800000000, 0, cidr: 31).isDocumentation)
            XCTAssertFalse(IPAddress(0x2001, 0xdb7, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff).isDocumentation)
            XCTAssertFalse(IPAddress(0x2001, 0xdb9, 0, 0, 0, 0, 0, 0).isDocumentation)
            XCTAssertFalse(IPAddress(0, 0, 0, 0, 0, 0, 0, 0).isDocumentation)
            XCTAssertFalse(IPAddress(0, 0, 0, 0, 0, 0, 0, 1).isDocumentation)
        }
    }
    func test_routerAddress() {
        do { // v4
            XCTAssertEqual(IPAddress(0, 0, 0, 0, cidr: 0).routerAddress, IPAddress(0, 0, 0, 1, cidr: 0))
            XCTAssertEqual(IPAddress(0, 0, 0, 0, cidr: 22).routerAddress, IPAddress(0, 0, 0, 1, cidr: 22))
            XCTAssertEqual(IPAddress(0, 0, 0, 0, cidr: 32).routerAddress, nil)
            XCTAssertEqual(IPAddress(172, 16, 17, 10, cidr: 22).routerAddress, IPAddress(172, 16, 16, 1, cidr: 22))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 22).routerAddress, IPAddress(255, 255, 252, 1, cidr: 22))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 30).routerAddress, IPAddress(255, 255, 255, 253, cidr: 30))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 31).routerAddress, IPAddress(255, 255, 255, 255, cidr: 31))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 32).routerAddress, nil)
        }
        do { // v6
            XCTAssertEqual(IPAddress(1, 2, 3, 4, 5, 6, 7, 8, cidr: 95).routerAddress, IPAddress(1, 2, 3, 4, 5, 6, 0, 1, cidr: 95))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, 255, 255, 255, 255, cidr: 95).routerAddress, IPAddress(255, 255, 255, 255, 255, 254, 0, 1, cidr: 95))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, 255, 255, 255, 255, cidr: 128).routerAddress, nil)
            XCTAssertEqual(IPAddress(65534, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 128).routerAddress, nil)
            XCTAssertEqual(IPAddress(65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 128).routerAddress, nil)
            XCTAssertEqual(IPAddress(255, 255, 255, 255, 255, 255, 255, 255, cidr: 127).routerAddress,
                           IPAddress(255, 255, 255, 255, 255, 255, 255, 255, cidr: 127))
            XCTAssertEqual(IPAddress(65534, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 127).routerAddress,
                           IPAddress(65534, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 127))
            XCTAssertEqual(IPAddress(65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 127).routerAddress,
                           IPAddress(65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 127))
        }
    }
    func test_broadcastAddress() {
        do { // v4
            XCTAssertEqual(IPAddress(0, 0, 0, 0, cidr: 0).broadcastAddress, IPAddress(255, 255, 255, 255, cidr: 0))
            XCTAssertEqual(IPAddress(0, 0, 0, 0, cidr: 22).broadcastAddress, IPAddress(0, 0, 3, 255, cidr: 22))
            XCTAssertEqual(IPAddress(0, 0, 0, 0, cidr: 32).broadcastAddress, nil)
            XCTAssertEqual(IPAddress(172, 16, 17, 10, cidr: 22).broadcastAddress, IPAddress(172, 16, 19, 255, cidr: 22))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 22).broadcastAddress, IPAddress(255, 255, 255, 255, cidr: 22))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 30).broadcastAddress, IPAddress(255, 255, 255, 255, cidr: 30))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 31).broadcastAddress, IPAddress(255, 255, 255, 255, cidr: 31))
            XCTAssertEqual(IPAddress(255, 255, 255, 255, cidr: 32).broadcastAddress, nil)
        }
        do { // v6
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 0, cidr: 128).broadcastAddress,
                           nil)
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 0, cidr: 127).broadcastAddress,
                           IPAddress(0, 0, 0, 0, 0, 0, 0, 1, cidr: 127))
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 0, cidr: 126).broadcastAddress,
                           IPAddress(0, 0, 0, 0, 0, 0, 0, 3, cidr: 126))
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 0, cidr: 125).broadcastAddress,
                           IPAddress(0, 0, 0, 0, 0, 0, 0, 7, cidr: 125))
            XCTAssertEqual(IPAddress(0, 0, 0, 0, 0, 0, 0, 0, cidr: 119).broadcastAddress,
                           IPAddress(0, 0, 0, 0, 0, 0, 0, 511, cidr: 119))
            XCTAssertEqual(IPAddress(1, 2, 3, 4, 5, 6, 7, 8, cidr: 126).broadcastAddress,
                           IPAddress(1, 2, 3, 4, 5, 6, 7, 11, cidr: 126))
            XCTAssertEqual(IPAddress(1, 2, 3, 4, 5, 6, 7, 5, cidr: 95).broadcastAddress,
                           IPAddress(1, 2, 3, 4, 5, 7, 65535, 65535, cidr: 95))
            XCTAssertEqual(IPAddress(65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 127).broadcastAddress,
                           IPAddress(65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 127))
            XCTAssertEqual(IPAddress(65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535, cidr: 128).broadcastAddress,
                           nil)
        }
    }
    func test_hashable() {
        let v4 = IPAddress(127, 0, 0, 1)
        let v6 = IPAddress("::1")!
        
        var dict:[IPAddress:Int] = [
            v4: 0, v6: 1
        ]
        
        XCTAssertTrue(dict.count == 2)
        XCTAssertEqual(dict[v4], 0)
        XCTAssertEqual(dict[v6], 1)
        dict.updateValue(2, forKey: v4)
        XCTAssertTrue(dict.count == 2)
        XCTAssertEqual(dict[v4], 2)
    }
    func test_equatable() {
        do { // v4
            XCTAssertTrue(IPAddress(127, 0, 0, 1) == IPAddress(127, 0, 0, 1)) // both; addr & cidr are equal
            XCTAssertFalse(IPAddress(127, 0, 0, 1, cidr: 31) == IPAddress(127, 0, 0, 1)) // cidr doesn't match
            XCTAssertFalse(IPAddress(127, 0, 0, 1) == IPAddress(127, 0, 0, 1, cidr: 30)) // cidr doesn't match
            XCTAssertFalse(IPAddress(127, 0, 0, 1, cidr: 22) == IPAddress(127, 0, 0, 1, cidr: 30)) // cidr doesn't match
            XCTAssertFalse(IPAddress(0, 0, 0, 1, cidr: 30) == IPAddress(127, 0, 0, 1, cidr: 30)) // ip addr doesn't match
        }
        do { // v6
            XCTAssertTrue(IPAddress(0, 0, 0, 0, 0, 0, 0, 1) == IPAddress(0, 0, 0, 0, 0, 0, 0, 1)) // both; addr & cidr are equal
            XCTAssertFalse(IPAddress(0, 0, 0, 0, 0, 0, 0, 1, cidr: 64) == IPAddress(0, 0, 0, 0, 0, 0, 0, 1)) // cidr doesn't match
            XCTAssertFalse(IPAddress(0, 0, 0, 0, 0, 0, 0, 1) == IPAddress(0, 0, 0, 0, 0, 0, 0, 1, cidr: 32)) // cidr doesn't match
            XCTAssertFalse(IPAddress(0, 0, 0, 0, 0, 0, 0, 1, cidr: 64) == IPAddress(0, 0, 0, 0, 0, 0, 0, 1, cidr: 32)) // cidr doesn't match
            XCTAssertFalse(IPAddress(0, 0, 0, 0, 0, 0, 0, 255, cidr: 64) == IPAddress(0, 0, 0, 0, 0, 0, 0, 1, cidr: 64)) // ip addr doesn't match
        }
        do { // v4 & v6 mixed
            XCTAssertFalse(IPAddress(127, 0, 0, 1) == IPAddress(0, 0, 0, 0, 127, 0, 0, 1)) // different types
            XCTAssertFalse(IPAddress(127, 0, 0, 1) == IPAddress(127, 0, 0, 1, 0, 0, 0, 0)) // different types
            XCTAssertFalse(IPAddress(127, 0, 0, 1, cidr: 28) == IPAddress(0, 0, 0, 0, 127, 0, 0, 1)) // different types
            XCTAssertFalse(IPAddress(127, 0, 0, 1) == IPAddress(127, 0, 0, 1, 0, 0, 0, 0, cidr: 64)) // different types
        }
    }
    func test_comparable() {
        do { // v4
            let ipv4host_a = IPAddress(62, 115, 44, 0)
            let ipv4host_b = IPAddress(62, 115, 44, 164)
            let ipv4host_c = IPAddress(62, 115, 44, 1, cidr: 22)
            XCTAssertTrue(ipv4host_a < ipv4host_b)
            XCTAssertTrue(ipv4host_a < ipv4host_c)
            XCTAssertFalse(ipv4host_b < ipv4host_c)
        }
        do { // v6
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
        do { // v4 & v6 mixed
            XCTAssertFalse(IPAddress(1, 2, 3, 4) == IPAddress(1, 2, 3, 4, 0, 0, 0, 0))
        }
    }
    func test_contains() {
        do { // v4
            let ipv4host_a = IPAddress(62, 115, 44, 0)
            let ipv4host_b = IPAddress(62, 115, 44, 164)
            let ipv4host_c = IPAddress(62, 115, 44, 0, cidr: 22)

            XCTAssertTrue(ipv4host_c.contains(ipv4host_a))
            XCTAssertFalse(ipv4host_a.contains(ipv4host_b))
            XCTAssertTrue(ipv4host_c.contains(ipv4host_a))
            XCTAssertTrue(ipv4host_c.contains(ipv4host_b))
            XCTAssertFalse(ipv4host_a.contains(ipv4host_c))
            XCTAssertFalse(ipv4host_b.contains(ipv4host_c))

            let v4network = IPAddress(192, 168, 9, 224, cidr: 28)
            let v4host_below = IPAddress(192, 168, 9, 223)
            let v4host_above = IPAddress(192, 168, 9, 240)
            let v4host_inrange:ClosedRange<UInt8> = (224...239)
            
            XCTAssertFalse(v4network.contains(v4host_below))
            for d in v4host_inrange {
                let other = IPAddress(192, 168, 9, d)
                XCTAssertTrue(v4network.contains(other))
                XCTAssertTrue(IPAddress(0, 0, 0, 0, cidr: 0).contains(other))
                XCTAssertTrue(IPAddress(255, 255, 255, 255, cidr: 0).contains(other))
                XCTAssertFalse(IPAddress(255, 255, 255, 255, cidr: 30).contains(other))
                XCTAssertFalse(IPAddress(255, 255, 255, 255, cidr: 32).contains(other))
            }
            XCTAssertFalse(v4network.contains(v4host_above))
            
            let v4 = IPAddress(172, 16, 16, 0, cidr: 22)
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
            XCTAssertFalse(IPAddress(172, 16, 16, 0, cidr: 22).contains(IPAddress(172, 16, 17, 1, cidr: 21)))
            XCTAssertTrue(IPAddress(172, 16, 16, 0, cidr: 22).contains(IPAddress(172, 16, 17, 1, cidr: 22)))
            XCTAssertTrue(IPAddress(172, 16, 16, 0, cidr: 22).contains(IPAddress(172, 16, 17, 1, cidr: 23)))
        }
        do { // v6
            let v6network = IPAddress(1, 2, 3, 4, 5, 6, 7, 8, cidr: 88)
            let v6host_below = IPAddress(1, 2, 3, 4, 4, 65535, 65535, 65535)
            let v6host_above = IPAddress(1, 2, 3, 4, 5, 256, 0, 0)
            let v6host_inrange = [
                IPAddress(1, 2, 3, 4, 5, 6, 7, 8),
                IPAddress(1, 2, 3, 4, 5, 6, 7, 9),
                IPAddress(1, 2, 3, 4, 5, 255, 65535, 65535),
            ]
            
            XCTAssertFalse(v6network.contains(v6host_below))
            for other in v6host_inrange {
                let msg = [
                    "ip\(v6network.type) network \(v6network.networkAddress.debugDescription)",
                    "(range \(v6network.routerAddress?.debugDescription as Any)",
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
            
            XCTAssertFalse(IPAddress(172, 16, 16, 0, cidr: 22).contains(IPAddress(172, 16, 17, 1, cidr: 21)))
            XCTAssertTrue(IPAddress(172, 16, 16, 0, cidr: 22).contains(IPAddress(172, 16, 17, 1, cidr: 22)))
            XCTAssertTrue(IPAddress(172, 16, 16, 0, cidr: 22).contains(IPAddress(172, 16, 17, 1, cidr: 23)))

        }
        do { // v4 & v6 mixed
            XCTAssertFalse(IPAddress(127, 0, 0, 1).contains(IPAddress(127, 0, 0, 1, 0, 0, 0, 0)))
            XCTAssertFalse(IPAddress(127, 0, 0, 1, 0, 0, 0, 0).contains(IPAddress(127, 0, 0, 1)))
        }
    }
    func test_compactDescription() {

        for (str, _, expected) in ipv4ParsingZoo + ipv6ParsingZoo {
            guard let _ = IPAddress(str) else {
                XCTAssertNil(expected, "Expected init from '\(str)' to \(expected == nil ? "succeed" : "fail")")
                continue
            }
            //print("init(\(str)) => expecting \(expected == nil ? "nil" : "\(expected!)") => got \(ip.compactDescription)\n")
            XCTAssertEqual(IPAddress(str)?.compactDescription, expected)
        }
    }
    func test_iterator() {
        do { // v4
            let cidr = 30
            let expected = [
                IPAddress(192, 168, 13, 4, cidr: cidr),
                IPAddress(192, 168, 13, 5, cidr: cidr),
                IPAddress(192, 168, 13, 6, cidr: cidr),
                IPAddress(192, 168, 13, 7, cidr: cidr),
            ]
            let ip = IPAddress(192, 168, 13, 6, cidr: cidr)

            var iter = IPAddressIterator(address: ip)
            var index = 0
            while let i = iter.next() {
                XCTAssertEqual(i, expected[index])
                index += 1
            }
        }
        do { // v6
            let cidr = 126
            let expected = [
                IPAddress(0xaaaa, 0xbb, 0xcc00, 0xd00d, 0xffff, 0, 0, 0xfffc, cidr: cidr),
                IPAddress(0xaaaa, 0xbb, 0xcc00, 0xd00d, 0xffff, 0, 0, 0xfffd, cidr: cidr),
                IPAddress(0xaaaa, 0xbb, 0xcc00, 0xd00d, 0xffff, 0, 0, 0xfffe, cidr: cidr),
                IPAddress(0xaaaa, 0xbb, 0xcc00, 0xd00d, 0xffff, 0, 0, 0xffff, cidr: cidr),
            ]
            let ip = IPAddress(0xaaaa, 0xbb, 0xcc00, 0xd00d, 0xffff, 0, 0, 0xffff, cidr: cidr)
            var iter = IPAddressIterator(address: ip)
            var index = 0
            while let i = iter.next() {
                XCTAssertEqual(i, expected[index])
                index += 1
            }
        }
    }
    func test_sequence() {
        do { // v4
            let cidr = 30
            let expected = [
                IPAddress(192, 168, 13, 4, cidr: cidr),
                IPAddress(192, 168, 13, 5, cidr: cidr),
                IPAddress(192, 168, 13, 6, cidr: cidr),
                IPAddress(192, 168, 13, 7, cidr: cidr),
            ]
            let ip = IPAddress(192, 168, 13, 6, cidr: cidr)

            let seq = IPAddressSequence(address: ip)
            XCTAssertEqual(seq.underestimatedCount, 4)
            for (value,expected) in zip(seq,expected) {
                XCTAssertEqual(value, expected)
            }
        }
        do { // v6
            let cidr = 126
            let expected = [
                IPAddress("::0/\(cidr)")!,
                IPAddress("::1/\(cidr)")!,
                IPAddress("::2/\(cidr)")!,
                IPAddress("::3/\(cidr)")!,
            ]
            let ip = IPAddress("::1/\(cidr)")!
            //print(ip.debugDescription, ip.compactDebugDescription, ip.cidr.type, ip.cidr.bits, ip.cidr.hostCount, ip.cidr.networkCount)
            let seq = IPAddressSequence(address: ip)
            XCTAssertEqual(seq.underestimatedCount, 4)
            for (value,expected) in zip(seq,expected) {
                //print(value.networkOrderedAddressBytes, expected.networkOrderedAddressBytes)
                XCTAssertEqual(value, expected)
            }
        }
    }
    func test_ipv6_internal_storage() {
        let a = IPAddress([2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1])!
        let b = IPAddress(0x200, 0, 0, 0, 0, 0, 0, 1)
        let c = IPAddress("200::1")!
//        print("A",
//              a.description,
//              withUnsafeBytes(of: a.ipv6lhs, { Array($0) }),
//              withUnsafeBytes(of: a.ipv6rhs, { Array($0) }), "init(bytes:)"
//        )
        XCTAssertEqual(withUnsafeBytes(of: a.ipv6lhs, { Array($0) }), [0, 0, 0, 0, 0, 0, 0, 2])
        XCTAssertEqual(withUnsafeBytes(of: a.ipv6rhs, { Array($0) }), [1, 0, 0, 0, 0, 0, 0, 0])
//        print("B",
//              b.description,
//              withUnsafeBytes(of: b.ipv6lhs, { Array($0) }),
//              withUnsafeBytes(of: b.ipv6rhs, { Array($0) }), "init(UInt16...)"
//        )
        XCTAssertEqual(withUnsafeBytes(of: b.ipv6lhs, { Array($0) }), [0, 0, 0, 0, 0, 0, 0, 2])
        XCTAssertEqual(withUnsafeBytes(of: b.ipv6rhs, { Array($0) }), [1, 0, 0, 0, 0, 0, 0, 0])
//        print("C",
//              c.description,
//              withUnsafeBytes(of: c.ipv6lhs, { Array($0) }),
//              withUnsafeBytes(of: c.ipv6rhs, { Array($0) }), "init(String)"
//        )
        XCTAssertEqual(withUnsafeBytes(of: c.ipv6lhs, { Array($0) }), [0, 0, 0, 0, 0, 0, 0, 2])
        XCTAssertEqual(withUnsafeBytes(of: c.ipv6rhs, { Array($0) }), [1, 0, 0, 0, 0, 0, 0, 0])
    }
    func test_bige() {
        let v6 = IPAddress(1, 2, 3, 4)
        let v6cd = v6.description
        print(v6cd)
        XCTAssertEqual(v6cd, "1.2.3.4")
    }
    /* Now for-in loops would be fun but Strideable protocol's distance(to other:) -> Int
       makes it challenging for ipv6 addresses as ipv6 can have distances way beyond
       the Int's capabilities.
     
    func test_strideable() {
        do { // v4
            let cidr = 30
            let expected = [
                IPAddress(192, 168, 13, 4, cidr: cidr)!,
                IPAddress(192, 168, 13, 5, cidr: cidr)!,
                IPAddress(192, 168, 13, 6, cidr: cidr)!,
                IPAddress(192, 168, 13, 7, cidr: cidr)!,
            ]
            let ip = IPAddress(192, 168, 13, 6, cidr: cidr)!

            let distance = expected.first!.distance(to: expected.last!)
            XCTAssertEqual(distance, 3)
            for (value,expected) in zip(stride(from: ip.networkAddress!, through: ip.broadcastAddress!, by: 1), expected) {
                XCTAssertEqual(value, expected)
            }
        }
        do { // v4
            let cidr = 27
            let expected = [
                IPAddress(192, 168, 13, 6, cidr: cidr)!,
                IPAddress(192, 168, 13, 2, cidr: cidr)!,
            ]
            let ip = IPAddress(192, 168, 13, 6, cidr: cidr)!
            
            let distance = ip.distance(to: ip.networkAddress!)
            XCTAssertEqual(distance, -6)
            for (value,expected) in zip(stride(from: ip, through: ip.networkAddress!, by: -4), expected) {
                XCTAssertEqual(value, expected)
            }
        }
    }
     */
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
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
internal extension IPAddress {
    static var random:IPAddress {
        Bool.random() ?
        IPAddress(UInt32.random(in: 0...UInt32.max))
        :
        IPAddress(UInt64.random(in: 0...UInt64.max), UInt64.random(in: 0...UInt64.max))
    }
    static var randomIpv4Address:IPAddress {
        IPAddress(UInt32.random(in: 0...UInt32.max))
    }
    static var randomIpv6Address:IPAddress {
        IPAddress(UInt64.random(in: 0...UInt64.max), UInt64.random(in: 0...UInt64.max))
    }
}
final class PerformanceTests : XCTestCase {
    private func fmttr(_ value:Double, _ postfix:String = "") -> String {
        let e = Int(log10(value))
        let fmtstr:String
        if e < 0 {
            fmtstr = "%-.\(-e+2)f"
            return String(format: fmtstr, value) + postfix
        }
        else {
            fmtstr = "%-.0f"
            let str = String(format: fmtstr, value)
            let thousandSeparated = str
                .reversed()
                .map({$0})
                .chunked(into: 3)
                .reversed()
                .map({ $0.reversed().reduce("", {$0 + "\($1)" }) })
                .joined(separator: " ")
            return thousandSeparated + postfix
        }
    }
    private func ms(_ ns:Double) -> String {
        let value = ns / 1_000_000.0
        return fmttr(value, " ms")
    }
    private func µs(_ ns:Double) -> String {
        let value = ns / 1_000.0
        return fmttr(value, " µs")
    }
    private func rate(_ ns:Double, iterations:UInt64) -> String {
        let foo = Double(iterations) / (ns / 1_000_000_000)
        return fmttr(foo, " invocations/second")
    }
    func perf_ipv4_init_from_uint32(iterations:Int) -> (Double,UInt64) {
        var tarr:[Double] = []
        let count = UInt(UInt16.max)
        for i in 1...iterations {
            var t:UInt64 = 0
            for i in UInt32(0)..<UInt32(UInt16.max) {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = IPAddress(i)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("\(i): \(count) invocations in", self.µs(Double(t)))
        }
        return (tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), UInt64(count))
    }
    func perf_ipv4_init_from_bytes(iterations:Int) -> (Double,UInt64) {
        var tarr:[Double] = []
        let count = UInt(UInt16.max)
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in UInt32(0)..<UInt32(UInt16.max) {
                let byteArray = Array(repeating: UInt8.random(in: 0...255), count: 4)
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = IPAddress(byteArray)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("\(i): \(count) invocations in", self.µs(Double(t)))
        }
        return (tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), UInt64(count))
    }
    func perf_ipv6_init_from_bytes(iterations:Int) -> (Double,UInt64) {
        var tarr:[Double] = []
        let count = UInt(UInt16.max)
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in UInt32(0)..<UInt32(UInt16.max) {
                let byteArray = Array(repeating: UInt8.random(in: 0...255), count: 16)
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = IPAddress(byteArray)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("\(i): \(count) invocations in", self.µs(Double(t)))
        }
        return (tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), UInt64(count))
    }
    func perf_ipv6_init_from_abcdefgh(iterations:Int) -> (Double,UInt64) {
        var tarr:[Double] = []
        let count = UInt(UInt16.max)
        for i in 1...iterations {
            var t:UInt64 = 0
            for i in UInt16(0)..<UInt16.max {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = IPAddress(0, 0, 0, 0, 0, 0, 0, i)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("\(i): \(count) invocations in", self.µs(Double(t)))
        }
        return (tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), UInt64(count))
    }
    func perf_ipv4_contains(iterations:Int) -> (Double,UInt64) {
        let a = IPAddress(127, 0, 0, 1)
        let b = IPAddress(127, 0, 0, 1, cidr: 8)
        let c = IPAddress(192, 168, 0, 1, cidr: 20)
        let d = IPAddress(192, 168, 2, 1)
        var tarr:[Double] = []
        let count = UInt(UInt16.max) * 4
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in UInt16(0)..<UInt16.max {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = a.contains(a) // true
                let _ = a.contains(b) // false
                let _ = c.contains(d) // true
                let _ = d.contains(b) // false
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("\(i): \(count) invocations in", self.µs(Double(t)))
        }
        return (tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), UInt64(count))
    }
    func perf_ipv6_contains(iterations:Int) -> (Double,UInt64) {
        let a = IPAddress(0, 0, 0, 0, 0, 0, 0, 1)
        let b = IPAddress(0, 0, 0, 0, 0, 0, 0, 255, cidr: 64)
        let c = IPAddress(0xffff, 0, 0, 0, 0, 0, 0, 255, cidr: 64)
        let d = IPAddress(0xffff, 0, 0, 0, 0, 0xaaaa, 0, 255, cidr: 72)
        var tarr:[Double] = []
        let count = UInt(UInt16.max) * 4
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in UInt16(0)..<UInt16.max {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = a.contains(a) // true
                let _ = a.contains(b) // false
                let _ = c.contains(d) // true
                let _ = d.contains(b) // false
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("\(i): \(count) invocations in", self.µs(Double(t)))
        }
        return (tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), UInt64(count))
    }
    func perf_init_from_string(iterations:Int) -> (Double,UInt64) {
        //print("Generating test strings...", terminator: "")
        var a:[String] = []
        var i:UInt16 = 0
        while i < UInt16.max {
            for (str, _, _) in (ipv4ParsingZoo + ipv6ParsingZoo) {
                guard i < UInt16.max else { break }
                a.append(str)
                i += 1
            }
        }
        //print("done")
        var tarr:[Double] = []
        let count = UInt(a.count)
        for i in 1...iterations {
            var t:UInt64 = 0
            for str in a {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = IPAddress(str)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("\(i): \(count) invocations in", self.µs(Double(t)))
        }
        return (tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), UInt64(count))
    }
    func perf_ipv4_iterator(iterations:Int) -> (Double,UInt64) {
        var tarr:[Double] = []
        let ip = IPAddress(0, cidr: 10)
        let count = UInt64(ip.cidr.hostCount)
        for i in 1...iterations {
            var iterator = IPAddressIterator(address: ip)
            let t0 = DispatchTime.now().uptimeNanoseconds
            while let _ = iterator.next() {}
            let t1 = DispatchTime.now().uptimeNanoseconds
            tarr.append(Double(t1 - t0))
            print("\(i): \(count) invocations in", self.µs(Double(t1-t0)))
        }
        return (tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv6_iterator(iterations:Int) -> (Double,UInt64) {
        var tarr:[Double] = []
        let ip = IPAddress(0, 0, 0, 0, 0, 0, 0, 0, cidr: 105)
        let count = UInt64(ip.cidr.hostCount)
        for i in 1...iterations {
            var iterator = IPAddressIterator(address: ip)
            let t0 = DispatchTime.now().uptimeNanoseconds
            while let _ = iterator.next() {}
            let t1 = DispatchTime.now().uptimeNanoseconds
            print("\(i): \(count) invocations in", self.µs(Double(t1-t0)))
            tarr.append(Double(t1 - t0))
        }
        return (tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv4_description(iterations:Int) -> (Double,UInt64) {
        var tarr:[Double] = []
        let count = UInt64(UInt16.max)
        for i in 1...iterations {
            let ip = IPAddress(1, 2, 3, 4)
            var t:UInt64 = 0
            for _ in UInt16(0)..<UInt16.max {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = ip.description
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            print("\(i): \(count) invocations in", self.µs(Double(t)))
            tarr.append(Double(t))
        }
        return (tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv6_description(iterations:Int) -> (Double,UInt64) {
        var tarr:[Double] = []
        let count = UInt64(UInt16.max)
        for i in 1...iterations {
            let ip = IPAddress(1, 2, 3, 4, 5, 6, 7, 8)
            var t:UInt64 = 0
            for _ in UInt16(0)..<UInt16.max {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = ip.description
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            print("\(i): \(count) invocations in", self.µs(Double(t)))
            tarr.append(Double(t))
        }
        return (tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv6_compactDescription(iterations:Int) -> (Double,UInt64) {
        var tarr:[Double] = []
        let count = UInt64(UInt16.max)
        for i in 1...iterations {
            let a = IPAddress(1, 2, 3, 4, 5, 6, 7, 8)
            let b = IPAddress(1, 2, 3, 0, 0, 6, 7, 8)
            let c = IPAddress(1, 2, 3, 0, 0, 0, 7, 8)
            let d = IPAddress(1, 0, 0, 4, 0, 0, 7, 8)
            let e = IPAddress(1, 0, 0, 4, 0, 0, 0, 8)
            var t:UInt64 = 0
            for _ in UInt16(0)..<UInt16.max {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = a.description
                let _ = b.description
                let _ = c.description
                let _ = d.description
                let _ = e.description
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            print("\(i): \(count) invocations in", self.µs(Double(t)))
            tarr.append(Double(t))
        }
        return (tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func hwspec() -> String {
        // system_profiler SPSoftwareDataType SPHardwareDataType
        var elements:[String] = []
        let info = ProcessInfo.processInfo
        elements.append("Operating system \(info.operatingSystemVersionString)")
        #if os(Linux)
        elements.append("\(fmttr(Double(info.physicalMemory), " bytes of memory"))")
        #elseif os(macOS)
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0,  count: size)
        sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
        elements.append(String(cString: machine))
        elements.append("\(info.processorCount) processors")
        var measurement = Measurement(value: Double(info.physicalMemory), unit: UnitInformationStorage.bytes)
        measurement.convert(to: UnitInformationStorage.gibibytes)
        elements.append("\(measurement.description) of memory")
        #endif
        return elements.joined(separator: ", ")
    }
    func runit(name:String, _ f: (Int)->(Double,UInt64)) {
        print("##", name)
        print("### \(hwspec())")
        #if DEBUG
        print("### Build: Debug")
        #else
        print("### Build: Release")
        #endif
        print("```")
        let (avg, count) = f(3)
        print("==============================================")
        print("Average:", rate(avg, iterations: count))
        print("```")
    }
        // system_profiler SPSoftwareDataType SPHardwareDataType
    func test_run_all_perf_tests() {
        runit(name: "IPAddress .init(uint32:) performance (ipv4)", perf_ipv4_init_from_uint32(iterations:))
        runit(name: "IPAddress .init(abcdefgh:) performance (ipv6)", perf_ipv6_init_from_abcdefgh(iterations:))
        runit(name: "IPAddress .init(bytes:) performance (ipv4)", perf_ipv4_init_from_bytes(iterations:))
        runit(name: "IPAddress .init(bytes:) performance (ipv6)", perf_ipv6_init_from_bytes(iterations:))
        runit(name: "IPAddress .init(string:) performance (ipv4 & ipv6)", perf_init_from_string(iterations:))
        runit(name: "IPAddress .contains(other:) performance (ipv4)", perf_ipv4_contains(iterations:))
        runit(name: "IPAddress .contains(other:) performance (ipv6)", perf_ipv6_contains(iterations:))
        runit(name: "IPAddressIterator .next() performance (ipv4)", perf_ipv4_iterator(iterations:))
        runit(name: "IPAddressIterator .next() performance (ipv6)", perf_ipv6_iterator(iterations:))
        runit(name: "IPAddress .description performance (ipv4)", perf_ipv4_description(iterations:))
        runit(name: "IPAddress .description performance (ipv6)", perf_ipv6_description(iterations:))
        runit(name: "IPAddress .compactDescription performance (ipv6)", perf_ipv6_compactDescription(iterations:))
    }
}
let ipv4ParsingZoo:[(in:String, value:IPAddress?, out:String?)] = [
    ("192.168.5.4/32", IPAddress(192, 168, 5,4, cidr: 32), "192.168.5.4"),
    ("192.168.5.4/18", IPAddress(192, 168, 5,4, cidr: 18), "192.168.5.4"),
    ("192.168.5.4/0", IPAddress(192, 168, 5,4, cidr: 0), "192.168.5.4"),
    ("255.255.255.255/32", IPAddress(255, 255, 255,255, cidr: 32), "255.255.255.255"),
//    ("192.168.5.4/33", nil, nil), // invalid cidr
//    ("192.168.5.4/-5", nil, nil), // invalid cidr
    ("192.168.5.4/a", nil, nil), // invalid cidr
    ("192.168.5.4/", nil, nil), // missing cidr
    ("192.168.5./18", nil, nil), // invalid quartet
    ("192.168..4/18", nil, nil), // invalid quartet
    ("192..5.4/18", nil, nil), // invalid quartet
    (".168.5.4/18", nil, nil), // invalid quartet
    ("...5.4/18", nil, nil), // invalid quartet
    ("", nil, nil), // not v4 nor v6
    ("a", nil, nil), // not v4 nor v6
    ("192.-168.5.4/18", nil, nil), // invalid element
    ("192.168.5.256/18", nil, nil), // invalid element
]
let ipv6ParsingZoo:[(in:String,value:IPAddress?,out:String?)] = [
    ("1:2:3:4:5:6:7:8/18", IPAddress(1, 2, 3, 4, 5, 6, 7, 8, cidr: 18), "1:2:3:4:5:6:7:8"),
    ("1:2:3:4:5:6:7:dead/18", IPAddress(1, 2, 3, 4, 5, 6, 7, 57005, cidr: 18), "1:2:3:4:5:6:7:dead"),
    ("::1/128", IPAddress(0, 0, 0, 0, 0, 0, 0, 1, cidr: 128), "::1"),
    ("1::", IPAddress(1, 0, 0, 0, 0, 0, 0, 0), "1::"),
    ("dead::beef:1/64", IPAddress(57005, 0, 0, 0, 0, 0, 48879, 1, cidr: 64), "dead::beef:1"),
    ("ffff:/64", IPAddress(65535, 0, 0, 0, 0, 0, 0, 0, cidr: 64), "ffff::"),
    ("ffff::/64", IPAddress(65535, 0, 0, 0, 0, 0, 0, 0, cidr: 64), "ffff::"),
    ("ffff::ff/64", IPAddress(65535, 0, 0, 0, 0, 0, 0, 255, cidr: 64), "ffff::ff"),
    ("f0f0::f1f1", IPAddress(0xf0f0, 0, 0, 0, 0, 0, 0, 0xf1f1), "f0f0::f1f1"),
    ("a:b:c:d:e:f:0:1", IPAddress(10, 11, 12, 13, 14, 15, 0, 1), "a:b:c:d:e:f::1"),
    ("a:b:c::d:e:f:0:1", nil, nil), // extra element
    ("dead:beef:1/128", nil, nil), // ambiguous, is this from head or tail?
    ("ffff0:/64", nil, nil), // This should fail
    ("ffff0::/64", nil, nil), // This should fail
    ("ffff0::ff/64", nil, nil), // This should fail
    ("dead:beef:::ff/96", nil, nil), // This should fail because of :::
    ("1:::", nil, nil), // :::
    ("[8.8.8.8]", nil, nil), // []
    ("ax", nil, nil), // invalid char
    ("a:x", nil, nil), // invalid char
    ("x", nil, nil), // invalid char
    ("n", nil, nil), // invalid char
    ("", nil, nil),  // empty
    ("::", IPAddress(0, 0, 0, 0, 0, 0, 0, 0), "::"),
    (":c:", nil, nil), // ambiguous
    ("0000:0000:0000:0000:0000:0000:0000:00000", nil, nil), // 00000 is too long
    (":n:n:n:n:n:n:", nil, nil), // non-hex
    ("::n:a:n:n:n:", nil, nil), // non-hex
    ("ffff:ffff:ffff0:ffff:ffff:", nil, nil), // overflow element
    ("ffff", nil, nil), // This should fail as we dont know if the intention is ::ffff or ffff::
    ("ffff:", IPAddress(65535, 0, 0, 0, 0, 0, 0, 0), "ffff::"), // intention is present
    ("ffff:n", nil, nil), // This should fail because of n
    ("ffff::", IPAddress(65535, 0, 0, 0, 0, 0, 0, 0), "ffff::"),
    ("ffff:::", nil, nil), // :::
    (":ffff", IPAddress(0, 0, 0, 0, 0, 0, 0, 65535), "::ffff"), // intention is present
    ("::fffe", IPAddress(0, 0, 0, 0, 0, 0, 0, 65534), "::fffe"),
    (":::ffff", nil, nil), // :::
    (":2:3:4:5:6:7:", IPAddress(0, 2, 3, 4, 5, 6, 7, 0), "::2:3:4:5:6:7:0"), // intention is present
    (":2::4:5:6:7:", nil, nil), // :: should be first, not in the middle
    ("ff0:f00::aaaa:bbbb", IPAddress(0xff0, 0xf00, 0, 0, 0, 0, 0xaaaa, 0xbbbb), "ff0:f00::aaaa:bbbb"),
    ("0:1:2:3:4:5:6:7:8", nil, nil), // Too many elements
    (":1:2:3:4:5:6:7:8", nil, nil), // Too many elements
    ("1:2:3:4:5:6:7:8:9", nil, nil), // Too many elements
    ("1:2:3:4:5:6:7:8:", nil, nil), // Too many elements
    ("2002:0db8::0001:0000", IPAddress(8194, 3512, 0, 0, 0, 0, 1, 0), "2002:db8::1:0"),
    ("2001:db8::1:0:0:1/19", IPAddress(8193, 3512, 0, 0, 1, 0, 0, 1, cidr: 19), "2001:db8::1:0:0:1"),
    ("2001:db8:0000:1:1:1:1:1", IPAddress(8193, 3512, 0, 1, 1, 1, 1, 1), "2001:db8::1:1:1:1:1"),
    ("a::b", IPAddress(10, 0, 0, 0, 0, 0, 0, 11), "a::b"),
    ("a::c::b", nil, nil), // 2 x :: not allowed
    ("0:1:A:B:C:D:E:F", IPAddress(0, 1, 10, 11, 12, 13, 14, 15), "::1:a:b:c:d:e:f"), // uppercase
    ("0:1:a:b:c:d:e:f", IPAddress(0, 1, 10, 11, 12, 13, 14, 15), "::1:a:b:c:d:e:f"), // lowercase
    (":", nil, nil),
    ("::", IPAddress(0, 0, 0, 0, 0, 0, 0, 0), "::"),
    (":::", nil, nil),
    ("::::", nil, nil),
    (":::::", nil, nil),
    ("::::::", nil, nil),
    (":::::::", nil, nil),
    ("::::::::", nil, nil),
    (":::::::::", nil, nil),
]

import XCTest
@testable import IPAddress
import Table

final class IPAddressTests: XCTestCase {
    func test_IPAddress_init() {
        // Failable
        // init?(_ bytes:[UInt8])
        for i in IPAddress.validV4CIDRRange {
            switch i {
            case 4, 16:
                XCTAssertNotNil(IPAddress(bytes: Array<UInt8>(repeating: 0, count: i)), "\(i)")
            default:
                XCTAssertNil(IPAddress(bytes: Array<UInt8>(repeating: 0, count: i)))
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
                    XCTAssertNil(initialized, "expected nil, got '\(initialized as Any)'")
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
                    XCTAssertNil(initialized, "expected nil from '\(str)', got '\(initialized as Any)'")
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
            XCTAssertEqual(v4.cidrBits, 32)
            XCTAssertEqual(v4.type, .v4)
            XCTAssertEqual(v4.isLoopback, false)
            XCTAssertEqual(v4.rawAddressData, Data([1, 2, 3, 4]))
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
            XCTAssertEqual(v6.cidrBits, 128)
            XCTAssertEqual(v6.type, .v6)
            XCTAssertEqual(v6.rawAddressData, Data([0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8]), "\(v6.rawAddressData.withUnsafeBytes({ Array($0) }))")
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
            for (i,expected) in zip(IPAddress.validV4CIDRRange, expectedNetworkAddress) {
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
                let v6 = IPAddress(1, 2, 3, 4, 5, 6, 7, 8, cidr: expected.cidrBits)
                XCTAssertEqual(v6.networkAddress, expected)
                XCTAssertEqual(v6.networkAddress!.debugDescription, expected.debugDescription)
            }
            XCTAssertEqual(IPAddress(0xff0a, 2, 3, 4, 5, 6, 7, 8, cidr: 65).networkAddress,
                           IPAddress(0xff0a, 2, 3, 4, 0, 0, 0, 0, cidr: 65))
            XCTAssertEqual(IPAddress(0xff0a, 2, 3, 4, 5, 6, 7, 8, cidr: 65).networkAddress,
                           IPAddress(0xff0a, 2, 3, 4, 0, 0, 0, 0, cidr: 65))
            XCTAssertEqual(IPAddress(0xff0a, 2, 3, 4, 5, 6, 7, 8, cidr: 65).networkAddress!.rawAddressData,
                           IPAddress(0xff0a, 2, 3, 4, 0, 0, 0, 0, cidr: 65).rawAddressData)
        }
    }
    func test_underestimatedHostCount() {
        do { // v4
            var expectedArray:[Int] = []
            var n = 1
            for _ in IPAddress.validV4CIDRRange {
                expectedArray.append(n)
                n = n * 2
            }
            for (i, expected) in zip(IPAddress.validV4CIDRRange, expectedArray.reversed()) {
                let ip = IPAddress(0, cidr: i)
                XCTAssertEqual(ip.underestimatedHostCount, expected)
            }
        }
        do { // v6
            var expectedArray:[Int] = []
            var n = 1
            for _ in IPAddress.validV6CIDRRange {
                expectedArray.append(n)
                let (partial,overflow) = n.multipliedReportingOverflow(by: 2)
                n = overflow ? Int.max : partial
            }
            for (i, expected) in zip(IPAddress.validV6CIDRRange, expectedArray.reversed()) {
                let ip = IPAddress(0, 0, cidr: i)
                XCTAssertEqual(ip.underestimatedHostCount, expected)
            }
            
            XCTAssertEqual(IPAddress("::1/0")!.underestimatedHostCount, Int.max)
            XCTAssertEqual(IPAddress("::1/62")!.underestimatedHostCount, Int.max)
            XCTAssertEqual(IPAddress("::1/63")!.underestimatedHostCount, Int.max)
            XCTAssertEqual(IPAddress("::1/64")!.underestimatedHostCount, Int.max)
            XCTAssertEqual(IPAddress("::1/65")!.underestimatedHostCount, Int.max)
            XCTAssertEqual(IPAddress("::1/66")!.underestimatedHostCount, 4611686018427387904)
            XCTAssertEqual(IPAddress("::1/67")!.underestimatedHostCount, 2305843009213693952)
            XCTAssertEqual(IPAddress("::1/128")!.underestimatedHostCount, 1)
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
    func test_isSingleHost() {
        do { // v4
            XCTAssertTrue(IPAddress(0).isSingleEndPoint)
            XCTAssertFalse(IPAddress(0, cidr: 31).isSingleEndPoint)
            XCTAssertFalse(IPAddress(0, cidr: 0).isSingleEndPoint)
        }
        do { // v6
            XCTAssertTrue(IPAddress(0, 0).isSingleEndPoint)
            XCTAssertFalse(IPAddress(0, 0, cidr: 127).isSingleEndPoint)
            XCTAssertFalse(IPAddress(0, 0, cidr: 0).isSingleEndPoint)
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

            XCTAssertTrue(ipv4host_c.contains(ipv4host_c))
            XCTAssertTrue(ipv4host_c.contains(ipv4host_a))
            XCTAssertFalse(ipv4host_a.contains(ipv4host_b))
            XCTAssertTrue(ipv4host_c.contains(ipv4host_a))
            XCTAssertTrue(ipv4host_c.contains(ipv4host_b))
            XCTAssertFalse(ipv4host_a.contains(ipv4host_c)) // single host can not contain a network
            XCTAssertFalse(ipv4host_b.contains(ipv4host_c)) // single host can not contain a network

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
            
            XCTAssertTrue(v6network.contains(v6network))
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
                XCTAssertNil(expected, "Expected init from '\(str)' to \(expected != nil ? "succeed" : "fail")")
                continue
            }
            XCTAssertEqual(IPAddress(str)?.compactDescription, expected)
        }
    }
    func test_iterator() {
        do { // v4

            var o1 = IPAddressIterator(network: IPAddress(255, 255, 255, 255, cidr: 31))
            XCTAssertEqual(o1.next(), IPAddress(0xfffffffe, cidr: 31))
            XCTAssertEqual(o1.next(), IPAddress(0xffffffff, cidr: 31))
            XCTAssertNil(o1.next())

            var o2 = IPAddressIterator(range: IPAddress(0, 0, 255, 255, cidr: 32)...IPAddress(0, 1, 0, 0, cidr: 32))
            XCTAssertEqual(o2.next(), IPAddress(0x0000ffff, cidr: 32))
//            XCTAssertEqual(o2.next(), IPAddress(0x0000ffff, cidr: 32))
            XCTAssertEqual(o2.next(), IPAddress(0x00010000, cidr: 32))
            XCTAssertNil(o2.next())

            var o3 = IPAddressIterator(network: IPAddress(0, 0, 255, 255, cidr: 31))
            XCTAssertEqual(o3.next(), IPAddress(0x0000fffe, cidr: 31))
            XCTAssertEqual(o3.next(), IPAddress(0x0000ffff, cidr: 31))
            XCTAssertNil(o3.next()) // clamped == true

            var o4 = IPAddressIterator(network: IPAddress(255, 255, 255, 255, cidr: 31))
            XCTAssertEqual(o4.next(), IPAddress(0xfffffffe, cidr: 31))
            XCTAssertEqual(o4.next(), IPAddress(0xffffffff, cidr: 31))
            XCTAssertNil(o4.next()) // clamped == false, but we've reached v4 end

            let cidr = 30
            let expected = [
                IPAddress(192, 168, 13, 4, cidr: cidr),
                IPAddress(192, 168, 13, 5, cidr: cidr),
                IPAddress(192, 168, 13, 6, cidr: cidr),
                IPAddress(192, 168, 13, 7, cidr: cidr),
            ]
            let ip = IPAddress(192, 168, 13, 6, cidr: cidr)

            var iter = IPAddressIterator(network: ip)
            var index = 0
            while let i = iter.next() {
                XCTAssertEqual(i, expected[index])
                index += 1
            }
        }
        do { // v6
            
            var o1 = IPAddressIterator(network: IPAddress(0xffffffffffffffff, 0xffffffffffffffff, cidr: 127))
            XCTAssertEqual(o1.next(), IPAddress(0xffffffffffffffff, 0xfffffffffffffffe, cidr: 127)) // fe
            XCTAssertEqual(o1.next(), IPAddress(0xffffffffffffffff, 0xffffffffffffffff, cidr: 127)) // ff
            XCTAssertNil(o1.next()) // nil

            var o2 = IPAddressIterator(range: IPAddress(0, 0xfffffffffffffffe, cidr: 127)...IPAddress(1, 0, cidr: 0))
            XCTAssertEqual(o2.next(), IPAddress(0, 0xfffffffffffffffe, cidr: 127)) // fe
            XCTAssertEqual(o2.next(), IPAddress(0, 0xffffffffffffffff, cidr: 127)) // ff
            XCTAssertEqual(o2.next(), IPAddress(0x1, 0x0, cidr: 127)) // clamped == false
            XCTAssertNil(o2.next()) // clamped == false

            var o3 = IPAddressIterator(network: IPAddress(0, 0xffffffffffffffff, cidr: 127))
            XCTAssertEqual(o3.next(), IPAddress(0, 0xfffffffffffffffe, cidr: 127)) // fe
            XCTAssertEqual(o3.next(), IPAddress(0, 0xffffffffffffffff, cidr: 127)) // ff
            XCTAssertNil(o3.next()) // clamped == true

            var o4 = IPAddressIterator(network: IPAddress(0xffffffffffffffff, 0xffffffffffffffff, cidr: 127))
            XCTAssertEqual(o4.next(), IPAddress(0xffffffffffffffff, 0xfffffffffffffffe, cidr: 127)) // fe
            XCTAssertEqual(o4.next(), IPAddress(0xffffffffffffffff, 0xffffffffffffffff, cidr: 127)) // ff
            XCTAssertNil(o4.next()) // clamped == false, but we've reached v6 end

            let cidr = 126
            let expected = [
                IPAddress(0xaaaa, 0xbb, 0xcc00, 0xd00d, 0xffff, 0, 0, 0xfffc, cidr: cidr),
                IPAddress(0xaaaa, 0xbb, 0xcc00, 0xd00d, 0xffff, 0, 0, 0xfffd, cidr: cidr),
                IPAddress(0xaaaa, 0xbb, 0xcc00, 0xd00d, 0xffff, 0, 0, 0xfffe, cidr: cidr),
                IPAddress(0xaaaa, 0xbb, 0xcc00, 0xd00d, 0xffff, 0, 0, 0xffff, cidr: cidr),
            ]
            let ip = IPAddress(0xaaaa, 0xbb, 0xcc00, 0xd00d, 0xffff, 0, 0, 0xffff, cidr: cidr)
            var iter = IPAddressIterator(network: ip)
            var index = 0
            while let i = iter.next() {
                XCTAssertEqual(i, expected[index])
                index += 1
            }
        }
    }
    func test_strideable() {
        do { // v4 distance(to:)
            XCTAssertEqual(IPAddress.ipv4unspecifiedAddress.distance(to: IPAddress(255, 255, 255, 255)), Int(UInt32.max))
            XCTAssertEqual(IPAddress.ipv4unspecifiedAddress.distance(to: IPAddress.ipv4localhost), 2130706433)
        }
        do { // v6 distance(to:)
            // Below: both of the following will cause crash 
            // let _ = IPAddress.ipv6localhost.distance(to: IPAddress.ipv6unspecifiedAddress)
            // let _ = IPAddress.ipv4localhost.distance(to: IPAddress.ipv6unspecifiedAddress)
        }
        do { // v4 advanced(by:)
            XCTAssertEqual(IPAddress.ipv4unspecifiedAddress.advanced(by: Int(UInt32.max)), IPAddress(255, 255, 255, 255))
            XCTAssertEqual(IPAddress.ipv4localhost.advanced(by: -Int(UInt32.max)), IPAddress.ipv4unspecifiedAddress)
            XCTAssertEqual(IPAddress.ipv4localhost.advanced(by: -5), IPAddress(126, 255, 255, 252))
        }
        do { // v6 advanced(by:)
            XCTAssertEqual(IPAddress.ipv6localhost.advanced(by: 1), IPAddress(0, 2, cidr: 128))
            XCTAssertEqual(IPAddress.ipv6localhost.advanced(by: 0), IPAddress(0, 1, cidr: 128))
            XCTAssertEqual(IPAddress.ipv6localhost.advanced(by: -1), IPAddress(0, 0, cidr: 128))
            XCTAssertEqual(IPAddress(UInt64.max, UInt64.max).advanced(by: 1), IPAddress(UInt64.max, UInt64.max))
        }
    }
    func test_sequence() {
        do { // v4
            let expected:[Int] = IPAddress.validV4CIDRRange.reversed().map({ Int(1)<<$0 })
            for (cidr,e) in zip(IPAddress.validV4CIDRRange,expected) {
                let ip = IPAddress(192, 168, 13, 7, cidr: cidr)
                let seq = IPAddressSequence(network: ip)
                //print(seq.underestimatedCount, seq.startAddress.debugDescription, seq.endAddress.debugDescription, e)
                XCTAssertEqual(seq.underestimatedCount, e)
                var iterator = seq.makeIterator()
                XCTAssertEqual(iterator.next(), ip.networkAddress)
                
                let seqr = IPAddressSequence(range: ip...IPAddress(192, 168, 14, 3, cidr: cidr))
                //print(seqr.underestimatedCount, seqr.startAddress.debugDescription, seqr.endAddress.debugDescription, e)
                XCTAssertEqual(seqr.underestimatedCount, 253)
                var iteratorr = seqr.makeIterator()
                XCTAssertEqual(iteratorr.next(), IPAddress(ip, cidr: IPAddress.validV4CIDRRange.upperBound))
            }
        }
        do {
            let cidr = 32
            let ip = IPAddress(255, 255, 254, 0, cidr: cidr)
            let seq = IPAddressSequence(range: ip...IPAddress(255,255,255,255, cidr: cidr))
            XCTAssertEqual(seq.underestimatedCount, 512)
            //print(seq.startAddress.debugDescription, "...", seq.endAddress.debugDescription)
        }
        do {
            let cidr = 128
            let ip = IPAddress(0xffff_ffff_ffff_ffff, 0, cidr: cidr)
            let seq = IPAddressSequence(range: ip...IPAddress(0xffff_ffff_ffff_ffff, 0xffff_ffff_ffff_ffff, cidr: cidr))
            XCTAssertEqual(seq.underestimatedCount, 9223372036854775807)
            //print(seq.startAddress.debugDescription, "...", seq.endAddress.debugDescription)
        }
        do {
            let cidr = 128
            let ip = IPAddress(0xffff_ffff_ffff_ffff, 0x8000_0000_0000_0002, cidr: cidr)
            let seq = IPAddressSequence(range: ip...IPAddress(0xffff_ffff_ffff_ffff, 0xffff_ffff_ffff_ffff, cidr: cidr))
            XCTAssertEqual(seq.underestimatedCount, 9223372036854775806)
            //print(seq.startAddress.debugDescription, "...", seq.endAddress.debugDescription)
        }
        do {
            let cidr = 128
            let ip = IPAddress(0xffff_ffff_0000_0000, 0x8000_0000_0000_0001, cidr: cidr)
            let seq = IPAddressSequence(range: ip...IPAddress(0xffff_ffff_ffff_ffff, 0xffff_ffff_ffff_ffff, cidr: cidr))
            XCTAssertEqual(seq.underestimatedCount, 9223372036854775807)
            //print(seq.startAddress.debugDescription, "...", seq.endAddress.debugDescription)
        }
        do {
            let expected = ["0.0.0.0/32", "0.0.0.1/32", "0.0.0.2/32", "0.0.0.3/32", "0.0.0.4/32"]
            for (i,ip) in (IPAddress.ipv4unspecifiedAddress...IPAddress.ipv4unspecifiedAddress.advanced(by: 4)).enumerated() {
                XCTAssertEqual(ip, IPAddress(expected[i]))
            }
        }
        do {
            let expected = ["2001:db8::100/128", "2001:db8::fe/128", "2001:db8::fc/128", "2001:db8::fa/128",
                            "2001:db8::f8/128", "2001:db8::f6/128", "2001:db8::f4/128", "2001:db8::f2/128",
                            "2001:db8::f0/128"]
            for (i,ip) in (stride(from: IPAddress(0x20010db800000000, 0x100), through: IPAddress(0x20010db800000000, 0xf0), by: -2)).enumerated() {
                XCTAssertEqual(ip, IPAddress(expected[i]))
            }
        }
        do { // v4
            let cidr = 30
            let expected = [
                IPAddress(192, 168, 13, 4, cidr: cidr),
                IPAddress(192, 168, 13, 5, cidr: cidr),
                IPAddress(192, 168, 13, 6, cidr: cidr),
                IPAddress(192, 168, 13, 7, cidr: cidr),
            ]
            let ip = IPAddress(192, 168, 13, 6, cidr: cidr)

            let seq = IPAddressSequence(network: ip)
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
            let seq = IPAddressSequence(network: ip)
            XCTAssertEqual(seq.underestimatedCount, 4)
            for (value,expected) in zip(seq,expected) {
                //print(value.networkOrderedAddressBytes, expected.networkOrderedAddressBytes)
                XCTAssertEqual(value, expected)
            }
        }
    }
    func test_ipv6_internal_storage() {
        let a = IPAddress(bytes: [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1])!
        let b = IPAddress(0x200, 0, 0, 0, 0, 0, 0, 1)
        let c = IPAddress("200::1")!
        XCTAssertEqual(withUnsafeBytes(of: a.ipv6lhs.littleEndian, { Array($0) }), [0, 0, 0, 0, 0, 0, 0, 2])
        XCTAssertEqual(withUnsafeBytes(of: a.ipv6rhs.littleEndian, { Array($0) }), [1, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(withUnsafeBytes(of: b.ipv6lhs.littleEndian, { Array($0) }), [0, 0, 0, 0, 0, 0, 0, 2])
        XCTAssertEqual(withUnsafeBytes(of: b.ipv6rhs.littleEndian, { Array($0) }), [1, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(withUnsafeBytes(of: c.ipv6lhs.littleEndian, { Array($0) }), [0, 0, 0, 0, 0, 0, 0, 2])
        XCTAssertEqual(withUnsafeBytes(of: c.ipv6rhs.littleEndian, { Array($0) }), [1, 0, 0, 0, 0, 0, 0, 0])
    }
    func test_advanced() {
        do { // v4
            let a = IPAddress(0)
            let b = IPAddress(0, 0, 0xff, 0xfe)
            let c = IPAddress(UInt32.max)

            XCTAssertEqual(a.advanced(by: 0), a)
            XCTAssertEqual(a.advanced(by: 1), IPAddress(0, 0, 0, 1, cidr: 32))
            XCTAssertNil(a.advanced(by: -1))

            XCTAssertEqual(b.advanced(by: 0), b)
            XCTAssertEqual(b.advanced(by: 1), IPAddress(0, 0, 0xff, 0xff, cidr: 32))
            XCTAssertEqual(b.advanced(by: 2), IPAddress(0, 1, 0, 0, cidr: 32))
            XCTAssertEqual(b.advanced(by: -1), IPAddress(0, 0, 0xff, 0xfd, cidr: 32))
            XCTAssertNil(b.advanced(by: -Int(UInt32.max)))
            XCTAssertEqual(b.advanced(by: 0x00010001), IPAddress(0, 1, 255, 255, cidr: 32))
            XCTAssertEqual(b.advanced(by: 0xffff0001), IPAddress(255, 255, 255, 255, cidr: 32))
            XCTAssertNil(b.advanced(by: 0xffff0002))

            XCTAssertEqual(c.advanced(by: 0), c)
            XCTAssertNil(c.advanced(by: 1))
            XCTAssertEqual(c.advanced(by: -1), IPAddress(0xfffffffe, cidr: 32))
            XCTAssertEqual(c.advanced(by: -Int(UInt32.max)), IPAddress(0, cidr: 32))
            XCTAssertNil(c.advanced(by: -Int(UInt32.max) - 1))
        }
        do { // v4 clamped
            let a = IPAddress(0, cidr: 30)
            let b = IPAddress(0, 0, 248, 65, cidr: 29)
            let c = IPAddress(UInt32.max, cidr: 0)
            XCTAssertEqual(a.advanced(by: 0, clamped: true), a)
            XCTAssertEqual(a.advanced(by: 1, clamped: true), IPAddress(0, 0, 0, 1, cidr: 30))
            XCTAssertEqual(a.advanced(by: 3, clamped: true), IPAddress(0, 0, 0, 3, cidr: 30))
            XCTAssertNil(a.advanced(by: 4, clamped: true))
            XCTAssertNil(a.advanced(by: -1, clamped: true))

            XCTAssertEqual(b.advanced(by: 0, clamped: true), b)
            XCTAssertEqual(b.advanced(by: 1, clamped: true), IPAddress(0, 0, 248, 66, cidr: 29))
            XCTAssertEqual(b.advanced(by: 6, clamped: true), IPAddress(0, 0, 248, 71, cidr: 29))
            XCTAssertNil(b.advanced(by: 7, clamped: true))
            XCTAssertEqual(b.advanced(by: -1, clamped: true), IPAddress(0, 0, 248, 64, cidr: 29))
            XCTAssertNil(b.advanced(by: -2, clamped: true))

            XCTAssertEqual(c.advanced(by: 0, clamped: true), c)
            XCTAssertNil(c.advanced(by: 1, clamped: true))
            XCTAssertEqual(c.advanced(by: -1, clamped: true), IPAddress(0xfffffffe, cidr: 0))
            XCTAssertEqual(c.advanced(by: -Int(UInt32.max), clamped: true), IPAddress(0, cidr: 0))
            XCTAssertNil(c.advanced(by: -Int(UInt32.max) - 1, clamped: true))
        }
        do { // v6
            let a = IPAddress("::")!
            let b = IPAddress(0, 0, 0, 0, 0xffff, 0xffff, 0xffff, 0xffff)
            let c = IPAddress(0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xfffe)
            XCTAssertEqual(a.advanced(by: 0), a)
            XCTAssertEqual(a.advanced(by: 1), IPAddress(0, 0, 0, 0, 0, 0, 0, 1, cidr: 128))
            XCTAssertEqual(a.advanced(by: Int.max), IPAddress(0, 0, 0, 0, 0x7fff, 0xffff, 0xffff, 0xffff, cidr: 128))
            XCTAssertNil(a.advanced(by: Int.min))
            XCTAssertNil(a.advanced(by: -1))

            XCTAssertEqual(b.advanced(by: 0), b)
            XCTAssertEqual(b.advanced(by: 1), IPAddress(0, 0, 0, 1, 0, 0, 0, 0, cidr: 128))
            XCTAssertEqual(b.advanced(by: 2), IPAddress(0, 0, 0, 1, 0, 0, 0, 1, cidr: 128))
            XCTAssertEqual(b.advanced(by: -1), IPAddress(0, 0, 0, 0, 0xffff, 0xffff, 0xffff, 0xfffe, cidr: 128))

            XCTAssertEqual(c.advanced(by: 0), IPAddress(0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xfffe, cidr: 128))
            XCTAssertEqual(c.advanced(by: 1), IPAddress(0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, cidr: 128))
            XCTAssertEqual(c.advanced(by: -1), IPAddress(0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xfffd, cidr: 128))
            XCTAssertNil(c.advanced(by: 2))
        }
        do { // v6 clamped
            let a = IPAddress("::/126")!
            let b = IPAddress(0, 0, 0, 0, 0xffff, 0xffff, 0xffff, 0xfffd, cidr: 125)
            let c = IPAddress(0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xfffe, cidr: 127)

            XCTAssertEqual(a.advanced(by: 0, clamped: true), a)
            XCTAssertEqual(a.advanced(by: 1, clamped: true), IPAddress(0, 0, 0, 0, 0, 0, 0, 1, cidr: 126))
            XCTAssertNil(a.advanced(by: 4, clamped: true))
            XCTAssertNil(a.advanced(by: Int.max, clamped: true))
            XCTAssertNil(a.advanced(by: Int.min, clamped: true))
            XCTAssertNil(a.advanced(by: -1, clamped: true))
            
            XCTAssertEqual(b.advanced(by: 0, clamped: true), b)
            XCTAssertEqual(b.advanced(by: 1, clamped: true), IPAddress(0, 0, 0, 0, 0xffff, 0xffff, 0xffff, 0xfffe, cidr: 125))
            XCTAssertEqual(b.advanced(by: 2, clamped: true), IPAddress(0, 0, 0, 0, 0xffff, 0xffff, 0xffff, 0xffff, cidr: 125))
            XCTAssertNil(b.advanced(by: 3, clamped: true))
            XCTAssertNil(b.advanced(by: -6, clamped: true))

            XCTAssertEqual(c.advanced(by: 0), IPAddress(0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xfffe, cidr: 127))
            XCTAssertEqual(c.advanced(by: 1), IPAddress(0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, cidr: 127))
            XCTAssertNil(c.advanced(by: -1,clamped: true))
        }
    }
    func test_string_parsing_options() {
        XCTAssertEqual(IPAddress("ABCD::")?.compactDescription, "abcd::") // default is to accept uppercase
        XCTAssertEqual(IPAddress("ABCD::", options: .ipv6Only)?.compactDescription, "abcd::") // ok
        XCTAssertEqual(IPAddress("192.168.5.4", options: .ipv4Only)?.compactDescription, "192.168.5.4") // ok

        XCTAssertNil(IPAddress("ABCD::", options: .ipv4Only))
        XCTAssertNil(IPAddress("ABCD::", options: .noUppercase))
        XCTAssertNil(IPAddress("ABCD::", options: [.ipv6Only, .noUppercase]))
        XCTAssertNil(IPAddress("192.168.5.4", options: .ipv6Only))
        XCTAssertNil(IPAddress("ABCD::", options: .ipv4Only))
        
        XCTAssertEqual(IPAddress("0123::")?.compactDescription, "123::") // default is to accept leading zeros
        XCTAssertNil(IPAddress("0123::", options: .noLeadingZeros))
        XCTAssertEqual(IPAddress("010.1.1.1")?.compactDescription, "10.1.1.1") // default is to accept leading zeros

        XCTAssertNil(IPAddress("abcd::", options: .noZeroSupression))
        XCTAssertNil(IPAddress("::abcd", options: .noZeroSupression))
        XCTAssertNil(IPAddress("beef::abcd", options: .noZeroSupression))
    }
    func test_codable_v4() {
        do { // v4
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let ip = IPAddress(192, 0, 2, 1, cidr: 22)
            let encodedData = try encoder.encode(ip)
            let decoder = JSONDecoder()
            let decodedIP = try decoder.decode(IPAddress.self, from: encodedData)
            XCTAssertEqual(ip, decodedIP)
        } catch let e {
            var str = ""
            dump(e, to: &str)
            XCTFail(str)
        }
    }
    func test_codable_v6() {
        do { // v6
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let ip = IPAddress(0x20010db800000000, 0, cidr: 48)
            let encodedData = try encoder.encode(ip)
            let decoder = JSONDecoder()
            let decodedIP = try decoder.decode(IPAddress.self, from: encodedData)
            XCTAssertEqual(ip, decodedIP)
        } catch let e {
            var str = ""
            dump(e, to: &str)
            XCTFail(str)
        }
    }
    func test_codable_v4_with_user_info_bytes() {
        do { // v4
            let encoder = JSONEncoder()
            let key = CodingUserInfoKey(rawValue: IPAddress.UserInfoKey.encodingSchema.rawValue)!
            encoder.userInfo[key] = IPAddress.EncodingSchema.bytes
            encoder.outputFormatting = .prettyPrinted
            let ip = IPAddress(192, 0, 2, 1, cidr: 22)
            let encodedData = try encoder.encode(ip)
            let decoder = JSONDecoder()
            decoder.userInfo[key] = IPAddress.EncodingSchema.bytes
            let decodedIP = try decoder.decode(IPAddress.self, from: encodedData)
            XCTAssertEqual(ip, decodedIP)
        } catch let e {
            var str = ""
            dump(e, to: &str)
            XCTFail(str)
        }
    }
    func test_codable_v6_with_user_info() {
        do { // v6
            let encoder = JSONEncoder()
            let key = CodingUserInfoKey(rawValue: IPAddress.UserInfoKey.encodingSchema.rawValue)!
            encoder.userInfo[key] = IPAddress.EncodingSchema.bytes
            encoder.outputFormatting = .prettyPrinted
            let ip = IPAddress(0x20010db800000000, 0, cidr: 48)
            let encodedData = try encoder.encode(ip)
            let decoder = JSONDecoder()
            decoder.userInfo[key] = IPAddress.EncodingSchema.bytes
            let decodedIP = try decoder.decode(IPAddress.self, from: encodedData)
            XCTAssertEqual(ip, decodedIP)
        } catch let e {
            var str = ""
            dump(e, to: &str)
            XCTFail(str)
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
    private func rate(_ ns:Double, iterations:UInt64, postfix:String? = nil) -> String {
        let foo = Double(iterations) / (ns / 1_000_000_000)
        return fmttr(foo, postfix ?? "")
    }
    // MARK: -
    func perf_ipv4_init_from_abcd(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var tarr:[Double] = []
        let range = UInt32(0)..<(UInt32(UInt16.max) * 10)
        let count = UInt64(range.count)
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in range {
                let ip = (UInt8.random(in: 0...UInt8.max), UInt8.random(in: 0...UInt8.max),
                          UInt8.random(in: 0...UInt8.max), UInt8.random(in: 0...UInt8.max),
                          Int.random(in: IPAddress.validV4CIDRRange))
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = IPAddress(ip.0, ip.1, ip.2, ip.3, cidr: ip.4)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".init(_:_:_:_:cidr:)", "ipv4", "Randomized addresses",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv4_init_from_uint32(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var tarr:[Double] = []
        let range = UInt32(0)..<(UInt32(UInt16.max) * 10)
        let count = UInt64(range.count)
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in range {
                let ip = (UInt32.random(in: 0..<UInt32.max), Int.random(in: IPAddress.validV4CIDRRange))
                let t0 = DispatchTime.now().uptimeNanoseconds
                          let _ = IPAddress(ip.0, cidr: ip.1)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".init(_:cidr:)", "ipv4", "Randomized addresses",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv6_init_from_abcdefgh(iterations:Int) -> (String,String,String,Double,UInt64) {
        print(#function)
        var tarr:[Double] = []
        let range = UInt32(0)..<(UInt32(UInt16.max) * 3)
        let count = UInt64(range.count)
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in range {
                let ip = (UInt16(1), UInt16.random(in: 0...UInt16.max), UInt16(3),
                          UInt16.random(in: 0...UInt16.max), UInt16(4), UInt16(5),
                          UInt16.random(in: 0...UInt16.max), UInt16(7),
                          Int.random(in: IPAddress.validV6CIDRRange))
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = IPAddress(ip.0, ip.1, ip.2, ip.3, ip.4, ip.5, ip.6, ip.7, cidr: ip.8)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".init(_:_:_:_:_:_:_:_:cidr:)", "ipv6", "Randomized addresses",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv4_init_from_bytes(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var tarr:[Double] = []
        let range = UInt32(0)..<(UInt32(UInt16.max) * 10)
        let count = UInt64(range.count)
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in range {
                let ip = (Array(repeating: UInt8.random(in: 0...255), count: 4), Int.random(in: IPAddress.validV4CIDRRange))
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = IPAddress(bytes: ip.0, cidr: ip.1)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".init?(bytes:cidr:)", "ipv4", "Randomized valid addresses",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv6_init_from_bytes(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var tarr:[Double] = []
        let range = UInt32(0)..<(UInt32(UInt16.max) * 4)
        let count = UInt64(range.count)
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in range {
                let ip = (Array(repeating: UInt8.random(in: 0...255), count: 16), Int.random(in: IPAddress.validV4CIDRRange))
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = IPAddress(bytes: ip.0, cidr: ip.1)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".init?(bytes:cidr:)", "ipv6", "Randomized valid addresses",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv4_init_from_data(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var tarr:[Double] = []
        let range = UInt32(0)..<(UInt32(UInt16.max) * 10)
        let count = UInt64(range.count)
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in range {
                let ip = (Data(Array(repeating: UInt8.random(in: 0...255), count: 4)),
                          Int.random(in: IPAddress.validV4CIDRRange))
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = IPAddress(data: ip.0, cidr: ip.1)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".init?(data:cidr:)", "ipv4", "Randomized valid addresses",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv6_init_from_data(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var tarr:[Double] = []
        let range = UInt32(0)..<(UInt32(UInt16.max) * 3)
        let count = UInt64(range.count)
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in range {
                let ip = (Data(Array(repeating: UInt8.random(in: 0...255), count: 16)),
                          Int.random(in: IPAddress.validV4CIDRRange))
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = IPAddress(data: ip.0, cidr: ip.1)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".init?(data:cidr:)", "ipv6", "Randomized valid addresses",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_init_from_string(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var a:[String] = []
        var i:UInt16 = 0
        while i < UInt16.max {
            for (str, _, _) in (ipv4ParsingZoo + ipv6ParsingZoo) {
                guard i < UInt16.max else { break }
                a.append(str)
                i += 1
            }
        }
        var tarr:[Double] = []
        let count = UInt64(a.count)
        for i in 1...iterations {
            var t:UInt64 = 0
            for str in a {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = IPAddress(str)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".init?(_:)", "ipv4 & ipv6", "Mix of strings resulting failure / success",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_init_from_alt_string_valid_random(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var a:[String] = []
        var zoo:[String] = []
        for _ in 0..<UInt16.max {
            var random:[String] = []
            for _ in 0..<8 {
                let randomU16 = (UInt16(0)...UInt16.max).randomElement()!
                random.append(String(randomU16, radix: 16))
            }
            zoo.append(random.joined(separator: ":") + "/" + "\(IPAddress.validV6CIDRRange.randomElement()!)")
        }
        a = zoo
        var tarr:[Double] = []
        let count = UInt64(zoo.count)
        for i in 1...iterations {
            var t:UInt64 = 0
            for str in a {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = IPAddress(str)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".init?(_:)", "ipv6", "Randomized valid addresses",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_init_from_alt_string_valid_random_ipv4(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var a:[String] = []
        var zoo:[String] = []
        for _ in 0..<UInt16.max {
            zoo.append(IPAddress((0...255).randomElement()!, (0...255).randomElement()!,
                                 (0...255).randomElement()!, (0...255).randomElement()!,
                                 cidr: IPAddress.validV4CIDRRange.randomElement()!).description)
        }
        a = zoo
        var tarr:[Double] = []
        let count = UInt64(zoo.count)
        for i in 1...iterations {
            var t:UInt64 = 0
            for str in a {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = IPAddress(str)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".init?(_:)", "ipv4", "Randomized valid addresses",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    // MARK: -
    func perf_ipv4_contains(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var tarr:[Double] = []
        var tfdict:[Bool:Int] = [:]
        let range = UInt16(0)..<(UInt16.max/10)
        let count = UInt64(range.upperBound) * 5
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in range {
                let cidr = Int.random(in: 0...IPAddress.validV4CIDRRange.upperBound)
                let a = IPAddress(UInt8.random(in: 0...UInt8.max), 2, 3, 4, cidr: cidr)
                let b = IPAddress(1, UInt8.random(in: 0...UInt8.max), 3, 4, cidr: cidr)
                let c = IPAddress(1, 2, UInt8.random(in: 0...UInt8.max), 4, cidr: cidr)
                let d = IPAddress(1, 2, 3, UInt8.random(in: 0...UInt8.max), cidr: cidr)
                let e = IPAddress(1, UInt8.random(in: 0...UInt8.max), 3, UInt8.random(in: 0...UInt8.max), cidr: cidr)
                let t0 = DispatchTime.now().uptimeNanoseconds
                let r1 = a.contains(a)
                let r2 = a.contains(b)
                let r3 = c.contains(d)
                let r4 = d.contains(b)
                let r5 = e.contains(c)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
                tfdict[r1, default: 0] = tfdict[r1, default: 0] + 1
                tfdict[r2, default: 0] = tfdict[r2, default: 0] + 1
                tfdict[r3, default: 0] = tfdict[r3, default: 0] + 1
                tfdict[r4, default: 0] = tfdict[r4, default: 0] + 1
                tfdict[r5, default: 0] = tfdict[r5, default: 0] + 1
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        let sum:Double = Double(tfdict[true, default: 0] + tfdict[false, default: 0])
        let shr = ((100.0 * Double(tfdict[true, default: 0])/sum).rounded(),
                   (100.0 * Double(tfdict[false, default: 0])/sum).rounded())
        let shrStr = "true \(shr.0)%, false \(shr.1)%"
        return (".contains(other:)", "ipv4", "Randomized addresses \(shrStr)",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv6_contains(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var tarr:[Double] = []
        var tfdict:[Bool:Int] = [:]
        let range = UInt16(0)..<(UInt16.max/10)
        let count = UInt64(range.upperBound) * 5
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in range {
                let cidr = Int.random(in: 0...IPAddress.validV6CIDRRange.upperBound)
                let a = IPAddress(1, 2, UInt16.random(in: 0...UInt16.max), 4, 5, 6, 7, 8, cidr: cidr)
                let b = IPAddress(1, 2, 3, UInt16.random(in: 0...UInt16.max), 5, 6, 7, 8, cidr: cidr)
                let c = IPAddress(1, 2, 3, 4, UInt16.random(in: 0...UInt16.max), 6, 7, 8, cidr: cidr)
                let d = IPAddress(1, 2, 3, 4, 5, UInt16.random(in: 0...UInt16.max), 7, 8, cidr: cidr)
                let e = IPAddress(1, 2, 3, 4, 5, 6, UInt16.random(in: 0...UInt16.max), 8, cidr: cidr)
                let t0 = DispatchTime.now().uptimeNanoseconds
                let r1 = a.contains(a)
                let r2 = a.contains(b)
                let r3 = c.contains(d)
                let r4 = d.contains(b)
                let r5 = e.contains(c)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
                tfdict[r1, default: 0] = tfdict[r1, default: 0] + 1
                tfdict[r2, default: 0] = tfdict[r2, default: 0] + 1
                tfdict[r3, default: 0] = tfdict[r3, default: 0] + 1
                tfdict[r4, default: 0] = tfdict[r4, default: 0] + 1
                tfdict[r5, default: 0] = tfdict[r5, default: 0] + 1
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        let sum:Double = Double(tfdict[true, default: 0] + tfdict[false, default: 0])
        let shr = ((100.0 * Double(tfdict[true, default: 0])/sum).rounded(),
                   (100.0 * Double(tfdict[false, default: 0])/sum).rounded())
        let shrStr = "true \(shr.0)%, false \(shr.1)%"
        return (".contains(other:)", "ipv6", "Randomized addresses \(shrStr)",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    // MARK: -
    func perf_ipv4_advanced(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var tarr:[Double] = []
        let range = -Int(UInt16.max)...Int(UInt16.max)
        let count:UInt64 = UInt64(range.count) * 5
        for i in 1...iterations {
            var t:UInt64 = 0
            for j in range {
                let a = IPAddress(UInt8.random(in: 0...UInt8.max), 2, 3, 4)
                let b = IPAddress(1, UInt8.random(in: 0...UInt8.max), 3, 4)
                let c = IPAddress(1, 2, UInt8.random(in: 0...UInt8.max), 4)
                let d = IPAddress(1, 2, 3, UInt8.random(in: 0...UInt8.max))
                let e = IPAddress(1, UInt8.random(in: 0...UInt8.max), 3, UInt8.random(in: 0...UInt8.max))
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = a.advanced(by: j)
                let _ = b.advanced(by: j)
                let _ = c.advanced(by: j)
                let _ = d.advanced(by: j)
                let _ = e.advanced(by: j)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".advanced(by:clamped:)", "ipv4", "Randomized addresses, not clamped",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv6_advanced(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var tarr:[Double] = []
        let range = -Int(UInt16.max)...Int(UInt16.max)
        let count:UInt64 = UInt64(range.count) * 5
        for i in 1...iterations {
            var t:UInt64 = 0
            for j in range {
                let a = IPAddress(1, 2, UInt16.random(in: 0...UInt16.max), 4, 5, 6, 7, 8)
                let b = IPAddress(1, 2, 3, UInt16.random(in: 0...UInt16.max), 5, 6, 7, 8)
                let c = IPAddress(1, 2, 3, 4, UInt16.random(in: 0...UInt16.max), 6, 7, 8)
                let d = IPAddress(1, 2, 3, 4, 5, UInt16.random(in: 0...UInt16.max), 7, 8)
                let e = IPAddress(1, 2, 3, 4, 5, 6, UInt16.random(in: 0...UInt16.max), 8)
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = a.advanced(by: j)
                let _ = b.advanced(by: j)
                let _ = c.advanced(by: j)
                let _ = d.advanced(by: j)
                let _ = e.advanced(by: j)
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".advanced(by:clamped:)", "ipv6", "Randomized addresses, not clamped",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    // MARK: -
    func perf_ipv4_iterator(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var tarr:[Double] = []
        #if DEBUG
        let cidr = 15
        #else
        let cidr = 10
        #endif
        let count = UInt64(IPAddress(UInt8.random(in: 0...UInt8.max), 2, 3, 4, cidr: cidr).underestimatedHostCount) * 5
        for i in 1...iterations {
            var a = IPAddressIterator(network: IPAddress(UInt8.random(in: 0...UInt8.max), 2, 3, 4, cidr: cidr))
            var b = IPAddressIterator(network: IPAddress(1, UInt8.random(in: 0...UInt8.max), 3, 4, cidr: cidr))
            var c = IPAddressIterator(network: IPAddress(1, 2, UInt8.random(in: 0...UInt8.max), 4, cidr: cidr))
            var d = IPAddressIterator(network: IPAddress(1, 2, 3, UInt8.random(in: 0...UInt8.max), cidr: cidr))
            var e = IPAddressIterator(network: IPAddress(1, UInt8.random(in: 0...UInt8.max), 3, UInt8.random(in: 0...UInt8.max), cidr: cidr))
            let t0 = DispatchTime.now().uptimeNanoseconds
            while let _ = a.next() {}
            while let _ = b.next() {}
            while let _ = c.next() {}
            while let _ = d.next() {}
            while let _ = e.next() {}
            let t1 = DispatchTime.now().uptimeNanoseconds
            let t = t1 - t0
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".next()", "ipv4", "Randomized addresses, clamped",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv6_iterator(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
#if DEBUG
        let cidr = 113
#else
        let cidr = 105
#endif
        var tarr:[Double] = []
        let count = UInt64(IPAddress(1, 2, UInt16.random(in: 0...UInt16.max), 4, 5, 6, 7, 8, cidr: cidr).underestimatedHostCount) * 5
        for i in 1...iterations {
            var a = IPAddressIterator(network: IPAddress(1, 2, UInt16.random(in: 0...UInt16.max), 4, 5, 6, 7, 8, cidr: cidr))
            var b = IPAddressIterator(network: IPAddress(1, 2, 3, UInt16.random(in: 0...UInt16.max), 5, 6, 7, 8, cidr: cidr))
            var c = IPAddressIterator(network: IPAddress(1, 2, 3, 4, UInt16.random(in: 0...UInt16.max), 6, 7, 8, cidr: cidr))
            var d = IPAddressIterator(network: IPAddress(1, 2, 3, 4, 5, UInt16.random(in: 0...UInt16.max), 7, 8, cidr: cidr))
            var e = IPAddressIterator(network: IPAddress(1, 2, 3, 4, 5, 6, UInt16.random(in: 0...UInt16.max), 8, cidr: cidr))
            let t0 = DispatchTime.now().uptimeNanoseconds
            while let _ = a.next() {}
            while let _ = b.next() {}
            while let _ = c.next() {}
            while let _ = d.next() {}
            while let _ = e.next() {}
            let t1 = DispatchTime.now().uptimeNanoseconds
            let t = t1 - t0
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".next()", "ipv6", "Randomized addresses, clamped",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    // MARK: -
    func perf_ipv4_description(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var tarr:[Double] = []
        let count = UInt64(UInt16.max) * 5
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in UInt16(0)..<UInt16.max {
                let a = IPAddress(UInt8.random(in: 0...UInt8.max), 2, 3, 4)
                let b = IPAddress(1, UInt8.random(in: 0...UInt8.max), 3, 4)
                let c = IPAddress(1, 2, UInt8.random(in: 0...UInt8.max), 4)
                let d = IPAddress(1, 2, 3, UInt8.random(in: 0...UInt8.max))
                let e = IPAddress(1, UInt8.random(in: 0...UInt8.max), 3, UInt8.random(in: 0...UInt8.max))
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = a.description
                let _ = b.description
                let _ = c.description
                let _ = d.description
                let _ = e.description
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".description", "ipv4", "Randomized addresses",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv6_description(iterations:Int) -> (String, String, String, Double, UInt64) {
        print(#function)
        var tarr:[Double] = []
        let count = UInt64(UInt16.max) * 5
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in UInt16(0)..<UInt16.max {
                let a = IPAddress(1, 2, UInt16.random(in: 0...UInt16.max), 4, 5, 6, 7, 8)
                let b = IPAddress(1, 2, 3, UInt16.random(in: 0...UInt16.max), 5, 6, 7, 8)
                let c = IPAddress(1, 2, 3, 4, UInt16.random(in: 0...UInt16.max), 6, 7, 8)
                let d = IPAddress(1, 2, 3, 4, 5, UInt16.random(in: 0...UInt16.max), 7, 8)
                let e = IPAddress(1, 2, 3, 4, 5, 6, UInt16.random(in: 0...UInt16.max), 8)
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = a.description
                let _ = b.description
                let _ = c.description
                let _ = d.description
                let _ = e.description
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".description", "ipv6", "Randomized addresses",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    func perf_ipv6_compactDescription(iterations:Int) -> (String,String,String,Double,UInt64) {
        print(#function)
        var tarr:[Double] = []
        let count = UInt64(UInt16.max) * 5
        for i in 1...iterations {
            var t:UInt64 = 0
            for _ in UInt16(0)..<UInt16.max {
                let a = IPAddress(1, UInt16.random(in: 0...UInt16.max), 0, 0, 5, 0, 0, 8)
                let b = IPAddress(1, 2, UInt16.random(in: 0...UInt16.max), 0, 0, 6, 7, 8)
                let c = IPAddress(1, 0, 0, UInt16.random(in: 0...UInt16.max), 0, 0, 0, 8)
                let d = IPAddress(1, 0, 0, 4, UInt16.random(in: 0...UInt16.max), 0, 7, 8)
                let e = IPAddress(1, 0, 0, 4, 0, UInt16.random(in: 0...UInt16.max), 0, 8)
                let t0 = DispatchTime.now().uptimeNanoseconds
                let _ = a.compactDescription
                let _ = b.compactDescription
                let _ = c.compactDescription
                let _ = d.compactDescription
                let _ = e.compactDescription
                let t1 = DispatchTime.now().uptimeNanoseconds
                t += (t1 - t0)
            }
            tarr.append(Double(t))
            print("    \(i): \(count) invocations in \(self.µs(Double(t)))")
        }
        return (".compactDescription", "ipv6", "Randomized addresses",
                tarr.reduce(0.0, { $0 + $1 }) / Double(iterations), count)
    }
    // MARK: -
    func hwspec() -> String {
        // system_profiler SPSoftwareDataType SPHardwareDataType
        var elements:[String] = []
        let info = ProcessInfo.processInfo
#if os(Linux)
        elements.append("\(fmttr(Double(info.physicalMemory), " bytes of memory"))")
#elseif os(macOS)
        var combined:[String] = []
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0,  count: size)
        sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
        combined.append(String(cString: machine))
        combined.append("\(info.processorCount) processors")
        var measurement = Measurement(value: Double(info.physicalMemory), unit: UnitInformationStorage.bytes)
        measurement.convert(to: UnitInformationStorage.gibibytes)
        combined.append("\(measurement.description) of memory")
        elements.append(combined.joined(separator: ", "))
        elements.append("Operating system \(info.operatingSystemVersionString)")
#endif
        return elements.joined(separator: "\n")
    }
    @discardableResult
    func runit(_ f: (Int)->(String, String, String, Double, UInt64)) -> (String, String, String, Double, UInt64) {
#if DEBUG
        f(2)
#else
        f(5)
#endif
    }
        // system_profiler SPSoftwareDataType SPHardwareDataType
    func test_run_all_perf_tests() {
        var averages:[(String, String, String, Double, UInt64)] = []
        averages.append(runit(perf_ipv4_init_from_abcd(iterations:)))
        averages.append(runit(perf_ipv4_init_from_uint32(iterations:)))
        averages.append(runit(perf_ipv6_init_from_abcdefgh(iterations:)))
        averages.append(runit(perf_ipv4_init_from_bytes(iterations:)))
        averages.append(runit(perf_ipv6_init_from_bytes(iterations:)))
        averages.append(runit(perf_ipv4_init_from_data(iterations:)))
        averages.append(runit(perf_ipv6_init_from_data(iterations:)))
        averages.append(runit(perf_init_from_string(iterations:)))
        averages.append(runit(perf_init_from_alt_string_valid_random(iterations:)))
        averages.append(runit(perf_init_from_alt_string_valid_random_ipv4(iterations:)))

        averages.append(runit(perf_ipv4_contains(iterations:)))
        averages.append(runit(perf_ipv6_contains(iterations:)))

        averages.append(runit(perf_ipv4_advanced(iterations:)))
        averages.append(runit(perf_ipv6_advanced(iterations:)))

        averages.append(runit(perf_ipv4_iterator(iterations:)))
        averages.append(runit(perf_ipv6_iterator(iterations:)))

        averages.append(runit(perf_ipv4_description(iterations:)))
        averages.append(runit(perf_ipv6_description(iterations:)))
        averages.append(runit(perf_ipv6_compactDescription(iterations:)))

        var cells:[[Txt]] = []
        let cols = [
            Col("IPAddress API", defaultAlignment: .bottomLeft),
            Col("Measured performance invocations / sec", width: 20,
                defaultAlignment: .bottomCenter),
            Col("Test data type", width: 6,
                defaultAlignment: .bottomCenter, defaultWrapping: .word),
            Col("Comment", width: 24,
                defaultAlignment: .bottomCenter, defaultWrapping: .word),
        ]
        
        averages.forEach { (api, addrType, comment, time, invCount) in
            let r = rate(time, iterations: invCount)
            cells.append([Txt(api),
                          Txt(r, alignment: .bottomRight),
                          Txt(addrType, alignment: .bottomCenter),
                          Txt(comment, alignment: .topLeft)])
        }
        let tbl = Tbl("Performance test summary for\n\(hwspec())",
                      columns: cols,
                      cells: cells)
        var out = "```\n"
        out += tbl.render(style: .roundedPadded)
        out += "```\n"
        var outfile:URL {
            var root = URL(fileURLWithPath: #file.replacingOccurrences(of: "IPAddress.swift", with: ""))
            root.appendPathComponent("../../../README.md")
            return root.standardized
        }
        do {
            let readme =
            """
            [![Tests](https://github.com/gallinapassus/IPAddress/actions/workflows/ipaddress-ci.yml/badge.svg)](https://github.com/gallinapassus/IPAddress/actions/workflows/ipaddress-ci.yml)
            
            # IPAddress
            
            A concrete type capable of encapsulating both ipv4 and ipv6 addresses.
            
            # IPAddressIterator
            
            An iterator over the elements of type `IPAddress`.
            
            # IPAddressSequence
            
            A type providing sequential, iterated access to `IPAddress` elements.
            
            # Reference performance
            
            """
            try (readme + out).write(to: outfile, atomically: true, encoding: .utf8)
        } catch let e {
            dump(e)
        }
        XCTAssertTrue(out.count > 0)
    }
}
let ipv4ParsingZoo:[(in:String, value:IPAddress?, out:String?)] = [
    ("192.168.5.4/32", IPAddress(192, 168, 5,4, cidr: 32), "192.168.5.4"),
    ("192.168.5.4/18", IPAddress(192, 168, 5,4, cidr: 18), "192.168.5.4"),
    ("192.168.5.4/0", IPAddress(192, 168, 5,4, cidr: 0), "192.168.5.4"),
    ("255.255.255.255/32", IPAddress(255, 255, 255,255, cidr: 32), "255.255.255.255"),
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
    ("1920.168.5.256/18", nil, nil), // too many digits
    ("192.168.5.", nil, nil), // missing segment
    ("192.168.5.4.", nil, nil), // too many segments
    ("192.168.5.4.3", nil, nil), // too many segments
]
let ipv6ParsingZoo:[(in:String,value:IPAddress?,out:String?)] = [
    ("0:0:0:0:0:0:0:1234", IPAddress(0, 0, 0, 0, 0, 0, 0, 4660, cidr: 128), "::1234"),
    ("1234:0:0:0:0:0:0:0", IPAddress(4660, 0, 0, 0, 0, 0, 0, 0, cidr: 128), "1234::"),
    ("12345:0:0:0:0:0:0:0", nil, nil), // too many digits, overflow
    ("1:2:3:4:5:6:7:8/18", IPAddress(1, 2, 3, 4, 5, 6, 7, 8, cidr: 18), "1:2:3:4:5:6:7:8"),
    ("1:2:3:4:5:6:7:dead/18", IPAddress(1, 2, 3, 4, 5, 6, 7, 57005, cidr: 18), "1:2:3:4:5:6:7:dead"),
    ("::1/128", IPAddress(0, 0, 0, 0, 0, 0, 0, 1, cidr: 128), "::1"),
    ("::1/129", IPAddress(0, 1), "::1"), // invalid cidr => precondition crash
    ("::A/128", IPAddress(0,10), "::a"), // relaxed parsing is default  => ok
    ("1::", IPAddress(1, 0, 0, 0, 0, 0, 0, 0), "1::"),
    ("dead::beef:1/64", IPAddress(57005, 0, 0, 0, 0, 0, 48879, 1, cidr: 64), "dead::beef:1"),
    ("ffff:/64", nil, nil), // invalid format, should have "::" at the end
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
    ("ffff:", nil, nil), // invalid format, should have "::" at the end
    ("ffff:n", nil, nil), // This should fail because of n
    ("ffff::", IPAddress(65535, 0, 0, 0, 0, 0, 0, 0), "ffff::"),
    ("ffff:::", nil, nil), // :::
    (":ffff", nil, nil), // invalid format, should have "::" at the start
    ("::fffe", IPAddress(0, 0, 0, 0, 0, 0, 0, 65534), "::fffe"),
    (":::ffff", nil, nil), // :::
    (":2:3:4:5:6:7:", nil, nil), // invalid format, "::" must be used to denote one or more "0" elements
    (":2::4:5:6:7:", nil, nil), // :: should be first, not in the middle
    ("ff0:f00::aaaa:bbbb", IPAddress(0xff0, 0xf00, 0, 0, 0, 0, 0xaaaa, 0xbbbb), "ff0:f00::aaaa:bbbb"),
    ("0:1:2:3:4:5:6:7:8", nil, nil), // Too many elements
    (":1:2:3:4:5:6:7:8", nil, nil), // Too many elements
    ("1:2:3:4:5:6:7:8:9", nil, nil), // Too many elements
    ("1:2:3:4:5:6:7:8:", nil, nil), // Too many elements
    ("2002:0db8::0001:0000", IPAddress(0x2002, 0xdb8, 0, 0, 0, 0, 1, 0), "2002:db8::1:0"), // depends on parsing options (has leading zeros)
    ("2001:db8::1:0:0:1/19", IPAddress(0x2001, 0xdb8, 0, 0, 1, 0, 0, 1, cidr: 19), "2001:db8::1:0:0:1"),
    ("2001:db8:0000:1:1:1:1:1", IPAddress(0x2001, 0xdb8, 0, 1, 1, 1, 1, 1), "2001:db8::1:1:1:1:1"), // depends on parsing options (has leading zeros)
    ("a::b", IPAddress(10, 0, 0, 0, 0, 0, 0, 11), "a::b"),
    ("a::c::b", nil, nil), // 2 x :: not allowed
    ("0:1:A:B:C:D:E:F", IPAddress(0, 1, 10, 11, 12, 13, 14, 15), "::1:a:b:c:d:e:f"), // uppercase
    ("0:1:a:b:c:d:e:f", IPAddress(0, 1, 10, 11, 12, 13, 14, 15), "::1:a:b:c:d:e:f"), // lowercase
    ("123", nil, nil), // not enough data to determine address type
    (":", nil, nil),
    (":.", nil, nil),
    (".:", nil, nil),
    ("::", IPAddress(0, 0, 0, 0, 0, 0, 0, 0), "::"),
    (":::", nil, nil),
    ("::::", nil, nil),
    (":::::", nil, nil),
    ("::::::", nil, nil),
    (":::::::", nil, nil),
    ("::::::::", nil, nil),
    (":::::::::", nil, nil),
]

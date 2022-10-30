// swift-tools-version: 5.5

import PackageDescription

let pkg = Package(
    name: "IPAddress",
    platforms: [ .macOS(.v10_15) ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "IPAddress",
            targets: ["IPAddress"]),
    ],
    dependencies: [
        /* This dependency will be included later on...
        .package(url: "https://github.com/pointfreeco/swift-parsing.git",
                 from: "0.10.0"),
         */
        .package(url: "https://github.com/attaswift/BigInt.git",
                 from: "5.3.0")
    ],
    targets: [
        .target(
            name: "IPAddress",
            dependencies: ["BigInt"]),
        .testTarget(
            name: "IPAddressTests",
            dependencies: ["IPAddress"]),
    ]
)

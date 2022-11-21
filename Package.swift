// swift-tools-version: 5.5

import PackageDescription

let pkg = Package(
    name: "IPAddress",
    platforms: [ .macOS(.v10_15) ],
    products: [
        .library(
            name: "IPAddress",
            targets: ["IPAddress"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-parsing.git",
               revision: "0.10.0"),
    ],
    targets: [
        .target(
            name: "IPAddress",
            dependencies: [.product(name: "Parsing", package: "swift-parsing")]),
        .testTarget(
            name: "IPAddressTests",
            dependencies: ["IPAddress"]),
    ]
)

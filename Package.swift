// swift-tools-version: 5.5

import PackageDescription

let pkg = Package(
    name: "IPAddress",
    products: [
        .library(
            name: "IPAddress",
            targets: ["IPAddress"]),
    ],
    targets: [
        .target(name: "IPAddress"),
        .testTarget(
            name: "IPAddressTests",
            dependencies: ["IPAddress"]),
    ]
)

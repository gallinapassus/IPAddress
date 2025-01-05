// swift-tools-version: 5.5

import PackageDescription

let pkg = Package(
    name: "IPAddress",
    products: [
        .library(
            name: "IPAddress",
            targets: ["IPAddress"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/gallinapassus/Table.git",
            from: "0.1.0"
        )
    ],
    targets: [
        .target(name: "IPAddress"),
        .testTarget(
            name: "IPAddressTests",
            dependencies: ["IPAddress", "Table"]),
    ]
)

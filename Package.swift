// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Meriq",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Meriq",
            targets: ["Meriq"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Meriq",
            resources: [
                .process("Resources")
            ]
        )
    ]
)

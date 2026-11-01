// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MetaDirCLI",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "metadir", targets: ["metadir"]),
        .library(name: "MetaDirCLIKit", targets: ["MetaDirCLIKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", exact: "6.2.2"),
    ],
    targets: [
        .target(name: "MetaDirCLIKit", dependencies: ["Yams"]),
        .executableTarget(name: "metadir", dependencies: ["MetaDirCLIKit"], path: "Sources/metadir"),
        .testTarget(name: "MetaDirCLIKitTests", dependencies: ["MetaDirCLIKit"]),
    ]
)

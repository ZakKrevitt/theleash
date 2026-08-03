// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Leash",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LeashCore", targets: ["LeashCore"]),
        .executable(name: "Leash", targets: ["LeashApp"]),
    ],
    targets: [
        .target(name: "LeashCore"),
        .executableTarget(
            name: "LeashApp",
            dependencies: ["LeashCore"]
        ),
        .testTarget(
            name: "LeashCoreTests",
            dependencies: ["LeashCore"]
        ),
    ],
    swiftLanguageModes: [.v5]
)

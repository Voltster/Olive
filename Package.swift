// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Olive",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Olive",
            targets: ["Olive"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Olive",
            dependencies: [],
            path: "Sources/Olive"
        )
    ]
)

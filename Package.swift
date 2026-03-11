// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BufferSave",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "BufferSaveCore",
            targets: ["BufferSaveCore"]
        ),
        .executable(
            name: "BufferSave",
            targets: ["BufferSave"]
        ),
    ],
    targets: [
        .target(
            name: "BufferSaveCore"
        ),
        .executableTarget(
            name: "BufferSave",
            dependencies: ["BufferSaveCore"]
        ),
        .testTarget(
            name: "BufferSaveCoreTests",
            dependencies: ["BufferSaveCore"]
        ),
        .testTarget(
            name: "BufferSaveTests",
            dependencies: ["BufferSave", "BufferSaveCore"]
        ),
    ]
)

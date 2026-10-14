// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AlloForge",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AlloForgeCore", targets: ["AlloForgeCore"]),
        .executable(name: "AlloForge", targets: ["AlloForge"])
    ],
    targets: [
        .target(name: "AlloForgeCore", path: "Sources/AlloForgeCore"),
        .executableTarget(
            name: "AlloForge",
            dependencies: ["AlloForgeCore"],
            path: "Sources/AlloForge",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "AlloForgeCoreTests",
            dependencies: ["AlloForgeCore"],
            path: "Tests/AlloForgeCoreTests"
        )
    ]
)

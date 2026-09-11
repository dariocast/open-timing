// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenTiming",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "OpenTiming",
            targets: ["OpenTiming"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "OpenTiming",
            dependencies: [],
            path: "Sources/OpenTiming",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon"),
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "OpenTimingTests",
            dependencies: ["OpenTiming"],
            path: "Tests/OpenTimingTests"
        )
    ]
)

// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PlaybackMacrosIntegration",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .executable(name: "PlaybackMacrosIntegrationClient", targets: ["PlaybackMacrosIntegrationClient"]),
    ],
    dependencies: [
        .package(path: "../avfoundation-playback-state-macro"),
        .package(path: "../avfoundation-playback-diagnostics-macro"),
        .package(path: "../playback-state-machine-macro"),
    ],
    targets: [
        .executableTarget(
            name: "PlaybackMacrosIntegrationClient",
            dependencies: [
                .product(name: "PlaybackState", package: "avfoundation-playback-state-macro"),
                .product(name: "PlaybackDiagnostics", package: "avfoundation-playback-diagnostics-macro"),
                .product(name: "PlaybackStateMachine", package: "playback-state-machine-macro"),
            ]
        ),
        .testTarget(
            name: "PlaybackMacrosIntegrationTests",
            dependencies: [
                "PlaybackMacrosIntegrationClient",
                .product(name: "PlaybackState", package: "avfoundation-playback-state-macro"),
                .product(name: "PlaybackDiagnostics", package: "avfoundation-playback-diagnostics-macro"),
                .product(name: "PlaybackStateMachine", package: "playback-state-machine-macro"),
            ]
        ),
    ]
)

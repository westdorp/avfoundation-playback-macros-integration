// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AVFoundationPlaybackMacrosIntegration",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    products: [
        .executable(name: "PlaybackStateMachineShowcase", targets: ["PlaybackStateMachineShowcase"]),
    ],
    dependencies: [
        .package(url: "https://github.com/westdorp/avfoundation-playback-state-macro.git", branch: "main"),
        .package(url: "https://github.com/westdorp/avfoundation-playback-diagnostics-macro.git", branch: "main"),
        .package(url: "https://github.com/westdorp/playback-state-machine-macro.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "PlaybackStateMachineShowcase",
            dependencies: [
                .product(name: "PlaybackStateMachine", package: "playback-state-machine-macro"),
                .product(name: "PlaybackState", package: "avfoundation-playback-state-macro"),
                .product(name: "PlaybackDiagnostics", package: "avfoundation-playback-diagnostics-macro"),
            ],
            path: "PlaybackStateMachineShowcase"
        ),
        .testTarget(
            name: "ShowcaseTests",
            dependencies: [
                "PlaybackStateMachineShowcase",
                .product(name: "PlaybackStateMachine", package: "playback-state-machine-macro"),
            ],
            path: "ShowcaseTests"
        ),
    ]
)

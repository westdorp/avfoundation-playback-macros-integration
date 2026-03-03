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
        .package(
            url: "https://github.com/westdorp/avfoundation-playback-state-macro.git",
            revision: "8040af189d52a0127368a3dce2480fac563d3480"
        ),
        .package(
            url: "https://github.com/westdorp/avfoundation-playback-diagnostics-macro.git",
            revision: "ac96198aa174720da3736013dc3c8ac5bf3bb37c"
        ),
        .package(
            url: "https://github.com/westdorp/playback-state-machine-macro.git",
            revision: "5ecab7b6860bb145ec1f41920d586b20061a7e62"
        ),
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

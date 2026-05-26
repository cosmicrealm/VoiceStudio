// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacQwenVoice",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacQwenVoice", targets: ["MacQwenVoice"]),
        .library(name: "MacQwenVoiceCore", targets: ["MacQwenVoiceCore"])
    ],
    targets: [
        .target(
            name: "MacQwenVoiceCore",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .executableTarget(
            name: "MacQwenVoice",
            dependencies: ["MacQwenVoiceCore"],
            linkerSettings: [.linkedFramework("Speech")]
        ),
        .testTarget(
            name: "MacQwenVoiceCoreTests",
            dependencies: ["MacQwenVoiceCore"]
        )
    ]
)

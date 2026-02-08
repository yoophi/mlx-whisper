// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoiceRecorder",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.15.0"),
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.1"),
    ],
    targets: [
        .executableTarget(
            name: "VoiceRecorder",
            dependencies: [
                "WhisperKit",
                "HotKey",
            ],
            path: "Sources/VoiceRecorder",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("UserNotifications"),
            ]
        ),
    ]
)

// swift-tools-version: 5.9
import PackageDescription

// Pure logic for Inkling: moods, streaks, tags, search and export.
// No UI, no SwiftData and no Foundation Models here, so `swift test` runs it on the Mac in seconds.
let package = Package(
    name: "InklingCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "InklingCore", targets: ["InklingCore"])],
    targets: [
        .target(name: "InklingCore"),
        .testTarget(name: "InklingCoreTests", dependencies: ["InklingCore"]),
    ],
    swiftLanguageVersions: [.v5]
)

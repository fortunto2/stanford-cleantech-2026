// swift-tools-version: 6.0
import PackageDescription

// CrewKit is the domain: the /api/crew contract, EPA bands, compass bearings and the
// horizon projection. No UIKit, no AVFoundation, so `swift test` runs on a Mac in a second.
let package = Package(
    name: "CrewKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "CrewKit", targets: ["CrewKit"]),
    ],
    targets: [
        .target(name: "CrewKit"),
        .testTarget(
            name: "CrewKitTests",
            dependencies: ["CrewKit"],
            resources: [.copy("Fixtures")]
        ),
    ]
)

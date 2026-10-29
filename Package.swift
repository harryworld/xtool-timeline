// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Hello",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        // An xtool project should contain exactly one library product,
        // representing the main app.
        .library(
            name: "Hello",
            targets: ["Hello"]
        ),
    ],
    targets: [
        .target(
            name: "Hello"
        ),
    ]
)

// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "JiggleBreak",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "JiggleBreak", targets: ["JiggleBreak"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "JiggleBreak",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)

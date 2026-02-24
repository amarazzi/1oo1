// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "1001Daily",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.29.3")
    ],
    targets: [
        .executableTarget(
            name: "1001Daily",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "1001Daily",
            exclude: [
                "Resources/Info.plist",
                "Resources/Assets.xcassets"
            ],
            resources: [
                .copy("Resources/Data/movies_1001.json"),
                .copy("Resources/Data/albums_1001.json")
            ],
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=targeted"])
            ]
        )
    ]
)

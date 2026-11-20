// swift-tools-version: 6.0
// SPDX-License-Identifier: Apache-2.0
import PackageDescription

let package = Package(
    name: "SwiftHTML",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6),
        .macCatalyst("13.1"), .visionOS(.v1)
    ],
    products: [.library(name: "SwiftHTML", targets: ["SwiftHTML"])],
    targets: [
        .target(
            name: "SwiftHTMLBackend",
            path: "Vendor/SwiftSoup/Sources",
            exclude: ["SwiftSoup.h"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(name: "SwiftHTML", dependencies: ["SwiftHTMLBackend"],
                resources: [.copy("Resources/ThirdPartyLicenses")],
                swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "SwiftHTMLTests", dependencies: ["SwiftHTML"],
                    swiftSettings: [.swiftLanguageMode(.v6)])
    ]
)

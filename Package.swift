// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftHTML",
    products: [.library(name: "SwiftHTML", targets: ["SwiftHTML"])],
    targets: [
        .target(
            name: "SwiftHTMLBackend",
            path: "Vendor/SwiftSoup/Sources",
            exclude: ["SwiftSoup.h"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(name: "SwiftHTML", dependencies: ["SwiftHTMLBackend"],
                swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "SwiftHTMLTests", dependencies: ["SwiftHTML"],
                    swiftSettings: [.swiftLanguageMode(.v6)])
    ]
)

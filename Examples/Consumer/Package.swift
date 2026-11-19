// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "Consumer",
    dependencies: [.package(path: "../..")],
    targets: [.executableTarget(name: "Consumer", dependencies: [
        .product(name: "SwiftHTML", package: "Swift-HTML")
    ])]
)

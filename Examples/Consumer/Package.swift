// swift-tools-version: 6.4
// SPDX-License-Identifier: Apache-2.0
import PackageDescription
let package = Package(
    name: "Consumer",
    platforms: [.macOS(.v15)],
    dependencies: [.package(name: "Swift-HTML", path: "../..")],
    targets: [.executableTarget(name: "Consumer", dependencies: [
        .product(name: "SwiftHTML", package: "Swift-HTML")
    ])]
)

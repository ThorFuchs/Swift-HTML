// swift-tools-version: 6.0
// SPDX-License-Identifier: Apache-2.0
import PackageDescription

let package = Package(
    name: "DeploymentConsumer",
    platforms: [.macOS(.v15)],
    dependencies: [.package(name: "Swift-HTML", path: "../..")],
    targets: [.executableTarget(name: "DeploymentConsumer", dependencies: [
        .product(name: "SwiftHTML", package: "Swift-HTML")
    ])]
)

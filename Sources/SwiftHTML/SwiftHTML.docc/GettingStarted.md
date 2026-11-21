# Getting started

Add SwiftHTML to a Swift package and parse your first fragment.

## Add the dependency

For the latest **published** 0.1.1 release, the package is:

```swift
.package(url: "https://github.com/ThorFuchs/Swift-HTML.git", from: "0.1.1")
```

**Once the public 0.2.0 tag has been published**, consumers requiring
structural DOM and Swift 6.4 can instead use:

```swift
.package(url: "https://github.com/ThorFuchs/Swift-HTML.git", from: "0.2.0")
```

The source in `main` is a 0.2.0 release candidate; an uncreated tag cannot
resolve through ordinary SwiftPM version selection. See the
[0.2.0 release notes](https://github.com/ThorFuchs/Swift-HTML/blob/main/Documentation/Releases/0.2.0.md).

```swift
.product(name: "SwiftHTML", package: "Swift-HTML")
```

The 0.2.0 release requires **Swift tools 6.4+** (qualified on 6.4.2).
Declared Apple minimums: macOS 15, iOS 15, tvOS 15, watchOS 9,
Mac Catalyst 15 and visionOS 1. macOS 15 Intel and Linux x86_64 have
native test/consumer proof; WASI has executed a compiled public consumer.
The Xcode 27 simulator build matrix for other Apple platforms was skipped,
so these minimums are declarations, not full 0.2.0 runtime qualification.
0.1.1 retains its earlier compiler and platform contract.
See [Qualification 0.2.0](https://github.com/ThorFuchs/Swift-HTML/blob/main/Documentation/Qualification/0.2.0.md).

## Parse and select

```swift
import SwiftHTML

let document = try HTMLDocument.parseFragment("<p>Hello <strong>Swift</strong></p>")
if let element = try document.select("strong").first {
    print(try element.text()) // Swift
}
```

``HTMLDocument/parseFragment(_:)`` parses in an HTML body context. To parse a
whole document use ``HTMLDocument/parse(_:)``. Parsing can repair malformed
HTML, and does not sanitize the input.

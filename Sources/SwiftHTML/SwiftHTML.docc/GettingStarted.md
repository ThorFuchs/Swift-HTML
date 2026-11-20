# Getting started

Add SwiftHTML to a Swift package and parse your first fragment.

## Add the dependency

Add the package to your dependencies and the library product to your target:

```swift
.package(url: "https://github.com/ThorFuchs/Swift-HTML.git", from: "0.1.1")
```

```swift
.product(name: "SwiftHTML", package: "Swift-HTML")
```

Swift tools 6.0 or newer are required. The declared Apple minimums are macOS
10.15, iOS and tvOS 13, watchOS 6, Mac Catalyst 13.1, and visionOS 1. The
package also builds on Linux. See the repository's validation document for the
actual tested platforms and runtimes.

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

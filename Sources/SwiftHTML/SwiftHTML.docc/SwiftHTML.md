# ``SwiftHTML``

Parse, query, traverse and edit HTML through a small, typed Swift API.

## Overview

SwiftHTML wraps the fixture-free, source-audited SwiftSoup 2.14.4 backend
behind document, element and **typed node** interfaces. Parse full documents
or body-context fragments, find elements using CSS selectors, traverse mixed
text/element/comment/data nodes in original parsed order with finite
**postparse traversal limits**, edit a shared DOM and serialize the result.
No browser or network runtime is required.

**SwiftHTML 0.2.0** requires Swift tools 6.4 or newer; the public wrapper uses
Swift 6 language mode. Mutable DOM references are intentionally **not
Sendable**. The compiler can run on macOS 15+, Linux and WASI in the
qualified profiles described by the project. Other Apple platform minimums
are declared, but the 0.2.0 Xcode 27 cross-build matrix was not executed.

```swift
import SwiftHTML

let document = try HTMLDocument.parseFragment("<p class='greeting'>Hello &amp; Swift</p>")
if let paragraph = try document.select("p.greeting").first {
    try paragraph.setAttribute("lang", value: "en")
    print(try paragraph.text()) // Hello & Swift
}
```

The parser may repair malformed markup, and serialization normalizes HTML;
output is not a byte-preserving copy of input. SwiftHTML is not a sanitizer.
See <doc:SafetyAndOwnership> before working with untrusted content.

## Topics

### Guides

- <doc:GettingStarted>
- <doc:ParsingAndQuerying>
- <doc:StructuralDOM>
- <doc:EditingHTML>
- <doc:SafetyAndOwnership>

### Documents and elements

- ``HTMLDocument``
- ``HTMLElement``
- ``HTMLNode``
- ``HTMLNodeKind``
- ``HTMLTraversalLimits``
- ``HTMLTraversalReport``
- ``HTMLTraversalError``
- ``HTMLFailure``

# ``SwiftHTML``

Parse, query, and edit HTML with a small Swift API.

## Overview

SwiftHTML wraps a vendored SwiftSoup backend behind document and element types.
Parse an HTML document or a body-context fragment, use CSS selectors to find
elements, edit their shared tree, and serialize the result. No browser or
network runtime is required.

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

# SwiftHTML

SwiftHTML is a small SwiftPM library for parsing, querying, and editing HTML.
It wraps a fixture-free SwiftSoup 2.14.4 source snapshot in an independent API.
The library itself has no network or browser runtime dependency.

## Installation

Add SwiftHTML to your Swift package dependencies:

```swift
.package(url: "https://github.com/ThorFuchs/Swift-HTML.git", from: "0.1.1")
```

Add `.product(name: "SwiftHTML", package: "Swift-HTML")` to your target's
dependencies, then import `SwiftHTML`.

```swift
import SwiftHTML

let document = try HTMLDocument.parseFragment("<p class='greeting'>Hello &amp; welcome</p>")
if let paragraph = try document.select("p.greeting").first {
    print(try paragraph.text())          // Hello & welcome
    try paragraph.setAttribute("lang", value: "en")
    try paragraph.appendText(" <friend>")
}
let fragment = try document.body!.innerHTML()
// <p class="greeting" lang="en">Hello &amp; welcome &lt;friend&gt;</p>
```

`parse` builds a document. `parseFragment` parses in a **body context** and
returns a document whose body contains the fragment; `document.html()` always
serializes the whole document, while `document.body?.innerHTML()` serializes
its body. These APIs are HTML parsers, not XML parsers or arbitrary
context-sensitive fragment parsers. Malformed HTML is generally repaired, not
rejected. Serialization normalizes markup and is not byte-preserving.

`select` accepts backend CSS selectors, returns matches in tree order without
duplicates, and throws `HTMLFailure.selector` for selector errors. Selection on
an element includes that element when it matches. `text()` returns normalized
text; it is not suitable for recovering exact code or whitespace. Attributes
return `nil` when missing and an empty string when present without a value.
`directText()` provides the decoded, non-normalized content of direct text
children in order. It returns `nil` if any direct child is not a text node,
including comments and elements; an empty element returns `""`. It reflects
the parsed tree, not original HTML bytes: entities are decoded and input
preprocessing may affect content. This makes the check suitable for preserving
the parsed whitespace of code blocks without silently skipping nested markup.

`parent` returns the current parent element, or `nil` for a detached element.
The document root is represented as an element. Each wrapper retains the document
and its referenced element, but detached parent links are weak: retain an ancestor
explicitly if a detached subtree must remain intact after other references vanish.

`setText`, `appendText`, attribute operations, `appendHTML`, `setInnerHTML`,
`insertHTMLBefore`, `insertTextBefore`, and `remove` mutate the shared tree;
existing element references remain live and retain the owning document. Neither documents nor elements are `Sendable`: confine a tree to one
isolation domain or synchronize all accesses externally.

Text and attribute setters treat their inputs as data and the HTML serializer
escapes where required by its output syntax. HTML raw-text elements such as
`script` and `style` have special serialization rules; do not use text setters
as an HTML-sanitization mechanism there. `appendHTML`, `setInnerHTML`, and `insertHTMLBefore` explicitly
parse markup:
only pass HTML appropriate for the caller's trust boundary. Parsing, selecting,
and serializing do **not** sanitize untrusted HTML, URLs, CSS, scripts, or SVG.
`setInnerHTML` parses before removing existing children, preserving the element
and its attributes. `insertHTMLBefore` uses the parent's parsing context;
`insertTextBefore` inserts text instead of markup. Both insertions throw on a
detached element. To replace an entire element, insert before it and then remove
it; these are separate operations and do not form a transaction. SwiftHTML does
not provide byte-preserving SVG insertion. There are no enforced time, memory,
or document-size limits.

Swift tools 6.0 or newer are required. The public target compiles in Swift 6
language mode, while the vendored backend compiles in Swift 5 language mode.
The declared minimum Apple deployment targets are macOS 10.15, iOS 13,
tvOS 13, watchOS 6, Mac Catalyst 13.1 and visionOS 1. These are build targets;
see the validation document for the specific platforms and runtimes tested.
No SwiftSoup types appear in the public API. See [validation and integration](Documentation/VALIDATION.md)
and [third-party provenance](Documentation/THIRD_PARTY.md).

## License

SwiftHTML's own code is licensed under [Apache 2.0](LICENSE). Its vendored
SwiftSoup and LRUCache components retain their MIT licenses, including the
jsoup copyright notices. Complete notices, provenance, and redistribution
guidance are in [third-party provenance](Documentation/THIRD_PARTY.md).

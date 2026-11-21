# SwiftHTML

SwiftHTML is a small SwiftPM library for parsing, querying, and editing HTML.
It wraps a fixture-free SwiftSoup 2.14.4 source snapshot in an independent API.
The library itself has no network or browser runtime dependency.

**Release status:** 0.2.0 is integrated into `main` and passing its
implementation CI; its **public tag is pending**. The latest published
immutable release remains **0.1.1** until that tag is created.
See the [0.2.0 release notes](Documentation/Releases/0.2.0.md) and
[source-bound qualification](Documentation/Qualification/0.2.0.md).

## Installation

Add the published **0.1.1** release today, or switch to **0.2.0
after its public tag is published**. Do not reference an unpublished
tag in a consumer that must resolve immediately:

```swift
// Published stable line until the 0.2.0 release is available:
.package(url: "https://github.com/ThorFuchs/Swift-HTML.git", from: "0.1.1")

// After 0.2.0 is published, replace that single line with:
// .package(url: "https://github.com/ThorFuchs/Swift-HTML.git", from: "0.2.0")
```

0.2.0 requires Swift tools 6.4 or later and raises the minimum macOS
deployment target to 15.0. The old 0.1.1 tag retains its own contract.

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

## Typed structural DOM (0.2.0)

A parsed document now exposes live, owner-retaining nodes of distinct kinds:
elements, decoded text nodes (without whitespace normalization), comments, raw
script/style data and document/other nodes. Read the immediate children by
index, or traverse in document order using an explicit finite budget:

```swift
let document = try HTMLDocument.parseFragment("<section>before <b>bold</b> after</section>")
let section = try document.select("section").first!
let report = try section.node.walk(
    limits: HTMLTraversalLimits(maximumNodes: 100, maximumDepth: 8)
) { node, depth in
    switch node.kind {
    case .text: print(depth, node.wholeText ?? "")
    case .element: print(depth, node.element?.tagName ?? "")
    default: break
    }
}
print(report.visitedNodes, report.maximumDepth)
```

Use node.childCount / node.child(at:) to avoid unbounded sibling arrays;
children(maximumCount:) requires an explicit allocation limit. All wrappers
reference the *same mutable tree*, are intentionally **not Sendable**, and
must remain in one isolation domain. The traversal is iterative, checks Task
cancellation, and rejects node-count/depth overruns; the visitor must not mutate
the tree. Limits act **after** parsing and do not bound parser peak RAM or CPU.

See [Structural DOM](Sources/SwiftHTML/SwiftHTML.docc/StructuralDOM.md).
The structural API is present in `main` for **0.2.0** and will be
installable by version once the 0.2.0 tag is published; it is **not
included in 0.1.1**. On the merged 0.2.0 implementation, Swift 6.4.2 CI
has compiled, linked and **executed** an external consumer under
`wasm32-unknown-wasip1` (including structural node traversal). This
does not establish full WASI XCTest, browser, or universal runtime support.

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

**The 0.2.0 source requires Swift tools 6.4 (qualified with Swift 6.4.2).**
The public module uses Swift 6 language mode; the vendored backend uses
Swift 5 language mode **under the same modern compiler**. Declared Apple
minimums: **macOS 15, iOS 15, tvOS 15, watchOS 9, Mac Catalyst 15
and visionOS 1**. macOS 15 Intel and Linux x86_64 have native runtime
test evidence. WebAssembly WASI has a real consumer execution gate;
the complete unit suite has not run on WASI. Other Apple platform
minimums are declarations, **not CI-verified 0.2.0 simulator/device
support**: the conditional Xcode 27 cross-build job was skipped.
The stable 0.1.1 tag retains its earlier compiler and platform requirements.
Consult the [qualification record](Documentation/Qualification/0.2.0.md).
No SwiftSoup types appear in the public API. See [validation and integration](Documentation/VALIDATION.md)
and [third-party provenance](Documentation/THIRD_PARTY.md).

API reference and guides are available in the [SwiftHTML documentation](https://thorfuchs.github.io/Swift-HTML/documentation/swifthtml/).

## License

SwiftHTML's own code is licensed under [Apache 2.0](LICENSE). Its vendored
SwiftSoup and LRUCache components retain their MIT licenses, including the
jsoup copyright notices. Complete notices, provenance, and redistribution
guidance are in [third-party provenance](Documentation/THIRD_PARTY.md).

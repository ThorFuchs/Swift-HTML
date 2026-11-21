# Structural DOM: nodes and finite traversals

This guide describes the structural DOM introduced in **SwiftHTML 0.2.0**.
The current public `0.1.1` tag does not include this API; the versioned
`0.2.0` source becomes installable once its release tag is published.

Use live node references to inspect an HTML document in parsed order, including
mixed text, element, comment and data nodes. The public interface does not
expose any SwiftSoup/SwiftHTMLBackend types.

## Node kinds and ownership

Get the document root through `HTMLDocument.rootNode` or a selected
element's node through `HTMLElement.node`.

~~~swift
let doc = try HTMLDocument.parseFragment("<section>before <b>bold</b> after<!--note--></section>")
let section = try doc.select("section").first!
let start = section.node.child(at: 0)!
assert(start.kind == .text && start.wholeText == "before ")
let bold = start.nextSibling!
assert(bold.element?.tagName == "b")
assert(bold.parent?.name == "section")
~~~

- `HTMLNodeKind` distinguishes document, element, text, comment, data and
  other nodes. `node.name` retains the parser's node naming convention.
- `wholeText` is meaningful only for text nodes; `commentText` for comments;
  `rawData` for script/style data nodes. They are **not interchangeable**.
- `wholeText` is the parsed, decoded text. It preserves the parser's
  whitespace, but HTML entity decoding and input preprocessing mean it is
  not a byte-for-byte copy of the original source.
- A node retains its owning document and references the same mutable tree as
  its `HTMLElement` view. Even when detached, a retained node can inspect
  its remaining subtree.
- **No HTMLNode/HTMLElement/HTMLDocument is Sendable.** Confine the tree to one
  actor or otherwise synchronized isolation domain. Cross-actor output
  must be a separately authored immutable, checked Sendable projection.

## Bounded preorder traversal

~~~swift
let limits = try HTMLTraversalLimits(maximumNodes: 100_000, maximumDepth: 128)
let report = try doc.rootNode.walk(limits: limits) { node, depth in
    try Task.checkCancellation()
    switch node.kind {
    case .element:
        if node.element?.tagName == "section" {
            // Extract checked article metadata.
        }
    case .text:
        // Text is already parsed and decoded; bound your output bytes.
        _ = node.wholeText
    default:
        break
    }
}
print(report.visitedNodes, report.maximumDepth)
~~~

- The iterator is **iterative** and walks in document order; the supplied
  root is counted at depth zero.
- Node and depth limits are mandatory finite values with validated ranges.
  A violation throws `HTMLTraversalError`, without returning a success report.
- Traversal checks cooperative Task cancellation. A callback's thrown error
  propagates unchanged.
- **Do not mutate the tree during a walk.** Child-count changes are detected
  where possible; equal-count sibling reorderings or text/attribute edits
  cannot be reliably detected and are unsupported during iteration.
- Use `node.childCount` and `node.child(at:)` for individual nodes, or
  `node.children(maximumCount:)` only with a deliberate allocation budget.

These are **postparse** limits. Parsing into a DOM may already have consumed
more CPU or memory. Callers must separately bound input bytes, deadlines,
and the size of extracted values. This library does not claim general HTML
sanitization, safe URL resolution, hard CPU cancellation, or an RSS bound.

## Platform profile

The 0.2.0 package requires Swift tools **6.4** (qualified with 6.4.2)
and Swift 6 language mode for the public API. The vendored backend
compiles in Swift 5 language mode **with the same Swift 6.4.2 compiler**.
Apple minimums: macOS 15, iOS 15, tvOS 15, watchOS 9,
Mac Catalyst 15 and visionOS 1.

Linux native debug and optimized tests, a real macOS 15 Intel consumer and
WASI build, linking **and executed consumer** succeeded on the merged
0.2.0 implementation baseline. WASI is **not** proven for browser hosts
or by a full WASI XCTest run. The optional Xcode 27 cross-build matrix
for iOS/tvOS/watchOS/Catalyst/visionOS was skipped, so qualification for
those declared Apple targets remains open. See the
[qualification matrix](../../../../Documentation/Qualification/0.2.0.md).

## Migration from SwiftHTML 0.1.1

No existing functions are removed or renamed. The structural API is additive
and useful for document outlines, Markdown transformations and bounded
Wikipedia extraction. Existing CSS-selection and DOM-edit consumers require
no source changes.

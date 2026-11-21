# Structural DOM: nodes and finite traversals

This guide describes the **0.2.0 development API**. It is not yet part
of the published SwiftHTML 0.1.1 release.

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

The development package requires Swift tools **6.4** and Swift 6 language mode;
the unchanged vendored backend is compiled in Swift 5 mode. Swift 6.4.2 is the
CI qualification baseline. Apple minimums are macOS 15, iOS 15, tvOS 15,
watchOS 9, Mac Catalyst 15 and visionOS 1.

Linux native tests, a macOS 15 consumer, optional Xcode 27 cross-builds,
and a WebAssembly WASI linked-consumer gate have separate CI workflows.
**A platform is not qualified until its exact-source checks pass.**
A linked WASI executable is not proof of behavior in all browser hosts.

## Migration from SwiftHTML 0.1.1

No existing functions are removed or renamed. The structural API is additive
and useful for document outlines, Markdown transformations and bounded
Wikipedia extraction. Existing CSS-selection and DOM-edit consumers require
no source changes.

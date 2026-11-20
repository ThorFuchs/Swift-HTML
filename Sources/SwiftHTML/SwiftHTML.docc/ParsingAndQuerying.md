# Parsing and querying

Find elements and inspect parsed HTML without assuming the input bytes survive.

## Documents and fragments

``HTMLDocument/parse(_:)`` parses a whole HTML document, while
``HTMLDocument/parseFragment(_:)`` puts a fragment's nodes in a body context.
``HTMLDocument/html()`` serializes the whole document. For the fragment's
body contents use ``HTMLDocument/body`` and ``HTMLElement/innerHTML()``.

```swift
let document = try HTMLDocument.parseFragment("<p>A &amp; B</p>")
let fragment = try document.body?.innerHTML()
```

The parser handles HTML, not general XML or arbitrary context-sensitive
fragment parsing. The serialized form may differ from the original markup.

## Select and read

``HTMLDocument/select(_:)`` and ``HTMLElement/select(_:)`` accept backend CSS
selectors, return matches in tree order without duplicates, and throw on an
invalid selector. Element selection includes the element itself when it matches.

``HTMLElement/text()`` returns normalized descendant text. Use
``HTMLElement/directText()`` when you need unnormalized *direct* text nodes:
it returns `nil` if a direct child is not a text node, including a comment or
nested element, and returns an empty string for an empty element. Entities
have already been decoded and HTML input processing may normalize line endings.

``HTMLElement/attribute(_:)`` distinguishes a missing attribute (`nil`) from
an attribute whose value is empty (`""`). ``HTMLElement/parent`` follows the
current tree and is `nil` for a detached element.

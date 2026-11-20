# Editing HTML

Change attributes, text, and child nodes in the document's shared mutable tree.

```swift
let document = try HTMLDocument.parseFragment("<p class='greeting'>Hello</p>")
if let paragraph = try document.select("p.greeting").first {
    try paragraph.setAttribute("lang", value: "en")
    try paragraph.appendText(" <friend>")
    let html = try paragraph.outerHTML()
    print(html) // <p class="greeting" lang="en">Hello &lt;friend&gt;</p>
}
```

``HTMLElement/setText(_:)`` replaces the children with text;
``HTMLElement/appendText(_:)`` appends text. Attribute values and ordinary
text are serialized according to HTML rules. Raw-text elements such as
`script` and `style` have special serialization behavior.

``HTMLElement/appendHTML(_:)`` parses and appends markup in the element's
context. ``HTMLElement/setInnerHTML(_:)`` parses first, then replaces the
children while retaining the element and its attributes. These methods accept
markup and do not sanitize it.

``HTMLElement/insertHTMLBefore(_:)`` parses markup in the parent's context;
``HTMLElement/insertTextBefore(_:)`` inserts text. Both require a parent.
``HTMLElement/remove()`` detaches an element; existing references remain
usable. Replacing an element by inserting and then removing it is two separate
operations, not an atomic transaction.

Elements reference the same mutable tree; copying a reference does not make an
independent document. See <doc:SafetyAndOwnership> for ownership and isolation.

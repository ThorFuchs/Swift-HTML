// SPDX-License-Identifier: Apache-2.0
import SwiftHTML

let document = try HTMLDocument.parseFragment("<pre><code>Hello  &amp; welcome\n</code></pre>")
guard let code = try document.select("pre > code").first,
      code.directText() == "Hello  & welcome\n",
      let pre = code.parent else { fatalError("Unexpected DOM") }
try code.setInnerHTML("<strong>Hello</strong>")
try pre.insertTextBefore("marker")
print(try document.body!.innerHTML())


// Exercise the public structural DOM API as an actual external consumer,
// including when the executable is compiled and run under WebAssembly WASI.
let structure = try HTMLDocument.parseFragment("<section>before <b>bold</b> after<!--note--></section>")
guard let section = try structure.select("section").first else {
    fatalError("Structural DOM section not found")
}
let nodes = try section.node.children(maximumCount: 4)
precondition(nodes.map(\.kind) == [.text, .element, .text, .comment])
precondition(nodes[0].wholeText == "before ")
precondition(nodes[1].element?.tagName == "b")
precondition(nodes[2].wholeText == " after")
precondition(nodes[3].commentText == "note")
let traversal = try section.node.walk(limits: .init(maximumNodes: 6, maximumDepth: 2)) { _, _ in }
precondition(traversal.visitedNodes == 6 && traversal.maximumDepth == 2)
print("Structural DOM traversal passed")

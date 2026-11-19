import SwiftHTML

let document = try HTMLDocument.parseFragment("<pre><code>Hello  &amp; welcome\n</code></pre>")
guard let code = try document.select("pre > code").first,
      code.directText() == "Hello  & welcome\n",
      let pre = code.parent else { fatalError("Unexpected DOM") }
try code.setInnerHTML("<strong>Hello</strong>")
try pre.insertTextBefore("marker")
print(try document.body!.innerHTML())

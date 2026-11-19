import XCTest
import SwiftHTML

final class DOMIntegrationTests: XCTestCase {
    func testDirectTextPreservesParsedWhitespaceUnicodeAndEntityValues() throws {
        let doc = try HTMLDocument.parseFragment("<pre><code>let  x = 1\n\tprint(&quot;&amp;&quot;)\nGrüße 東京 🙂\n</code></pre>")
        let code = try XCTUnwrap(doc.select("code").first)
        let expected = "let  x = 1\n\tprint(\"&\")\nGrüße 東京 🙂\n"
        XCTAssertEqual(Array(try XCTUnwrap(code.directText()).utf8), Array(expected.utf8))
        XCTAssertNotEqual(try code.text(), expected)
    }

    func testDirectTextCombinesMultipleTextNodesAndAcceptsEmpty() throws {
        let doc = try HTMLDocument.parseFragment("<code></code>")
        let code = try XCTUnwrap(doc.select("code").first)
        XCTAssertEqual(code.directText(), "")
        try code.appendText("a  \n")
        try code.appendText("\t&<東京>")
        XCTAssertEqual(code.directText(), "a  \n\t&<東京>")
        XCTAssertEqual(try code.innerHTML(), "a  \n\t&amp;&lt;東京&gt;")
    }

    func testDirectTextRejectsAnyNonTextChildWithoutDroppingContent() throws {
        for html in ["<code>a<b>b</b>c</code>", "<code>a<!--comment-->b</code>", "<code><br></code>"] {
            let doc = try HTMLDocument.parseFragment(html)
            let code = try XCTUnwrap(doc.select("code").first)
            XCTAssertNil(code.directText(), html)
            XCTAssertFalse(try code.innerHTML().isEmpty)
        }
    }

    func testParsedTextDoesNotClaimOriginalSourceBytes() throws {
        let doc = try HTMLDocument.parseFragment("<code>a\r\nb\rc &amp; &#65;</code>")
        let code = try XCTUnwrap(doc.select("code").first)
        XCTAssertEqual(Array(try XCTUnwrap(code.directText()).utf8), Array("a\r\nb\rc & A".utf8))
    }

    func testParentAndInnerReplacementPreserveAttributesAndDetachOldChildren() throws {
        let doc = try HTMLDocument.parseFragment("<pre lang='swift'><code class='language-swift'><i>old</i></code></pre>")
        let code = try XCTUnwrap(doc.select("code").first)
        let old = try XCTUnwrap(doc.select("i").first)
        let parent = try XCTUnwrap(code.parent)
        XCTAssertEqual(parent.tagName, "pre")
        XCTAssertEqual(try parent.attribute("lang"), "swift")
        try code.setInnerHTML("<span class='kw'>let</span> &amp; <b>x</b>")
        XCTAssertEqual(try code.attribute("class"), "language-swift")
        XCTAssertEqual(try code.innerHTML(), "<span class=\"kw\">let</span> &amp; <b>x</b>")
        XCTAssertNil(old.parent)
        XCTAssertEqual(try old.text(), "old")
        XCTAssertEqual(try doc.select("code > span").count, 1)
        try code.setInnerHTML("")
        XCTAssertEqual(code.directText(), "")
    }

    func testInsertBeforeAndRemovePreserveSiblingOrderAndDetachedReference() throws {
        let doc = try HTMLDocument.parseFragment("<main><p>before</p><pre><code>x</code></pre><p>after</p></main>")
        let pre = try XCTUnwrap(doc.select("pre").first)
        try pre.insertHTMLBefore("<figure>one</figure><aside>two</aside>")
        try pre.remove()
        XCTAssertNil(pre.parent)
        XCTAssertEqual(try pre.select("code").first?.text(), "x")
        XCTAssertEqual(try XCTUnwrap(doc.select("main").first).innerHTML(),
                       "<p>before</p><figure>one</figure><aside>two</aside><p>after</p>")
        XCTAssertThrowsError(try pre.insertHTMLBefore("<b>no</b>"))
        XCTAssertThrowsError(try pre.insertTextBefore("no"))
        XCTAssertEqual(try pre.outerHTML(), "<pre><code>x</code></pre>")
    }

    func testTextMarkerEscapesMarkupAndPreservesSurroundingOrder() throws {
        let doc = try HTMLDocument.parseFragment("<main>start<pre>old</pre>end</main>")
        let pre = try XCTUnwrap(doc.select("pre").first)
        try pre.insertTextBefore("marker<&>")
        try pre.remove()
        XCTAssertEqual(try XCTUnwrap(doc.select("main").first).innerHTML(), "startmarker&lt;&amp;&gt;end")
    }

    func testBlockProcessingPatternAndBytePreservingMarker() throws {
        let doc = try HTMLDocument.parseFragment("<pre><code class='language-swift'>let  x = 1\n</code></pre><pre><code class='language-mermaid'>A--&gt;B\n</code></pre>")
        let blocks = try doc.select("pre > code")
        let swift = try XCTUnwrap(blocks.first)
        XCTAssertEqual(swift.directText(), "let  x = 1\n")
        try swift.setInnerHTML("<span class='keyword'>let</span>  x = 1\n")
        let diagram = try XCTUnwrap(blocks.last)
        XCTAssertEqual(diagram.directText(), "A-->B\n")
        let pre = try XCTUnwrap(diagram.parent)
        try pre.insertTextBefore("SAFE_MARKER_42")
        try pre.remove()
        let output = try XCTUnwrap(doc.body).innerHTML()
        XCTAssertEqual(output.components(separatedBy: "SAFE_MARKER_42").count, 2)
        let validatedSVG = "<svg viewBox=\"0 0 10 10\"><path d=\"M0 0L1 1\"/></svg>"
        let final = output.replacingOccurrences(of: "SAFE_MARKER_42", with: validatedSVG)
        XCTAssertTrue(final.contains(validatedSVG))
        XCTAssertTrue(final.contains("<code class=\"language-swift\"><span class=\"keyword\">let</span>  x = 1\n</code>"))
    }

    func testInsertionUsesParentParsingContext() throws {
        let doc = try HTMLDocument.parseFragment("<table><tbody><tr><td>old</td></tr></tbody></table>")
        let row = try XCTUnwrap(doc.select("tr").first)
        try row.insertHTMLBefore("<tr><td>new</td></tr>")
        try row.remove()
        XCTAssertEqual(try doc.select("tbody > tr > td").map { try $0.text() }, ["new"])
    }
}

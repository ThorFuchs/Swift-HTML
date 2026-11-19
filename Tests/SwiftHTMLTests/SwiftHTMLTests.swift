// SPDX-License-Identifier: Apache-2.0
import XCTest
@testable import SwiftHTML

final class SwiftHTMLTests: XCTestCase {
    func testDocumentRepairsMarkupAndPreservesComments() throws {
        let doc = try HTMLDocument.parse("<!doctype html><title>Hi</title><p>one<p>two<!--note-->")
        XCTAssertEqual(try doc.select("p").map { try $0.text() }, ["one", "two"])
        let html = try doc.html()
        XCTAssertTrue(html.contains("<!--note-->"))
        XCTAssertTrue(html.contains("<html>"))
    }

    func testFragmentUnicodeEntitiesAndAttributes() throws {
        let doc = try HTMLDocument.parseFragment("<p title='A &amp; B' empty>Grüße &amp; 東京 &#x1F642;</p>")
        let p = try XCTUnwrap(doc.select("p").first)
        XCTAssertEqual(try p.text(), "Grüße & 東京 🙂")
        XCTAssertEqual(try p.attribute("title"), "A & B")
        XCTAssertEqual(try p.attribute("empty"), "")
        XCTAssertNil(try p.attribute("missing"))
        XCTAssertTrue(try XCTUnwrap(doc.body).innerHTML().hasPrefix("<p"))
    }

    func testSelectorsOrderAndDeduplication() throws {
        let doc = try HTMLDocument.parseFragment("<ul><li id='a' class='x'>A</li><li id='b' class='x'>B</li><li id='c'>C</li></ul>")
        let items = try doc.select("li.x, li")
        XCTAssertEqual(try items.map { try $0.attribute("id") }, ["a", "b", "c"])
        XCTAssertEqual(try doc.select("ul > li:nth-child(2)").first?.text(), "B")
        XCTAssertThrowsError(try doc.select("[")) { XCTAssertTrue($0 is HTMLFailure) }
    }

    func testMutationsEscapeTextAndAttributeAndRawHTMLIsExplicit() throws {
        let doc = try HTMLDocument.parseFragment("<div><b>old</b></div>")
        let div = try XCTUnwrap(doc.select("div").first)
        try div.setText("<tag> & \"hello\"")
        try div.setAttribute("title", value: "\" & <")
        try div.appendText("<more>")
        try div.appendHTML("<em>raw</em>")
        let html = try XCTUnwrap(doc.body).innerHTML()
        XCTAssertTrue(html.contains("&lt;tag&gt; &amp;"), html)
        XCTAssertTrue(html.contains("&quot; &amp;"), html)
        let reparsed = try HTMLDocument.parseFragment(html)
        XCTAssertEqual(try reparsed.select("div").first?.attribute("title"), "\" & <")
        XCTAssertTrue(html.contains("&lt;more&gt;<em>raw</em>"), html)
        XCTAssertEqual(try doc.select("em").count, 1)
        try div.removeAttribute("title")
        XCTAssertNil(try div.attribute("title"))
        let em = try XCTUnwrap(try doc.select("em").first)
        try em.remove()
        XCTAssertTrue(try doc.select("em").isEmpty)
    }

    func testLiveElementsRetainTheirDocument() throws {
        let element: HTMLElement = try {
            let doc = try HTMLDocument.parseFragment("<p>before</p>")
            return try XCTUnwrap(doc.select("p").first)
        }()
        try element.setText("after")
        XCTAssertEqual(try element.outerHTML(), "<p>after</p>")
    }
}

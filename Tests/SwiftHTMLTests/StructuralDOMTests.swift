// SPDX-License-Identifier: Apache-2.0
import XCTest
import SwiftHTML

final class StructuralDOMTests: XCTestCase {
    func testDocumentRootAndOrderedMixedNodes() throws {
        let doc = try HTMLDocument.parseFragment(
            "<section>before &amp; <b>bold</b> after<!--note--><script>var a = 1;</script></section>"
        )
        XCTAssertEqual(doc.rootNode.kind, .document)
        let section = try XCTUnwrap(doc.select("section").first)
        XCTAssertEqual(section.node.kind, .element)
        XCTAssertEqual(section.node.name, "section")
        let children = try section.node.children(maximumCount: 5)
        XCTAssertEqual(children.map(\.kind), [.text, .element, .text, .comment, .element])
        XCTAssertEqual(children[0].wholeText, "before & ")
        XCTAssertEqual(children[1].element?.tagName, "b")
        XCTAssertEqual(children[2].wholeText, " after")
        XCTAssertEqual(children[3].commentText, "note")
        XCTAssertNil(children[3].wholeText)
        XCTAssertNil(children[3].element)
        XCTAssertEqual(children[4].element?.tagName, "script")
        let data = try XCTUnwrap(children[4].child(at: 0))
        XCTAssertEqual(data.kind, .data)
        XCTAssertEqual(data.rawData, "var a = 1;")
        XCTAssertNil(data.wholeText)
    }

    func testNodeOrderAndBoundedPreorderTraversal() throws {
        let doc = try HTMLDocument.parseFragment("<section>a<b>β</b> c<!--note--></section>")
        let section = try XCTUnwrap(doc.select("section").first)
        var visited: [(String, Int)] = []
        let report = try section.node.walk(limits: .init(maximumNodes: 10, maximumDepth: 2)) { node, depth in
            visited.append((node.name, depth))
        }
        XCTAssertEqual(visited.map { $0.0 }, ["section", "#text", "b", "#text", "#text", "#comment"])
        XCTAssertEqual(visited.map { $0.1 }, [0, 1, 1, 2, 1, 1])
        XCTAssertEqual(report.visitedNodes, 6)
        XCTAssertEqual(report.maximumDepth, 2)
        XCTAssertEqual(section.node.childCount, 4)
        XCTAssertNil(section.node.child(at: -1))
        XCTAssertNil(section.node.child(at: 4))
        XCTAssertEqual(section.node.child(at: 1)?.element?.tagName, "b")
    }

    func testParentAndSiblingRelationshipsKeepOwner() throws {
        let doc = try HTMLDocument.parseFragment("<main>alpha<strong>bold</strong>omega</main>")
        let main = try XCTUnwrap(doc.select("main").first)
        let start = try XCTUnwrap(main.node.child(at: 0))
        let bold = try XCTUnwrap(start.nextSibling)
        let end = try XCTUnwrap(bold.nextSibling)
        XCTAssertEqual(start.wholeText, "alpha")
        XCTAssertEqual(bold.element?.tagName, "strong")
        XCTAssertEqual(bold.previousSibling?.wholeText, "alpha")
        XCTAssertEqual(end.previousSibling?.kind, .element)
        XCTAssertEqual(end.wholeText, "omega")
        XCTAssertEqual(end.parent?.name, "main")
        XCTAssertEqual(main.node.parent?.name, "body")
    }

    func testPostparseNodeAndDepthBudgetsFailClosed() throws {
        let doc = try HTMLDocument.parseFragment("<div><p>text</p><p>again</p></div>")
        let div = try XCTUnwrap(doc.select("div").first)
        let tooFew = try HTMLTraversalLimits(maximumNodes: 2, maximumDepth: 10)
        var visits = 0
        XCTAssertThrowsError(try div.node.walk(limits: tooFew) { _, _ in visits += 1 }) { error in
            XCTAssertEqual(error as? HTMLTraversalError, .nodeLimit)
        }
        XCTAssertEqual(visits, 2)

        let tooShallow = try HTMLTraversalLimits(maximumNodes: 20, maximumDepth: 1)
        XCTAssertThrowsError(try div.node.walk(limits: tooShallow) { _, _ in }) { error in
            XCTAssertEqual(error as? HTMLTraversalError, .depthLimit)
        }
        XCTAssertThrowsError(try HTMLTraversalLimits(maximumNodes: 0, maximumDepth: 10)) { error in
            XCTAssertEqual(error as? HTMLTraversalError, .invalidLimits)
        }
        XCTAssertThrowsError(try HTMLTraversalLimits(maximumNodes: 20, maximumDepth: -1)) { error in
            XCTAssertEqual(error as? HTMLTraversalError, .invalidLimits)
        }
        XCTAssertThrowsError(try div.node.children(maximumCount: 1)) { error in
            XCTAssertEqual(error as? HTMLTraversalError, .nodeLimit)
        }
        XCTAssertEqual(try div.node.children(maximumCount: 2).count, 2)
    }

    func testMutationDuringVisitIsDetectedWhenChildCountChanges() throws {
        let doc = try HTMLDocument.parseFragment("<p>old</p>")
        let paragraph = try XCTUnwrap(doc.select("p").first)
        XCTAssertThrowsError(
            try paragraph.node.walk(limits: .init(maximumNodes: 10, maximumDepth: 2)) { node, depth in
                if depth == 0 { try node.element?.appendText("added") }
            }
        ) { error in
            XCTAssertEqual(error as? HTMLTraversalError, .treeChanged)
        }
        XCTAssertEqual(try paragraph.text(), "oldadded")
    }

    func testDetachedElementRetainsItsOwnSubtree() throws {
        let held: HTMLNode = try {
            let doc = try HTMLDocument.parseFragment("<main><em>stay</em></main>")
            let em = try XCTUnwrap(doc.select("em").first)
            try em.remove()
            return em.node
        }()
        XCTAssertNil(held.parent)
        XCTAssertEqual(held.kind, .element)
        XCTAssertEqual(held.element?.tagName, "em")
        XCTAssertEqual(held.child(at: 0)?.wholeText, "stay")
        XCTAssertEqual(try held.element?.outerHTML(), "<em>stay</em>")
    }

    func testWideTreeDoesNotRequireRecursiveTraversal() throws {
        let count = 1_200
        let html = "<div>" + String(repeating: "<i>x</i>", count: count) + "</div>"
        let doc = try HTMLDocument.parseFragment(html)
        let div = try XCTUnwrap(doc.select("div").first)
        let report = try div.node.walk(limits: .init(maximumNodes: 2 * count + 1, maximumDepth: 2)) { _, _ in }
        XCTAssertEqual(report.visitedNodes, 2 * count + 1)
        XCTAssertEqual(report.maximumDepth, 2)
    }

    func testEmptyElementAndNonTextChildrenAreUnambiguous() throws {
        let doc = try HTMLDocument.parseFragment("<div><span></span><!--c--><br></div>")
        let div = try XCTUnwrap(doc.select("div").first)
        let span = try XCTUnwrap(div.node.child(at: 0))
        XCTAssertEqual(span.kind, .element)
        XCTAssertEqual(span.childCount, 0)
        XCTAssertEqual(try span.children(maximumCount: 0).count, 0)
        XCTAssertNil(span.wholeText)
        XCTAssertEqual(span.element?.directText(), "")
        XCTAssertEqual(div.node.child(at: 1)?.commentText, "c")
        XCTAssertEqual(div.node.child(at: 2)?.element?.tagName, "br")
    }
}

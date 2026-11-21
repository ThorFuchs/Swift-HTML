// SPDX-License-Identifier: Apache-2.0
internal import SwiftHTMLBackend

/// An operation failed. Details originate in the parser and are diagnostic, not stable API.
public enum HTMLFailure: Error, CustomStringConvertible, Sendable {
    /// The HTML parser could not produce a document.
    case parsing(String)
    /// The supplied CSS selector could not be evaluated.
    case selector(String)
    /// An element operation or serialization failed.
    case operation(String)

    /// A diagnostic description that includes the underlying error detail.
    public var description: String {
        switch self {
        case .parsing(let detail): "HTML parsing failed: \(detail)"
        case .selector(let detail): "CSS selector failed: \(detail)"
        case .operation(let detail): "HTML operation failed: \(detail)"
        }
    }
}

/// An owned, mutable HTML document. Elements obtained from it share the same tree.
/// Keep each tree confined to one isolation domain; concurrent access is not supported.
public final class HTMLDocument {
    private let document: SwiftHTMLBackend.Document

    private init(_ document: SwiftHTMLBackend.Document) {
        self.document = document
        document.outputSettings().prettyPrint(pretty: false)
    }

    /// Parses as HTML, even when the input starts with an XML declaration.
    public static func parse(_ html: String) throws -> HTMLDocument {
        do { return HTMLDocument(try SwiftHTMLBackend.parseHTML(html)) }
        catch { throw HTMLFailure.parsing(String(describing: error)) }
    }

    /// Parses a fragment in an HTML body context; this is not a context-sensitive XML parser.
    public static func parseFragment(_ html: String) throws -> HTMLDocument {
        do { return HTMLDocument(try SwiftHTMLBackend.parseBodyFragment(html)) }
        catch { throw HTMLFailure.parsing(String(describing: error)) }
    }

    /// The live document root, including head, body and other parsed node kinds.
    /// The returned reference retains this document and is not Sendable.
    public var rootNode: HTMLNode { HTMLNode(document, owner: self) }

    /// Finds elements in tree order, with each element appearing at most once.
    public func select(_ css: String) throws -> [HTMLElement] {
        do { return try document.select(css).array().map { HTMLElement($0, owner: self) } }
        catch { throw HTMLFailure.selector(String(describing: error)) }
    }

    /// The body, when present. Its children are the result of body-context fragment parsing.
    public var body: HTMLElement? {
        document.body().map { HTMLElement($0, owner: self) }
    }

    /// Serializes the whole document as HTML. Output need not reproduce input bytes.
    public func html() throws -> String {
        do { return try document.outerHtml() }
        catch { throw HTMLFailure.operation(String(describing: error)) }
    }
}

/// A reference into a document's mutable tree. Retains the owning document.
/// Copying this reference does not copy the element or the tree.
public final class HTMLElement {
    private let element: SwiftHTMLBackend.Element
    private let owner: HTMLDocument

    fileprivate init(_ element: SwiftHTMLBackend.Element, owner: HTMLDocument) {
        self.element = element
        self.owner = owner
    }

    /// The element's HTML tag name.
    public var tagName: String { element.tagName() }

    /// The current parent element, or nil if detached. The document root is also
    /// represented as an element. Parent links follow the current tree.
    public var parent: HTMLElement? {
        element.parent().map { HTMLElement($0, owner: owner) }
    }

    /// A live, general-purpose node view of this element, including text children.
    public var node: HTMLNode { HTMLNode(element, owner: owner) }

    /// Concatenates direct text-node contents in order without whitespace
    /// normalization, or returns nil if any direct child is not a text node.
    /// An empty element returns an empty string. This is parsed text: entities
    /// have been decoded and HTML input preprocessing may normalize line endings.
    public func directText() -> String? {
        var result = ""
        for child in element.getChildNodes() {
            guard let text = child as? SwiftHTMLBackend.TextNode else { return nil }
            result += text.getWholeText()
        }
        return result
    }

    /// Finds matching elements in tree order, including this element if it matches.
    public func select(_ css: String) throws -> [HTMLElement] {
        do { return try element.select(css).array().map { HTMLElement($0, owner: owner) } }
        catch { throw HTMLFailure.selector(String(describing: error)) }
    }

    /// Returns the backend's normalized descendant text.
    public func text() throws -> String {
        do { return try element.text() }
        catch { throw HTMLFailure.operation(String(describing: error)) }
    }

    /// Replaces the children with text. HTML raw-text elements have special serialization rules.
    public func setText(_ text: String) throws {
        do { try element.text(text) }
        catch { throw HTMLFailure.operation(String(describing: error)) }
    }

    /// Returns nil for a missing attribute, distinguishing it from an empty value.
    public func attribute(_ name: String) throws -> String? {
        do { return element.hasAttr(name) ? try element.attr(name) : nil }
        catch { throw HTMLFailure.operation(String(describing: error)) }
    }

    /// Sets or replaces an attribute on this element.
    public func setAttribute(_ name: String, value: String) throws {
        do { try element.attr(name, value) }
        catch { throw HTMLFailure.operation(String(describing: error)) }
    }

    /// Removes an attribute if present.
    public func removeAttribute(_ name: String) throws {
        do { try element.removeAttr(name) }
        catch { throw HTMLFailure.operation(String(describing: error)) }
    }

    /// Serializes this element's children, not the element itself.
    public func innerHTML() throws -> String {
        do { return try element.html() }
        catch { throw HTMLFailure.operation(String(describing: error)) }
    }

    /// Serializes this element and its children as HTML.
    public func outerHTML() throws -> String {
        do { return try element.outerHtml() }
        catch { throw HTMLFailure.operation(String(describing: error)) }
    }

    /// Parses and appends raw HTML in this element's context. This does not sanitize it.
    public func appendHTML(_ html: String) throws {
        do { try element.append(html) }
        catch { throw HTMLFailure.operation(String(describing: error)) }
    }

    /// Replaces all children with parsed HTML while retaining this element and
    /// its attributes. The input is trusted markup, not sanitized or byte-preserved.
    /// Parsing occurs before existing children are removed.
    public func setInnerHTML(_ html: String) throws {
        do {
            let nodes = try SwiftHTMLBackend.Parser.parseFragment(html, element, element.getBaseUriUTF8())
            _ = element.empty()
            try element.addChildren(nodes)
        } catch { throw HTMLFailure.operation(String(describing: error)) }
    }

    /// Parses trusted HTML in the parent's context and inserts it before this
    /// element. Throws if the element has no parent; no sanitization is performed.
    public func insertHTMLBefore(_ html: String) throws {
        do { try element.before(html) }
        catch { throw HTMLFailure.operation(String(describing: error)) }
    }

    /// Inserts a text node before this element. Throws if it has no parent.
    public func insertTextBefore(_ text: String) throws {
        do { try element.before(SwiftHTMLBackend.TextNode(text, nil)) }
        catch { throw HTMLFailure.operation(String(describing: error)) }
    }

    /// Detaches this element from its parent. Existing references remain usable.
    public func remove() throws {
        do { try element.remove() }
        catch { throw HTMLFailure.operation(String(describing: error)) }
    }

    /// Appends text to this element without interpreting it as HTML markup.
    public func appendText(_ text: String) throws {
        do { try element.appendText(text) }
        catch { throw HTMLFailure.operation(String(describing: error)) }
    }
}


/// Stable classifications of parsed DOM nodes, without exposing vendored parser types.
/// A Document is reported separately even though the backend derives it from Element.
public enum HTMLNodeKind: Sendable, Equatable {
    case document
    case element
    case text
    case comment
    case data
    case other
}

/// Distinct errors for caller-chosen postparse traversal limits.
/// These limits do not bound the parser's peak memory or CPU while building a DOM.
public enum HTMLTraversalError: Error, Sendable, Equatable {
    case invalidLimits
    case nodeLimit
    case depthLimit
    case treeChanged
}

/// An explicit finite budget for traversing an *already parsed* document.
/// Depth zero is the supplied root. A traversal visits the root itself.
public struct HTMLTraversalLimits: Sendable, Equatable {
    public let maximumNodes: Int
    public let maximumDepth: Int

    public init(maximumNodes: Int = 100_000, maximumDepth: Int = 128) throws {
        guard (1...1_000_000).contains(maximumNodes),
              (0...4_096).contains(maximumDepth) else {
            throw HTMLTraversalError.invalidLimits
        }
        self.maximumNodes = maximumNodes
        self.maximumDepth = maximumDepth
    }
}

/// Aggregate evidence for a successfully completed bounded DOM traversal.
public struct HTMLTraversalReport: Sendable, Equatable {
    public let visitedNodes: Int
    public let maximumDepth: Int
}

/// A live reference to a parsed node, retained by its owning HTMLDocument.
///
/// Node and element references are intentionally *not Sendable*: the underlying
/// tree is mutable and callers must confine it to one actor/isolation domain.
/// Parsed text is not byte-identical original HTML source. No parser backend
/// types appear in this public interface.
public final class HTMLNode {
    private let backend: SwiftHTMLBackend.Node
    private let owner: HTMLDocument

    fileprivate init(_ backend: SwiftHTMLBackend.Node, owner: HTMLDocument) {
        self.backend = backend
        self.owner = owner
    }

    public var kind: HTMLNodeKind {
        if backend is SwiftHTMLBackend.Document { return .document }
        if backend is SwiftHTMLBackend.Element { return .element }
        if backend is SwiftHTMLBackend.TextNode { return .text }
        if backend is SwiftHTMLBackend.Comment { return .comment }
        if backend is SwiftHTMLBackend.DataNode { return .data }
        return .other
    }

    /// Parsed node name (e.g. "p", "#text", "#comment").
    public var name: String { backend.nodeName() }

    /// Mutable element view sharing the same owner, when this node is an element.
    /// Document nodes are not exposed as ordinary elements here.
    public var element: HTMLElement? {
        guard kind == .element, let element = backend as? SwiftHTMLBackend.Element else { return nil }
        return HTMLElement(element, owner: owner)
    }

    /// Parsed, un-normalized text-node contents; nil for all other kinds.
    /// Entity references are already decoded and line endings may be transformed.
    public var wholeText: String? { (backend as? SwiftHTMLBackend.TextNode)?.getWholeText() }

    /// The content of an HTML comment, not its serialized delimiters.
    public var commentText: String? { (backend as? SwiftHTMLBackend.Comment)?.getData() }

    /// Raw data for script/style-like data nodes. Never execute or trust it.
    public var rawData: String? { (backend as? SwiftHTMLBackend.DataNode)?.getWholeData() }

    public var parent: HTMLNode? {
        backend.parent().map { HTMLNode($0, owner: owner) }
    }

    public var nextSibling: HTMLNode? {
        backend.nextSibling().map { HTMLNode($0, owner: owner) }
    }

    public var previousSibling: HTMLNode? {
        backend.previousSibling().map { HTMLNode($0, owner: owner) }
    }

    public var childCount: Int { backend.childNodeSize() }

    /// Index-based access avoids materializing an unbounded child-node array.
    public func child(at index: Int) -> HTMLNode? {
        guard index >= 0, index < backend.childNodeSize() else { return nil }
        return HTMLNode(backend.childNode(index), owner: owner)
    }

    /// Convenience materialization with an explicit limit. Prefer walk for large DOMs.
    public func children(maximumCount: Int) throws -> [HTMLNode] {
        guard (0...1_000_000).contains(maximumCount) else { throw HTMLTraversalError.invalidLimits }
        let count = backend.childNodeSize()
        guard count <= maximumCount else { throw HTMLTraversalError.nodeLimit }
        return (0..<count).map { HTMLNode(backend.childNode($0), owner: owner) }
    }

    /// Depth-first, preorder traversal with strict caller-supplied node and depth
    /// limits. Uses an iterative index stack rather than recursion or an unbounded
    /// copy of each node's children. Checks cooperative Task cancellation.
    ///
    /// The callback must **not mutate** the tree during traversal. Child-count
    /// changes are detected where possible, but equal-count reorderings and
    /// mutations of text/attributes cannot be reliably detected. A returned
    /// HTMLTraversalReport certifies only this traversal, not parser memory limits.
    @discardableResult
    public func walk(
        limits: HTMLTraversalLimits,
        _ visit: (HTMLNode, Int) throws -> Void
    ) throws -> HTMLTraversalReport {
        struct Frame {
            let node: SwiftHTMLBackend.Node
            let depth: Int
            let originalChildCount: Int
            var nextChildIndex: Int = 0
        }
        var frames = [Frame(node: backend, depth: 0, originalChildCount: backend.childNodeSize())]
        var visited = 0
        var deepest = 0

        while !frames.isEmpty {
            try Task.checkCancellation()
            let last = frames.count - 1
            let frame = frames[last]

            if frame.nextChildIndex == 0 {
                guard visited < limits.maximumNodes else { throw HTMLTraversalError.nodeLimit }
                guard frame.depth <= limits.maximumDepth else { throw HTMLTraversalError.depthLimit }
                visited += 1
                deepest = max(deepest, frame.depth)
                try visit(HTMLNode(frame.node, owner: owner), frame.depth)
            }

            guard frame.node.childNodeSize() == frame.originalChildCount else {
                throw HTMLTraversalError.treeChanged
            }
            if frame.nextChildIndex < frame.originalChildCount {
                let nextDepth = frame.depth + 1
                guard nextDepth <= limits.maximumDepth else { throw HTMLTraversalError.depthLimit }
                frames[last].nextChildIndex += 1
                let child = frame.node.childNode(frame.nextChildIndex)
                frames.append(Frame(node: child, depth: nextDepth, originalChildCount: child.childNodeSize()))
            } else {
                frames.removeLast()
            }
        }
        return HTMLTraversalReport(visitedNodes: visited, maximumDepth: deepest)
    }
}

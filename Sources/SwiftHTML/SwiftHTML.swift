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

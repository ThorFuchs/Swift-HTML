# Safety and ownership

Understand what parsing, mutation, and element references do and do not provide.

## Input and output trust

SwiftHTML parses and serializes HTML; it does not sanitize HTML, URLs, CSS,
scripts, or SVG. Only pass markup to HTML insertion APIs when it is appropriate
for the caller's trust boundary. Text and attribute setters are not general
HTML sanitizers, particularly for raw-text elements such as `script` or
`style`. SwiftHTML does not offer byte-preserving SVG insertion.

The package does not enforce time, memory, or document-size limits. A caller
processing untrusted or large documents must choose appropriate external limits
and isolation.

## Shared tree and concurrency

``HTMLDocument`` and ``HTMLElement`` refer to a mutable tree and are not
`Sendable`. Keep each tree within one isolation domain or synchronize all
access externally. An element retains its owning document. Detached parent links
are weak; retain an ancestor explicitly if a detached subtree must outlive
other references.

## Errors

``HTMLFailure`` distinguishes parser, selector, and operation failures. Its
underlying strings are diagnostic details, not a stable error-message API.

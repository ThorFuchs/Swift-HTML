# Changelog

## 0.2.0 — in development (unreleased)

- Raise Swift tools requirement to 6.4 (CI baseline 6.4.2), with macOS 15 as the deployment floor; align other Apple platform floors with supported Xcode 27 targets.
- Add owner-retaining, typed HTMLNode views for document, element, text, comment and data nodes, with indexed children and sibling/parent navigation.
- Add iterative preorder traversal, explicit postparse node/depth budgets, cancellation checks and a typed completion report.
- Add structural DOM tests, DocC API guide, updated Linux/Apple CI and a first WASI cross-build/linked consumer gate.
- The vendored SwiftSoup 2.14.4 tree is unchanged except for an exact, documented WASI-only NSLock shim; verification reverses that shim and checks original upstream hashes. No release or full platform-compatibility claim is made by this entry.

## 0.1.1 — 2026-11-20

- Declare explicit Apple deployment targets required by the bundled backend,
  fixing SwiftPM builds that otherwise compile it for an unsupported OS version.
- Add macOS Intel and Apple-platform build checks and a macOS 15 consumer check.

## 0.1.0 — 2026-11-19

- Add document and body-context fragment parsing, CSS selection, text and
  attribute access, mutable elements, and HTML serialization.
- Add direct text-node inspection, parent access, and targeted text and HTML
  mutations for structured consumers such as SwiftMD.
- Bundle SwiftSoup 2.14.4 with an isolated backend module and include its MIT
  notices and the MIT notice for LRUCache as SwiftPM resources.
- License SwiftHTML's own code under Apache 2.0. Document trust boundaries,
  provenance, platforms tested, and binary redistribution considerations.

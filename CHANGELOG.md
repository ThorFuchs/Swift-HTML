# Changelog

## 0.2.0 — 2026-11-21 (release candidate; public tag pending)

- Raise Swift tools requirement to 6.4 (CI baseline 6.4.2), with macOS 15 as the deployment floor; align other Apple platform floors with supported Xcode 27 targets.
- Add owner-retaining, typed HTMLNode views for document, element, text, comment and data nodes, with indexed children and sibling/parent navigation.
- Add iterative preorder traversal, explicit postparse node/depth budgets, cancellation checks and a typed completion report.
- Add eight structural DOM tests (22 in total), DocC API guide, updated Linux/macOS CI and a WASI cross-build **plus actual runtime-executed public consumer** gate.
- The vendored SwiftSoup 2.14.4 tree is unchanged except for an exact, documented WASI-only NSLock shim; verification reverses that shim and checks original upstream hashes.
- Compatibility note: Swift tools 6.4 and higher Apple deployment floors are **breaking requirements relative to 0.1.1**, even though the existing public API is source-additive.
- Platform qualification is scoped to tested macOS 15 Intel, Linux x86_64 and WASI consumer execution. The optional Xcode 27 Apple cross-build matrix was skipped, not passed. See [release notes](Documentation/Releases/0.2.0.md) and [qualification](Documentation/Qualification/0.2.0.md).


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

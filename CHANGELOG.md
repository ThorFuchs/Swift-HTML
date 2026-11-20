# Changelog

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

# Validation and SwiftMD integration

## Executed checks

On 2026-11-19: Apple Silicon arm64, macOS 27.3, Xcode 27.2,
Apple Swift 6.4.2. `swift test --disable-sandbox` ran 14 independently authored
XCTest cases covering malformed documents, body-context fragments, Unicode,
entities, attributes, comments, selector order and duplicates, selector errors,
live references, mutation, escaping, raw markup and serialization. Nine DOM
integration cases cover direct text including empty and mixed-node content,
UTF-8, entities, whitespace and observed CR/LF behavior; parent and detached
references; attribute-preserving child replacement; text and HTML insertion;
missing-parent errors; table-context parsing; ordered block replacement and a
synthetic post-serialization SVG marker. The marker test does not validate SVG. SwiftPM's
sandbox was disabled because it cannot nest inside this managed environment;
compiler caches were redirected to writable temporary directories. The public
module was compiled with `-swift-version 6`, the backend with `-swift-version 5`.

`swift run --package-path Examples/Consumer` built and ran a clean local
SwiftPM consumer. A second isolated temporary consumer imported both SwiftHTML
and an independently archived upstream SwiftSoup 2.14.4, built both modules,
and executed parse/query operations in each. The independent upstream archive,
including its tests and fixtures, was used only in the temporary experiment;
none was copied into this repository.

The local environment's Docker daemon was unavailable. Linux execution has not
been performed; iOS, other Apple platforms and Windows have not been run. A
cross-build would not establish runtime behavior. No browser or conformance suite
has been run. These tests do not establish complete HTML or CSS conformance.

## Read-only SwiftMD assessment

SwiftMD `main` was inspected at `f413383991f4f572b70d5377d4764a74fb595b18`;
release 1.0.0 was verified locally at `68903e4f0773df52956bf30510969bdd212d7bbd`.
Recheck both before integration. Its optional SwiftMDBlocks adapter currently
uses SwiftSoup 2.11.3 as `SwiftMDSoup`, while its Core's ordinary path preserves
SwiftGFM output byte-for-byte and must remain independent of optional parsers.
SwiftHTML must not depend on SwiftMD. A replacement should be limited to the
optional adapter and remove its private parser only once equivalence is tested.

The public API now covers the required basic operations: `directText()` checks
for exclusively direct text children and returns their concatenated parsed text
without whitespace normalization (or nil for mixed content); `parent` retrieves
the parent element; `setInnerHTML` replaces element children; and
`insertHTMLBefore`, `insertTextBefore`, and `remove` support block replacement.
`text()` remains normalized and must not reconstruct code, TeX, or Mermaid.
Entity decoding and parser behavior mean `directText()` is not original HTML
source bytes. The existing SwiftMD adapter requires an actual migration and its
own regression tests before behavioral equivalence can be claimed.

SwiftMD deliberately handles matching raw HTML as well as Markdown-generated
blocks; do not claim fence provenance. Its validated SVG is inserted as original
bytes after HTML serialization, preserving attributes such as `viewBox`.
Preserve that narrow trust boundary, validation, IDs, and references; generic
raw HTML is not an equivalent SVG safety contract. Compare 2.11.3 and 2.14.4
against SwiftMD's `BlocksTests`, `NodeTests`, `JavaScriptCoreCompilerTests`,
`IntegratedCompilerTests`, and browser test, including real renderer and
byte-identical default-path checks. Run its distribution/consumer tests as well.
No integration has been implemented, run, or claimed here.

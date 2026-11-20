# Validation and SwiftMD integration

## Apple deployment targets: 0.1.1 candidate

The package now declares minimum deployment targets of macOS 10.15, iOS 13,
tvOS 13, watchOS 6, Mac Catalyst 13.1 and visionOS 1. On macOS 27.3 arm64,
Xcode 27.2 and Swift 6.4.2, the backend was typechecked at each declared
minimum, and the full SwiftHTML product built for the iOS, tvOS, watchOS and
visionOS simulators and for Mac Catalyst. The macOS x86_64 minimum was
checked using an explicit compiler target. These are cross-build checks, not
execution on those minimum OS versions or on physical devices.

The Apple CI workflow additionally checks the full package and a normal macOS
15 consumer on a macOS 15 Intel runner with Xcode 16.4 / Swift 6.1.2. It
inspects the backend compiler target and builds the remaining Apple platform
products. Actual hosted run results must be tied to the candidate commit.

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

On 2026-11-19, the exact SwiftHTML commit
`8bc39e2bd950c89f79fcb006ec552edee0926a2e` was also executed natively on Linux
ARM64 inside an Ubuntu 24.04.5 container using Swift 6.2.4
(`aarch64-unknown-linux-gnu`). The image was `swift:6.2.4`, manifest digest
`sha256:3459518b2e723a7c363d0f8cfa44fc796c77ecd8c18e92fd10e6f92dd78c0b12`.
Its Docker host was an Ubuntu 24.04.4 ARM64 Colima 0.10.3 VM on Apple Silicon,
with Linux kernel 6.8.0-117-generic, Docker Engine 29.5.2, four CPUs and 8 GiB
RAM. Debug and release each passed all 14 XCTest cases; `swift build -c release`
and the release example consumer also succeeded. Release commands used
`-Xswiftc -no-whole-module-optimization`. Python 3 was installed in the
temporary container for the vendored-source verification, which passed.

The first consumer attempt failed when the checkout was named `/work`: the
example's path dependency currently assumes the directory name `Swift-HTML`.
It passed in a clean `/work/Swift-HTML` checkout. The later release-preparation
change assigns an explicit local dependency name so the example no longer depends
on the checkout directory name; the release-preparation candidate was then
tested from a renamed checkout as described below.

At that point Linux x86-64, iOS, other Apple platforms and Windows had not
been run by this package's test suite. A cross-build would not establish runtime behavior. No
browser or conformance suite has been run for SwiftHTML itself. These tests do
not establish complete HTML or CSS conformance.

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

## SwiftMD cross-project Linux run

On 2026-11-19, local SwiftMD commit
`7b47a5a3c2660732fc408396ff79c3ea3370ac13` and SwiftHTML commit
`8bc39e2bd950c89f79fcb006ec552edee0926a2e` were cloned from local Git bundles
into a separate Linux ARM64 container using the environment above. Node 24.22.1
was checked against the official SHA-256 list. `Scripts/test-all.sh` passed:
704 fixture expectations, 705 comparisons against independently built pinned
cmark-gfm, 22 Linux adapter tests, seven CLI tests, five Linux limit tests and
14 supervisor tests. Its published-GFM audit confirmed documented baseline
mismatches; it does not establish complete conformance.

The release CLI build and seven CLI tests passed. The mirror policy and
local distribution tests passed, including a consumer and coexistence with
separate SwiftSoup. Distribution tags were synthetic and remained local to the
container. JavaScriptCore, browser rendering, Linux x86-64, systemd and cgroup
behavior were not tested in this run. No artifacts were published.

## Release-preparation candidate

On 2026-11-19, commit `1adc3d1801cb27756b14eb272ac8054c070d5784` was tested
on macOS arm64 with Apple Swift 6.4.2: all 14 tests, the release library build,
and a clean version-based consumer passed. The consumer verified both bundled
third-party notices byte for byte. On the Linux ARM64 environment described
above, the same commit passed upstream and notice verification, 14 debug tests,
a release build, 14 release tests, and a release consumer from a deliberately
renamed checkout. A separate version-based consumer also passed and verified
the packaged MIT resources and Apache source license.

Both versioned consumers used a fresh temporary bare Git clone with a synthetic
local-only `0.0.1` tag. This is a distribution mechanism test, not a published
version, a GitHub download test, or a release. At the time of that check the
private GitHub repository was empty, so hosted CI and publicly resolved version
tags had not yet been tested. The prepared Linux workflow pins the same
multi-architecture Swift image digest. No final app archive or binary-only
redistribution was tested for this candidate.

Commit `9ccb0f058c12c4a00d9b78585de2d06c01e0f672` was tested on Linux ARM64
with the same Swift 6.2.4 image: source and notice verification, 14 debug tests,
a release build, 14 release tests, a consumer from a renamed checkout, and the
synthetic local-version consumer all passed. The versioned consumer also passed
on macOS arm64 with Swift 6.4.2. The only changes from the prior candidate were
the changelog, documentation and a pinned CI image.

The same commit was additionally exercised as Linux x86-64 **under QEMU
emulation**, not on a native x86-64 host. Fourteen debug tests and the release
library build passed. The first release-test build with two parallel jobs ended
in a Swift compiler signal 4 without a usable backtrace. A clean retry with one
job passed all 14 release tests. The cause of the first failure is unknown;
a native GitHub x86-64 CI run and a real public versioned consumer were still
needed at that point. The x86-64 versioned consumer
was not run in this emulated check.

## Initial hosted CI run

The first GitHub Linux x86-64 run for commit
`89e0f8e3b2fdec5ca6cff152cef35aae1ba74cca` passed debug tests, release build,
release tests and the release consumer, but its final versioned-consumer gate
failed because the container ran as a different owner from the host checkout.
The test harness now scopes Git's `safe.directory` setting to the current
checkout and its `.git` directory for its subprocesses, without changing global
Git configuration. See the repository’s GitHub Actions runs for the corrected
commit’s result.

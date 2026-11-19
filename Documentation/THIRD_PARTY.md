# Third-party provenance

The backend is derived from [SwiftSoup 2.14.4](https://github.com/scinfu/SwiftSoup/tree/8397a860c6955924b584c50c5265c6aac0970015),
commit `8397a860c6955924b584c50c5265c6aac0970015`, `Sources` tree
`f8472ba94c5dd20e84cc531ff046e7ad1029cdfa`. Its MIT license, including
Jonathan Hedley's jsoup copyright and Nabil Chatbi's Swift-port copyright, is
preserved at [Vendor/SwiftSoup/LICENSE](../Vendor/SwiftSoup/LICENSE). The
source also contains the MIT notice for Nick Lockwood's LRUCache in that file.
Retain all source-level notices when redistributing.

Only upstream `Sources` and `LICENSE` are included, not upstream tests or their
third-party webpage fixtures. `UPSTREAM.json` contains original hashes. Four
Swift files have the upstream module qualification `SwiftSoup.` replaced with
`SwiftHTMLBackend.` to allow an independently supplied SwiftSoup to coexist.
This includes occurrences in comments. No other upstream bytes are changed.

```sh
python3 Scripts/verify-upstream.py
python3 Scripts/verify-upstream.py --reference /path/to/swiftsoup-git-checkout
```

The verifier reverses that exact, counted replacement, checks all original
hashes and the file inventory, and optionally compares the pinned Git tree and
file contents. On 2026-11-19, `git ls-remote` showed the public `2.14.4` tag
at the pinned commit; the pinned upstream `Package.swift` has no external
package dependencies. Checksums and a license inventory are not a legal review
or security audit. This repository does not yet specify a license for its own
new code; the upstream license does not establish one.

# Third-party provenance

The backend is derived from [SwiftSoup 2.14.4](https://github.com/scinfu/SwiftSoup/tree/8397a860c6955924b584c50c5265c6aac0970015),
commit `8397a860c6955924b584c50c5265c6aac0970015`, `Sources` tree
`f8472ba94c5dd20e84cc531ff046e7ad1029cdfa`. Its MIT license, including
Jonathan Hedley's jsoup copyright and Nabil Chatbi's Swift-port copyright, is
preserved at [Vendor/SwiftSoup/LICENSE](../Vendor/SwiftSoup/LICENSE). The
source also contains the MIT notice for Nick Lockwood's LRUCache in that file.
Complete copies of both notices are also packaged as SwiftPM resources under
[ThirdPartyLicenses](../Sources/SwiftHTML/Resources/ThirdPartyLicenses). Run
`python3 Scripts/verify-notices.py` to check their contents against the vendor
files. Retain the original source-level notices when redistributing.

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
or security audit. SwiftHTML's own code is licensed under Apache 2.0; the
upstream MIT terms remain applicable to the vendored code.

SwiftPM resource bundles are a useful way to carry notices into ordinary
consumers, and a versioned consumer test checks their bytes in the generated
build products. A raw static library, standalone executable, container image,
or repackaged app can be distributed without those resource bundles: distributors
must include the complete applicable license notices with each artifact and
verify the final package. This inventory is not a substitute for a legal review.

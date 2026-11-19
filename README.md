# SwiftHTML

SwiftHTML is an independently developed Swift package planned around the
fixture-free source snapshot of SwiftSoup 2.14.4. The goal is a focused, modern
API for parsing, querying and editing HTML with transparent trust boundaries.

This is a preparation snapshot: the SwiftHTML API, package manifest and tests
have **not** been implemented yet. See [BRIEFING.md](BRIEFING.md) for the
implementation and validation scope.

`Vendor/SwiftSoup` contains the original upstream `Sources` and MIT `LICENSE`,
without upstream tests or test fixtures. `UPSTREAM.json` records the exact tag,
commit, source tree and SHA-256 of each imported file. Verify the snapshot with:

```sh
python3 Scripts/verify-upstream.py
python3 Scripts/verify-upstream.py --reference /path/to/swiftsoup-git-checkout
```

The optional reference comparison needs a Git checkout with the pinned commit
and objects available. A checksum check is provenance evidence, not a legal or
security audit. Original SwiftSoup and jsoup copyright notices must be retained.

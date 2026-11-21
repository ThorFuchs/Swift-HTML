#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Check release identity and documentation; not a substitute for native tests."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def require(path: str, *needles: str) -> None:
    value = (ROOT / path).read_text(encoding="utf-8")
    for needle in needles:
        if needle not in value:
            raise ValueError(f"{path}: missing release contract marker: {needle!r}")


def main() -> None:
    require(
        "Package.swift",
        "// swift-tools-version: 6.4", ".macOS(.v15)", ".iOS(.v15)",
        ".tvOS(.v15)", ".watchOS(.v9)", '.macCatalyst("15.0")',
        ".visionOS(.v1)", '.swiftLanguageMode(.v6)', '.swiftLanguageMode(.v5)',
    )
    require("Scripts/build-docc.sh", "version=${4:-0.2.0}", '--fallback-bundle-version "$version"')
    require("CHANGELOG.md", "## 0.2.0", "Swift tools 6.4", "WASI")
    require(
        "README.md", "Typed structural DOM (0.2.0)", "Swift tools 6.4", "WASI",
        "Documentation/Releases/0.2.0.md", "Documentation/Qualification/0.2.0.md",
    )
    require("Sources/SwiftHTML/SwiftHTML.docc/SwiftHTML.md", "<doc:StructuralDOM>", "``HTMLNode``")
    require("Sources/SwiftHTML/SwiftHTML.docc/GettingStarted.md", "Swift tools 6.4", "macOS 15")
    require("Sources/SwiftHTML/SwiftHTML.docc/StructuralDOM.md", "0.2.0", "postparse", "WASI")
    require("Sources/SwiftHTML/SwiftHTML.docc/SafetyAndOwnership.md", "0.2.0", "non-Sendable")
    require("Documentation/VALIDATION.md", "Current release line: SwiftHTML 0.2.0", "historical")
    require("Documentation/THIRD_PARTY.md", "WASI", "NSLock", "MIT")
    require("Documentation/Releases/0.2.0.md", "0.2.0", "macOS 15", "Linux", "WASI", "MIT")
    require("Documentation/Releases/0.2.0-PUBLISHING.md", "0.2.0", "SHA", "tag", "Research Explorer")
    require("Documentation/Qualification/0.2.0.md",
            "8a1d75b206d87538dda2be304365e5a50bf0bf31",
            "44916317312", "44916317402", "44916317296", "44916317332")
    for filename in ("SwiftSoup-MIT.txt", "LRUCache-MIT.txt"):
        if not (ROOT / "Sources/SwiftHTML/Resources/ThirdPartyLicenses" / filename).is_file():
            raise ValueError(f"Missing bundled third-party notice: {filename}")
    if not (ROOT / "Vendor/SwiftSoup/UPSTREAM.json").is_file():
        raise ValueError("Missing auditable vendored source identity")
    print("SwiftHTML 0.2.0 release documentation consistency passed.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError) as error:
        print(f"Release documentation check failed: {error}", file=sys.stderr)
        sys.exit(1)

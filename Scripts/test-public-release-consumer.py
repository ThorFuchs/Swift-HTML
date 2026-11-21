#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Resolve the real public SwiftHTML 0.2.0 tag in a fresh external SwiftPM consumer.

Unlike test-versioned-consumer.py, this test NEVER creates a synthetic tag
or a local SwiftPM mirror. Git and SwiftPM fetch from the public GitHub URL.
"""
import json
from pathlib import Path
import subprocess
import sys
import tempfile

URL = "https://github.com/ThorFuchs/Swift-HTML.git"
VERSION = "0.2.0"
EXPECTED_REVISION = "9e5922e19fb45d3c97c72a57cca58adb2f799c78"


def run(*args: str, cwd: Path | None = None, capture: bool = False) -> str:
    result = subprocess.run(
        args, cwd=cwd, check=True, text=True,
        stdout=subprocess.PIPE if capture else None,
    )
    return result.stdout or ""


def main() -> None:
    # Verify the remote, public Git ref rather than relying on a local tag.
    tag = run("git", "ls-remote", "--refs", URL, f"refs/tags/{VERSION}", capture=True).strip()
    fields = tag.split()
    if len(fields) != 2 or fields[1] != f"refs/tags/{VERSION}":
        raise ValueError(f"Unexpected public Git tag response: {tag!r}")
    if fields[0] != EXPECTED_REVISION:
        raise ValueError(f"Public {VERSION} tag moved or points to wrong commit: {fields[0]}")

    with tempfile.TemporaryDirectory(prefix="swifthtml-public-release-") as temporary:
        consumer = Path(temporary) / "Consumer"
        (consumer / "Sources/Consumer").mkdir(parents=True)
        (consumer / "Package.swift").write_text(
            '''// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "SwiftHTMLPublicConsumer",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/ThorFuchs/Swift-HTML.git", exact: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "Consumer",
            dependencies: [.product(name: "SwiftHTML", package: "Swift-HTML")]
        )
    ]
)
''', encoding="utf-8",
        )
        (consumer / "Sources/Consumer/main.swift").write_text(
            r'''import SwiftHTML

let doc = try HTMLDocument.parseFragment(
    "<section>before &amp; <b>bold</b> after<!--note--></section>"
)
guard let section = try doc.select("section").first else {
    fatalError("Missing parsed section")
}
let nodes = try section.node.children(maximumCount: 4)
precondition(nodes.map(\.kind) == [.text, .element, .text, .comment])
precondition(nodes[0].wholeText == "before & ")
precondition(nodes[1].element?.tagName == "b")
precondition(nodes[2].wholeText == " after")
precondition(nodes[3].commentText == "note")

let limits = try HTMLTraversalLimits(maximumNodes: 6, maximumDepth: 2)
let report = try section.node.walk(limits: limits) { _, _ in }
precondition(report.visitedNodes == 6)
precondition(report.maximumDepth == 2)

try section.setAttribute("data-verified", value: "yes")
let html = try doc.body!.innerHTML()
precondition(html.contains("data-verified=\"yes\""))
print("Public SwiftHTML 0.2.0 consumer passed")
''', encoding="utf-8",
        )

        # SwiftPM must fetch from GitHub; no path dependency or local Git tag.
        run("swift", "run", "--package-path", str(consumer), "-j", "2", "Consumer")
        resolved_path = consumer / "Package.resolved"
        resolved = json.loads(resolved_path.read_text(encoding="utf-8"))
        pins = resolved.get("pins", [])
        matches = [
            pin for pin in pins
            if pin.get("identity", "").lower() == "swift-html"
            or pin.get("location", "").lower().rstrip("/") == URL.lower()
        ]
        if len(matches) != 1:
            raise ValueError(f"Expected one Swift-HTML pin, got {matches!r}")
        state = matches[0].get("state", {})
        if state.get("version") != VERSION or state.get("revision") != EXPECTED_REVISION:
            raise ValueError(f"Public SwiftPM resolved the wrong version/revision: {state!r}")

        checkouts = consumer / ".build/checkouts"
        matches = []
        for directory in checkouts.iterdir():
            if not directory.is_dir():
                continue
            try:
                revision = run("git", "-C", str(directory), "rev-parse", "HEAD", capture=True).strip()
            except subprocess.CalledProcessError:
                continue
            if revision == EXPECTED_REVISION:
                matches.append(directory)
        if len(matches) != 1:
            raise ValueError(f"Expected one public Swift-HTML checkout at {EXPECTED_REVISION}")
        checkout = matches[0]
        if not (checkout / "LICENSE").is_file():
            raise ValueError("Public source checkout missing Apache-2.0 LICENSE")
        for part in ("Sources", "LICENSE", "UPSTREAM.json"):
            if not (checkout / "Vendor/SwiftSoup" / part).exists():
                raise ValueError(f"Public source missing vendored provenance component {part}")
        if (checkout / "Vendor/SwiftSoup/Tests").exists():
            raise ValueError("Unexpected upstream SwiftSoup tests in released source")

        binary_path = Path(run(
            "swift", "build", "--package-path", str(consumer),
            "--show-bin-path", capture=True,
        ).strip())
        for filename in ("SwiftSoup-MIT.txt", "LRUCache-MIT.txt"):
            notice = checkout / "Sources/SwiftHTML/Resources/ThirdPartyLicenses" / filename
            if not notice.is_file():
                raise ValueError(f"Missing source notice: {filename}")
            expected = notice.read_bytes()
            copies = [p for p in binary_path.rglob(filename)
                      if p.is_file() and p.read_bytes() == expected]
            if not copies:
                raise ValueError(f"Built public consumer missing matching MIT notice: {filename}")

        print(
            f"PUBLIC RELEASE VERIFIED: {URL} tag {VERSION} -> {EXPECTED_REVISION}; "
            "SwiftPM resolution, runtime structural DOM and MIT resource copies passed.",
            flush=True,
        )


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"Public SwiftHTML release consumer FAILED: {error}", file=sys.stderr)
        sys.exit(1)

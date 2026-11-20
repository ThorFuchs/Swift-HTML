#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Test an exact revision with a synthetic version in an isolated local repository."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = '0.0.1'  # Synthetic, in the temporary repository only; not a release.


def run(*args, cwd=None, capture=False):
    # GitHub Actions checks out on the host but runs the job as container root.
    # Scope trust to this checkout and its upload-pack directory for child Git
    # processes; do not change global Git configuration or trust other paths.
    env = os.environ.copy()
    index = int(env.get('GIT_CONFIG_COUNT', '0'))
    for path in (ROOT, ROOT / '.git'):
        env[f'GIT_CONFIG_KEY_{index}'] = 'safe.directory'
        env[f'GIT_CONFIG_VALUE_{index}'] = str(path)
        index += 1
    env['GIT_CONFIG_COUNT'] = str(index)
    return subprocess.run(args, cwd=cwd, check=True, text=True, env=env,
                          stdout=subprocess.PIPE if capture else None).stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('revision', help='Git revision to test')
    parser.add_argument('--disable-sandbox', action='store_true',
                        help='Disable SwiftPM sandbox only when the host cannot nest sandboxes')
    args = parser.parse_args()
    revision = run('git', '-C', str(ROOT), 'rev-parse', '--verify', args.revision + '^{commit}', capture=True).strip()
    with tempfile.TemporaryDirectory(prefix='swifthtml-versioned-consumer-') as temp:
        root = Path(temp)
        repository = root / 'Swift-HTML.git'
        run('git', 'clone', '--quiet', '--bare', '--no-hardlinks', str(ROOT), str(repository))
        existing = run('git', '-C', str(repository), 'tag', '--list', VERSION, capture=True).strip()
        if existing:
            raise ValueError(f'test repository already contains tag {VERSION}; refusing to replace it')
        run('git', '-C', str(repository), 'tag', VERSION, revision)
        consumer = root / 'consumer'
        (consumer / 'Sources/Consumer').mkdir(parents=True)
        (consumer / 'Package.swift').write_text('''// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "Consumer", platforms: [.macOS(.v10_15)], dependencies: [
    .package(url: "%s", exact: "%s")
], targets: [.executableTarget(name: "Consumer", dependencies: [
    .product(name: "SwiftHTML", package: "Swift-HTML")
])])
''' % (repository.as_uri(), VERSION))
        (consumer / 'Sources/Consumer/main.swift').write_text('''import SwiftHTML
let document = try HTMLDocument.parseFragment("<pre><code>A  &amp; B\\n</code></pre>")
let code = try document.select("pre > code").first!
precondition(code.directText() == "A  & B\\n")
print("Versioned consumer passed")
''')
        options = ['--disable-sandbox'] if args.disable_sandbox else []
        run('swift', 'run', *options, '--package-path', str(consumer), 'Consumer')
        bin_path = Path(run('swift', 'build', *options, '--package-path', str(consumer),
                            '--show-bin-path', capture=True).strip())
        license_at_revision = subprocess.check_output(['git', '-C', str(repository), 'show', revision + ':LICENSE'])
        checkouts = consumer / '.build/checkouts'
        if not any(p.is_file() and p.read_bytes() == license_at_revision for p in checkouts.glob('*/LICENSE')):
            raise ValueError('versioned source checkout is missing the package license')
        for filename in ('SwiftSoup-MIT.txt', 'LRUCache-MIT.txt'):
            expected_at_revision = subprocess.check_output(['git', '-C', str(repository), 'show',
                revision + ':Sources/SwiftHTML/Resources/ThirdPartyLicenses/' + filename])
            matches = [p for p in bin_path.rglob(filename) if p.is_file() and p.read_bytes() == expected_at_revision]
            if not matches:
                raise ValueError(f'compiled consumer does not contain the expected resource: {filename}')
        print(f'Exact local revision {revision} passed with synthetic local-only tag {VERSION}; bundled notices verified', flush=True)


if __name__ == '__main__':
    main()

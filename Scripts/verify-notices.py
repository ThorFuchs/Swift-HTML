#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Verify bundled third-party license texts against the vendored sources."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / 'Sources/SwiftHTML/Resources/ThirdPartyLicenses'


def main():
    swift_soup = (ROOT / 'Vendor/SwiftSoup/LICENSE').read_bytes()
    if (RESOURCES / 'SwiftSoup-MIT.txt').read_bytes() != swift_soup:
        raise ValueError('SwiftSoup MIT resource differs from its vendored license')
    source = (ROOT / 'Vendor/SwiftSoup/Sources/LRUCache.swift').read_text(encoding='utf-8')
    start = source.index('//  Copyright © 2021 Nick Lockwood. All rights reserved.')
    end = source.index('//  IN THE SOFTWARE.', start) + len('//  IN THE SOFTWARE.')
    lines = source[start:end].splitlines()
    if not all(line == '//' or line.startswith('//  ') for line in lines):
        raise ValueError('unexpected LRUCache license comment format')
    expected = '\n'.join('' if line == '//' else line[4:] for line in lines) + '\n'
    if (RESOURCES / 'LRUCache-MIT.txt').read_text(encoding='utf-8') != expected:
        raise ValueError('LRUCache MIT resource differs from the vendored notice')
    print('Bundled SwiftSoup/jsoup and LRUCache MIT notices match vendored sources')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError) as error:
        print(f'Notice verification failed: {error}', file=sys.stderr)
        sys.exit(1)

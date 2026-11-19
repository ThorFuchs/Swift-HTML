#!/usr/bin/env python3
"""Check the pinned, fixture-free SwiftSoup snapshot; optionally compare Git."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
VENDOR = ROOT / 'Vendor/SwiftSoup'
REVISION = '8397a860c6955924b584c50c5265c6aac0970015'
TREE = 'f8472ba94c5dd20e84cc531ff046e7ad1029cdfa'


def verify(reference):
    info = json.loads((VENDOR / 'UPSTREAM.json').read_text(encoding='utf-8'))
    if (info.get('repository'), info.get('tag'), info.get('commit'), info.get('sources_tree'),
            info.get('transformations')) != ('https://github.com/scinfu/SwiftSoup.git',
                                             '2.14.4', REVISION, TREE, [{
                                                 'description': 'Replace module qualification SwiftSoup. with SwiftHTMLBackend. for isolated target',
                                                 'files_and_counts': {'Sources/Attributes.swift': 8, 'Sources/Token.swift': 7, 'Sources/XmlTreeBuilder.swift': 2, 'Sources/SwiftSoup.swift': 3}
                                             }]):
        raise ValueError('unexpected upstream identity or modifications')
    expected = info['files_sha256']
    if len(expected) != 64 or 'LICENSE' not in expected:
        raise ValueError('unexpected source inventory')
    entries = list(VENDOR.rglob('*'))
    if any(p.is_symlink() for p in entries):
        raise ValueError('symbolic links are not permitted')
    actual = {p.relative_to(VENDOR).as_posix() for p in entries if p.is_file()}
    if actual != set(expected) | {'UPSTREAM.json'}:
        raise ValueError('unexpected or missing source files')
    if reference:
        def git(*args):
            return subprocess.check_output(['git', '-C', str(reference), *args])
        if git('rev-parse', REVISION + ':Sources').decode().strip() != TREE:
            raise ValueError('upstream source tree does not match')
        listing = git('ls-tree', '-r', '--name-only', '-z', REVISION, '--', 'Sources', 'LICENSE')
        if {p.decode() for p in listing.split(b'\0') if p} != set(expected):
            raise ValueError('upstream source inventory does not match')
    for name, digest in expected.items():
        path = Path(name)
        if path.is_absolute() or '..' in path.parts or not (name == 'LICENSE' or name.startswith('Sources/')):
            raise ValueError(f'forbidden path: {name}')
        data = (VENDOR / path).read_bytes()
        counts = info['transformations'][0]['files_and_counts']
        if name in counts:
            if data.count(b'SwiftHTMLBackend.') != counts[name] or b'SwiftSoup.' in data:
                raise ValueError(f'unexpected transformation: {name}')
            data = data.replace(b'SwiftHTMLBackend.', b'SwiftSoup.')
        if hashlib.sha256(data).hexdigest() != digest:
            raise ValueError(f'checksum mismatch: {name}')
        if reference and git('show', REVISION + ':' + name) != data:
            raise ValueError(f'upstream bytes differ: {name}')
    print(f'SwiftSoup {info["tag"]}: {len(expected)} upstream files verified after reversing documented module renaming; '
          f'independent Git comparison: {bool(reference)}; no upstream test fixtures')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reference', type=Path)
    args = parser.parse_args()
    try:
        verify(args.reference)
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print(f'Verification failed: {error}', file=sys.stderr)
        sys.exit(1)

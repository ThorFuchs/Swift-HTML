#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Verify the actual SwiftHTML backend target in a verbose Intel SwiftPM build."""
import re
import sys
from pathlib import Path

log = Path(sys.argv[1]).read_text(encoding='utf-8', errors='replace')
commands = [line for line in log.splitlines()
            if 'swiftc' in line and '-module-name SwiftHTMLBackend' in line]
if not commands:
    raise SystemExit('No SwiftHTMLBackend compiler command found; build must be fresh and verbose')
for command in commands:
    targets = re.findall(r'-target\s+(x86_64-apple-macosx?(\d+)\.(\d+)(?:\.\d+)?)', command)
    if not targets:
        raise SystemExit('SwiftHTMLBackend compiler command has no Intel macOS target')
    target, major, minor = targets[-1]
    if not ((10, 15) <= (int(major), int(minor)) <= (15, 0)):
        raise SystemExit(f'Unexpected SwiftHTMLBackend deployment target: {target}')
    print(f'SwiftHTMLBackend compiler target verified: {target}')

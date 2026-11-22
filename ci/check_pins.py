"""Fail loudly if what was checked out or resolved is not what the workflow pins.

Usage:
  python3 ci/check_pins.py --toolchain-file PATH --expect-toolchain VALUE
                           [--git-dir PATH --expect-git SHA]
                           [--manifest PATH --expect-package NAME=REV ...]
Every check prints one line "OK ..." or "MISMATCH ...". Exit code 1 on any mismatch.
"""
import argparse
import json
import subprocess
import sys


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--toolchain-file', required=True)
    p.add_argument('--expect-toolchain', required=True)
    p.add_argument('--git-dir')
    p.add_argument('--expect-git')
    p.add_argument('--manifest')
    p.add_argument('--expect-package', action='append', default=[])
    a = p.parse_args()
    bad = 0

    with open(a.toolchain_file, encoding='utf-8') as f:
        tc = f.read().strip()
    ok = tc == a.expect_toolchain
    bad += not ok
    print(('OK' if ok else 'MISMATCH'), 'toolchain', a.toolchain_file, repr(tc), 'expected', repr(a.expect_toolchain))

    if a.git_dir:
        head = subprocess.run(['git', '-C', a.git_dir, 'rev-parse', 'HEAD'],
                              capture_output=True, text=True, check=True).stdout.strip()
        ok = head == a.expect_git
        bad += not ok
        print(('OK' if ok else 'MISMATCH'), 'git HEAD', a.git_dir, head, 'expected', a.expect_git)

    if a.manifest:
        with open(a.manifest, encoding='utf-8') as f:
            pkgs = {q['name']: q.get('rev') for q in json.load(f).get('packages', [])}
        for spec in a.expect_package:
            name, rev = spec.split('=', 1)
            got = pkgs.get(name)
            ok = got == rev
            bad += not ok
            print(('OK' if ok else 'MISMATCH'), 'manifest', a.manifest, name, got, 'expected', rev)

    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()

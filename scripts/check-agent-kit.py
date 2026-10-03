#!/usr/bin/env python3
"""Verify vendored kit files against the checked-in adoption manifest."""
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    try:
        lock = json.loads((ROOT / "agents/kit-lock.json").read_text())
        if lock["repository"] != "cesarg88/agent-engineering-kit" or not re.fullmatch(r"[0-9a-f]{40}", lock["commit"]):
            raise ValueError("invalid kit provenance")
        entries = lock["files"]
        if not entries:
            raise ValueError("empty kit manifest")
        seen = set()
        for entry in entries:
            target = entry["target"]
            path = (ROOT / target).resolve()
            if path == ROOT or ROOT not in path.parents or target in seen:
                raise ValueError("invalid or duplicate kit target")
            seen.add(target)
            if not re.fullmatch(r"[0-9a-f]{64}", entry["sha256"]):
                raise ValueError("invalid SHA-256")
            if hashlib.sha256(path.read_bytes()).hexdigest() != entry["sha256"]:
                raise ValueError("kit file differs: " + target)
        print(f"Verified {len(entries)} kit files at {lock['commit']}")
        return 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"Kit integrity failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())

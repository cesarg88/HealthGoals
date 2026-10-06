#!/usr/bin/env python3
"""Classify the full PR diff; uncertainty always requires the iOS checks."""
import re
import subprocess
import sys


def documentation_only(base_sha, head_sha):
    if not all(re.fullmatch(r"[0-9a-f]{40}", sha) for sha in (base_sha, head_sha)):
        return False
    try:
        result = subprocess.run(
            ["git", "diff", "--no-ext-diff", "--no-renames", "--name-only", "-z",
             f"{base_sha}...{head_sha}", "--"],
            check=True, capture_output=True,
        )
    except (OSError, subprocess.CalledProcessError):
        print("Unable to classify the PR diff; running iOS checks.", file=sys.stderr)
        return False
    paths = result.stdout.split(b"\0")
    return bool(result.stdout) and all(path.endswith(b".md") for path in paths if path)


if __name__ == "__main__":
    docs_only = len(sys.argv) == 3 and documentation_only(*sys.argv[1:])
    print(f"docs_only={str(docs_only).lower()}")

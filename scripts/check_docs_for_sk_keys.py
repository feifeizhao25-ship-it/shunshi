#!/usr/bin/env python3
"""Fail when docs contain sk- style API keys.

Prints file paths and line numbers only. The matched text is never written
to stdout, stderr, or the process exit message.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


# Long enough to match provider keys (sk- plus 24+ token characters) and to
# ignore placeholders that contain hyphens, such as sk-your-openai-api-key.
SK_KEY = re.compile(r"(?<![A-Za-z0-9])sk-(?:proj-|ant-)?[A-Za-z0-9]{24,}")
TEXT_SUFFIXES = {".md", ".txt", ".rst", ".yml", ".yaml", ".json", ".html", ".csv"}


def find_sk_keys(docs_dir: Path) -> list[str]:
    """Return ``relative/path:line`` locations. Never include key material."""
    if not docs_dir.is_dir():
        return []
    locations: list[str] = []
    for path in sorted(docs_dir.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            continue
        for line_number, line in enumerate(text.splitlines(), 1):
            if SK_KEY.search(line):
                relative = path.relative_to(docs_dir)
                locations.append(f"{relative}:{line_number}")
    return locations


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    root = Path(__file__).resolve().parents[1]
    docs_dir = Path(args[0]) if args else root / "docs"
    locations = find_sk_keys(docs_dir)
    if not locations:
        print(f"No sk- style keys in {docs_dir}")
        return 0
    print(f"sk- style keys are not allowed in docs ({len(locations)} hit(s)):")
    for location in locations:
        print(f"- {location}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

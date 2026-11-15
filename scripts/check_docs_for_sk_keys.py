#!/usr/bin/env python3
"""Fail when docs contain provider API keys.

Prints file paths and line numbers only. The matched text is never written
to stdout, stderr, or the process exit message.

Decodes UTF-8, then GB18030, then latin-1 (a byte-preserving fallback so the
ASCII key regex still runs). A file is never skipped because of its encoding.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


# Long enough to match provider keys (sk- plus 24+ token characters) and to
# ignore placeholders that contain hyphens, such as sk-your-openai-api-key.
SK_KEY = re.compile(r"(?<![A-Za-z0-9])sk-(?:proj-|ant-)?[A-Za-z0-9]{24,}")
# Zhipu-style key: 32 hex characters, a dot, then 16 alphanumeric characters.
ZHIPU_KEY = re.compile(r"(?<![A-Za-z0-9])[0-9a-fA-F]{32}\.[A-Za-z0-9]{16}(?![A-Za-z0-9])")
SK_KEY_BYTES = re.compile(rb"(?<![A-Za-z0-9])sk-(?:proj-|ant-)?[A-Za-z0-9]{24,}")
ZHIPU_KEY_BYTES = re.compile(rb"(?<![A-Za-z0-9])[0-9a-fA-F]{32}\.[A-Za-z0-9]{16}(?![A-Za-z0-9])")
TEXT_SUFFIXES = {".md", ".txt", ".rst", ".yml", ".yaml", ".json", ".html", ".csv"}


def _decoded_lines(data: bytes) -> tuple[list[str], set[int]]:
    """UTF-8, then GB18030. Otherwise latin-1 plus a bytes regex.

    The third step never skips the file: latin-1 accepts every byte, and the
    bytes regex reports line numbers for ASCII key material on its own.
    """
    for encoding in ("utf-8", "gb18030"):
        try:
            return data.decode(encoding).splitlines(), set()
        except UnicodeError:
            continue
    byte_hits = {
        number
        for number, line in enumerate(data.splitlines(), 1)
        if SK_KEY_BYTES.search(line) or ZHIPU_KEY_BYTES.search(line)
    }
    return [line.decode("latin-1") for line in data.splitlines()], byte_hits


def _line_has_key(line: str) -> bool:
    return SK_KEY.search(line) is not None or ZHIPU_KEY.search(line) is not None


def find_sk_keys(docs_dir: Path) -> list[str]:
    """Return ``relative/path:line`` locations. Never include key material."""
    if not docs_dir.is_dir():
        return []
    locations: list[str] = []
    for path in sorted(docs_dir.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        try:
            data = path.read_bytes()
        except OSError:
            continue
        relative = path.relative_to(docs_dir)
        lines, byte_hits = _decoded_lines(data)
        for line_number, line in enumerate(lines, 1):
            if line_number in byte_hits or _line_has_key(line):
                locations.append(f"{relative}:{line_number}")
    return locations


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    root = Path(__file__).resolve().parents[1]
    docs_dir = Path(args[0]) if args else root / "docs"
    locations = find_sk_keys(docs_dir)
    if not locations:
        print(f"No provider keys in {docs_dir}")
        return 0
    print(f"Provider keys are not allowed in docs ({len(locations)} hit(s)):")
    for location in locations:
        print(f"- {location}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Missing i18n keys fall back to English at runtime and fail this build gate.

Also rejects the Japanese loading leftover and fullwidth colons in localization tables.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APPS = ("android-cn", "android-global")
KEY = re.compile(r"""(?:\.t|\.get)\(\s*'([A-Za-z][A-Za-z0-9_]*)'""")
EN_BLOCK = re.compile(r"'en'\s*:\s*\{(.*?)\n    \}", re.S)
EN_KEY = re.compile(r"'([A-Za-z][A-Za-z0-9_]*)'\s*:")


def en_keys(text: str) -> set[str]:
    match = EN_BLOCK.search(text)
    if not match:
        return set()
    return set(EN_KEY.findall(match.group(1)))


def main() -> int:
    extra = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1].startswith("--require-key=") else ""
    required = extra.split("=", 1)[1] if extra else ""
    errors: list[str] = []
    for app in APPS:
        loc = ROOT / app / "lib/core/theme/app_localizations.dart"
        text = loc.read_text(encoding="utf-8")
        if "読み込み中" in text:
            errors.append(f"{loc}: Japanese loading leftover")
        if "：" in text:
            errors.append(f"{loc}: fullwidth colon in localization table")
        known = en_keys(text)
        if not known:
            errors.append(f"{loc}: no English table")
            continue
        if required and required not in known:
            errors.append(f"{loc}: missing English key {required}")
        for path in (ROOT / app / "lib").rglob("*.dart"):
            for key in KEY.findall(path.read_text(encoding="utf-8")):
                if key not in known:
                    errors.append(f"{path}: missing English key {key}")
    if errors:
        print("i18n gate failed:")
        print("\n".join(errors[:80]))
        print(f"{len(errors)} problem(s)")
        return 1
    print("i18n keys resolve to English and localization tables are clean.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

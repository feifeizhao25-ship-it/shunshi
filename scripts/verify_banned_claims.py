#!/usr/bin/env python3
"""Fail if CN app copy still makes a medical claim.

Scans string-bearing lines in android-cn/lib and ios-cn/lib.
Words: 排毒 祛湿 利尿 消肿 调理 养生顾问 体质诊断.
治疗 is a claim unless the same line is a refusal (不构成 / 不提供 / 不能 / …).
The Baduanjin form name 调理脾胃须单举 is a proper noun, not a claim.

A planted file can be passed with --extra to prove the gate fails closed.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APPS = (ROOT / "android-cn" / "lib", ROOT / "ios-cn" / "lib")
EXEMPT_NAMES = {"safety_filter.dart"}
CLAIM = ("排毒", "祛湿", "利尿", "消肿", "调理", "养生顾问", "体质诊断")
PROPER = "调理脾胃须单举"
TREATMENT_OK = ("不构成", "不提供", "不能", "不可", "并非", "不作", "不是", "禁止", "不得")


def hits(path: Path) -> list[str]:
    found = []
    for i, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.split("//", 1)[0]
        line = line.replace(PROPER, "")
        if any(word in line for word in CLAIM):
            found.append(f"{path}:{i}: {raw.strip()}")
        if "治疗" in line and not any(ok in line for ok in TREATMENT_OK):
            found.append(f"{path}:{i}: {raw.strip()}")
    return found


def scan(extra: list[Path] | None = None) -> list[str]:
    found: list[str] = []
    for root in APPS:
        for path in root.rglob("*.dart"):
            if path.name in EXEMPT_NAMES:
                continue
            found.extend(hits(path))
    for path in extra or []:
        found.extend(hits(path))
    return found


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--extra", action="append", default=[], type=Path)
    args = parser.parse_args()
    found = scan(args.extra)
    if found:
        print("Banned medical-claim copy:")
        print("\n".join(found))
        return 1
    print("CN Dart copy has no banned medical claims.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

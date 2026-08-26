#!/usr/bin/env python3
"""Fail release checks when mobile production code contains clear-text public APIs."""

from pathlib import Path
import re
import sys
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[1]
MOBILE_LIBS = tuple(ROOT / name / "lib" for name in (
    "android-cn", "ios-cn", "android-global", "ios-global"
))
URL_PATTERN = re.compile(r"http://[^\s'\"<>]+")
LOCAL_HOSTS = {"localhost", "127.0.0.1", "10.0.2.2"}
FORBIDDEN_LEGACY_HOST = "116.62.32.43"


def main() -> int:
    errors: list[str] = []
    for lib in MOBILE_LIBS:
        for path in lib.rglob("*.dart"):
            text = path.read_text(encoding="utf-8")
            if FORBIDDEN_LEGACY_HOST in text:
                errors.append(f"{path.relative_to(ROOT)}: legacy public IP is forbidden")
            for match in URL_PATTERN.finditer(text):
                url = match.group(0).rstrip(").,;]")
                host = urlparse(url).hostname
                if host not in LOCAL_HOSTS:
                    errors.append(
                        f"{path.relative_to(ROOT)}: clear-text public URL is forbidden ({host})"
                    )

    if errors:
        print("Mobile network security gate failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("Mobile network security gate passed: production API URLs use HTTPS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

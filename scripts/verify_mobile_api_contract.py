#!/usr/bin/env python3
"""Fail when a mobile release can create missing or duplicated API prefixes."""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
VARIANTS = ("android-cn", "ios-cn", "android-global", "ios-global")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


for variant in VARIANTS:
    config_path = ROOT / variant / "lib/core/config/app_config.dart"
    config = config_path.read_text(encoding="utf-8")
    default_match = re.search(r"defaultValue:\s*'([^']+)'", config)
    require(default_match is not None, f"{variant}: API_BASE_URL default is missing")
    api_origin = default_match.group(1).rstrip("/")
    require("/api/v1" not in api_origin, f"{variant}: API_BASE_URL must be an origin, got {api_origin}")
    require(api_origin.startswith("https://"), f"{variant}: production API origin must use HTTPS")

release = (ROOT / ".github/workflows/release.yml").read_text(encoding="utf-8")
for name in ("CN_API_BASE_URL", "GLOBAL_API_BASE_URL"):
    match = re.search(rf'{name}:\s*"([^"]+)"', release)
    require(match is not None, f"release workflow is missing {name}")
    require("/api/v1" not in match.group(1), f"{name} must be an origin, not a versioned path")

for client in (
    "android-cn/lib/core/network/api_client.dart",
    "android-cn/lib/data/network/api_client.dart",
    "ios-cn/lib/core/network/api_client.dart",
    "android-global/lib/core/network/api_client.dart",
    "ios-global/lib/core/network/api_client.dart",
):
    source = (ROOT / client).read_text(encoding="utf-8")
    require("/api/v1" in source and "startsWith('/api/v1/')" in source, f"{client}: version-prefix normalization missing")

print("Mobile API origin/version contract verified for four variants")

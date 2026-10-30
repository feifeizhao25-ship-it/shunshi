#!/usr/bin/env python3
"""Fail when a mobile release can create missing or duplicated API prefixes."""

from pathlib import Path
import re
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
VARIANTS = ("android-cn", "ios-cn", "android-global", "ios-global")
# Debug/dev builds may default to loopback over http; nothing else may use http.
LOOPBACK_HOSTS = {"127.0.0.1", "localhost"}


def is_loopback_http(origin: str) -> bool:
    parsed = urlparse(origin)
    return parsed.scheme == "http" and parsed.hostname in LOOPBACK_HOSTS


def check_default_origin(variant: str, origin: str) -> None:
    """Default origin: https anywhere, or http only when it is loopback (debug default)."""
    require(
        origin.startswith("https://") or is_loopback_http(origin),
        f"{variant}: API_BASE_URL default must be https or loopback http (127.0.0.1/localhost), got {origin}",
    )


def check_release_origin(name: str, origin: str) -> None:
    """Release origin: https only, never http (loopback included)."""
    require(origin.startswith("https://"), f"{name}: release API origin must use HTTPS, got {origin}")
    require(urlparse(origin).hostname not in LOOPBACK_HOSTS, f"{name}: release API origin must not be loopback")


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
    check_default_origin(variant, api_origin)

release = (ROOT / ".github/workflows/release.yml").read_text(encoding="utf-8")
for name in ("CN_API_BASE_URL", "GLOBAL_API_BASE_URL"):
    match = re.search(rf'{name}:\s*"([^"]+)"', release)
    require(match is not None, f"release workflow is missing {name}")
    require("/api/v1" not in match.group(1), f"{name} must be an origin, not a versioned path")
    check_release_origin(name, match.group(1))

# Every release build must inject the API origin, otherwise the loopback default would ship.
release_steps = re.sub(r"\\\n\s*", " ", release)  # join shell line continuations
release_builds = [line for line in release_steps.splitlines() if "flutter build" in line and "--release" in line]
require(release_builds, "release workflow has no 'flutter build --release' step")
for build in release_builds:
    require("--dart-define=API_BASE_URL=" in build, f"release build must pass --dart-define=API_BASE_URL: {build.strip()}")

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

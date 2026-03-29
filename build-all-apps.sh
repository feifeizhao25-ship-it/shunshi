#!/bin/bash
# =============================================================================
# 顺时 / SEASONS — Flutter Build All Apps
# Builds all 4 app variants using --dart-define for compile-time config.
#
# Usage:
#   ./build-all-apps.sh [TARGET] [MODE]
#
# TARGET (default: all):
#   ios-cn | android-cn | ios-global | android-global | cn | global | all
#
# MODE (default: release):
#   release | debug | profile
#
# Examples:
#   ./build-all-apps.sh all release
#   ./build-all-apps.sh android-cn debug
#   ./build-all-apps.sh cn
#
# Environment overrides:
#   API_BASE_CN       — override CN backend URL
#   API_BASE_GLOBAL   — override Global backend URL
#   OUTPUT_DIR        — override output directory
# =============================================================================

set -euo pipefail

# ─── Colours ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $1"; }
info() { echo -e "${CYAN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# ─── Config ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

API_BASE_CN="${API_BASE_CN:-http://116.62.32.43/api/v1}"
API_BASE_GLOBAL="${API_BASE_GLOBAL:-https://api.seasonsapp.com/api/v1}"

IOS_CN_DIR="ios-cn"
ANDROID_CN_DIR="android-cn"
IOS_GLOBAL_DIR="ios-global"
ANDROID_GLOBAL_DIR="android-global"

OUTPUT_DIR="${OUTPUT_DIR:-./build-output}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "$OUTPUT_DIR"

TARGET="${1:-all}"
MODE="${2:-release}"

# ─── Helpers ─────────────────────────────────────────────────────────────────
check_flutter() {
    if ! command -v flutter &>/dev/null; then
        err "flutter not found in PATH. Please install Flutter and try again."
        exit 1
    fi
    info "Flutter version: $(flutter --version 2>&1 | head -1)"
}

# Run flutter pub get and fail fast if it errors
pub_get() {
    local dir=$1
    log "  Running flutter pub get in $dir..."
    (cd "$dir" && flutter pub get 2>&1 | tail -5) || {
        err "flutter pub get failed in $dir"
        return 1
    }
}

# ─── iOS Build ───────────────────────────────────────────────────────────────
build_ios() {
    local variant=$1   # e.g. ios-cn
    local app_dir=$2
    local output_name=$3
    local api_url=$4

    log ""
    log "=== Building iOS ($variant / $MODE) ==="

    if [[ ! -d "$app_dir" ]]; then
        warn "Directory $app_dir not found — skipping."
        return
    fi

    pub_get "$app_dir"

    local output_path="$OUTPUT_DIR/${output_name}_${TIMESTAMP}.ipa"

    (
        cd "$app_dir"
        flutter build ios "--$MODE" --no-codesign \
            --dart-define=API_BASE_URL="$api_url" \
            --dart-define=APP_VARIANT="$variant" \
            2>&1 | tail -15
    ) || { err "iOS build failed for $variant"; return 1; }

    # Copy artefact (location varies by Xcode version)
    local found=0
    for candidate in \
        "$app_dir/build/ios/iphoneos/Output/Runner.ipa" \
        "$app_dir/build/ios/iphoneos/Runner.app" \
        "$app_dir/build/ios/iphonesimulator/Runner.app"
    do
        if [[ -e "$candidate" ]]; then
            cp -r "$candidate" "$OUTPUT_DIR/" 2>/dev/null && found=1 && break
        fi
    done

    if [[ $found -eq 1 ]]; then
        log "  iOS $variant: ${GREEN}OK${NC}"
    else
        warn "  iOS $variant: build succeeded but output artefact not found (check $app_dir/build/)"
    fi
}

# ─── Android Build ───────────────────────────────────────────────────────────
build_android() {
    local variant=$1
    local app_dir=$2
    local output_name=$3
    local api_url=$4

    log ""
    log "=== Building Android ($variant / $MODE) ==="

    if [[ ! -d "$app_dir" ]]; then
        warn "Directory $app_dir not found — skipping."
        return
    fi

    pub_get "$app_dir"

    (
        cd "$app_dir"

        # AAB (Play Store)
        flutter build appbundle "--$MODE" \
            --dart-define=API_BASE_URL="$api_url" \
            --dart-define=APP_VARIANT="$variant" \
            2>&1 | tail -15

        local aab_src="build/app/outputs/bundle/${MODE}/app-${MODE}.aab"
        [[ -f "$aab_src" ]] || aab_src="build/app/outputs/bundle/release/app.aab"
        if [[ -f "$aab_src" ]]; then
            cp "$aab_src" "$OUTPUT_DIR/${output_name}_${TIMESTAMP}.aab"
            log "  AAB: ${GREEN}OK${NC} → $OUTPUT_DIR/${output_name}_${TIMESTAMP}.aab"
        else
            warn "  AAB not found at expected path"
        fi

        # APK (sideload / QA)
        flutter build apk "--$MODE" \
            --dart-define=API_BASE_URL="$api_url" \
            --dart-define=APP_VARIANT="$variant" \
            2>&1 | tail -15

        local apk_src="build/app/outputs/flutter-apk/app-${MODE}.apk"
        [[ -f "$apk_src" ]] || apk_src="build/app/outputs/flutter-apk/app-release.apk"
        if [[ -f "$apk_src" ]]; then
            cp "$apk_src" "$OUTPUT_DIR/${output_name}_${TIMESTAMP}.apk"
            log "  APK: ${GREEN}OK${NC} → $OUTPUT_DIR/${output_name}_${TIMESTAMP}.apk"
        else
            warn "  APK not found at expected path"
        fi
    ) || { err "Android build failed for $variant"; return 1; }
}

# ─── Per-variant wrappers ─────────────────────────────────────────────────────
do_ios_cn()        { build_ios      "ios-cn"        "$IOS_CN_DIR"        "seasons-ios-cn"        "$API_BASE_CN";     }
do_android_cn()    { build_android  "android-cn"    "$ANDROID_CN_DIR"    "seasons-android-cn"    "$API_BASE_CN";     }
do_ios_global()    { build_ios      "ios-global"    "$IOS_GLOBAL_DIR"    "seasons-ios-global"    "$API_BASE_GLOBAL"; }
do_android_global(){ build_android  "android-global" "$ANDROID_GLOBAL_DIR" "seasons-android-global" "$API_BASE_GLOBAL"; }

# ─── Main ─────────────────────────────────────────────────────────────────────
echo -e ""
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}  顺时 / SEASONS — Build All Apps${NC}"
echo -e "${BOLD}${CYAN}  Target: $TARGET  |  Mode: $MODE${NC}"
echo -e "${BOLD}${CYAN}  Time:   $(date)${NC}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e ""

check_flutter

case "$TARGET" in
  ios-cn)         do_ios_cn ;;
  android-cn)     do_android_cn ;;
  ios-global)     do_ios_global ;;
  android-global) do_android_global ;;
  cn)             do_ios_cn; do_android_cn ;;
  global)         do_ios_global; do_android_global ;;
  all|*)
    do_ios_cn
    do_android_cn
    do_ios_global
    do_android_global
    ;;
esac

echo -e ""
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  Build complete — $TIMESTAMP${NC}"
echo -e "${BOLD}${GREEN}  Output: $OUTPUT_DIR/${NC}"
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════${NC}"
ls -lh "$OUTPUT_DIR/" 2>/dev/null | grep -v "^total" || echo "  (no artefacts copied)"
echo ""

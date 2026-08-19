#!/bin/bash

# run_all_tests.sh - 顺时项目全平台自动化测试脚本
# 支持 iOS 模拟器 + Android 模拟器
# 使用方法: ./scripts/run_all_tests.sh [ios|android|flutter|all]

set -o pipefail

# ===================== 配置 =====================
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_DIR="$PROJECT_ROOT/shunshi_flutter"
REPORT_FILE="$PROJECT_ROOT/FULL_TEST_REPORT.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
IOS_SCHEME="shunshi"
IOS_DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro"
ANDROID_SDK="$HOME/Library/Android/sdk"
ANDROID_EMULATOR="$ANDROID_SDK/emulator/emulator"
ADB="$ANDROID_SDK/platform-tools/adb"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 计数器
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0

# ===================== 工具函数 =====================
log_info()  { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_ok()    { echo -e "${GREEN}✅ $1${NC}"; }
log_warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step()  { echo -e "${CYAN}━━━ $1 ━━━${NC}"; }

# 初始化报告
init_report() {
    cat > "$REPORT_FILE" << EOF
# 🧪 顺时 - 全平台自动化测试报告

> 📅 测试时间: $TIMESTAMP
> 🖥️ 测试环境: macOS $(sw_vers -productVersion)
> ⚙️ Xcode: $(xcodebuild -version 2>/dev/null | head -1 || echo 'N/A')
> 🐦 Flutter: $(flutter --version 2>/dev/null | head -1 || echo 'N/A')

---

EOF
}

# 追加报告内容
append_report() {
    echo "$1" >> "$REPORT_FILE"
}

# ===================== iOS 原生测试 =====================
run_ios_unit_tests() {
    log_step "iOS 原生单元测试 (shunshiTests)"
    
    append_report "## 📱 iOS 原生单元测试"
    append_report ""
    
    local result_bundle="$PROJECT_ROOT/TestResults_Unit.xcresult"
    rm -rf "$result_bundle"
    
    local output
    output=$(xcodebuild test \
        -project "$PROJECT_ROOT/shunshi.xcodeproj" \
        -scheme "$IOS_SCHEME" \
        -destination "$IOS_DESTINATION" \
        -only-testing:shunshiTests \
        -resultBundlePath "$result_bundle" \
        -enableCodeCoverage YES \
        CODE_SIGNING_ALLOWED=NO \
        2>&1)
    
    local exit_code=$?
    
    # 解析结果
    local passed=$(echo "$output" | grep -c "Test Case.*passed" || true)
    local failed=$(echo "$output" | grep -c "Test Case.*failed" || true)
    
    TOTAL_PASS=$((TOTAL_PASS + passed))
    TOTAL_FAIL=$((TOTAL_FAIL + failed))
    
    if [ $exit_code -eq 0 ]; then
        log_ok "iOS 单元测试全部通过 ($passed 通过)"
        append_report "| 状态 | ✅ 通过 |"
    else
        log_error "iOS 单元测试有失败 ($passed 通过, $failed 失败)"
        append_report "| 状态 | ❌ 部分失败 |"
    fi
    
    append_report "|---|---|"
    append_report "| 通过 | $passed |"
    append_report "| 失败 | $failed |"
    append_report ""
    
    # 记录失败的测试
    if [ $failed -gt 0 ]; then
        append_report "### 失败的测试"
        append_report '```'
        echo "$output" | grep "Test Case.*failed" >> "$REPORT_FILE"
        append_report '```'
        append_report ""
    fi
    
    # 显示测试详情
    append_report "<details>"
    append_report "<summary>查看测试详情</summary>"
    append_report ""
    append_report '```'
    echo "$output" | grep -E "(Test Case|Test Suite)" | tail -30 >> "$REPORT_FILE"
    append_report '```'
    append_report "</details>"
    append_report ""
    
    return $exit_code
}

run_ios_ui_tests() {
    log_step "iOS 原生 UI 测试 (shunshiUITests)"
    
    append_report "## 🖥️ iOS 原生 UI 测试"
    append_report ""
    
    local result_bundle="$PROJECT_ROOT/TestResults_UI.xcresult"
    rm -rf "$result_bundle"
    
    local output
    output=$(xcodebuild test \
        -project "$PROJECT_ROOT/shunshi.xcodeproj" \
        -scheme "$IOS_SCHEME" \
        -destination "$IOS_DESTINATION" \
        -only-testing:shunshiUITests \
        -resultBundlePath "$result_bundle" \
        -enableCodeCoverage YES \
        CODE_SIGNING_ALLOWED=NO \
        2>&1)
    
    local exit_code=$?
    
    local passed=$(echo "$output" | grep -c "Test Case.*passed" || true)
    local failed=$(echo "$output" | grep -c "Test Case.*failed" || true)
    
    TOTAL_PASS=$((TOTAL_PASS + passed))
    TOTAL_FAIL=$((TOTAL_FAIL + failed))
    
    if [ $exit_code -eq 0 ]; then
        log_ok "iOS UI 测试全部通过 ($passed 通过)"
        append_report "| 状态 | ✅ 通过 |"
    else
        log_error "iOS UI 测试有失败 ($passed 通过, $failed 失败)"
        append_report "| 状态 | ❌ 部分失败 |"
    fi
    
    append_report "|---|---|"
    append_report "| 通过 | $passed |"
    append_report "| 失败 | $failed |"
    append_report ""
    
    if [ $failed -gt 0 ]; then
        append_report "### 失败的测试"
        append_report '```'
        echo "$output" | grep "Test Case.*failed" >> "$REPORT_FILE"
        append_report '```'
        append_report ""
    fi
    
    append_report "<details>"
    append_report "<summary>查看测试详情</summary>"
    append_report ""
    append_report '```'
    echo "$output" | grep -E "(Test Case|Test Suite)" | tail -30 >> "$REPORT_FILE"
    append_report '```'
    append_report "</details>"
    append_report ""
    
    return $exit_code
}

# ===================== Flutter 测试 =====================
run_flutter_unit_tests() {
    log_step "Flutter 单元测试"
    
    append_report "## 🐦 Flutter 单元测试"
    append_report ""
    
    cd "$FLUTTER_DIR"
    
    local output
    output=$(flutter test --reporter expanded 2>&1)
    local exit_code=$?
    
    local passed=$(echo "$output" | grep -c "✓\|PASSED\|passed" || true)
    local failed=$(echo "$output" | grep -c "✗\|FAILED\|failed" || true)
    
    TOTAL_PASS=$((TOTAL_PASS + passed))
    TOTAL_FAIL=$((TOTAL_FAIL + failed))
    
    if [ $exit_code -eq 0 ]; then
        log_ok "Flutter 单元测试全部通过"
        append_report "| 状态 | ✅ 通过 |"
    else
        log_error "Flutter 单元测试有失败"
        append_report "| 状态 | ❌ 部分失败 |"
    fi
    
    append_report "|---|---|"
    append_report ""
    
    append_report "<details>"
    append_report "<summary>查看测试输出</summary>"
    append_report ""
    append_report '```'
    echo "$output" | tail -40 >> "$REPORT_FILE"
    append_report '```'
    append_report "</details>"
    append_report ""
    
    cd "$PROJECT_ROOT"
    return $exit_code
}

run_flutter_integration_ios() {
    log_step "Flutter 集成测试 (iOS 模拟器)"
    
    append_report "## 📱 Flutter 集成测试 (iOS)"
    append_report ""
    
    cd "$FLUTTER_DIR"
    
    local output
    output=$(flutter test integration_test/app_test.dart \
        -d "iPhone 16 Pro" \
        --reporter expanded \
        2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_ok "Flutter iOS 集成测试通过"
        append_report "| 状态 | ✅ 通过 |"
        TOTAL_PASS=$((TOTAL_PASS + 1))
    else
        log_error "Flutter iOS 集成测试失败"
        append_report "| 状态 | ❌ 失败 |"
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
    fi
    
    append_report "|---|---|"
    append_report "| 平台 | iOS 模拟器 (iPhone 16 Pro) |"
    append_report ""
    
    append_report "<details>"
    append_report "<summary>查看测试输出</summary>"
    append_report ""
    append_report '```'
    echo "$output" | tail -50 >> "$REPORT_FILE"
    append_report '```'
    append_report "</details>"
    append_report ""
    
    cd "$PROJECT_ROOT"
    return $exit_code
}

run_flutter_integration_android() {
    log_step "Flutter 集成测试 (Android 模拟器)"
    
    append_report "## 🤖 Flutter 集成测试 (Android)"
    append_report ""
    
    # 检查 Android 模拟器是否运行
    if ! "$ADB" devices 2>/dev/null | grep -q "emulator"; then
        log_warn "Android 模拟器未运行，正在启动..."
        "$ANDROID_EMULATOR" -avd Medium_Phone_API_36.1 -no-window -no-audio -no-boot-anim &
        EMULATOR_PID=$!
        
        # 等待模拟器启动
        log_info "等待 Android 模拟器启动 (最多 120 秒)..."
        local wait_time=0
        while [ $wait_time -lt 120 ]; do
            if "$ADB" shell getprop sys.boot_completed 2>/dev/null | grep -q "1"; then
                log_ok "Android 模拟器已启动"
                break
            fi
            sleep 5
            wait_time=$((wait_time + 5))
            echo -n "."
        done
        echo ""
        
        if [ $wait_time -ge 120 ]; then
            log_error "Android 模拟器启动超时"
            append_report "| 状态 | ⏰ 模拟器启动超时，跳过 |"
            append_report "|---|---|"
            append_report ""
            TOTAL_SKIP=$((TOTAL_SKIP + 1))
            return 1
        fi
    fi
    
    cd "$FLUTTER_DIR"
    
    local output
    output=$(flutter test integration_test/app_test.dart \
        -d emulator \
        --reporter expanded \
        2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_ok "Flutter Android 集成测试通过"
        append_report "| 状态 | ✅ 通过 |"
        TOTAL_PASS=$((TOTAL_PASS + 1))
    else
        log_error "Flutter Android 集成测试失败"
        append_report "| 状态 | ❌ 失败 |"
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
    fi
    
    append_report "|---|---|"
    append_report "| 平台 | Android 模拟器 (Medium_Phone_API_36) |"
    append_report ""
    
    append_report "<details>"
    append_report "<summary>查看测试输出</summary>"
    append_report ""
    append_report '```'
    echo "$output" | tail -50 >> "$REPORT_FILE"
    append_report '```'
    append_report "</details>"
    append_report ""
    
    cd "$PROJECT_ROOT"
    return $exit_code
}

# ===================== 汇总报告 =====================
generate_summary() {
    append_report "---"
    append_report ""
    append_report "## 📊 测试汇总"
    append_report ""
    append_report "| 指标 | 数量 |"
    append_report "|------|------|"
    append_report "| ✅ 通过 | $TOTAL_PASS |"
    append_report "| ❌ 失败 | $TOTAL_FAIL |"
    append_report "| ⏭️ 跳过 | $TOTAL_SKIP |"
    append_report "| 📝 总计 | $((TOTAL_PASS + TOTAL_FAIL + TOTAL_SKIP)) |"
    append_report ""
    
    if [ $TOTAL_FAIL -eq 0 ]; then
        append_report "> ✅ **所有测试通过！**"
    else
        append_report "> ⚠️ **有 $TOTAL_FAIL 项测试失败，请查看详情。**"
    fi
    
    append_report ""
    append_report "---"
    append_report "_报告生成时间: $TIMESTAMP_"
}

# ===================== 主程序 =====================
main() {
    local mode="${1:-all}"
    
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   🧪 顺时 - 全平台自动化测试          ║"
    echo "║   📅 $TIMESTAMP               ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    init_report
    
    case "$mode" in
        ios)
            run_ios_unit_tests || true
            run_ios_ui_tests || true
            ;;
        android)
            run_flutter_integration_android || true
            ;;
        flutter)
            run_flutter_unit_tests || true
            run_flutter_integration_ios || true
            run_flutter_integration_android || true
            ;;
        all)
            run_ios_unit_tests || true
            run_ios_ui_tests || true
            run_flutter_unit_tests || true
            run_flutter_integration_ios || true
            run_flutter_integration_android || true
            ;;
        *)
            echo "用法: $0 [ios|android|flutter|all]"
            exit 1
            ;;
    esac
    
    generate_summary
    
    echo ""
    log_step "测试完成"
    echo ""
    log_info "📊 测试报告已保存到: $REPORT_FILE"
    log_info "通过: $TOTAL_PASS | 失败: $TOTAL_FAIL | 跳过: $TOTAL_SKIP"
    echo ""
}

main "$@"

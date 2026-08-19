#!/bin/bash

# 顺时App 自动截图脚本
# 通过UI自动化捕获所有主要功能界面

SCREENSHOTS_DIR="Screenshots"
DEVICE_ID="booted"

echo "📱 顺时App 自动截图工具"
echo "=========================="
echo ""

# 创建截图目录
mkdir -p "$SCREENSHOTS_DIR"
echo "📁 截图将保存到: $SCREENSHOTS_DIR"
echo ""

# 等待函数
wait_and_capture() {
    local name=$1
    local wait_time=${2:-2}
    echo "⏱️  等待 ${wait_time}秒..."
    sleep $wait_time
    local filename="${SCREENSHOTS_DIR}/${name}.png"
    xcrun simctl io $DEVICE_ID screenshot "$filename" 2>/dev/null
    echo "✅ 已捕获: $name"
    echo ""
}

echo "🚀 开始截图流程..."
echo ""

# 1. 首页
echo "📸 1. 首页 (Home Screen)"
wait_and_capture "01_home_screen" 3

# 2. 首页滚动后
echo "📸 2. 首页滚动"
osascript << 'EOF'
tell application "Simulator"
    activate
end tell

tell application "System Events"
    keystroke (ASCII character 31) -- Down arrow
    delay 0.5
    keystroke (ASCII character 31)
    delay 0.5
    keystroke (ASCII character 31)
end tell
EOF
wait_and_capture "02_home_scrolled" 1

# 3. 养生Tab
echo "📸 3. 养生页面"
osascript << 'EOF'
tell application "System Events"
    keystroke (ASCII character 30) -- Up arrow (回到顶部)
    delay 0.5
    keystroke (ASCII character 30)
    delay 0.5
end tell
EOF
sleep 1

# 点击养生Tab (使用UI自动化)
osascript << 'EOF'
tell application "Simulator"
    activate
end tell

tell application "System Events"
    -- 点击养生Tab (假设在底部Tab栏第二个位置)
    click at {200, 800} -- 这个坐标可能需要调整
end tell
EOF
wait_and_capture "03_wellness_tab" 2

# 4. AI顾问Tab
echo "📸 4. AI顾问"
osascript << 'EOF'
tell application "System Events"
    click at {300, 800} -- AI顾问Tab
end tell
EOF
wait_and_capture "04_ai_consultant" 3

# 5. 个人中心Tab
echo "📸 5. 个人中心"
osascript << 'EOF'
tell application "System Events"
    click at {400, 800} -- 个人中心Tab
end tell
EOF
wait_and_capture "05_profile" 2

echo ""
echo "✨ 截图完成！"
echo "📂 查看截图: open $SCREENSHOTS_DIR"
echo ""

# 打开截图文件夹
open "$SCREENSHOTS_DIR"

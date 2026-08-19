#!/bin/bash

# 提取Xcode测试截图脚本
# 使用方法: ./extract_screenshots.sh

RESULT_BUNDLE="/tmp/ShunshiScreenshots.xcresult"
OUTPUT_DIR="/Users/feifei00/Documents/shunshi/shunshi/Screenshots"

echo "🔍 开始提取截图..."
echo "📦 测试结果包: $RESULT_BUNDLE"
echo "📁 输出目录: $OUTPUT_DIR"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 获取测试结果的ID
echo ""
echo "📋 获取测试附件列表..."

# 使用xcresulttool获取测试摘要
TEST_REF=$(xcrun xcresulttool get object --legacy --path "$RESULT_BUNDLE" --format json | \
    python3 -c "import sys, json; data=json.load(sys.stdin); print(data['actions']['_values'][0]['actionResult']['testsRef']['id']['_value'])")

if [ -z "$TEST_REF" ]; then
    echo "❌ 无法获取测试引用ID"
    exit 1
fi

echo "✅ 测试引用ID: $TEST_REF"

# 获取测试详情
xcrun xcresulttool get object --legacy --path "$RESULT_BUNDLE" --id "$TEST_REF" --format json > /tmp/test_details.json

# 提取所有附件
echo ""
echo "🖼️  提取截图附件..."

python3 << 'PYTHON_SCRIPT'
import json
import subprocess
import os

with open('/tmp/test_details.json', 'r') as f:
    data = json.load(f)

def find_attachments(obj, attachments=[]):
    if isinstance(obj, dict):
        if obj.get('_type', {}).get('_name') == 'ActionTestAttachment':
            name = obj.get('name', {}).get('_value', 'unknown')
            payload_ref = obj.get('payloadRef', {}).get('id', {}).get('_value')
            if payload_ref and 'Screenshot' in obj.get('uniformTypeIdentifier', {}).get('_value', ''):
                attachments.append({'name': name, 'id': payload_ref})
        for value in obj.values():
            find_attachments(value, attachments)
    elif isinstance(obj, list):
        for item in obj:
            find_attachments(item, attachments)
    return attachments

attachments = find_attachments(data)
print(f"找到 {len(attachments)} 个截图附件")

output_dir = os.environ.get('OUTPUT_DIR', '/tmp/screenshots')
result_bundle = os.environ.get('RESULT_BUNDLE', '/tmp/ShunshiScreenshots.xcresult')

for i, att in enumerate(attachments, 1):
    name = att['name'].replace(' ', '_').replace('/', '_')
    output_path = f"{output_dir}/{i:02d}_{name}.png"
    
    print(f"  {i}. {att['name']}")
    
    # 导出截图
    cmd = [
        'xcrun', 'xcresulttool', 'export', 'object', '--legacy',
        '--path', result_bundle,
        '--id', att['id'],
        '--output-path', output_path,
        '--type', 'file'
    ]
    
    try:
        subprocess.run(cmd, check=True, capture_output=True)
        print(f"     ✅ 已保存: {output_path}")
    except subprocess.CalledProcessError as e:
        print(f"     ❌ 导出失败: {e}")

print(f"\n✨ 完成！所有截图已保存到: {output_dir}")
PYTHON_SCRIPT

echo ""
echo "📸 截图提取完成！"
echo "📂 查看截图: open $OUTPUT_DIR"

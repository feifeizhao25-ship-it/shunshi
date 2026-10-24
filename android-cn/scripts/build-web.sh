#!/bin/bash
# 网页版构建：不使用 Google CDN（canvaskit、字体全部随包）
set -e
cd "$(dirname "$0")/.."
flutter build web --release --no-web-resources-cdn --no-tree-shake-icons "$@"

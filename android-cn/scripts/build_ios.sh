#!/bin/bash

# ShunShi iOS Build Script
# Usage: ./build_ios.sh [simulator|testflight|appstore]

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
BUILD_TYPE="simulator"
CONFIGURATION="Debug"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    simulator)
      BUILD_TYPE="simulator"
      CONFIGURATION="Debug"
      shift
      ;;
    testflight)
      BUILD_TYPE="testflight"
      CONFIGURATION="Release"
      shift
      ;;
    appstore)
      BUILD_TYPE="appstore"
      CONFIGURATION="Release"
      shift
      ;;
    *)
      echo "Usage: $0 [simulator|testflight|appstore]"
      exit 1
      ;;
  esac
done

echo -e "${GREEN}🚀 Building ShunShi iOS ($BUILD_TYPE)${NC}"

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

# Get dependencies
echo -e "${YELLOW}📦 Getting dependencies...${NC}"
flutter pub get

# Build based on type
case $BUILD_TYPE in
  simulator)
    echo -e "${YELLOW}🏗️ Building for simulator...${NC}"
    flutter build ios --simulator --no-codesign
    echo -e "${GREEN}✅ Build complete!${NC}"
    echo -e "Run: xcrun simctl list devices available"
    ;;
    
  testflight)
    echo -e "${YELLOW}🏗️ Building for TestFlight...${NC}"
    if [ ! -f "ios/ExportOptions/TestFlight.plist" ]; then
        echo -e "${RED}❌ ExportOptions/TestFlight.plist not found${NC}"
        exit 1
    fi
    flutter build ios --release \
      --export-options-plist=ios/ExportOptions/TestFlight.plist
    echo -e "${GREEN}✅ Build complete!${NC}"
    echo -e "Upload to TestFlight using Transporter or:"
    echo -e "xcrun altool --upload-app -f build/ios/ipa/shunshi.ipa -t ios -u YOUR_APPLE_ID -p YOUR_APP_PASSWORD"
    ;;
    
  appstore)
    echo -e "${YELLOW}🏗️ Building for App Store...${NC}"
    if [ ! -f "ios/ExportOptions/AppStore.plist" ]; then
        echo -e "${RED}❌ ExportOptions/AppStore.plist not found${NC}"
        exit 1
    fi
    flutter build ios --release \
      --export-options-plist=ios/ExportOptions/AppStore.plist
    echo -e "${GREEN}✅ Build complete!${NC}"
    echo -e "Upload to App Store using Transporter or:"
    echo -e "xcrun altool --upload-app -f build/ios/ipa/shunshi.ipa -t ios -u YOUR_APPLE_ID -p YOUR_APP_PASSWORD"
    ;;
esac

echo -e "${GREEN}🎉 Done!${NC}"

# SEASONS — Deployment Guide

> How to build and release SEASONS for iOS (TestFlight / Production) and Android (Play Store).

---

## Prerequisites

- **iOS**: Xcode 15+, Apple Developer account (paid), App Store Connect access
- **Android**: Android Studio / Android SDK, Google Play Developer Console access
- **Both**: Flutter 3.x, `flutter` CLI available in PATH

---

## Pre-Build Checklist

Before any build, verify:

- [ ] `pubspec.yaml` version is incremented (for production)
- [ ] `ios/Runner/Info.plist` bundle version and build number are correct
- [ ] `android/app/build.gradle` `versionCode` and `versionName` are correct
- [ ] `lib/core/constants/app_constants.dart` points to production API URL
- [ ] All `TODO` comments in source code are resolved
- [ ] `flutter analyze` passes with no errors
- [ ] Tests pass: `flutter test`
- [ ] Assets are present in `assets/` directories

---

## iOS — App Store

### 1. Environment

```bash
flutter --version   # Should be 3.x
xcodebuild -version # Should be 15+
```

### 2. Build for Simulator (Local Verification)

```bash
cd /Users/feifei00/Documents/Shunshi/ios-global

# iOS Simulator build (no code signing)
flutter build ios --simulator --no-codesign
```

### 3. Build for App Store (TestFlight / Production)

```bash
# Build for release (requires Apple Developer credentials configured in Xcode)
flutter build ios --release
```

Xcode will handle the archive and export. Alternatively, use Xcode directly:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" (or a connected device)
3. Product → Archive
4. In the Organizer window, click "Distribute App"
5. Choose: "App Store Connect" → "Upload"

### 4. Upload to App Store Connect

If using the command line:

```bash
# Install Transporter (Mac App Store) and upload the .ipa
# Or use altool:
xcrun altool --upload-app \
  -t ios \
  -f ./build/ios/iphoneos/Runner.ipa \
  -u "your Apple ID" \
  -p "your app-specific password"
```

### 5. App Store Connect Configuration

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app (or create a new one)
3. **Version Information**:
   - What's New in This Version: changelog
   - Screenshots: iPhone 6.5", 6.7", iPad Pro 12.9"
   - App Preview videos (optional)
   - Description, Keywords, Support URL, Marketing URL
4. **Pricing**: Free / Subscription tiers
5. **Content Rating**: Complete the questionnaire
6. **Submit for Review**

### 6. Review Timeline

Apple review typically takes **24–48 hours** for new apps, **1–3 days** for updates.

---

## iOS — TestFlight

TestFlight allows testing before App Store release.

### Steps

1. **Build the app** (same as step 3 above)
2. **Upload to App Store Connect** (same as step 4)
3. In **App Store Connect**:
   - Go to TestFlight tab
   - Select the build
   - Add **Beta Testers**:
     - **Internal**: Add by Apple ID (immediate access)
     - **External**: Add by email or public link (requires Apple review, ~1 day)
   - Set **Test Information**: what to test, feedback instructions
4. Install TestFlight app on device, accept invitation
5. Install build, test, report bugs via TestFlight

### TestFlight Public Link

Generate a public link in App Store Connect → TestFlight → Test Information → Public Link. Share this with external testers.

---

## Android — Google Play Store

### 1. Environment

```bash
flutter --version
java --version  # Should be 17+ for AGP 8.x
echo $ANDROID_HOME  # Should point to Android SDK
```

### 2. Build Release APK / AAB

```bash
cd /Users/feifei00/Documents/Shunshi/android-global

# Debug build (APK) — for internal testing
flutter build apk --debug

# Release build (AAB) — required for Play Store
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### 3. Sign the AAB

The AAB must be signed with a keystore. Configure in `android/app/build.gradle`:

```groovy
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

Keystore credentials stored in `android/key.properties` (not committed to git):

```
keyAlias=seasons-upload
keyPassword=...
storePassword=...
storeFile=/path/to/seasons-keystore.jks
```

### 4. Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create app (or select existing)
3. **App Content**:
   - Targeted audience + age group
   - Content rating questionnaire
   - Ads declaration
4. **Tracks**:
   - **Internal testing**: Immediate, up to 100 testers
   - **Closed testing**: Limited testers, version control
   - **Open testing**: Anyone can join via Play Store link
   - **Production**: Public release
5. **Artifacts**: Upload the `.aab` file
6. **Store Listing**: Title, short description, full description, screenshots (phone + tablet + TV), feature graphic
7. **Pricing & Distribution**: Free / paid, countries
8. **Submit for review**

### 5. Review Timeline

Google Play review is typically **1–7 days** (faster for updates, slower for new apps).

---

## Android — APK (Alternative Distribution)

For distribution outside Play Store (e.g., APK download from website):

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Enable sideloading on the Android device (Settings → Security → Unknown Sources).

---

## Web Deployment

SEASONS Global is a mobile-first app. For web access (optional):

### Firebase Hosting

```bash
# Build
flutter build web

# Deploy to Firebase Hosting
firebase init hosting
firebase deploy --only hosting
```

Output: `build/web/` — contains `index.html` and compiled assets.

---

## Version Numbering

SEASONS uses **semantic versioning**: `MAJOR.MINOR.PATCH`

| Part | When to increment | Example |
|---|---|---|
| `MAJOR` | Breaking changes to API or user-facing features | 1.0.0 → 2.0.0 |
| `MINOR` | New features, non-breaking | 1.0.0 → 1.1.0 |
| `PATCH` | Bug fixes, small improvements | 1.0.0 → 1.0.1 |

同步更新:
- `pubspec.yaml` → `version: X.Y.Z`
- `ios/Runner/Info.plist` → `CFBundleShortVersionString` = `X.Y`, `CFBundleVersion` = `Z`
- `android/app/build.gradle` → `versionCode` = Z (int), `versionName` = `X.Y.Z`

---

## Environment Configuration

### Staging vs Production

```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  static const String apiBaseUrl = _isStaging
      ? 'http://116.62.32.43-staging'
      : 'http://116.62.32.43';

  static const bool enableAnalytics = !_isStaging;
  static const bool enableCrashReporting = !_isStaging;
}
```

`_isStaging` can be controlled via build flavor:

```bash
flutter build ios --release -t staging
```

---

## CI/CD (GitHub Actions)

Example workflow: `.github/workflows/deploy.yml`

```yaml
name: Deploy

on:
  push:
    tags:
      - 'v*'

jobs:
  ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build ios --release
      - uses: apple-actions/upload-testflight-build@v1
        with:
          token: ${{ secrets.APPLE_CONNECT_TOKEN }}

  android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build appbundle --release
      - uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJson: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}
          packageName: com.seasons.global
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
```

---

## Hot Reload / Fast Lane

For frequent internal builds, use Fastlane:

```bash
# iOS TestFlight deployment
fastlane ios testflight

# Android internal testing track
fastlane android internal
```

Configure `fastlane/Fastfile` with your App Store Connect credentials.

---

## Post-Launch Checklist

- [ ] Monitor App Store Connect / Google Play Console for crash reports
- [ ] Enable Firebase Performance Monitoring
- [ ] Set up Stackdriver / Crashlytics alerts for crash spikes
- [ ] Verify subscription flow works in production (test with sandbox accounts)
- [ ] Check API error rates in backend logs after launch
- [ ] Monitor `/health` endpoint for uptime

---

*Last updated: 2026-03*

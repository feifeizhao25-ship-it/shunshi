# SEASONS — Deployment Guide (Android)

> How to build and release SEASONS for Android (Google Play Store).
> For iOS deployment, see the ios-global docs.

---

## Prerequisites

- **Android**: Flutter 3.x, Android Studio / Android SDK, Java 17+
- **Google Play Console** access with a paid developer account ($25 one-time)
- **Bundlesignature**: Create a keystore for app signing

---

## Pre-Build Checklist

Before any build, verify:

- [ ] `pubspec.yaml` version is incremented
- [ ] `android/app/build.gradle` `versionCode` and `versionName` are correct
- [ ] `lib/core/constants/app_constants.dart` points to production API URL
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Assets present in `assets/` directories

---

## Android — Google Play Store

### 1. Environment

```bash
flutter --version
java --version   # Java 17+ required for AGP 8.x
echo $ANDROID_HOME
```

### 2. Build Debug APK (Local Testing)

```bash
cd /Users/feifei00/Documents/Shunshi/android-global
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

Install on a connected device or emulator:
```bash
flutter install
```

### 3. Build Release AAB (Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### 4. Sign the AAB

#### Option A: Use a keystore (recommended for production)

Create a keystore (one-time):

```bash
keytool -genkey -v -keystore seasons-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias seasons-upload
```

Store credentials in `android/key.properties` (never commit this file):

```
keyAlias=seasons-upload
keyPassword=<your-password>
storePassword=<your-store-password>
storeFile=/path/to/seasons-keystore.jks
```

Reference in `android/app/build.gradle`:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

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

#### Option B: Play App Signing (Google manages the key)

When you opt into **Play App Signing**, Google generates and manages your signing key. You just need an upload key:

1. In Play Console → Release → Setup → App Signing → Choose "Let Google manage and protect your app signing key"
2. Generate an upload key:
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias seasons-upload
```
3. Use this keystore in `build.gradle` (signingConfigs.release above)

### 5. Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app (or create a new one)
3. **Production** → **Create Release** → Upload the `.aab` file
4. **App Content**:
   - Targeted audience + age group declaration
   - Content rating questionnaire (free, takes ~10 min)
   - Ads declaration (our app: no ads)
5. **Store Listing**: Title, short description, full description, screenshots (phone + tablet), feature graphic
6. **Pricing & Distribution**: Free or paid, select countries
7. Save and **Submit for Review**

### 6. Review Timeline

Google Play review: **1–7 days** (faster for updates, up to 7 days for new apps).

---

## Google Play Tracks

| Track | Purpose | Access | Review |
|---|---|---|---|
| **Internal testing** | Immediate QA testing | Up to 100 testers via email | None |
| **Closed testing** | Alpha/Beta testers | Limited testers, version control | None |
| **Open testing** | Pre-release public | Anyone via Play Store link | None |
| **Production** | Public release | All users | Required (1–7 days) |

---

## Android — APK Distribution (Outside Play Store)

For APK-based distribution (e.g., company internal, website download):

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

For a standalone web build (if needed):

```bash
flutter build web
# Output: build/web/
```

---

## Permissions (Android)

Required permissions declared in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.BILLING"/>
```

Runtime permissions (requested in-app via `permission_handler`):
- `RECORD_AUDIO` — for voice input
- `INTERNET` — always granted at install on modern Android

---

## In-App Purchase (Google Billing)

The app uses `in_app_purchase` + `in_app_purchase_android` packages.

### Billing Setup

1. Create products/subscriptions in **Google Play Console** → Monetize → Products
2. Use exact product IDs as defined in `SubscriptionTier` enum

### Subscription Flow

```
1. User taps "Upgrade" in app
2. SubscriptionPage displays available tiers
3. User selects tier → StoreService initiates purchase
4. Google Play Billing dialog appears
5. On success: token validated with backend
6. Subscription status updated in app
```

---

## Version Numbering

Synchronized across iOS and Android:

| Part | When to increment | Example |
|---|---|---|
| `versionName` (MAJOR.MINOR.PATCH) | All platforms together | `1.2.0` |
| `versionCode` (int) | Android only, must increase | `12` |

In `android/app/build.gradle`:
```groovy
versionCode 12        // Integer, must increment
versionName "1.2.0"  // String, matches iOS CFBundleShortVersionString
```

---

## CI/CD (GitHub Actions)

Example Android deploy workflow:

```yaml
name: Deploy Android

on:
  push:
    tags:
      - 'android-v*'

jobs:
  android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          java-version: '17'

      - name: Decode keystore
        run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/seasons-keystore.jks

      - run: flutter pub get
      - run: flutter build appbundle --release

      - uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJson: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}
          packageName: com.seasons.global
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: production
```

---

## Troubleshooting

**`keytool` not found**
```bash
export PATH="$PATH:/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home/bin"
```

**Build fails with `minSdkVersion` error**
Check `android/app/build.gradle` for `minSdkVersion` — must be ≥ 21.

**Billing fails in debug**
Google Play Billing requires a signed release build or internal test track. Debug builds cannot test IAP.

**Play Store rejects: "App not compatible with your device"**
Check `minSdkVersion` and `targetSdkVersion` in `build.gradle`, and supported device declarations in Play Console.

---

## Post-Launch Checklist

- [ ] Monitor Play Console → Statistics for crash rate and ANR rate
- [ ] Enable Firebase Performance Monitoring
- [ ] Set up Crashlytics alerts for crash spikes (>1% crash rate)
- [ ] Verify subscription flow with sandbox test account
- [ ] Check API error rates in backend logs after launch
- [ ] Monitor `/health` endpoint for uptime

---

*Last updated: 2026-03*

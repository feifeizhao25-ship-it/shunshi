# SEASONS — App Store Screenshots Guide

## Required Screenshots

### iPhone (mandatory)

| Size | Device | Resolution | Required |
|------|--------|-----------|----------|
| 6.9" | iPhone 16 Pro Max / 15 Pro Max | 1320 × 2868 px | ✅ |
| 6.7" | iPhone 15 Plus / 14 Plus | 1290 × 2796 px | ✅ |
| 6.5" | iPhone 14 Pro Max / 13 Pro Max | 1284 × 2778 px | Recommended |
| 5.5" | iPhone 8 Plus (legacy) | 1242 × 2208 px | Optional |

### iPad (if supporting iPad)

| Size | Device | Resolution |
|------|--------|-----------|
| 12.9" | iPad Pro 12.9" (6th gen) | 2048 × 2732 px |
| 11" | iPad Pro 11" (4th gen) | 1668 × 2388 px |

> Note: If app is iPhone-only, iPad screenshots are auto-generated from iPhone versions.

## Screenshot Plan (up to 10)

1. **Splash / Hero** — App icon + tagline "Find your rhythm with the seasons" + calm gradient background
2. **Solar Terms Calendar** — Show the 24 solar terms wheel with current term highlighted
3. **AI Chat** — Conversation with AI wellness advisor, showing TCM-style recommendations
4. **Body Constitution** — Assessment result card with constitution type visualization
5. **Daily Wellness** — Today's personalized recommendations (diet, activity, mindfulness)
6. **Wellness Journal** — Clean journal entry view with mood tracking
7. **Seasonal Foods** — Food recommendations for current solar term
8. **Profile / Pro** — Pro subscription benefits overview

## Design Guidelines

- Use the app's actual UI — Apple rejects mockups that misrepresent the app
- Add concise headline text overlays (2-4 words per screenshot)
- Use consistent brand colors: dark backgrounds with nature-inspired accents
- Keep it calm and minimal — match the app's wellness aesthetic
- First screenshot is the most important — it appears in search results

## How to Take Screenshots

### Option A: Simulator (Recommended)
```bash
# Boot simulator
xcrun simctl boot "iPhone 16 Pro Max"
# Open app and navigate to each screen
# Take screenshots with Cmd+S or:
xcrun simctl io booted screenshot screenshot-name.png
```

### Option B: Fastlane Snapshot (Automated)
```bash
# Install fastlane
gem install fastlane
# Setup snapshot in ios-global/ios/
cd /Users/feifei00/Documents/Shunshi/ios-global/ios/
fastlane snapshot
```

### Option C: Device
- Press Power + Volume Up simultaneously
- Or use Xcode's Debug > View Debugging > Capture View Hierarchy

## Screenshot Specs

- **Format**: PNG or JPEG
- **Color space**: sRGB
- **Status bar**: Can be included but will be overlaid by App Store
- **No transparency**: Must be opaque
- **Portrait orientation only** (for iPhone apps)

# SEASONS — Development Guide

> **SEASONS** is an AI-powered calm lifestyle companion app for iOS and Android.
> This document covers the Global (English) version built with Flutter.

---

## Project Overview

| Property | Value |
|---|---|
| Project Name | `seasons` |
| Package ID (iOS) | `com.seasons.global` |
| Package ID (Android) | `com.seasons.global` |
| Min iOS Version | 12.0 |
| Min Android SDK | API 21 (Android 5.0) |
| State Management | Riverpod 2.x |
| Routing | GoRouter 14.x |
| Backend Base URL | `http://116.62.32.43/api/v1/` |
| Target Markets | Global (English-speaking) |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| State Management | `flutter_riverpod` + `riverpod_annotation` |
| Routing | `go_router` with `ShellRoute` for bottom nav |
| Networking | `dio` with retry + logging interceptors |
| Code Generation | `freezed`, `json_serializable`, `riverpod_generator` |
| Local Storage | `shared_preferences`, `flutter_secure_storage` |
| Auth | OAuth: Google Sign-In, Sign in with Apple |
| Payments | In-App Purchase (StoreKit + Google Billing) |
| Audio | `just_audio` |
| Voice Input | `speech_to_text` |
| Internationalization | Flutter built-in l10n |

---

## Directory Structure

```
ios-global/lib/
├── main.dart                      # App entry point, ProviderScope bootstrap
├── core/
│   ├── constants/
│   │   └── app_constants.dart     # App-wide constants (API base URL, etc.)
│   ├── network/
│   │   ├── api_service.dart       # Singleton ApiService with Dio + interceptors
│   │   └── api_client.dart        # HTTP client helpers (get/post wrappers)
│   ├── router/
│   │   └── app_router.dart        # GoRouter configuration + all routes
│   ├── theme/
│   │   ├── theme.dart             # SeasonsTheme (light + dark ThemeData)
│   │   ├── seasons_colors.dart    # SeasonsColors (light + dark tokens)
│   │   ├── seasons_text_styles.dart
│   │   ├── seasons_spacing.dart
│   │   ├── seasons_animations.dart
│   │   ├── app_localizations.dart
│   │   └── theme_provider.dart    # ThemeMode Riverpod provider
│   └── utils/
│       ├── notifications.dart      # Local notification helpers
│       └── analytics.dart          # Analytics tracking helpers
├── design_system/
│   ├── design_system.dart         # Public barrel export
│   ├── theme.dart                 # Design system core theme
│   ├── colors.dart                # Color tokens
│   ├── typography.dart             # Text style tokens
│   ├── components.dart            # Reusable component library
│   ├── animations.dart            # Animation constants
│   └── temp.dart                  # Temporary/staging exports
├── data/
│   ├── models/
│   │   └── content_item.dart     # Content API model
│   └── services/
│       ├── voice_service.dart     # Voice input service
│       ├── image_service.dart     # Image picking service
│       └── store_service.dart     # In-app purchase service
├── domain/
│   └── entities/
│       ├── entities.dart          # Barrel export
│       ├── user.dart              # User entity
│       ├── message.dart           # Chat message entity
│       ├── reflection.dart        # Reflection/journal entry entity
│       ├── content.dart           # Content item entity
│       ├── ai_response.dart        # AI chat response entity
│       └── reflection.dart
└── presentation/
    ├── providers/                 # Riverpod providers (state management)
    │   ├── home_provider.dart     # Home dashboard state
    │   ├── chat_provider.dart     # AI chat conversation state
    │   ├── library_provider.dart  # Content library state
    │   ├── profile_provider.dart  # User profile state
    │   ├── reflection_provider.dart # Reflection/journal state
    │   ├── seasons_provider.dart  # Seasonal content state
    │   └── subscription_provider.dart # Subscription/premium state
    ├── pages/                      # Route page widgets
    │   ├── splash/
    │   │   └── splash_page.dart   # Launch screen + onboarding redirect
    │   ├── onboarding/
    │   │   └── onboarding_page.dart
    │   ├── login/
    │   │   └── login_page.dart
    │   ├── home/
    │   │   └── home_page.dart
    │   ├── chat/
    │   │   └── chat_page.dart     # AI Companion chat
    │   ├── seasons/
    │   │   └── seasons_page.dart   # Seasonal wellness content
    │   ├── library/
    │   │   └── library_page.dart   # Content library (articles, audio)
    │   ├── profile/
    │   │   └── profile_page.dart
    │   ├── reflection/
    │   │   └── reflection_page.dart
    │   ├── records/
    │   │   └── records_page.dart
    │   ├── subscription/
    │   │   └── subscription_page.dart
    │   ├── content/
    │   │   └── content_detail_page.dart
    │   └── audio/
    │       └── audio_player_page.dart
    └── widgets/
        ├── shell/
        │   └── main_shell.dart    # 5-tab bottom navigation shell
        ├── common/
        │   ├── insight_card.dart
        │   ├── suggestion_card.dart
        │   └── chat_entry_card.dart
        ├── components/
        │   ├── loading_state.dart
        │   ├── loading_indicator.dart
        │   ├── error_state.dart
        │   ├── empty_state.dart
        │   ├── soft_card.dart
        │   ├── gentle_button.dart
        │   ├── breathing_animation.dart
        │   └── components.dart     # Barrel export
        └── voice_input_widget.dart
```

---

## Development Environment Setup

### Prerequisites

- Flutter 3.x SDK (`flutter --version` >= 3.8)
- Dart 3.x
- Xcode 15+ (for iOS builds)
- Android Studio / Android SDK

### 1. Clone & Install Dependencies

```bash
cd /Users/feifei00/Documents/Shunshi/ios-global
flutter pub get
```

### 2. Environment Variables

No `.env` file is used. All configuration is hardcoded in:

- `lib/core/constants/app_constants.dart` — API base URL, feature flags
- `lib/core/network/api_service.dart` — base URL for HTTP client

To switch between staging/production, modify `ApiService.instance` baseUrl.

### 3. Code Generation

Models use `freezed` and `json_serializable`. Run after editing any model:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Riverpod providers using annotations:

```bash
flutter pub run build_runner build
```

### 4. Running the App

```bash
# iOS Simulator
flutter run -d "iPhone 16"

# Android Emulator
flutter run -d emulator-5554

# All devices
flutter devices
flutter run -d <device-id>
```

### 5. Directory Alias

The `lib/` structure mirrors exactly between `ios-global` and `android-global`.
Platform-specific implementations are guarded with:

```dart
import 'dart:io' show Platform;
// or
import 'package:flutter/foundation.dart' show kIsWeb;
```

---

## Code Standards

### Style Guide

Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide with these project-specific rules:

**File Naming**
- Files: `snake_case.dart` (e.g., `chat_provider.dart`)
- Classes: `PascalCase` (e.g., `ChatProvider`)
- Enums: `PascalCase` with `kebab-case` values (e.g., `ChatTone.calm`)

**Imports**
```dart
import 'package:flutter/material.dart';          // Flutter
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod
import '../domain/entities/user.dart';          // Relative cross-layer
import 'package:seasons/data/services/voice_service.dart'; // Package-level
```

**Avoid**
- `print()` for debugging — use `debugPrint()` from `flutter/foundation.dart`
- `setState()` in Provider files — Riverpod manages all state
- Hardcoded strings — use `app_localizations.dart` for user-facing text

### Architecture Pattern

The app follows a **simplified Clean Architecture**:

```
presentation/
  pages/        # UI — route destinations
  widgets/      # UI — reusable components
  providers/    # State — Riverpod StateNotifier/AsyncNotifier providers

domain/
  entities/     # Business objects (pure Dart, no Flutter imports)

data/
  models/       # API transfer objects (JSON serialization)
  services/     # External integrations (API, audio, store)

core/
  router/       # GoRouter route definitions
  theme/        # SeasonsTheme, colors, typography, spacing
  constants/    # App-wide constants
  network/      # Dio API service
  utils/        # Helpers (analytics, notifications)
```

### State Management with Riverpod

All providers live in `presentation/providers/`. Example structure:

```dart
// providers/chat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_provider.g.dart';

@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  Future<ChatState> build() async {
    return ChatState.initial();
  }

  Future<void> sendMessage(String text) async { ... }
}

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    @Default([]) List<Message> messages,
    @Default(false) bool isLoading,
    @Default(false) bool isStreaming,
  }) = _ChatState;
}
```

---

## Testing Standards

See [TEST_GUIDE.md](./TEST_GUIDE.md) for the full testing guide.

Quick overview:

| Type | Location | Framework |
|---|---|---|
| Unit tests | `test/unit/` | `flutter_test` |
| Widget tests | `test/widget/` | `flutter_test` |
| Integration tests | `test/integration/` | `integration_test` package |
| E2E tests | `test/e2e/` | Flutter integration_test |

---

## Backend API

See [API.md](./API.md) for the complete API reference.

Base URL: `http://116.62.32.43/api/v1/` (append `/api/v1/` if not already present)

All endpoints return JSON. Auth uses `Authorization: Bearer <token>` header.

---

## Key Architectural Decisions

### Why GoRouter ShellRoute?
The 5-tab bottom navigation is implemented as a `ShellRoute` so the nav bar persists across tab switches without rebuilding the widget tree. Each tab is a `GoRoute` child of the `ShellRoute`.

### Why Riverpod over Bloc?
Riverpod was chosen for its compile-time safety, testability, and minimal boilerplate. Provider dependencies are explicit and graph-resolved.

### Why freezed for models?
`freezed` generates immutable data classes with `equals`, `hashCode`, `toString`, and JSON serialization out of the box — reducing boilerplate significantly.

### No Repository Pattern
The Global version uses a **direct service approach** — providers call `ApiService` directly. This is simpler than the CN version's repository layer and appropriate for the current scale.

---

## Troubleshooting

**Build fails with `riverpod_generator` errors**
Run `flutter pub run build_runner build --delete-conflicting-outputs`

**Dio timeout on simulator**
Increase `connectTimeout` / `receiveTimeout` in `api_service.dart` for debug mode.

**Google Sign-In fails on iOS**
Ensure `CLIENT_ID` in `ios/Runner/Info.plist` matches your Google Cloud Console configuration.

---

*Last updated: 2026-03*

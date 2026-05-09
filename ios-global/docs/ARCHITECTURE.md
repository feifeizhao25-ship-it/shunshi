# SEASONS — Architecture Document

> How the SEASONS Global app is structured, wired together, and why.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │   Pages     │  │  Widgets    │  │  Providers   │   │
│  │  (routes)   │  │ (reusable)  │  │ (Riverpod)   │   │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │
│         │                 │                 │           │
│         └─────────────────┼─────────────────┘           │
│                           │                             │
│         ┌─────────────────┴─────────────────┐         │
│         │            main_shell.dart          │         │
│         │     (5-tab bottom navigation)      │         │
│         └─────────────────┬─────────────────┘         │
│                           │                             │
│  ┌───────────────────────┴───────────────────────┐     │
│  │              GoRouter AppRouter               │     │
│  │   Splash → Onboarding → Main Shell → Routes  │     │
│  └───────────────────────────────────────────────┘     │
└──────────────────────────┬──────────────────────────────┘
                           │ Riverpod InheritedWidget
┌──────────────────────────┴──────────────────────────────┐
│                      DOMAIN LAYER                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │              Pure Dart Entities                    │   │
│  │  User | Message | Reflection | Content | AIResponse │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────┘
                           │ Direct call
┌──────────────────────────┴──────────────────────────────┐
│                       DATA LAYER                         │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐   │
│  │ ApiService   │  │ VoiceService │  │ StoreService │   │
│  │   (Dio)      │  │ (speech_*)   │  │ (in_app_*)   │   │
│  └──────────────┘  └──────────────┘  └─────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │              Flutter Secure Storage               │   │
│  │         (auth tokens, user preferences)           │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

---

## Navigation Architecture

### GoRouter Route Tree

```
/splash                           → SplashPage
/onboarding                       → OnboardingPage
/login                            → LoginPage

/chat                             → ChatPage (?conversation_id=)
/reflection                       → ReflectionPage
/subscribe                        → SubscriptionPage
/records                          → RecordsPage
/content/:id                      → ContentDetailPage

[ShellRoute — 5-tab nav container]
  /home                           → HomePage
  /companion                      → ChatPage
  /seasons                        → SeasonsPage
  /library                        → LibraryPage
  /profile                        → ProfilePage
```

### ShellRoute Pattern

`ShellRoute` wraps the 5 tab pages. The `MainShell` widget:
- Receives the current `child` page from GoRouter
- Renders a persistent `Scaffold` with `BottomNavigationBar`
- Tracks `GoRouterState.of(context).uri.path` to highlight the active tab
- Calls `context.go(tabPath)` on tab tap — this replaces the shell child without rebuilding the shell itself

```dart
ShellRoute(
  navigatorKey: _shellNavigatorKey,
  builder: (context, state, child) => MainShell(child: child),
  routes: [ /* 5 GoRoute children */ ],
)
```

### Splash → Onboarding Flow

```
SplashPage loads
  → checks local storage for auth token
  → if no token:   context.go('/onboarding')
  → if token valid: context.go('/home')
  → if token invalid: context.go('/login')
```

---

## State Management (Riverpod)

### Provider Map

| Provider | Type | Purpose |
|---|---|---|
| `homeProvider` | `AsyncNotifierProvider` | Home dashboard data (greeting, insight, suggestions) |
| `chatProvider` | `AsyncNotifierProvider` | Chat messages, streaming state |
| `libraryProvider` | `AsyncNotifierProvider` | Content library list + pagination |
| `profileProvider` | `NotifierProvider` | User profile, preferences |
| `reflectionProvider` | `AsyncNotifierProvider` | Reflection entries, weekly summary |
| `seasonsProvider` | `AsyncNotifierProvider` | Current season, seasonal content |
| `subscriptionProvider` | `NotifierProvider` | Subscription status, purchase flow |

### Provider Dependencies

Providers depend on each other via `ref.watch()` and `ref.read()`:

```dart
// Example: chat_provider.dart
@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  Future<ChatState> build() async {
    // Watch auth state if needed
    final auth = ref.watch(authStateProvider);
    return ChatState.initial();
  }
}
```

### API Calls Inside Providers

All HTTP calls go through `ApiService.instance`:

```dart
final response = await ApiService.instance.getHomeDashboard(
  userId: userId,
  hemisphere: 'north',
);
```

---

## Network Layer

### ApiService (Singleton)

`ApiService` is a singleton backed by `Dio`. Key features:

- **Base URL**: `http://116.62.32.43` (no `/api/v1/` prefix in current code — appended per call)
- **Auth header injection**: `updateAuthToken(token)` / `clearAuthToken()`
- **Retry interceptor**: Auto-retries on timeout and 5xx errors (max 3 retries, exponential backoff)
- **Logging interceptor**: Logs requests/responses in debug mode

### Request Flow

```
Provider calls ApiService method
  → Dio adds auth header + JSON content-type
  → Interceptors run (logging, retry)
  → HTTP request sent
  → Response parsed to typed model (ChatResponse, etc.)
  → Provider updates Riverpod state
  → UI rebuilds via ref.watch()
```

### Error Handling

Dio throws `DioException`. Providers catch and convert to `AsyncValue.error()`:

```dart
try {
  final result = await ApiService.instance.getUserProfile(userId);
  state = AsyncValue.data(result);
} on DioException catch (e) {
  state = AsyncValue.error(e, StackTrace.current);
}
```

---

## Design System

### Colors

Defined in `lib/core/theme/seasons_colors.dart` (light + dark variants) and `lib/design_system/colors.dart`.

Primary palette:
- **Primary**: `#A8D5A2` (soft sage green)
- **Accent**: `#F4B942` (warm amber)
- **Background**: `#FEFEFE` (light) / `#1A1A1A` (dark)
- **Surface**: `#F5F5F5` (light) / `#252525` (dark)

### Typography

Text styles in `lib/core/theme/seasons_text_styles.dart`:
- Display, Headline, Title, Body, Label, Caption variants
- Each with light/dark-aware colors

### Spacing

Spacing scale in `lib/core/theme/seasons_spacing.dart`:
- `xxs: 4`, `xs: 8`, `sm: 12`, `md: 16`, `lg: 24`, `xl: 32`, `xxl: 48`

### Animations

Animation durations in `lib/core/theme/seasons_animations.dart`:
- Fast: 150ms, Normal: 300ms, Slow: 500ms
- Common curves: `Curves.easeOut`, `Curves.easeInOut`

---

## Internationalization

The app uses Flutter's built-in `flutter_localizations` + `intl`. All user-facing strings are extracted to `lib/core/theme/app_localizations.dart`.

The Global version ships in English only. String keys follow the pattern:

```dart
AppLocalizations.of(context).homeTabLabel
```

For future localization, wrap the `MaterialApp.router` with `LocalizationsApp` and add `l10n.yaml`.

---

## Data Models (freezed)

All API response models live in `lib/core/network/api_service.dart` as nested classes:

```dart
class ChatResponse {
  final String text;
  final String tone;
  final List<String> suggestions;
  final FollowUp? followUp;
  final String safetyFlag;
  final String model;
  final int tokensUsed;
  final int latencyMs;
}
```

Domain entities in `lib/domain/entities/` are pure Dart classes mirroring these models but without JSON serialization logic.

---

## Key Platform-Specific Notes

### iOS
- `speech_to_text` requires `NSSpeechRecognitionUsageDescription` in `Info.plist`
- `google_sign_in` requires `CLIENT_ID` in `Info.plist`
- StoreKit (In-App Purchase) handled via `in_app_purchase` package

### Android
- `speech_to_text` requires `RECORD_AUDIO` permission
- Google Play Billing via `in_app_purchase_android`
- `permission_handler` for runtime permission management

### Shared
- `just_audio` for audio playback (background audio supported)
- `flutter_secure_storage` for token storage (Keychain on iOS, EncryptedSharedPreferences on Android)
- `shared_preferences` for non-sensitive settings (theme mode, onboarding completed flag)

---

## Security Considerations

- Auth tokens stored in `flutter_secure_storage` (not `shared_preferences`)
- No medical diagnoses or prescription advice in AI responses (safety flag field in `ChatResponse`)
- HTTPS enforced by backend (HTTP only for local development staging)
- API responses sanitized before rendering (no raw HTML)

---

*Last updated: 2026-03*

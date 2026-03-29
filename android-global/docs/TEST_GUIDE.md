# SEASONS — Testing Guide

> How to test the SEASONS Global app at every level.

---

## Testing Philosophy

SEASONS prioritizes **trust through testability**:
- Providers are stateless functions of their inputs — easy to mock and verify
- `ApiService` is a singleton that can be overridden in tests
- Domain entities are pure Dart — no Flutter dependencies
- UI widgets use Riverpod providers — state is injected, not hard-coded

---

## Testing Pyramid

```
        ┌─────────────────┐
        │   E2E Tests     │  ← Full app flow, real backend (or mock server)
        │  (integration)  │
        └───────┬─────────┘
                │
        ┌───────┴─────────┐
        │ Integration Tests│  ← App-level flows: onboarding, home, chat
        │  (integration/) │
        └───────┬─────────┘
                │
        ┌───────┴─────────┐
        │  Widget Tests   │  ← Single widget, mocked providers
        │   (widget/)     │
        └───────┬─────────┘
                │
        ┌───────┴─────────┐
        │   Unit Tests    │  ← Pure functions, providers, services
        │    (unit/)      │
        └─────────────────┘
```

---

## Test Directory Structure

```
test/
├── unit/
│   ├── providers/
│   │   ├── home_provider_test.dart
│   │   ├── chat_provider_test.dart
│   │   ├── reflection_provider_test.dart
│   │   └── seasons_provider_test.dart
│   ├── services/
│   │   └── api_service_test.dart
│   └── entities/
│       ├── message_test.dart
│       ├── reflection_test.dart
│       └── content_test.dart
├── widget/
│   ├── pages/
│   │   ├── splash_page_test.dart
│   │   ├── home_page_test.dart
│   │   ├── chat_page_test.dart
│   │   └── onboarding_page_test.dart
│   └── widgets/
│       ├── insight_card_test.dart
│       ├── gentle_button_test.dart
│       └── main_shell_test.dart
├── integration/
│   ├── app_launch_test.dart
│   ├── onboarding_flow_test.dart
│   ├── home_dashboard_test.dart
│   ├── chat_flow_test.dart
│   ├── audio_playback_test.dart
│   └── settings_flow_test.dart
└── e2e/
    └── full_user_journey_test.dart
```

---

## Unit Tests

### Running Unit Tests

```bash
flutter test test/unit/
flutter test test/unit/providers/chat_provider_test.dart
```

### Provider Tests

**Pattern:** Use `provider_container` from `riverpod_test` to override providers with mock implementations.

**Example: `test/unit/providers/chat_provider_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_test/flutter_riverpod_test.dart';
import 'package:seasons/presentation/providers/chat_provider.dart';
import 'package:seasons/domain/entities/message.dart';

void main() {
  group('ChatNotifier', () {
    test('initial state has empty messages and not loading', () async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override any dependencies (e.g., ApiService mock)
          ],
          child: ProviderTestWidget(),
        ),
      );

      // Verify initial state
    });

    test('sendMessage appends user message and returns AI response', () async {
      // Arrange: set up mock ApiService that returns a ChatResponse
      // Act: call ref.read(chatNotifierProvider.notifier).sendMessage(...)
      // Assert: state contains both user message and AI response
    });

    test('sendMessage sets isLoading during API call', () async {
      // Arrange
      // Act
      // Assert: isLoading transitions true → false
    });

    test('streamChat sets isStreaming to true while streaming', () async {
      // Arrange: mock streaming endpoint
      // Act: call streamChat()
      // Assert: isStreaming is true during stream
    });
  });
}
```

**Mocking ApiService:**

Create a mock class that implements the same interface:

```dart
class MockApiService extends Fake implements ApiService {
  @override
  Future<ChatResponse> sendChat({
    required String prompt,
    String? conversationId,
    String? userId,
    String? model,
  }) async {
    return ChatResponse.fromJson({
      'text': 'This is a mock response.',
      'tone': 'calm',
      'suggestions': ['Try deep breathing'],
      'safety_flag': 'none',
      'model': 'mock',
      'tokens_used': 10,
      'latency_ms': 100,
    });
  }
}
```

### Entity Tests

**Example: `test/unit/entities/message_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/domain/entities/message.dart';

void main() {
  group('Message', () {
    test('fromJson creates a user message correctly', () {
      final json = {
        'id': 'msg_001',
        'text': 'Hello',
        'sender': 'user',
        'timestamp': '2025-03-20T10:00:00Z',
        'isFromUser': true,
      };

      final message = Message.fromJson(json);

      expect(message.id, 'msg_001');
      expect(message.text, 'Hello');
      expect(message.isFromUser, true);
    });

    test('toJson produces correct JSON', () {
      final message = Message(
        id: 'msg_001',
        text: 'Hello',
        sender: 'user',
        timestamp: DateTime.utc(2025, 3, 20, 10, 0),
        isFromUser: true,
      );

      final json = message.toJson();

      expect(json['id'], 'msg_001');
      expect(json['isFromUser'], true);
    });
  });
}
```

---

## Widget Tests

### Running Widget Tests

```bash
flutter test test/widget/
flutter test test/widget/pages/home_page_test.dart
```

### Pattern: Pump with ProviderScope + Mock Providers

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seasons/presentation/pages/home/home_page.dart';
import 'package:seasons/presentation/providers/home_provider.dart';

void main() {
  group('HomePage', () {
    testWidgets('displays greeting text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProvider.overrideWith(() => MockHomeProvider()),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Good morning'), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching data', (tester) async {
      // Arrange: override with a provider that delays
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProvider.overrideWith(() => DelayedHomeProvider()),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProvider.overrideWith(() => ErrorHomeProvider()),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
```

---

## Integration Tests

Integration tests run the full app with `integration_test` package.

### Setup

```yaml
# pubspec.yaml — add if not present
dev_dependencies:
  integration_test:
    sdk: flutter
```

### Running Integration Tests

```bash
# On iOS Simulator
flutter test integration_test/app_launch_test.dart -d "iPhone 16"

# On Android Emulator
flutter test integration_test/app_launch_test.dart -d emulator-5554

# All platforms
flutter test integration_test/
```

### Example: `test/integration/app_launch_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seasons/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Launch', () {
    testWidgets('app launches and shows splash screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify splash screen elements (e.g., app logo)
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('splash navigates to onboarding when no token', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should land on onboarding or home depending on token state
      // Adjust based on actual splash redirect logic
    });
  });
}
```

### Example: `test/integration/chat_flow_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seasons/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Flow', () {
    testWidgets('user can send a message and receive a response', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chat tab
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      // Find text input field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Type a message
      await tester.enterText(textField, 'Hello, I need some advice');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      // Tap send button (adjust selector based on actual UI)
      final sendButton = find.byIcon(Icons.send);
      if (sendButton.evaluate().isNotEmpty) {
        await tester.tap(sendButton);
      }

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify message appears in chat
      expect(find.text('Hello, I need some advice'), findsOneWidget);
    });
  });
}
```

---

## E2E Tests (Full User Journey)

E2E tests cover complete user flows including auth and subscription. These require a mock backend or test server.

### Example: `test/e2e/full_user_journey_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seasons/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete user journey: onboarding → home → chat', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Complete onboarding
    // (fill in onboarding form steps)
    await tester.pumpAndSettle();

    // 2. Verify home screen loads
    expect(find.byType(HomePage), findsOneWidget);

    // 3. Navigate to chat
    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pumpAndSettle();

    // 4. Send a message
    // ... (see chat_flow_test above)
  });
}
```

---

## Test Data / Fixtures

Store reusable test fixtures in `test/fixtures/`:

```
test/
└── fixtures/
    ├── chat_responses.dart    # Mock ChatResponse JSON
    ├── user_profile.dart      # Mock User JSON
    └── dashboard_response.dart
```

Example fixture file:

```dart
// test/fixtures/chat_responses.dart
class ChatResponses {
  static Map<String, dynamic> calmGreeting = {
    'text': 'Hello! How are you feeling today?',
    'tone': 'calm',
    'suggestions': ['Share how you feel', 'Take a deep breath'],
    'follow_up': {'in_days': 2, 'intent': 'general_check_in'},
    'safety_flag': 'none',
    'model': 'seasons-small',
    'tokens_used': 45,
    'latency_ms': 890,
  };

  static Map<String, dynamic> tiredResponse = {
    'text': 'Feeling tired is your body asking for rest...',
    'tone': 'warm',
    'suggestions': ['Try a 5-minute breathing exercise'],
    'safety_flag': 'none',
    'model': 'seasons-small',
    'tokens_used': 52,
    'latency_ms': 1020,
  };
}
```

---

## CI / Pre-commit Checks

Add to your CI pipeline:

```bash
# Run all tests
flutter test

# With coverage
flutter test --coverage

# Lint
flutter analyze
```

---

## Writing Good Tests

**Do:**
- Test one thing per test case
- Use descriptive test names: `test('sendMessage clears input after sending')`
- Keep tests independent — no shared mutable state
- Use `setUp` / `tearDown` for fixture management

**Don't:**
- Test implementation details — test behavior
- Write tests that depend on network (mock everything in unit/widget tests)
- Assert on `toString()` output — it changes
- Use `sleep()` — use `pumpAndSettle()` or `pump(Duration)`

---

*Last updated: 2026-03*

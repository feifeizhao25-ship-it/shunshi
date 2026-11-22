// 11-21 UI test (SEASONS web, 5 visitors): after onboarding, Today, recommendations, follow-ups and the device
// culture sync all came back 401 until the tester tapped Guest on the login page; the onboarding answers went to
// POST /api/v1/auth/me (405). The chat also put "based on TCM wellness principles" under every reply, including
// refusals and "Sorry, unable to respond right now."
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seasons/data/network/onboarding_sync.dart';
import 'package:seasons/data/network/session.dart';
import 'package:seasons/data/storage/storage_manager.dart';

class FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> calls = [];
  final List<Object?> bodies = [];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    calls.add(options);
    bodies.add(options.data);
    final reply = options.path.endsWith('/auth/guest-login')
        ? {'success': true, 'data': {'token': 'guest-token-1', 'user': {'id': 'g1'}}}
        : {'saved': true};
    return ResponseBody.fromString(jsonEncode(reply), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(Dio, FakeAdapter)> boot([Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    await StorageManager.init();
    final adapter = FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter;
    return (dio, adapter);
  }

  test('a visitor finishing onboarding gets a guest session before Today, then the answers are saved', () async {
    final (dio, adapter) = await boot();
    final token = await finishOnboardingSession(dio, onboardingBody(feeling: 'Tired', helpWith: ['Sleep', 'Reflection']));
    expect(token, 'guest-token-1');
    expect(adapter.calls.map((c) => '${c.method} ${c.path}').toList(),
        ['POST /api/v1/auth/guest-login', 'POST $onboardingCompletePath']);
    expect(adapter.calls.last.headers['Authorization'], 'Bearer guest-token-1');
    expect(adapter.bodies.last, {'feeling': 'tired', 'help_goal': 'sleep, reflection'});
    // Saved where the API client and the pages read it, so Today is not a page of 401s.
    expect(StorageManager.user.getToken(), 'guest-token-1');
    expect(currentUserId(), 'g1');
  });

  test('a signed-in user keeps their own session; no extra guest account', () async {
    final (dio, adapter) = await boot({'auth_token': 'my-token'});
    final token = await finishOnboardingSession(dio, onboardingBody(lifeStage: 'Retired'));
    expect(token, 'my-token');
    expect(adapter.calls.map((c) => c.path).toList(), [onboardingCompletePath]);
    expect(adapter.calls.single.headers['Authorization'], 'Bearer my-token');
  });

  test('answers fit the server fields (short strings, nothing empty)', () {
    final body = onboardingBody(feeling: '  ', helpWith: List.filled(20, 'Evening Unwind'), feelStyle: 'Minimal');
    expect(body.containsKey('feeling'), isFalse);
    expect(body['help_goal']!.length, lessThanOrEqualTo(64));
    expect(body['style_preference'], 'minimal');
  });

  test('onboarding no longer posts to /auth/me and uses the shared session', () {
    final src = File('lib/presentation/pages/onboarding/onboarding_page.dart').readAsStringSync();
    expect(src.contains("'/api/v1/auth/me'"), isFalse);
    expect(src.contains('finishOnboardingSession('), isTrue);
    final splash = File('lib/presentation/pages/splash/splash_page.dart').readAsStringSync();
    expect(splash.contains('ensureSessionToken('), isTrue);
  });

  test('chat replies are not stamped "based on TCM wellness principles"', () {
    final src = File('lib/presentation/pages/chat_page.dart')
        .readAsLinesSync()
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');
    expect(src.contains('based on TCM wellness principles'), isFalse);
  });
}

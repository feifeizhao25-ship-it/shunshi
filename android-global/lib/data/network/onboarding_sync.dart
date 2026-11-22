import 'package:dio/dio.dart';

import 'session.dart';

/// Where the onboarding answers are stored on the server (`POST /api/v1/seasons/onboarding/complete`).
/// The old code posted them to `/api/v1/auth/me`, which only answers GET (405), so the answers never arrived.
const onboardingCompletePath = '/api/v1/seasons/onboarding/complete';

/// The server keeps each answer as a short string (64 characters at most).
Map<String, String> onboardingBody({
  String? feeling,
  Iterable<String> helpWith = const [],
  String? lifeStage,
  String? supportTime,
  String? feelStyle,
}) {
  String? clean(String? v) {
    final t = v?.trim().toLowerCase();
    if (t == null || t.isEmpty) return null;
    return t.length > 64 ? t.substring(0, 64) : t;
  }

  final body = <String, String?>{
    'feeling': clean(feeling),
    'help_goal': clean(helpWith.map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ')),
    'life_stage': clean(lifeStage),
    'support_time': clean(supportTime),
    'style_preference': clean(feelStyle),
  };
  return {
    for (final e in body.entries)
      if (e.value != null) e.key: e.value!,
  };
}

/// Finishing onboarding as a visitor: open (or reuse) the one guest session first, then save the answers.
///
/// 11-21 UI test: a visitor who finished onboarding reached Today with no session, so the home dashboard,
/// recommendations, follow-ups and the device culture sync all came back 401 ("Could not load"; chat said the
/// sign-in had expired) until the tester tapped Guest on the login page. Returns the session token (or null when
/// the guest session could not be opened; the caller still moves on, the pages show their own error).
Future<String?> finishOnboardingSession(
  Dio dio,
  Map<String, String> answers, {
  Future<String?> Function(Dio dio)? ensureSession,
}) async {
  final token = await (ensureSession ?? ensureSessionToken)(dio);
  if (token == null || token.trim().isEmpty) return null;
  if (answers.isNotEmpty) {
    try {
      await dio.post(
        onboardingCompletePath,
        data: answers,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (_) {
      // The answers are also kept on the device; failing to save them must not block the visitor.
    }
  }
  return token;
}

// POST /api/v1/speech/asr and /tts are behind the product access guard (401 without a Bearer token).
// The phone's mic (ASR) and the speaker's server-voice fallback (TTS) built a bare Dio, so both
// failed for logged-in users. Every Dio that talks to /speech/* must go through withSessionAuth.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every service that posts to /speech/* builds its Dio with withSessionAuth', () {
    final speechFiles = Directory('lib/data/services')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => RegExp(r'/api/v1/speech/(asr|tts)').hasMatch(f.readAsStringSync()))
        .toList();
    expect(speechFiles, isNotEmpty);
    for (final f in speechFiles) {
      final src = f.readAsStringSync();
      expect(src.contains('withSessionAuth(Dio('), isTrue, reason: '${f.path} posts to /speech/* without a session token');
      expect(src.contains("network/session.dart'"), isTrue, reason: f.path);
    }
  });
}

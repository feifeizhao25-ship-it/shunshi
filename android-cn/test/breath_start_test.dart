import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/audio/audio_player_page.dart';

void main() {
  test('bundled breath starts with play so the clock leaves 00:00', () {
    expect(breathNeedsPlay(bundled: true, started: false), isTrue);
    expect(breathNeedsPlay(bundled: true, started: true), isFalse);
    expect(breathNeedsPlay(bundled: false, started: false), isFalse);
  });
}

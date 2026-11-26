import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the breathing mark is a Material icon, not an emoji that the web font draws as a box', () {
    final src = File('lib/presentation/pages/audio/audio_player_page.dart').readAsStringSync();
    expect(src.contains('🌿'), isFalse);
    expect(src.contains('🧘'), isFalse);
    expect(src.contains('_categoryIcon'), isTrue);
    expect(src.contains('Icons.spa_outlined'), isTrue);
  });
}

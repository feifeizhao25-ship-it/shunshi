import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/data/services/speech_text.dart';

void main() {
  test('spoken reply keeps the bubble and the suggestion card', () {
    expect(
      speakableReply('Rest earlier tonight', ['This season', 'Slow the evening down']),
      'Rest earlier tonight This season Slow the evening down',
    );
  });

  test('long replies are split without dropping the ending', () {
    final source = List.filled(900, 'a').join();
    final chunks = speechChunks(source, maxChars: 180);
    expect(chunks.length, greaterThan(1));
    expect(chunks.fold<int>(0, (n, part) => n + part.length), source.length);
    expect(chunks.join(), source);
  });

  test('read-aloud strips markdown symbols before the text is spoken', () {
    const raw = 'After winter begins, two things matter: **sleep enough, and keep regular hours**.\n\n'
        '### Wind down earlier\n'
        '1. **Protect your sleep**\n'
        '   Aim for **7-8 hours**.\n'
        '   For example:\n'
        '   - 6:30 wake: in bed by 22:30-23:30\n'
        '   - 7:30 wake: in bed by 23:30\n'
        '2. __Keep the same wake time__\n'
        'See [this season](https://example.com/season) and `wind down`.';

    final spoken = speechChunks(speakableReply(raw, const ['**This season**'])).join(' ');

    expect(spoken.contains('**'), isFalse);
    expect(spoken.contains('__'), isFalse);
    expect(spoken.contains('#'), isFalse);
    expect(spoken.contains('`'), isFalse);
    expect(spoken.contains('http'), isFalse);
    expect(spoken.contains(' - '), isFalse);
    expect(
      spoken,
      'After winter begins, two things matter: sleep enough, and keep regular hours. Wind down earlier 1. Protect your sleep Aim for 7-8 hours. For example: 6:30 wake: in bed by 22:30-23:30 7:30 wake: in bed by 23:30 2. Keep the same wake time See this season and wind down. This season',
    );
  });

  test('already flattened markdown is speakable', () {
    const captured =
        'Two things matter: **sleep enough**. 1. **Protect your sleep** Aim for **7-8 hours**. For example: - 6:30 wake: in bed by 22:30 - 23:30 2. ### Wind down earlier';
    expect(
      speechChunks(captured).single,
      'Two things matter: sleep enough. 1. Protect your sleep Aim for 7-8 hours. For example: 6:30 wake: in bed by 22:30 - 23:30 2. Wind down earlier',
    );
  });

  test('plain times and numeric ranges are not treated as markdown', () {
    expect(
      speakablePlainText('7-8 hours, 22:30-23:30, or 9 - 11'),
      '7-8 hours, 22:30-23:30, or 9 - 11',
    );
  });
}

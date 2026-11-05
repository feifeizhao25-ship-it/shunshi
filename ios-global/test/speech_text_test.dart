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
}

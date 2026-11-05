import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/services/speech_text.dart';

void main() {
  test('spoken reply keeps the bubble and the suggestion card', () {
    expect(
      speakableReply('今晚早点休息', ['当前：立夏', '把作息放慢一点']),
      '今晚早点休息 当前：立夏 把作息放慢一点',
    );
  });

  test('long replies are split without dropping the ending', () {
    final source = List.filled(900, '甲').join();
    final chunks = speechChunks(source, maxChars: 180);
    expect(chunks.length, greaterThan(1));
    expect(chunks.fold<int>(0, (n, part) => n + part.length), source.length);
    expect(chunks.join(), source);
  });
}

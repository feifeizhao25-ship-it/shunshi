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

  test('read-aloud strips markdown symbols before the text is spoken', () {
    const raw = '立冬后，作息调整可抓住两点：**睡够、起居有常**。\n\n'
        '1. **保证睡眠时间**\n'
        '   成人可把每日平均睡眠时间 **7～8小时**作为目标。\n'
        '   例如：\n'
        '   - 6:30起床：尽量在22:30～23:30入睡\n'
        '   - 7:30起床：尽量在23:30～00:30入睡\n'
        '2. **固定起床节奏**\n'
        '   每天尽量在相近时间起床。\n'
        '3. ### 提前安排睡前流程\n'
        '详见 [节气说明](https://example.com/term) 与 `早睡`。';

    final spoken = speechChunks(speakableReply(raw, const ['**当前：立冬**'])).join(' ');

    expect(spoken.contains('**'), isFalse);
    expect(spoken.contains('##'), isFalse);
    expect(spoken.contains('#'), isFalse);
    expect(spoken.contains('`'), isFalse);
    expect(spoken.contains('http'), isFalse);
    expect(spoken.contains(' - '), isFalse);
    expect(
      spoken,
      '立冬后，作息调整可抓住两点：睡够、起居有常。 1. 保证睡眠时间 成人可把每日平均睡眠时间 7～8小时作为目标。 例如： 6:30起床：尽量在22:30～23:30入睡 7:30起床：尽量在23:30～00:30入睡 2. 固定起床节奏 每天尽量在相近时间起床。 3. 提前安排睡前流程 详见 节气说明 与 早睡。 当前：立冬',
    );
  });

  test('already flattened markdown from the speech log is speakable', () {
    const captured =
        '立冬后，作息调整可抓住两点：**睡够、起居有常**。 1. **保证睡眠时间** 成人可把每日平均睡眠时间 **7～8小时**作为目标。 例如： - 6:30起床：尽量在22:30～23:30入睡 - 7:30起床：尽量在23:30～00:30入睡 2. **固定起床节奏** ### 提前安排睡前流程';
    expect(
      speechChunks(captured).single,
      '立冬后，作息调整可抓住两点：睡够、起居有常。 1. 保证睡眠时间 成人可把每日平均睡眠时间 7～8小时作为目标。 例如： 6:30起床：尽量在22:30～23:30入睡 7:30起床：尽量在23:30～00:30入睡 2. 固定起床节奏 提前安排睡前流程',
    );
  });

  test('plain times and numeric ranges are not treated as markdown', () {
    expect(
      speakablePlainText('7-8小时，22:30-23:30，或 9 - 11 点'),
      '7-8小时，22:30-23:30，或 9 - 11 点',
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/core/audio/listen_clock.dart';

void main() {
  test('only time spent playing counts, not seeking or pauses', () {
    var t = DateTime(2026, 10, 31, 12);
    final clock = ListenClock(now: () => t);
    expect(clock.takeSeconds(), 0);
    clock.setPlaying(true);
    t = t.add(const Duration(seconds: 70));
    expect(clock.takeSeconds(), 70);
    clock.setPlaying(false);
    t = t.add(const Duration(minutes: 20)); // paused: nothing counts
    expect(clock.takeSeconds(), 0);
    clock.setPlaying(true);
    t = t.add(const Duration(milliseconds: 1500));
    clock.setPlaying(false);
    expect(clock.takeSeconds(), 1); // the extra 500 ms is carried
    clock.setPlaying(true);
    t = t.add(const Duration(milliseconds: 600));
    expect(clock.takeSeconds(), 1); // 500 carried + 600 = 1.1 s
  });

  test('a failed report gives its seconds back', () {
    var t = DateTime(2026, 10, 31);
    final clock = ListenClock(now: () => t);
    clock.setPlaying(true);
    t = t.add(const Duration(seconds: 30));
    final s = clock.takeSeconds();
    clock.giveBack(s);
    expect(clock.takeSeconds(), 30);
  });

  test('playing twice or stopping twice does not double count', () {
    var t = DateTime(2026, 10, 31);
    final clock = ListenClock(now: () => t);
    clock.setPlaying(true);
    clock.setPlaying(true);
    t = t.add(const Duration(seconds: 10));
    clock.setPlaying(false);
    clock.setPlaying(false);
    expect(clock.takeSeconds(), 10);
    expect(clock.takeSeconds(), 0);
  });
}

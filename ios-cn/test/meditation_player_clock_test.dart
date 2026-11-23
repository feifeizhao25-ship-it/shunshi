import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/meditation/meditation_player_page.dart';

void main() {
  test('播放器总时长按整秒四舍五入，和列表的「2 分 46 秒」一致', () {
    // 霜降：收敛 实际 165.6 秒，目录登记 166 秒，列表显示「2 分 46 秒」
    expect(formatPlayerClock(const Duration(milliseconds: 165600)), '02:46');
    expect(formatPlayerClock(const Duration(milliseconds: 165300)), '02:45');
    expect(formatPlayerClock(Duration.zero), '00:00');
    expect(formatPlayerClock(const Duration(minutes: 3, seconds: 16)), '03:16');
  });

  test('超过 60 分钟时分钟不回绕', () {
    expect(formatPlayerClock(const Duration(minutes: 61, seconds: 5)), '61:05');
  });
}

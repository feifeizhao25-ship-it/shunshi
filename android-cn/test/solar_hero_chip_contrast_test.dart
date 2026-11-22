import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/solar/solar_term_page_v2.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('头图小标签白字在四季渐变上对比度 ≥ 4.5（问题 47）', () {
    // 头图是：底图 → 季节渐变（浅色主题 alpha 0.65–0.75）→ 小标签底色。
    // 底图未知，按最坏情况（纯白底图）算，再按纯黑底图算一遍。
    for (final g in solarHeroGradientColors) {
      for (final photo in [Colors.white, Colors.black]) {
        final overlay = Color.alphaBlend(g.withValues(alpha: 0.65), photo);
        final chip = Color.alphaBlend(solarHeroChipScrim, overlay);
        final c = _contrast(solarHeroChipText, chip);
        expect(c, greaterThanOrEqualTo(4.5), reason: 'gradient=$g photo=$photo contrast=$c');
      }
    }
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/library/wellness_library_parse.dart';

void main() {
  test('parses the real /contents/recommend envelope (data.items)', () {
    final body = {
      'success': true,
      'data': {
        'items': [
          {'id': 'a', 'type': 'food_therapy', 'category': '秋季食疗', 'tags': ['秋季'], 'season_tag': 'autumn'},
          {'id': 'b', 'type': 'exercise', 'category': '有氧', 'tags': ['简单']},
          {'id': 'c', 'type': 'acupressure', 'category': '上肢穴位', 'tags': ['安神', '宁心']},
        ],
        'total': 3,
      },
    };
    final items = parseRecommendItems(body);
    expect(items.length, 3);
    expect(items.where((c) => matchesWellnessFilter(c, '饮食')).length, 1);
    expect(items.where((c) => matchesWellnessFilter(c, 'Nutrition')).length, 1);
    expect(items.where((c) => matchesWellnessFilter(c, '运动')).length, 1);
    expect(items.where((c) => matchesWellnessFilter(c, '睡眠')).length, 1);
    expect(items.where((c) => matchesWellnessFilter(c, '节气养生')).length, 1);
    expect(items.where((c) => matchesWellnessFilter(c, 'Seasonal')).length, 1);
  });
  test('still accepts a bare list and ignores garbage', () {
    expect(parseRecommendItems({'data': [{'id': 'x'}]}).length, 1);
    expect(parseRecommendItems(null), isEmpty);
    expect(parseRecommendItems({'data': 'nope'}), isEmpty);
  });
}

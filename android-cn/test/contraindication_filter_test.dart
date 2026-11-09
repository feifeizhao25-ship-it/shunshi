import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/wellness/widgets/constitution_data.dart';

void main() {
  test('pregnancy flag drops documented items and keeps 麦冬', () {
    final diet = filterContraindicatedAdvice(kConstitutionAdvice['yinxu']!['饮食']!, ['孕期']);
    final tea = filterContraindicatedAdvice(kConstitutionAdvice['yinxu']!['茶饮']!, ['孕期']);
    expect(diet.contains('甲鱼'), isFalse);
    expect(diet.contains('银耳'), isTrue);
    expect(tea.contains('麦冬'), isTrue);
    expect(profileSafetyFlags(['备孕']), isEmpty);
  });

  test('breastfeeding flag drops 鸭肉 from yin advice', () {
    final diet = filterContraindicatedAdvice(kConstitutionAdvice['yinxu']!['饮食']!, ['哺乳期']);
    expect(diet.contains('鸭肉'), isFalse);
    expect(diet.contains('甲鱼'), isTrue);
  });

  test('flagged profiles never keep a contraindicated name', () {
    const bits = ['孕期', '哺乳'];
    final blocked = contraindicatedNamesFor(bits);
    expect(blocked.contains('麦冬'), isFalse);
    for (final advice in kConstitutionAdvice.values) {
      for (final text in advice.values) {
        final filtered = filterContraindicatedAdvice(text, bits);
        for (final name in blocked) {
          expect(filtered.contains(name), isFalse, reason: '$name in $filtered');
        }
      }
    }
  });
}

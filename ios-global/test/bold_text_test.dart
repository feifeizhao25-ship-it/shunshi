import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/widgets/bold_text.dart';

void main() {
  test('**bold** becomes a bold span without the asterisks; plain text is untouched', () {
    final span = boldSpans('For you, it\'s **spring** in the south.\n- a\n- b', const TextStyle(fontSize: 15));
    expect(span.toPlainText(), 'For you, it\'s spring in the south.\n- a\n- b');
    final bold = (span.children!.whereType<TextSpan>().firstWhere((s) => s.text == 'spring'));
    expect(bold.style!.fontWeight, FontWeight.w700);
    expect(boldSpans('no markup', const TextStyle()).toPlainText(), 'no markup');
    expect(boldSpans('unclosed **bold', const TextStyle()).toPlainText(), 'unclosed **bold');
  });
}

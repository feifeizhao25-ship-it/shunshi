import 'package:flutter/widgets.dart';

/// Replies may contain `**bold**`; the chat bubble does not render markdown, so the asterisks showed up as text.
/// Only bold is handled (no new dependency); everything else is shown as written.
TextSpan boldSpans(String text, TextStyle style) {
  final spans = <TextSpan>[];
  final re = RegExp(r'\*\*(.+?)\*\*', dotAll: true);
  var last = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
    spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return TextSpan(style: style, children: spans);
}

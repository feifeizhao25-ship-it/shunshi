/// Text prepared for speech. Markup is removed so the voice does not read
/// symbols such as `**` or `###`. Chunks keep the whole reply: nothing is
/// dropped after a character cap, and the spoken string is the bubble plus
/// its cards.
String speakableReply(String text, List<String> extras) {
  final parts = <String>[];
  final body = speakablePlainText(text).trim();
  if (body.isNotEmpty) parts.add(body);
  for (final extra in extras) {
    final piece = speakablePlainText(extra).trim();
    if (piece.isNotEmpty) parts.add(piece);
  }
  return parts.join(' ');
}

/// Markdown (and a few HTML tags) turned into words a voice can say.
///
/// The words inside emphasis, headings, links, and list items stay. Markers
/// that engines pronounce — asterisks, hashes, backticks, list dashes — go.
/// Numeric ranges such as `7-8` and `22:30-23:30` are left alone.
String speakablePlainText(String input) {
  var text = input.replaceAll('\r\n', '\n');

  text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'</?[A-Za-z][^>\n]*>'), '');

  text = text.replaceAllMapped(
    RegExp(r'```[^\n`]*\n?([\s\S]*?)```'),
    (m) => m.group(1) ?? '',
  );
  text = text.replaceAllMapped(
    RegExp(r'!\[([^\]]*)\]\([^)]*\)'),
    (m) => m.group(1) ?? '',
  );
  text = text.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\([^)]*\)'),
    (m) => m.group(1) ?? '',
  );

  // Headings, including a run of hashes that is no longer at line start.
  text = text.replaceAll(RegExp(r'^#{1,6}[ \t]*', multiLine: true), '');
  text = text.replaceAll(RegExp(r'#{2,6}[ \t]*'), '');

  text = text.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*', dotAll: true), (m) => m.group(1)!);
  text = text.replaceAllMapped(RegExp(r'__(.+?)__', dotAll: true), (m) => m.group(1)!);
  text = text.replaceAllMapped(RegExp(r'~~(.+?)~~', dotAll: true), (m) => m.group(1)!);
  text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1)!);

  text = text.replaceAll(RegExp(r'^>[ \t]?', multiLine: true), '');
  text = text.replaceAll(RegExp(r'^[ \t]*([-*_])\1{2,}[ \t]*$', multiLine: true), '');
  // Line bullets before single-star italics, so "* item" is a list, not emphasis.
  text = text.replaceAll(RegExp(r'^[ \t]*[-*+][ \t]+', multiLine: true), '');
  text = text.replaceAllMapped(
    RegExp(r'(?<!\*)\*(?!\s)([^*\n]+?)(?<!\s)\*(?!\*)'),
    (m) => m.group(1)!,
  );

  text = text.replaceAll('**', '');
  text = text.replaceAll('*', '');
  text = text.replaceAll(RegExp(r'#{2,6}'), '');
  text = text.replaceAll(RegExp(r'(^|\s)#(?=\s)'), r'\1');
  // Inline " - " bullets. A hyphen with a digit before it (9 - 11, 22:30 - 23:30) stays.
  text = text.replaceAll(RegExp(r'(?<!\d)[ \t]+-[ \t]+'), ' ');

  return text;
}

List<String> speechChunks(String text, {int maxChars = 400}) {
  final clean = speakablePlainText(text).replaceAll(RegExp(r'\s+'), ' ').trim();
  if (clean.isEmpty) return const [];
  if (maxChars < 20) maxChars = 20;
  if (clean.length <= maxChars) return [clean];

  final parts = <String>[];
  var rest = clean;
  while (rest.isNotEmpty) {
    if (rest.length <= maxChars) {
      parts.add(rest);
      break;
    }
    final window = rest.substring(0, maxChars);
    var cut = -1;
    for (final mark in ['。', '！', '？', '.', '!', '?', '；', ';', '，', ',', ' ']) {
      final at = window.lastIndexOf(mark);
      if (at > cut) cut = at;
    }
    if (cut < maxChars ~/ 3) cut = maxChars - 1;
    final piece = rest.substring(0, cut + 1).trim();
    if (piece.isNotEmpty) parts.add(piece);
    rest = rest.substring(cut + 1).trim();
  }
  return parts;
}

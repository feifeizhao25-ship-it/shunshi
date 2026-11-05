/// Text prepared for speech. Chunks keep the whole reply: nothing is dropped
/// after a character cap, and the spoken string is the bubble plus its cards.
String speakableReply(String text, List<String> extras) {
  final parts = <String>[];
  final body = text.trim();
  if (body.isNotEmpty) parts.add(body);
  for (final extra in extras) {
    final piece = extra.trim();
    if (piece.isNotEmpty) parts.add(piece);
  }
  return parts.join(' ');
}

List<String> speechChunks(String text, {int maxChars = 400}) {
  final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
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

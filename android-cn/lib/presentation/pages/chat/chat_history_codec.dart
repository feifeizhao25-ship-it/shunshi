import 'dart:convert';
import '../../widgets/chat_sources.dart';
import 'chat_models.dart';

String encodeChatHistory(List<ChatMessage> messages) => jsonEncode({
  'version': 1,
  'messages': messages
      .map(
        (m) => {
          'role': m.role,
          'text': m.text,
          'time': m.time,
          'sources': m.sources,
          if (m.sourceDetails != null && m.sourceDetails!.isNotEmpty)
            'source_details': m.sourceDetails!.map((e) => e.toJson()).toList(),
          'cards': m.cards
              ?.map(
                (c) => {
                  'type': c.type,
                  'title': c.title,
                  'subtitle': c.subtitle,
                },
              )
              .toList(),
        },
      )
      .toList(),
});

List<ChatMessage> decodeChatHistory(String? saved) {
  if (saved == null || saved.isEmpty) return [];
  if (saved.trimLeft().startsWith('{')) {
    try {
      final data = jsonDecode(saved);
      if (data is! Map || data['version'] != 1 || data['messages'] is! List) {
        return [];
      }
      return (data['messages'] as List).map((item) {
        final m = item as Map;
        return ChatMessage(
          role: m['role'] as String,
          text: m['text'] as String,
          time: m['time'] as String,
          sources: (m['sources'] as List?)?.cast<String>(),
          sourceDetails: ChatSource.parseAll(m['source_details']),
          cards: (m['cards'] as List?)
              ?.map(
                (c) => SuggestionCard(
                  type: c['type'] as String,
                  title: c['title'] as String,
                  subtitle: c['subtitle'] as String,
                  icon: iconForType(c['type']),
                ),
              )
              .toList(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
  // Legacy messages did not escape newlines. Preserve continuation lines where possible.
  final result = <ChatMessage>[];
  String? role;
  final lines = <String>[];
  void flush() {
    if (role != null) {
      result.add(ChatMessage(role: role, text: lines.join('\n'), time: ''));
    }
    lines.clear();
  }

  for (final line in saved.split('\n')) {
    final match = RegExp(
      r'^(user|ai|assistant|system)\|(.*)$',
    ).firstMatch(line);
    if (match != null) {
      flush();
      role = match.group(1);
      lines.add(match.group(2)!);
    } else if (role != null) {
      lines.add(line);
    }
  }
  flush();
  return result;
}

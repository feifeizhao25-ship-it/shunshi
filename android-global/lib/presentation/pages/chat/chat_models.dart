import 'package:flutter/material.dart';

/// ChatMessages模型
class ChatMessage {
  final String role;
  final String text;
  final List<SuggestionCard>? cards;
  final List<String>? sources;
  final String time;
  ChatMessage({required this.role, required this.text, this.cards, this.sources, required this.time});
}

/// AI suggestion: 卡片
class SuggestionCard {
  final String type;
  final String title;
  final String subtitle;
  final IconData? icon;
  SuggestionCard({required this.type, required this.title, required this.subtitle, this.icon});
}

/// 图标映射
IconData iconForType(String? t) {
  switch (t) {
    case 'diet': case 'food': return Icons.restaurant;
    case 'rest': case 'sleep': return Icons.bedtime;
    case 'exercise': return Icons.self_improvement;
    case 'emotion': return Icons.favorite;
    case 'acupoint': return Icons.accessibility_new;
    case 'mindfulness': return Icons.spa;
    case 'social': return Icons.people;
    case 'crisis': return Icons.phone_in_talk;
    default: return Icons.auto_awesome;
  }
}

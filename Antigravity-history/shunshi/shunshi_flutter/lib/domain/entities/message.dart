import 'care_status.dart';

/// ──────────────────────────────────────────────────
/// Message & Conversation — 聊天核心实体
/// 映射自 iOS ChatMessage.swift
/// ──────────────────────────────────────────────────

enum MessageRole { user, assistant, system }

enum MessageType { text, card, system }

/// 内容卡片类型
enum ContentCardType { recipe, acupoint, exercise, article }

/// 内容卡片（穴位/食谱/运动 等）
class ContentCard {
  final String id;
  final ContentCardType type;
  final String title;
  final String description;
  final String? imageUrl;

  const ContentCard({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.imageUrl,
  });

  factory ContentCard.fromJson(Map<String, dynamic> json) => ContentCard(
        id: json['id'] as String? ?? '',
        type: ContentCardType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ContentCardType.article,
        ),
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imageUrl: json['image_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'image_url': imageUrl,
      };
}

/// 消息
class Message {
  final String id;
  final MessageRole role;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final List<ContentCard> contentCards;
  final List<String> followUpQuestions;
  final bool isLoading;
  final SafetyFlag? safetyFlag;

  const Message({
    required this.id,
    required this.role,
    this.type = MessageType.text,
    required this.content,
    required this.timestamp,
    this.contentCards = const [],
    this.followUpQuestions = const [],
    this.isLoading = false,
    this.safetyFlag,
  });

  factory Message.userMessage(String content) => Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.user,
        content: content,
        timestamp: DateTime.now(),
      );

  factory Message.assistantMessage(String content,
          {List<ContentCard> contentCards = const [],
          List<String> followUpQuestions = const [],
          SafetyFlag? safetyFlag}) =>
      Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: content,
        timestamp: DateTime.now(),
        contentCards: contentCards,
        followUpQuestions: followUpQuestions,
        safetyFlag: safetyFlag,
      );

  factory Message.systemMessage(String content) => Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.system,
        type: MessageType.system,
        content: content,
        timestamp: DateTime.now(),
      );

  static Message get loading => Message(
        id: 'loading',
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isLoading: true,
      );

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String? ?? '',
        role: MessageRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => MessageRole.assistant,
        ),
        type: MessageType.values.firstWhere(
          (e) => e.name == (json['type'] as String?),
          orElse: () => MessageType.text,
        ),
        content: json['content'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        contentCards: (json['content_cards'] as List?)
                ?.map((e) => ContentCard.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        followUpQuestions: (json['follow_up_questions'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        safetyFlag: json['safety_flag'] != null
            ? SafetyFlag.fromString(json['safety_flag'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'type': type.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'content_cards': contentCards.map((e) => e.toJson()).toList(),
        'follow_up_questions': followUpQuestions,
        'safety_flag': safetyFlag?.toJson(),
      };
}

/// 会话
class Conversation {
  final String id;
  final DateTime createdAt;
  final List<Message> messages;
  final String? title;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const Conversation({
    required this.id,
    required this.createdAt,
    this.messages = const [],
    this.title,
    this.lastMessage,
    this.lastMessageAt,
  });

  Conversation copyWith({
    List<Message>? messages,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return Conversation(
      id: id,
      createdAt: createdAt,
      messages: messages ?? this.messages,
      title: title,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}

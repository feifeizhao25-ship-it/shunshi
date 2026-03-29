// lib/domain/entities/message.dart
// 聊天消息实体

/// 消息角色
enum MessageRole { user, assistant, system }

/// 消息安全标志
enum SafetyFlag { none, caution, blocked }

/// AI 关怀状态
enum CareStatus { stable, concerned, attention }

/// 聊天消息
class Message {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final SafetyFlag safetyFlag;
  final CareStatus? careStatus;
  final String? tone;
  final Map<String, dynamic>? followUp;
  final Map<String, dynamic>? cardData;
  final bool isStreaming;

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.safetyFlag = SafetyFlag.none,
    this.careStatus,
    this.tone,
    this.followUp,
    this.cardData,
    this.isStreaming = false,
  });

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get hasCard => cardData != null && cardData!.isNotEmpty;

  Message copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    SafetyFlag? safetyFlag,
    CareStatus? careStatus,
    String? tone,
    Map<String, dynamic>? followUp,
    Map<String, dynamic>? cardData,
    bool? isStreaming,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      safetyFlag: safetyFlag ?? this.safetyFlag,
      careStatus: careStatus ?? this.careStatus,
      tone: tone ?? this.tone,
      followUp: followUp ?? this.followUp,
      cardData: cardData ?? this.cardData,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'role': role.name,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'safety_flag': safetyFlag.name,
    'care_status': careStatus?.name,
    'tone': tone,
    'follow_up': followUp,
    'card_data': cardData,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    conversationId: json['conversation_id'] as String,
    role: MessageRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => MessageRole.user,
    ),
    content: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    safetyFlag: SafetyFlag.values.firstWhere(
      (e) => e.name == json['safety_flag'],
      orElse: () => SafetyFlag.none,
    ),
    careStatus: json['care_status'] != null
        ? CareStatus.values.firstWhere(
            (e) => e.name == json['care_status'],
            orElse: () => CareStatus.stable,
          )
        : null,
    tone: json['tone'] as String?,
    followUp: json['follow_up'] as Map<String, dynamic>?,
    cardData: json['card_data'] as Map<String, dynamic>?,
  );
}

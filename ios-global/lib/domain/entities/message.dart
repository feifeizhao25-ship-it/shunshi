enum MessageRole {
  user,
  assistant,
  system,
}

class Message {
  final String id;
  final String conversationId;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final String? audioUrl;
  final String? imageUrl;
  final Map<String, dynamic> metadata;
  
  const Message({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.role,
    required this.timestamp,
    this.audioUrl,
    this.imageUrl,
    this.metadata = const {},
  });
}

class Conversation {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final List<Message> messages;
  
  const Conversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    this.lastMessageAt,
    this.messages = const [],
  });
}

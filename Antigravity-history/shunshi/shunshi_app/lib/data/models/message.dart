import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

enum MessageType { text, card, system }
enum MessageSender { user, assistant, system }

@JsonSerializable()
class MessageCard {
  final String type; // "acupoint", "content", "action"
  final String? contentId;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final Map<String, dynamic>? media;

  const MessageCard({
    required this.type,
    this.contentId,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.media,
  });

  factory MessageCard.fromJson(Map<String, dynamic> json) =>
      _$MessageCardFromJson(json);
  Map<String, dynamic> toJson() => _$MessageCardToJson(this);
}

@JsonSerializable()
class Message {
  final String id;
  final MessageType type;
  final MessageSender sender;
  final String text;
  final List<MessageCard>? cards;
  final String? tone;
  final DateTime createdAt;
  final bool isSafetyFlagged;

  const Message({
    required this.id,
    this.type = MessageType.text,
    required this.sender,
    required this.text,
    this.cards,
    this.tone,
    required this.createdAt,
    this.isSafetyFlagged = false,
  });

  Message copyWith({
    String? id,
    MessageType? type,
    MessageSender? sender,
    String? text,
    List<MessageCard>? cards,
    String? tone,
    DateTime? createdAt,
    bool? isSafetyFlagged,
  }) {
    return Message(
      id: id ?? this.id,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      cards: cards ?? this.cards,
      tone: tone ?? this.tone,
      createdAt: createdAt ?? this.createdAt,
      isSafetyFlagged: isSafetyFlagged ?? this.isSafetyFlagged,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  factory Message.userMessage({required String id, required String text}) {
    return Message(
      id: id,
      type: MessageType.text,
      sender: MessageSender.user,
      text: text,
      createdAt: DateTime.now(),
    );
  }

  factory Message.systemNotice({required String id, required String text}) {
    return Message(
      id: id,
      type: MessageType.system,
      sender: MessageSender.system,
      text: text,
      createdAt: DateTime.now(),
      isSafetyFlagged: true,
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'message.dart';

MessageCard _$MessageCardFromJson(Map<String, dynamic> json) => MessageCard(
      type: json['type'] as String,
      contentId: json['content_id'] as String?,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['image_url'] as String?,
      media: json['media'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$MessageCardToJson(MessageCard instance) =>
    <String, dynamic>{
      'type': instance.type,
      'content_id': instance.contentId,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'image_url': instance.imageUrl,
      'media': instance.media,
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      id: json['id'] as String,
      type: $enumDecodeNullable(_$MessageTypeEnumMap, json['type']) ??
          MessageType.text,
      sender: $enumDecode(_$MessageSenderEnumMap, json['sender']),
      text: json['text'] as String,
      cards: (json['cards'] as List<dynamic>?)
          ?.map((e) => MessageCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      tone: json['tone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isSafetyFlagged: json['is_safety_flagged'] as bool? ?? false,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'id': instance.id,
      'type': _$MessageTypeEnumMap[instance.type]!,
      'sender': _$MessageSenderEnumMap[instance.sender]!,
      'text': instance.text,
      'cards': instance.cards?.map((e) => e.toJson()).toList(),
      'tone': instance.tone,
      'created_at': instance.createdAt.toIso8601String(),
      'is_safety_flagged': instance.isSafetyFlagged,
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.card: 'card',
  MessageType.system: 'system',
};

const _$MessageSenderEnumMap = {
  MessageSender.user: 'user',
  MessageSender.assistant: 'assistant',
  MessageSender.system: 'system',
};

T $enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
  return enumValues.entries
      .singleWhere((e) => e.value == source)
      .key;
}

T? $enumDecodeNullable<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) return null;
  try {
    return enumValues.entries.singleWhere((e) => e.value == source).key;
  } catch (_) {
    return enumValues.entries.first.key;
  }
}

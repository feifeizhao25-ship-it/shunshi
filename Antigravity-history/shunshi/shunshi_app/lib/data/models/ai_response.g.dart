// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'ai_response.dart';

AiResponseCard _$AiResponseCardFromJson(Map<String, dynamic> json) =>
    AiResponseCard(
      type: json['type'] as String,
      contentId: json['content_id'] as String?,
      title: json['title'] as String?,
      media: json['media'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AiResponseCardToJson(AiResponseCard instance) =>
    <String, dynamic>{
      'type': instance.type,
      'content_id': instance.contentId,
      'title': instance.title,
      'media': instance.media,
    };

AiResponse _$AiResponseFromJson(Map<String, dynamic> json) => AiResponse(
      text: json['text'] as String,
      tone: json['tone'] as String? ?? 'gentle',
      careStatus: json['care_status'] as String? ?? 'stable',
      followUp: json['follow_up'] == null
          ? null
          : FollowUpPlan.fromJson(json['follow_up'] as Map<String, dynamic>),
      offlineEncouraged: json['offline_encouraged'] as bool? ?? false,
      presenceLevel: json['presence_level'] as String? ?? 'normal',
      safetyFlag: json['safety_flag'] as String? ?? 'none',
      cards: (json['cards'] as List<dynamic>?)
          ?.map((e) => AiResponseCard.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AiResponseToJson(AiResponse instance) =>
    <String, dynamic>{
      'text': instance.text,
      'tone': instance.tone,
      'care_status': instance.careStatus,
      'follow_up': instance.followUp?.toJson(),
      'offline_encouraged': instance.offlineEncouraged,
      'presence_level': instance.presenceLevel,
      'safety_flag': instance.safetyFlag,
      'cards': instance.cards?.map((e) => e.toJson()).toList(),
    };

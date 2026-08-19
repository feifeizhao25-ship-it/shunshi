// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'content_item.dart';

MediaAsset _$MediaAssetFromJson(Map<String, dynamic> json) => MediaAsset(
      url: json['url'] as String,
      type: json['type'] as String,
      thumbnail: json['thumbnail'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
    );

Map<String, dynamic> _$MediaAssetToJson(MediaAsset instance) =>
    <String, dynamic>{
      'url': instance.url,
      'type': instance.type,
      'thumbnail': instance.thumbnail,
      'duration_seconds': instance.durationSeconds,
    };

ContentItem _$ContentItemFromJson(Map<String, dynamic> json) => ContentItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      type: $enumDecode(_$ContentTypeEnumMap, json['type']),
      cover: json['cover'] == null
          ? null
          : MediaAsset.fromJson(json['cover'] as Map<String, dynamic>),
      media: (json['media'] as List<dynamic>?)
          ?.map((e) => MediaAsset.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isPremium: json['is_premium'] as bool? ?? false,
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
      readTimeMinutes: json['read_time_minutes'] as int? ?? 3,
    );

Map<String, dynamic> _$ContentItemToJson(ContentItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'description': instance.description,
      'type': _$ContentTypeEnumMap[instance.type]!,
      'cover': instance.cover?.toJson(),
      'media': instance.media?.map((e) => e.toJson()).toList(),
      'tags': instance.tags,
      'is_premium': instance.isPremium,
      'published_at': instance.publishedAt?.toIso8601String(),
      'read_time_minutes': instance.readTimeMinutes,
    };

const _$ContentTypeEnumMap = {
  ContentType.article: 'article',
  ContentType.video: 'video',
  ContentType.acupoint: 'acupoint',
  ContentType.exercise: 'exercise',
  ContentType.recipe: 'recipe',
  ContentType.meditation: 'meditation',
};

T $enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
  return enumValues.entries.singleWhere((e) => e.value == source).key;
}

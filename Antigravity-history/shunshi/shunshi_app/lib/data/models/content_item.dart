import 'package:json_annotation/json_annotation.dart';

part 'content_item.g.dart';

enum ContentType { article, video, acupoint, exercise, recipe, meditation }

@JsonSerializable()
class MediaAsset {
  final String url;
  final String type; // "image", "video", "audio"
  final String? thumbnail;
  final int? durationSeconds;

  const MediaAsset({
    required this.url,
    required this.type,
    this.thumbnail,
    this.durationSeconds,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) =>
      _$MediaAssetFromJson(json);
  Map<String, dynamic> toJson() => _$MediaAssetToJson(this);
}

@JsonSerializable()
class ContentItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final ContentType type;
  final MediaAsset? cover;
  final List<MediaAsset>? media;
  final List<String> tags;
  final bool isPremium;
  final DateTime? publishedAt;
  final int readTimeMinutes;

  const ContentItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    required this.type,
    this.cover,
    this.media,
    this.tags = const [],
    this.isPremium = false,
    this.publishedAt,
    this.readTimeMinutes = 3,
  });

  ContentItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    ContentType? type,
    MediaAsset? cover,
    List<MediaAsset>? media,
    List<String>? tags,
    bool? isPremium,
    DateTime? publishedAt,
    int? readTimeMinutes,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      type: type ?? this.type,
      cover: cover ?? this.cover,
      media: media ?? this.media,
      tags: tags ?? this.tags,
      isPremium: isPremium ?? this.isPremium,
      publishedAt: publishedAt ?? this.publishedAt,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
    );
  }

  String get typeLabel {
    switch (type) {
      case ContentType.article:
        return '文章';
      case ContentType.video:
        return '视频';
      case ContentType.acupoint:
        return '穴位';
      case ContentType.exercise:
        return '运动';
      case ContentType.recipe:
        return '食谱';
      case ContentType.meditation:
        return '冥想';
    }
  }

  factory ContentItem.fromJson(Map<String, dynamic> json) =>
      _$ContentItemFromJson(json);
  Map<String, dynamic> toJson() => _$ContentItemToJson(this);
}

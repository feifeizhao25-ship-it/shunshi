/// ──────────────────────────────────────────────────
/// ContentItem & MediaAsset — 内容库实体
/// 穴位 / 食谱 / 运动
/// ──────────────────────────────────────────────────

enum ContentCategory { acupoint, recipe, movement }

enum MediaType { image, video }

class ContentItem {
  final String id;
  final ContentCategory category;
  final String title;
  final String description;
  final List<MediaAsset> media;
  final List<String> contraindications; // 禁忌提醒
  final String? solarTermTag;
  final String? constitutionTag;
  final Map<String, dynamic>? metadata;

  const ContentItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.media = const [],
    this.contraindications = const [],
    this.solarTermTag,
    this.constitutionTag,
    this.metadata,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
        id: json['id'] as String? ?? '',
        category: ContentCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ContentCategory.recipe,
        ),
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        media: (json['media'] as List?)
                ?.map((e) => MediaAsset.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        contraindications: (json['contraindications'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        solarTermTag: json['solar_term_tag'] as String?,
        constitutionTag: json['constitution_tag'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'title': title,
        'description': description,
        'media': media.map((e) => e.toJson()).toList(),
        'contraindications': contraindications,
        'solar_term_tag': solarTermTag,
        'constitution_tag': constitutionTag,
        'metadata': metadata,
      };
}

class MediaAsset {
  final String id;
  final MediaType type;
  final String url;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String? altText;

  const MediaAsset({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.durationSeconds,
    this.altText,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) => MediaAsset(
        id: json['id'] as String? ?? '',
        type: json['type'] == 'video' ? MediaType.video : MediaType.image,
        url: json['url'] as String? ?? '',
        thumbnailUrl: json['thumbnail_url'] as String?,
        durationSeconds: json['duration_seconds'] as int?,
        altText: json['alt_text'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'url': url,
        'thumbnail_url': thumbnailUrl,
        'duration_seconds': durationSeconds,
        'alt_text': altText,
      };
}

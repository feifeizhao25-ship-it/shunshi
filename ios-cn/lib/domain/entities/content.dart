// lib/domain/entities/content.dart
// 养生内容实体

/// 内容类型
enum ContentType {
  foodTherapy,   // 食疗
  tea,           // 茶饮
  exercise,      // 运动导引
  acupoint,      // 穴位保健
  acupressure,   // 穴位按摩
  sleepTip,      // 睡眠调理
  emotion,       // 情志调摄
  audio,         // 音频冥想
  article,       // 文章
  unknown,
}

/// 季节
enum Season { spring, summer, autumn, winter }

/// 难度
enum Difficulty { easy, medium, hard }

/// 养生内容
class Content {
  final String id;
  final ContentType type;
  final String title;
  final String? summary;
  final String? content;
  final String? imageUrl;
  final List<String> tags;
  final Season? season;
  final String? solarTerm;
  final Difficulty? difficulty;
  final int? durationMinutes;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  const Content({
    required this.id,
    required this.type,
    required this.title,
    this.summary,
    this.content,
    this.imageUrl,
    this.tags = const [],
    this.season,
    this.solarTerm,
    this.difficulty,
    this.durationMinutes,
    this.metadata,
    this.createdAt,
  });

  Content copyWith({
    String? id,
    ContentType? type,
    String? title,
    String? summary,
    String? content,
    String? imageUrl,
    List<String>? tags,
    Season? season,
    String? solarTerm,
    Difficulty? difficulty,
    int? durationMinutes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return Content(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      season: season ?? this.season,
      solarTerm: solarTerm ?? this.solarTerm,
      difficulty: difficulty ?? this.difficulty,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'summary': summary,
    'content': content,
    'image_url': imageUrl,
    'tags': tags,
    'season': season?.name,
    'solar_term': solarTerm,
    'difficulty': difficulty?.name,
    'duration_minutes': durationMinutes,
    'metadata': metadata,
    'created_at': createdAt?.toIso8601String(),
  };

  factory Content.fromJson(Map<String, dynamic> json) => Content(
    id: json['id'] as String,
    type: ContentType.values.firstWhere(
      (e) => e.name == (json['type'] as String?)?.replaceAll('_', '').toLowerCase(),
      orElse: () => ContentType.unknown,
    ),
    title: json['title'] as String,
    summary: json['summary'] as String?,
    content: json['content'] as String?,
    imageUrl: json['image_url'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    season: json['season'] != null
        ? Season.values.firstWhere(
            (e) => e.name == json['season'],
            orElse: () => Season.spring,
          )
        : null,
    solarTerm: json['solar_term'] as String?,
    difficulty: json['difficulty'] != null
        ? Difficulty.values.firstWhere(
            (e) => e.name == json['difficulty'],
            orElse: () => Difficulty.easy,
          )
        : null,
    durationMinutes: json['duration_minutes'] as int?,
    metadata: json['metadata'] as Map<String, dynamic>?,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
  );
}

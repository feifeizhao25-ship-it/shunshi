// lib/domain/entities/reflection.dart
// 每日感悟/日记实体

/// 情绪类型
enum MoodType {
  great,    // 很好
  good,     // 还好
  neutral,  // 一般
  bad,      // 不好
  awful,    // 很差
}

/// 每日感悟
class Reflection {
  final String id;
  final String userId;
  final String content;
  final MoodType? mood;
  final int? sleepHours;
  final List<String> tags;
  final DateTime date;
  final DateTime createdAt;

  const Reflection({
    required this.id,
    required this.userId,
    required this.content,
    this.mood,
    this.sleepHours,
    this.tags = const [],
    required this.date,
    required this.createdAt,
  });

  Reflection copyWith({
    String? id,
    String? userId,
    String? content,
    MoodType? mood,
    int? sleepHours,
    List<String>? tags,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Reflection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      sleepHours: sleepHours ?? this.sleepHours,
      tags: tags ?? this.tags,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'content': content,
    'mood': mood?.name,
    'sleep_hours': sleepHours,
    'tags': tags,
    'date': date.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  factory Reflection.fromJson(Map<String, dynamic> json) => Reflection(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    content: json['content'] as String,
    mood: json['mood'] != null
        ? MoodType.values.firstWhere(
            (e) => e.name == json['mood'],
            orElse: () => MoodType.neutral,
          )
        : null,
    sleepHours: json['sleep_hours'] as int?,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    date: DateTime.parse(json['date'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

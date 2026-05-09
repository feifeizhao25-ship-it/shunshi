// lib/domain/entities/solar_term.dart
// 二十四节气实体

/// 节气
class SolarTerm {
  final String id;
  final String name;         // 中文名，如"立春"
  final String nameEn;       // 英文名，如"Start of Spring"
  final String emoji;
  final String season;       // spring/summer/autumn/winter
  final String date;         // 日期描述，如"2月3日-5日"
  final String description;  // 节气简介
  final Map<String, dynamic>? wellnessPlan; // 完整养生方案
  final bool isCurrent;      // 是否为当前节气

  const SolarTerm({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.emoji,
    required this.season,
    required this.date,
    required this.description,
    this.wellnessPlan,
    this.isCurrent = false,
  });

  SolarTerm copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? emoji,
    String? season,
    String? date,
    String? description,
    Map<String, dynamic>? wellnessPlan,
    bool? isCurrent,
  }) {
    return SolarTerm(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      emoji: emoji ?? this.emoji,
      season: season ?? this.season,
      date: date ?? this.date,
      description: description ?? this.description,
      wellnessPlan: wellnessPlan ?? this.wellnessPlan,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  factory SolarTerm.fromJson(Map<String, dynamic> json) => SolarTerm(
    id: json['id']?.toString() ?? json['name'] as String,
    name: json['name'] as String,
    nameEn: json['name_en'] as String? ?? '',
    emoji: json['emoji'] as String? ?? '🌿',
    season: json['season'] as String? ?? 'spring',
    date: json['date'] as String? ?? '',
    description: json['description'] as String? ?? '',
    wellnessPlan: json['wellness_plan'] as Map<String, dynamic>?,
    isCurrent: json['is_current'] as bool? ?? false,
  );
}

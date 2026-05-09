/// 数据模型 - 内容
class ContentItem {
  final String id;
  final String title;
  final String summary;
  final String category;
  final String imageUrl;
  final bool isFavorite;
  final DateTime createdAt;

  ContentItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    this.imageUrl = '',
    this.isFavorite = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class WellnessContent {
  final String id;
  final String title;
  final String type;
  final Map<String, dynamic> content;

  WellnessContent({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
  });

  factory WellnessContent.fromJson(Map<String, dynamic> json) {
    return WellnessContent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      content: json['content'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'content': content,
    };
  }
}

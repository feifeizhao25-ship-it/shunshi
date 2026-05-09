enum ContentType {
  breathing,
  stretch,
  teaRitual,
  sleep,
  reflection,
  meditation,
  story,
  food,
  acupressure,
}

enum Season {
  spring,
  summer,
  autumn,
  winter,
  all,
}

class Content {
  final String id;
  final String title;
  final String description;
  final ContentType type;
  final String? videoUrl;
  final String? imageUrl;
  final String? audioUrl;
  final int? durationSeconds;
  final List<String> tags;
  final List<String> steps;
  final Season? season;
  final bool isPremium;
  
  const Content({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.videoUrl,
    this.imageUrl,
    this.audioUrl,
    this.durationSeconds,
    this.tags = const [],
    this.steps = const [],
    this.season,
    this.isPremium = false,
  });
}

class ContentCategory {
  final String id;
  final String name;
  final ContentType type;
  final String? iconUrl;
  final List<Content> contents;
  
  const ContentCategory({
    required this.id,
    required this.name,
    required this.type,
    this.iconUrl,
    this.contents = const [],
  });
}

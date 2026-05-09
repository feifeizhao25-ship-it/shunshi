class Reflection {
  final String id;
  final String content;
  final DateTime createdAt;
  final String? mood;
  final String? seasonTag;
  Reflection({required this.id, required this.content, required this.createdAt, this.mood, this.seasonTag});
  Map<String, dynamic> toJson() => {"id": id, "content": content, "createdAt": createdAt.toIso8601String(), "mood": mood, "seasonTag": seasonTag};
  factory Reflection.fromJson(Map<String, dynamic> j) => Reflection(id: j["id"], content: j["content"], createdAt: DateTime.parse(j["createdAt"]), mood: j["mood"], seasonTag: j["seasonTag"]);
}

/// Prompt 版本管理

class PromptVersion {
  final String version;
  final String content;
  final String author;
  final DateTime createdAt;
  final String status;

  PromptVersion({
    required this.version,
    required this.content,
    required this.author,
    required this.createdAt,
    this.status = 'active',
  });
}

class PromptRegistry {
  final Map<String, List<PromptVersion>> _prompts = {};

  void register(String name, PromptVersion version) {
    _prompts[name] ??= [];
    _prompts[name]!.add(version);
  }

  PromptVersion? getActive(String name) {
    final versions = _prompts[name];
    if (versions == null || versions.isEmpty) return null;
    return versions.firstWhere(
      (v) => v.status == 'active',
      orElse: () => versions.first,
    );
  }
}

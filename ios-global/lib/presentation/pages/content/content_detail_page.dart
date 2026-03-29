// lib/presentation/pages/content/content_detail_page.dart
//
// Seasons content detail page — fetches from API, supports all content types
// Food / Acupressure / Exercise / Tea / Sleep / Breathing / Meditation / etc.
// English UI only, no Chinese

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_spacing.dart';
import '../../../core/theme/seasons_text_styles.dart';
import '../../../core/network/api_client.dart';

/// Content type enum
enum ContentDetailType {
  food,
  acupressure,
  exercise,
  tea,
  sleep,
  breathing,
  stretch,
  teaRitual,
  reflection,
  meditation,
  story,
}

/// Content detail data model
class ContentDetail {
  final String id;
  final String title;
  final String? category;
  final List<String> tags;
  final String? body;
  final List<String> ingredients;
  final List<String> steps;
  final List<String> benefits;
  final String? tip;
  final String? imageUrl;
  final String? duration;
  final String? difficulty;
  final String? emoji;
  final bool isLiked;
  final ContentDetailType type;

  const ContentDetail({
    required this.id,
    required this.title,
    this.category,
    this.tags = const [],
    this.body,
    this.ingredients = const [],
    this.steps = const [],
    this.benefits = const [],
    this.tip,
    this.imageUrl,
    this.duration,
    this.difficulty,
    this.emoji,
    this.isLiked = false,
    this.type = ContentDetailType.food,
  });

  factory ContentDetail.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] ?? json['category'] ?? 'food';
    ContentDetailType type = ContentDetailType.food;
    for (final t in ContentDetailType.values) {
      if (t.name == typeStr) {
        type = t;
        break;
      }
    }

    return ContentDetail(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      body: json['body'] ?? json['description'],
      ingredients: List<String>.from(json['ingredients'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
      benefits: List<String>.from(json['benefits'] ?? json['effects'] ?? []),
      tip: json['tip'],
      imageUrl: json['image_url'],
      duration: json['duration'],
      difficulty: json['difficulty'],
      emoji: json['emoji'],
      isLiked: json['is_liked'] ?? false,
      type: type,
    );
  }
}

/// Seasons content detail page
class ContentDetailPage extends StatefulWidget {
  final String contentId;

  const ContentDetailPage({super.key, required this.contentId});

  @override
  State<ContentDetailPage> createState() => _ContentDetailPageState();
}

class _ContentDetailPageState extends State<ContentDetailPage> {
  ContentDetail? _content;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLiked = false;
  bool _isLiking = false;

  /// Type → icon
  static const Map<ContentDetailType, IconData> _typeIcons = {
    ContentDetailType.food: Icons.restaurant,
    ContentDetailType.acupressure: Icons.pan_tool,
    ContentDetailType.exercise: Icons.self_improvement,
    ContentDetailType.tea: Icons.coffee,
    ContentDetailType.sleep: Icons.nightlight_round,
    ContentDetailType.breathing: Icons.air,
    ContentDetailType.stretch: Icons.self_improvement,
    ContentDetailType.teaRitual: Icons.coffee,
    ContentDetailType.reflection: Icons.lightbulb_outline,
    ContentDetailType.meditation: Icons.spa,
    ContentDetailType.story: Icons.auto_stories,
  };

  /// Type → label
  static const Map<ContentDetailType, String> _typeLabels = {
    ContentDetailType.food: 'Nourishing Food',
    ContentDetailType.acupressure: 'Acupressure',
    ContentDetailType.exercise: 'Movement',
    ContentDetailType.tea: 'Herbal Tea',
    ContentDetailType.sleep: 'Sleep',
    ContentDetailType.breathing: 'Breathing',
    ContentDetailType.stretch: 'Stretch',
    ContentDetailType.teaRitual: 'Tea Ritual',
    ContentDetailType.reflection: 'Reflection',
    ContentDetailType.meditation: 'Meditation',
    ContentDetailType.story: 'Story',
  };

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ApiClient();

      Map<String, dynamic>? data;
      try {
        final response = await client.get('/api/v1/contents/${widget.contentId}');
        data = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null;
      } catch (_) {}

      data ??= await (() async {
        final response = await client.get('/api/v1/cms/content/${widget.contentId}');
        return response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null;
      })();

      if (data != null) {
        final contentData = data;
        setState(() {
          _content = ContentDetail.fromJson(contentData);
          _isLiked = _content!.isLiked;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Content not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_isLiking || _content == null) return;
    setState(() => _isLiking = true);

    try {
      final client = ApiClient();
      await client.post('/api/v1/contents/${widget.contentId}/like');
      setState(() {
        _isLiked = !_isLiked;
        _isLiking = false;
      });
    } catch (_) {
      setState(() => _isLiking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeasonsColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SeasonsColors.primary))
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage!, style: SeasonsTextStyles.bodySecondary),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadContent,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final c = _content!;
    final icon = _typeIcons[c.type] ?? Icons.article;

    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: SeasonsColors.primary,
          leading: IconButton(
            onPressed: () => context.go('/library'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    SeasonsColors.primaryLight,
                    SeasonsColors.primary,
                  ],
                ),
              ),
              child: Center(
                child: Icon(icon, size: 80, color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ),

        // Body
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(SeasonsSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Like
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.title,
                        style: SeasonsTextStyles.insight,
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleLike,
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? SeasonsColors.error : SeasonsColors.textHint,
                        size: 28,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: SeasonsSpacing.md),

                // Category + duration
                if (c.category != null || c.type != ContentDetailType.food)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (c.category != null || c.type != ContentDetailType.food)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: SeasonsColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(SeasonsSpacing.radiusFull),
                          ),
                          child: Text(
                            c.category ?? _typeLabels[c.type]!,
                            style: SeasonsTextStyles.caption.copyWith(
                              color: SeasonsColors.primary,
                            ),
                          ),
                        ),
                      if (c.duration != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: SeasonsColors.surfaceDim,
                            borderRadius: BorderRadius.circular(SeasonsSpacing.radiusFull),
                          ),
                          child: Text(c.duration!, style: SeasonsTextStyles.caption),
                        ),
                      if (c.difficulty != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: SeasonsColors.surfaceDim,
                            borderRadius: BorderRadius.circular(SeasonsSpacing.radiusFull),
                          ),
                          child: Text(c.difficulty!, style: SeasonsTextStyles.caption),
                        ),
                    ],
                  ),

                const SizedBox(height: SeasonsSpacing.lg),

                // Body
                if (c.body != null && c.body!.isNotEmpty) ...[
                  Text(c.body!, style: SeasonsTextStyles.body.copyWith(height: 1.8)),
                  const SizedBox(height: SeasonsSpacing.lg),
                ],

                // Tags
                if (c.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: SeasonsSpacing.sm,
                    runSpacing: SeasonsSpacing.sm,
                    children: c.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SeasonsSpacing.md,
                        vertical: SeasonsSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: SeasonsColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(SeasonsSpacing.radiusFull),
                      ),
                      child: Text(
                        '#$tag',
                        style: SeasonsTextStyles.caption.copyWith(
                          color: SeasonsColors.primary,
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: SeasonsSpacing.lg),
                ],

                // Benefits
                if (c.benefits.isNotEmpty) ...[
                  Text('Benefits', style: SeasonsTextStyles.heading),
                  const SizedBox(height: SeasonsSpacing.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: c.benefits.map((b) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: SeasonsColors.sage.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(SeasonsSpacing.radiusFull),
                      ),
                      child: Text(b, style: SeasonsTextStyles.caption),
                    )).toList(),
                  ),
                  const SizedBox(height: SeasonsSpacing.lg),
                ],

                // Ingredients
                if (c.ingredients.isNotEmpty) ...[
                  Text('Ingredients', style: SeasonsTextStyles.heading),
                  const SizedBox(height: SeasonsSpacing.md),
                  Text(c.ingredients.join(' · '), style: SeasonsTextStyles.body),
                  const SizedBox(height: SeasonsSpacing.lg),
                ],

                // Steps
                if (c.steps.isNotEmpty) ...[
                  Text('How to practice', style: SeasonsTextStyles.heading),
                  const SizedBox(height: SeasonsSpacing.md),
                  ...c.steps.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: SeasonsSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: SeasonsColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: SeasonsTextStyles.caption.copyWith(
                                color: SeasonsColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: SeasonsSpacing.md),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: SeasonsTextStyles.body.copyWith(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],

                // Tip
                if (c.tip != null) ...[
                  const SizedBox(height: SeasonsSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SeasonsColors.warm.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(SeasonsSpacing.radiusMedium),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tip', style: SeasonsTextStyles.heading.copyWith(fontSize: 15)),
                              const SizedBox(height: 6),
                              Text(c.tip!, style: SeasonsTextStyles.bodySecondary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: SeasonsSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

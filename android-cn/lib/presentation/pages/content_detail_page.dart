// lib/presentation/pages/content_detail_page.dart
//
// 养生内容详情页 — 从推荐API获取内容，支持多类型展示
// 食疗 / 穴位 / 运动 / 茶饮 / 睡眠

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/shunshi_colors.dart';
import '../../core/theme/shunshi_spacing.dart';
import '../../core/theme/shunshi_text_styles.dart';
import '../../core/theme/wellness_assets.dart';
import '../../data/network/api_client.dart';
import '../../presentation/widgets/components/soft_card.dart';

/// 内容类型枚举
enum ContentDetailType {
  food,
  acupressure,
  exercise,
  tea,
  sleep,
}

/// 内容详情数据模型
class ContentDetail {
  final String id;
  final String title;
  final String? category;
  final List<String> tags;
  final String? body;
  final String? description;
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
  final double? matchScore;

  const ContentDetail({
    required this.id,
    required this.title,
    this.category,
    this.tags = const [],
    this.body,
    this.description,
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
    this.matchScore,
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

    // Handle body vs description
    String? body = json['body'];
    if (body == null || body.isEmpty) {
      body = json['description'] ?? json['content'] ?? json['text'];
    }

    return ContentDetail(
      id: json['id']?.toString() ?? json['content_id']?.toString() ?? '',
      title: json['title'] ?? '',
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      body: body,
      description: json['description'],
      ingredients: List<String>.from(json['ingredients'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
      benefits: List<String>.from(json['benefits'] ?? json['effects'] ?? []),
      tip: json['tip'] ?? json['note'],
      imageUrl: json['image_url'] ?? json['image'],
      duration: json['duration'],
      difficulty: json['difficulty'],
      emoji: json['emoji'],
      isLiked: json['is_liked'] ?? false,
      type: type,
      matchScore: (json['match_score'] ?? json['score'])?.toDouble(),
    );
  }
}

/// 养生内容详情页
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

  static const Map<ContentDetailType, String> _typeEmojis = {
    ContentDetailType.food: '🥣',
    ContentDetailType.acupressure: '✋',
    ContentDetailType.exercise: '🧘',
    ContentDetailType.tea: '🍵',
    ContentDetailType.sleep: '😴',
  };

  static const Map<ContentDetailType, String> _typeLabels = {
    ContentDetailType.food: '食疗',
    ContentDetailType.acupressure: '穴位',
    ContentDetailType.exercise: '运动',
    ContentDetailType.tea: '茶饮',
    ContentDetailType.sleep: '睡眠',
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

      // 优先尝试推荐 API
      Map<String, dynamic>? data;
      try {
        final response = await client.get('/api/v1/recommend/content/${widget.contentId}');
        data = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null;
      } catch (_) {}

      // 回退到 contents API
      data ??= await (() async {
        try {
          final response = await client.get('/api/v1/contents/${widget.contentId}');
          return response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null;
        } catch (_) {
          return null;
        }
      })();

      // 回退到 CMS API
      data ??= await (() async {
        try {
          final response = await client.get('/api/v1/cms/content/${widget.contentId}');
          return response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null;
        } catch (_) {
          return null;
        }
      })();

      if (data != null) {
        // Handle nested data structure
        final contentData = data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
        setState(() {
          _content = ContentDetail.fromJson(contentData);
          _isLiked = _content!.isLiked;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '未找到内容';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败，请稍后重试';
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
          const SnackBar(content: Text('操作失败，请稍后重试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/library');
      },
      child: Scaffold(
      backgroundColor: ShunshiColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ShunshiColors.primary))
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: ShunshiTextStyles.bodySecondary),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadContent,
            child: const Text('重试'),
          ),
        ],
    ),
    );
  }

  Widget _buildContent() {
    final c = _content!;
    final emoji = c.emoji ?? _typeEmojis[c.type] ?? '📋';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ShunshiSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 返回按钮
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: GestureDetector(
                onTap: () => context.go('/library'),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new, size: 18, color: ShunshiColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('返回', style: ShunshiTextStyles.caption),
                  ],
                ),
              ),
            ),
          ),

          // 顶部大图
          _buildHeroImage(c, emoji),

          const SizedBox(height: 20),

          // emoji + 标题
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(c.title, style: ShunshiTextStyles.insight.copyWith(fontSize: 24)),
          const SizedBox(height: 12),

          // 匹配度 + 分类 + 时长 + 难度 + 收藏
          _buildMetaRow(c),

          const SizedBox(height: 24),

          // 标签
          if (c.tags.isNotEmpty) ...[
            Text('标签', style: ShunshiTextStyles.heading),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: c.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: ShunshiColors.primaryLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(ShunshiSpacing.radiusFull),
                ),
                child: Text(tag, style: ShunshiTextStyles.caption.copyWith(color: ShunshiColors.primaryDark)),
              )).toList(),
            ),
            const SizedBox(height: 28),
          ],

          // 功效
          if (c.benefits.isNotEmpty) ...[
            Text('功效', style: ShunshiTextStyles.heading),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: c.benefits.map((b) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: ShunshiColors.primaryLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(ShunshiSpacing.radiusFull),
                ),
                child: Text(b, style: ShunshiTextStyles.caption.copyWith(color: ShunshiColors.primaryDark)),
              )).toList(),
            ),
            const SizedBox(height: 28),
          ],

          // 正文描述
          if ((c.body ?? c.description) != null && (c.body ?? c.description!).isNotEmpty) ...[
            Text('详情', style: ShunshiTextStyles.heading),
            const SizedBox(height: 10),
            Text(c.body ?? c.description ?? '', style: ShunshiTextStyles.body.copyWith(height: 1.8)),
            const SizedBox(height: 28),
          ],

          // 食材列表
          if (c.ingredients.isNotEmpty) ...[
            Text('材料', style: ShunshiTextStyles.heading),
            const SizedBox(height: 10),
            ...c.ingredients.map((ing) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: ShunshiColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Text(ing, style: ShunshiTextStyles.body),
                ],
              ),
            )),
            const SizedBox(height: 28),
          ],

          // 步骤列表
          if (c.steps.isNotEmpty) ...[
            Text('步骤', style: ShunshiTextStyles.heading),
            const SizedBox(height: 10),
            ...c.steps.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: ShunshiColors.primaryLight.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${entry.key + 1}', style: ShunshiTextStyles.buttonSmall.copyWith(color: ShunshiColors.primaryDark, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(entry.value, style: ShunshiTextStyles.body.copyWith(height: 1.5))),
                ],
              ),
            )),
          ],

          // 小贴士
          if (c.tip != null) ...[
            const SizedBox(height: 28),
            SoftCard(
              borderRadius: ShunshiSpacing.radiusMedium,
              color: ShunshiColors.warm.withValues(alpha: 0.15),
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('小贴士', style: ShunshiTextStyles.heading.copyWith(fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(c.tip!, style: ShunshiTextStyles.bodySecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeroImage(ContentDetail c, String emoji) {
    // 穴位类型优先用已有穴位图
    String? acupointImage;
    if (c.type == ContentDetailType.acupressure) {
      acupointImage = WellnessAssets.getAcupointImage(c.title);
    }
    final fallbackImage = WellnessAssets.getImageForType(c.type.name, c.id);
    final useImage = acupointImage ?? fallbackImage;

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
        color: ShunshiColors.surfaceDim,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
        child: Image.asset(
          useImage,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(child: Text(emoji, style: const TextStyle(fontSize: 72))),
        ),
      ),
    );
  }

  Widget _buildMetaRow(ContentDetail c) {
    return Row(
      children: [
        // 匹配度
        if (c.matchScore != null) ...[
          _buildMatchBadge(c.matchScore!),
          const SizedBox(width: 8),
        ],
        // 分类
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: ShunshiColors.primaryLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(ShunshiSpacing.radiusFull),
          ),
          child: Text(
            c.category ?? _typeLabels[c.type]!,
            style: ShunshiTextStyles.caption.copyWith(color: ShunshiColors.primaryDark),
          ),
        ),
        // 时长
        if (c.duration != null) ...[
          const SizedBox(width: 8),
          Text(c.duration!, style: ShunshiTextStyles.caption),
        ],
        // 难度
        if (c.difficulty != null) ...[
          const SizedBox(width: 4),
          Text(' · ${c.difficulty!}', style: ShunshiTextStyles.caption),
        ],
        const Spacer(),
        // 喜欢按钮
        GestureDetector(
          onTap: _toggleLike,
          child: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? ShunshiColors.blush : ShunshiColors.textHint,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchBadge(double score) {
    final label = score >= 85 ? '高度匹配' : score >= 65 ? '推荐' : '参考';
    final color = score >= 85 ? const Color(0xFF4CAF50) : score >= 65 ? const Color(0xFFFF9800) : const Color(0xFF9E9E9E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text('$label ${score.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

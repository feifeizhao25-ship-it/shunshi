/// 养生馆首页 — V2 渐变卡片网格 + 今日养生横幅 + 入场动画
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/network/api_client.dart';
import '../../../design_system/theme.dart';

// ── 卡片数据模型 ──
class _WellnessCategory {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> lightGradient;
  final List<Color> darkGradient;
  final String route;
  final String? backgroundImage; // AI-generated image asset

  const _WellnessCategory({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.lightGradient,
    required this.darkGradient,
    required this.route,
    this.backgroundImage,
  });
}

class WellnessHomePage extends StatefulWidget {
  const WellnessHomePage({super.key});

  @override
  State<WellnessHomePage> createState() => _WellnessHomePageState();
}

class _WellnessHomePageState extends State<WellnessHomePage>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final List<Animation<double>> _scaleAnimations;
  late final List<Animation<double>> _fadeAnimations;
  late final Animation<double> _bannerFade;

  final _api = ApiClient();
  String _bannerTitle = '午时养心，宜静坐调息';
  String _bannerDesc = '心经当令，适合闭目养神 15 分钟，配合深呼吸舒缓心火。';
  String _bannerTag = '立夏 · 午时';
  String _bannerEmoji = '🧘';

  static const _categories = [
    _WellnessCategory(
      emoji: '🍲',
      title: '饮食调养',
      subtitle: '顺时而食',
      lightGradient: [Color(0xFF2D5A3D), Color(0xFF3E7A55)],
      darkGradient: [Color(0xFF1A3D2A), Color(0xFF2A4D3A)],
      route: '/wellness-category/food_therapy',
      backgroundImage: 'assets/images/food_therapy.jpg',
    ),
    _WellnessCategory(
      emoji: '🧘',
      title: '运动养生',
      subtitle: '动静相宜',
      lightGradient: [Color(0xFF4A7A9B), Color(0xFF6B8FAD)],
      darkGradient: [Color(0xFF2A4A5B), Color(0xFF3A5A6B)],
      route: '/wellness-category/exercise',
      backgroundImage: 'assets/images/exercise.jpg',
    ),
    _WellnessCategory(
      emoji: '🫖',
      title: '茶饮推荐',
      subtitle: '温润养人',
      lightGradient: [Color(0xFF8B6D3F), Color(0xFFB8935A)],
      darkGradient: [Color(0xFF5A4528), Color(0xFF6A5538)],
      route: '/wellness-category/tea',
      backgroundImage: 'assets/images/tea.jpg',
    ),
    _WellnessCategory(
      emoji: '👆',
      title: '穴位按摩',
      subtitle: '通经活络',
      lightGradient: [Color(0xFF6B5A8D), Color(0xFF8B7AAD)],
      darkGradient: [Color(0xFF3A3250), Color(0xFF4A4260)],
      route: '/wellness-category/acupressure',
      backgroundImage: 'assets/images/acupressure.jpg',
    ),
    _WellnessCategory(
      emoji: '🎯',
      title: '冥想放松',
      subtitle: '静心凝神',
      lightGradient: [Color(0xFF3B5998), Color(0xFF5A7ABF)],
      darkGradient: [Color(0xFF25365A), Color(0xFF35466A)],
      route: '/mood',
      backgroundImage: 'assets/images/meditation.jpg',
    ),
    _WellnessCategory(
      emoji: '😴',
      title: '睡眠改善',
      subtitle: '安神助眠',
      lightGradient: [Color(0xFF7A6B5A), Color(0xFF9E9080)],
      darkGradient: [Color(0xFF4A4035), Color(0xFF5A5045)],
      route: '/wellness-category/sleep',
      backgroundImage: 'assets/images/sleep.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimations = List.generate(_categories.length, (i) {
      final start = i * 0.08;
      return Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, start + 0.3, curve: Curves.easeOutBack),
        ),
      );
    });

    _fadeAnimations = List.generate(_categories.length, (i) {
      final start = i * 0.08;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, start + 0.35, curve: Curves.easeOut),
        ),
      );
    });

    _bannerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _staggerController.forward();
    _loadDailyAdvice();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      backgroundColor: bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── TopAppBar ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ShunShiColors.surfaceVariant,
                        border: Border.all(
                          color: ShunShiColors.textTertiary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 20,
                        color: ShunShiColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '养生馆',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.3,
                        color: ShunShiColors.primary,
                        fontFamily: ShunShiTypography.serifFamily,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/notifications'),
                      child: const Icon(
                        Icons.notifications_outlined,
                        size: 22,
                        color: ShunShiColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 1,
              color: ShunShiColors.surfaceContainerLow,
              margin: const EdgeInsets.symmetric(horizontal: 20),
            ),

            // ── Content ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                children: [
                  // ── 搜索栏 ──
                  Container(
                    decoration: BoxDecoration(
                      color: ShunShiColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: '搜索调理方案、节气食谱...',
                        hintStyle: TextStyle(
                          color: ShunShiColors.textTertiary,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: ShunShiColors.textTertiary,
                          size: 22,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 今日养生建议横幅 ──
                  FadeTransition(
                    opacity: _bannerFade,
                    child: _buildDailyTipBanner(isDark),
                  ),
                  const SizedBox(height: 32),

                  // ── 2x3 渐变卡片网格 ──
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      return _buildAnimatedCard(
                        index: index,
                        category: _categories[index],
                        isDark: isDark,
                      );
                    },
                  ),
                  const SizedBox(height: 48),

                  // ── 精选编辑 ──
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: ShunShiColors.apricot,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '精选编辑',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: ShunShiTypography.serifFamily,
                                  color: ShunShiColors.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                '编辑推荐',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: ShunShiColors.secondary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.push('/wellness-report'),
                            child: const Row(
                              children: [
                                Text(
                                  '查看全部',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ShunShiColors.primary,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: ShunShiColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 3 Editor Cards
      _editorCard(
                        tag: '惊蛰',
                        readTime: '5分钟阅读',
                        title: '春季养生：从调理肝气开始',
                        desc: '惊蛰时节，阳气初动。本期编辑精选为您带来春季护肝的三个关键穴位与食疗方案。',
                        likes: '1,208',
                        gradient: [ShunShiColors.apricotLight, ShunShiColors.secondary],
                        route: '/wellness-category/food_therapy',
                      ),
                      const SizedBox(height: 16),
                      _editorCard(
                        tag: '功法',
                        readTime: '8分钟阅读',
                        title: '八段锦：唤醒身体的经络能量',
                        desc: '简单易学的传统健身功法，每天十分钟，改善久坐带来的肩颈僵硬。',
                        likes: '3,450',
                        gradient: [ShunShiColors.primaryContainer, ShunShiColors.primaryLight],
                        route: '/wellness-category/exercise',
                      ),
                      const SizedBox(height: 16),
                      _editorCard(
                        tag: '食补',
                        readTime: '4分钟阅读',
                        title: '五味入五脏：平衡你的日常膳食',
                        desc: '酸入肝、辛入肺。理解食物的味道，就是理解身体的需求。',
                        likes: '892',
                        gradient: [ShunShiColors.apricotLight, ShunShiColors.apricot],
                        route: '/wellness-category/food_therapy',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDailyAdvice() async {
    try {
      String solarTerm = '';
      String timeOfDay = '';

      // Fetch solar term
      final solarRes = await _api.get('/api/v1/solar-terms/today');
      if (solarRes.data is Map) {
        final d = solarRes.data as Map<String, dynamic>;
        solarTerm = d['name'] as String? ?? '';
      }

      // Compute current 时辰
      final hour = DateTime.now().hour;
      const shiChen = [
        '子时', '丑时', '丑时', '寅时', '寅时', '卯时',
        '卯时', '辰时', '辰时', '巳时', '巳时', '午时',
        '午时', '未时', '未时', '申时', '申时', '酉时',
        '酉时', '戌时', '戌时', '亥时', '亥时', '子时',
      ];
      timeOfDay = shiChen[hour];

      // Fetch daily advice
      final res = await _api.get('/api/v1/solar-wellness/daily-advice');
      if (res.data is Map) {
        final d = res.data as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _bannerTitle = d['title'] as String? ?? _bannerTitle;
            _bannerDesc = d['description'] as String? ?? d['content'] as String? ?? _bannerDesc;
            _bannerEmoji = d['emoji'] as String? ?? _bannerEmoji;
            if (solarTerm.isNotEmpty) {
              _bannerTag = '$solarTerm · $timeOfDay';
            }
          });
        }
        return;
      }

      // Fallback: update time-based tag even if advice API fails
      if (mounted && solarTerm.isNotEmpty) {
        setState(() => _bannerTag = '$solarTerm · $timeOfDay');
      }
    } catch (_) {
      // Keep fallback static content
    }
  }

  // ── 今日养生建议横幅 ──
  Widget _buildDailyTipBanner(bool isDark) {
    final bannerGradient = isDark
        ? [const Color(0xFF1A3D2A), const Color(0xFF2D5A3D)]
        : [const Color(0xFF2D5A3D), const Color(0xFF3E7A55)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ShunShiSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ShunShiRadius.xl),
        boxShadow: ShunShiShadows.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 节气 + 时辰 标签
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _bannerTag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '今日建议',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _bannerTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: ShunShiTypography.serifFamily,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _bannerDesc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _bannerEmoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 渐变卡片（带动画） ──
  Widget _buildAnimatedCard({
    required int index,
    required _WellnessCategory category,
    required bool isDark,
  }) {
    final gradient = isDark ? category.darkGradient : category.lightGradient;

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, child) {
        final scale = _scaleAnimations[index].value;
        final opacity = _fadeAnimations[index].value;

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: _WellnessCard(
        category: category,
        gradient: gradient,
        onTap: () => context.push(category.route),
      ),
    );
  }

  // ── 精选编辑卡片（保持原有逻辑） ──
  Widget _editorCard({
    required String tag,
    required String readTime,
    required String title,
    required String desc,
    required String likes,
    required List<Color> gradient,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ShunShiShadows.sm,
          border: Border.all(
            color: ShunShiColors.textTertiary.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            // Left image placeholder
            Container(
              width: 110,
              height: 140,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.article,
                  size: 32,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
            // Right content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: ShunShiColors.apricotLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: ShunShiColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              readTime,
                              style: const TextStyle(
                                fontSize: 10,
                                color: ShunShiColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            fontFamily: ShunShiTypography.serifFamily,
                            color: ShunShiColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          desc,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ShunShiColors.textSecondary,
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 14,
                          color: ShunShiColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$likes 收藏',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: ShunShiColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 可交互的渐变养生卡片 ──
class _WellnessCard extends StatefulWidget {
  final _WellnessCategory category;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _WellnessCard({
    required this.category,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_WellnessCard> createState() => _WellnessCardState();
}

class _WellnessCardState extends State<_WellnessCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.category.backgroundImage != null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ShunShiRadius.xl),
          child: Stack(
            children: [
              // ── Background: image or gradient ──
              if (hasImage)
                Positioned.fill(
                  child: Image.asset(
                    widget.category.backgroundImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              // ── Gradient overlay (semi-transparent to preserve image) ──
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasImage
                          ? [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.55),
                            ]
                          : widget.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // ── Card content ──
              Padding(
                padding: const EdgeInsets.all(ShunShiSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Emoji icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          widget.category.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Title + Subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: ShunShiTypography.serifFamily,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.category.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

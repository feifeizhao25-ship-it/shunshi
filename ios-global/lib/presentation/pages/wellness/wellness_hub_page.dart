import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/theme_helper.dart';

class WellnessHubPage extends StatefulWidget {
  const WellnessHubPage({super.key});

  @override
  State<WellnessHubPage> createState() => _WellnessHubPageState();
}

class _WellnessHubPageState extends State<WellnessHubPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Widget _buildSkeleton() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(height: 28, width: 100, decoration: BoxDecoration(color: Colors.grey[200]?.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6))),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, __) => Container(
                decoration: BoxDecoration(color: Colors.grey[200]?.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
              ),
              childCount: 6,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Container(height: 20, width: 100, decoration: BoxDecoration(color: Colors.grey[200]?.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6))),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 88,
                  decoration: BoxDecoration(color: Colors.grey[200]?.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(14)),
                ),
              ),
              childCount: 3,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(backgroundColor: ShunShiColors.background, body: _buildSkeleton());
    return _buildContent();
  }

  static const _categories = [
    _Cat(Icons.favorite_rounded, '体质调养', Color(0xFFE8B4B4)),
    _Cat(Icons.ramen_dining_rounded, '节气食谱', Color(0xFFB4D8B4)),
    _Cat(Icons.local_cafe_rounded, '养生茶饮', Color(0xFFD4B896)),
    _Cat(Icons.accessibility_new_rounded, '经络穴位', Color(0xFFB4C4D8)),
    _Cat(Icons.self_improvement_rounded, '传统功法', Color(0xFFC8B4D8)),
    _Cat(Icons.menu_book_rounded, '养生日记', Color(0xFFB4D4D4)),
  ];

  static const _picks = [
    _Pick('春季疏肝茶', '玫瑰花 · 陈皮 · 枸杞', '茶饮'),
    _Pick('八段锦入门', '传统养生功法 · 15分钟', '功法'),
    _Pick('子午觉指南', '顺应天时的睡眠调理', '起居'),
  ];

  Widget _buildContent() {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('养生馆', style: TextStyle(
                      fontFamily: ShunShiTypography.serifFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ShunShiColors.primary,
                    )),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.search), color: ShunShiColors.textTertiary, onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('搜索功能开发中'), duration: Duration(seconds: 1))); }),
                      IconButton(icon: const Icon(Icons.notifications_outlined), color: ShunShiColors.textTertiary, onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('暂无新通知'), duration: Duration(seconds: 1))); }),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          // 6 分类卡片
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final c = _categories[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest(context),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        final routes = ['/constitution', '/wellness-category/food_therapy', '/wellness-category/tea', '/wellness-category/acupressure', '/wellness-category/exercise', '/diary'];
                        context.push(routes[index]);
                      },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: c.color.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: Icon(c.icon, color: c.color, size: 24),
                            ),
                            const SizedBox(height: 10),
                            Text(c.title, style: TextStyle(
                              fontFamily: ShunShiTypography.serifFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(context),
                            )),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: 6,
              ),
            ),
          ),
          // 精选编辑标题
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('精选编辑', style: TextStyle(
                    fontFamily: ShunShiTypography.serifFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ShunShiColors.textPrimary,
                  )),
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('更多精选内容开发中'), duration: Duration(seconds: 1))),
                    child: Text('查看全部', style: TextStyle(
                      fontFamily: ShunShiTypography.sansFamily,
                      fontSize: 13,
                      color: AppColors.textTertiary(context),
                    )),
                  ),
                ],
              ),
            ),
          ),
          // 精选内容卡片
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final p = _picks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: ShunShiColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(p.tag, style: TextStyle(
                                    fontFamily: ShunShiTypography.sansFamily,
                                    fontSize: 11,
                                    color: ShunShiColors.primary,
                                    fontWeight: FontWeight.w600,
                                  )),
                                ),
                                const SizedBox(height: 8),
                                Text(p.title, style: TextStyle(
                                  fontFamily: ShunShiTypography.sansFamily,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(context),
                                )),
                                const SizedBox(height: 3),
                                Text(p.subtitle, style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textTertiary(context),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: ShunShiColors.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.play_circle_outline_rounded, color: ShunShiColors.primary, size: 28),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: 3,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('向AI顺时助手了解更多个性化养生方案'), duration: Duration(seconds: 2)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ShunShiColors.primary.withValues(alpha: 0.08), ShunShiColors.primary.withValues(alpha: 0.03)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 20, color: ShunShiColors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('想深入了解您的体质？', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.primary)),
                          const SizedBox(height: 2),
                          Text('完成体质测试，获取AI个性化养生方案', style: TextStyle(fontSize: 12, color: ShunShiColors.textSecondary)),
                        ],
                      )),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: ShunShiColors.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _Cat {
  final IconData icon;
  final String title;
  final Color color;
  const _Cat(this.icon, this.title, this.color);
}

class _Pick {
  final String title;
  final String subtitle;
  final String tag;
  const _Pick(this.title, this.subtitle, this.tag);
}

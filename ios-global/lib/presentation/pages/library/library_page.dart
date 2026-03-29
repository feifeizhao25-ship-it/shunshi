// lib/presentation/pages/library/library_page.dart
//
// 内容库页面 — 极简排版，英文内容
// Tab: Food · Acupressure · Exercise · Tea (4 tabs)
// SingleChildScrollView滚动

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_spacing.dart';
import '../../../core/theme/seasons_text_styles.dart';
import '../../../domain/entities/content.dart';
import '../../providers/library_provider.dart';

// ── 内容类型Tab ────────────────────────────────────────

enum _LibraryTab {
  food,
  acupressure,
  exercise,
  tea,
}

class _TabInfo {
  final _LibraryTab tab;
  final String label;

  const _TabInfo(this.tab, this.label);
}

const _tabs = [
  _TabInfo(_LibraryTab.food, 'Food'),
  _TabInfo(_LibraryTab.acupressure, 'Acupressure'),
  _TabInfo(_LibraryTab.exercise, 'Exercise'),
  _TabInfo(_LibraryTab.tea, 'Tea'),
];

// ── 映射 lib ContentType → our tab ────────────────────

ContentType _contentTypeFromTab(_LibraryTab tab) {
  switch (tab) {
    case _LibraryTab.food:
      return ContentType.food;
    case _LibraryTab.acupressure:
      return ContentType.acupressure;
    case _LibraryTab.exercise:
      return ContentType.stretch;
    case _LibraryTab.tea:
      return ContentType.teaRitual;
  }
}

// ── 主页面 ────────────────────────────────────────────

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _LibraryTab _selectedTab = _LibraryTab.food;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabs[_tabController.index].tab;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final targetType = _contentTypeFromTab(_selectedTab);

    final filteredItems = libraryState.contents
        .where((c) => c.type == targetType)
        .toList();

    return Scaffold(
      backgroundColor: SeasonsColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 标题 ──
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  SeasonsSpacing.pagePadding,
                  20,
                  SeasonsSpacing.pagePadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Library',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w200,
                        color: SeasonsColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your collection of calm',
                      style: SeasonsTextStyles.bodySecondary.copyWith(
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Tab栏 (下划线指示器) ──
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: SeasonsColors.divider,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 2,
                  indicatorColor: SeasonsColors.primary,
                  labelColor: SeasonsColors.textPrimary,
                  unselectedLabelColor: SeasonsColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                  tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── 内容网格 ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SeasonsSpacing.pagePadding,
              ),
              child: filteredItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'Coming soon...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: SeasonsColors.textHint,
                          ),
                        ),
                      ),
                    )
                  : GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.82,
                      children: filteredItems.map((content) {
                        return _ContentCard(
                          content: content,
                          onTap: () =>
                              context.go('/content/${content.id}'),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ── 内容卡片 — 圆角12，无阴影，surfaceDim背景 ──

class _ContentCard extends StatelessWidget {
  final Content content;
  final VoidCallback onTap;

  const _ContentCard({required this.content, required this.onTap});

  IconData _getIcon() {
    switch (content.type) {
      case ContentType.breathing:
        return Icons.air;
      case ContentType.stretch:
        return Icons.self_improvement;
      case ContentType.teaRitual:
        return Icons.coffee;
      case ContentType.sleep:
        return Icons.nightlight_round;
      case ContentType.reflection:
        return Icons.lightbulb_outline;
      case ContentType.meditation:
        return Icons.spa;
      case ContentType.story:
        return Icons.auto_stories;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: SeasonsColors.surfaceDim,
          borderRadius: BorderRadius.circular(SeasonsSpacing.radiusMedium),
          // 无阴影
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon area
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: SeasonsColors.surfaceDim.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(SeasonsSpacing.radiusMedium),
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getIcon(),
                    size: 32,
                    color: SeasonsColors.primary,
                  ),
                ),
              ),
            ),
            // Text
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      content.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: SeasonsColors.textPrimary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (content.durationSeconds != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: SeasonsColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(content.durationSeconds! / 60).round()} min',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: SeasonsColors.textHint,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/home_providers.dart';
import '../../providers/chat_providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../../domain/entities/solar_term.dart';
import '../../../core/theme/app_theme.dart';
import 'home_components.dart';

/// 首页 — 今日计划 + 节气信息
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    if (hour < 22) return '晚上好';
    return '夜深了';
  }

  @override
  Widget build(BuildContext context) {
    final solarTerm = ref.watch(currentSolarTermProvider);
    final dailyPlan = ref.watch(dailyPlanProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HomePremiumHero(
              greeting: _timeGreeting(),
              userName: '朋友', 
              dateText: DateTime.now().toString().substring(0, 10).replaceAll('-', '/'),
              completed: 0,
              total: dailyPlan.valueOrNull?.steps.length ?? 3,
              solarTerm: solarTerm,
              onSolarTermTap: () {},
              onMoodTap: () {},
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SmartInsightHub(
                focusTitle: dailyPlan.valueOrNull?.greeting ?? '顺应节气，调养身心',
                summary: dailyPlan.valueOrNull?.steps.firstOrNull?.detail ?? '请点击查看今日详细养生推荐',
                onOpenPlan: () {},
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HealthToolboxGrid(
                actions: [
                  HomeQuickAction(title: '今日记录', subtitle: '养生打卡', icon: Icons.check_circle_outline, color: AppColors.primary),
                  HomeQuickAction(title: '咨询小师', subtitle: '生活建议', icon: Icons.chat_bubble_outline, color: AppColors.summer),
                  HomeQuickAction(title: '节气日历', subtitle: '今日节气', icon: Icons.calendar_today_outlined, color: AppColors.autumn),
                  HomeQuickAction(title: '养生库', subtitle: '五维指南', icon: Icons.eco_outlined, color: AppColors.spring),
                ],
                onTap: (index) {},
              ),
            ),
          ),
          if (solarTerm != null) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SolarTermPoemCard(
                  solarTerm: solarTerm,
                  onTap: () {},
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}


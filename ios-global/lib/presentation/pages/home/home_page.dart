import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../widgets/seasonal_image.dart';
import '../../widgets/follow_up_card.dart';
import '../../widgets/skeleton_loading.dart';
import '../../../core/services/feedback_service.dart';
import '../../widgets/membership_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Map<String, Map<String, String>> shiChenData = {
    '子': {'time': '23:00-01:00', 'organ': 'Gallbladder', 'element': 'Water'},
    '丑': {'time': '01:00-03:00', 'organ': 'Liver', 'element': 'Earth'},
    '寅': {'time': '03:00-05:00', 'organ': 'Lung', 'element': 'Wood'},
    '卯': {'time': '05:00-07:00', 'organ': 'Large Intestine', 'element': 'Wood'},
    '辰': {'time': '07:00-09:00', 'organ': 'Stomach', 'element': 'Earth'},
    '巳': {'time': '09:00-11:00', 'organ': 'Spleen', 'element': 'Fire'},
    '午': {'time': '11:00-13:00', 'organ': 'Heart', 'element': 'Fire'},
    '未': {'time': '13:00-15:00', 'organ': 'Small Intestine', 'element': 'Earth'},
    '申': {'time': '15:00-17:00', 'organ': 'Bladder', 'element': 'Metal'},
    '酉': {'time': '17:00-19:00', 'organ': 'Kidney', 'element': 'Metal'},
    '戌': {'time': '19:00-21:00', 'organ': 'Pericardium', 'element': 'Earth'},
    '亥': {'time': '21:00-23:00', 'organ': 'Triple Energizer', 'element': 'Water'},
  };

  String _currentTerm = 'Loading...';
  String _userName = 'Friend';
  bool _isLoading = true;
  List<Map<String, dynamic>> _recommendations = [];
  bool _loadingRecs = true;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final data = await FeedbackService.getRecommendations();
    if (data != null && data['recommendations'] != null) {
      setState(() {
        _recommendations = List<Map<String, dynamic>>.from(data['recommendations']);
        _loadingRecs = false;
      });
    } else {
      setState(() => _loadingRecs = false);
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = prefs.getBool('is_subscribed') ?? false;
    if (mounted) setState(() => _isLoading = true);
    final name = prefs.getString('user_name');
    final onboarded = prefs.getBool('onboarding_completed');
    if (onboarded != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push('/onboarding-wellness');
      });
      return;
    }
    try {
      final dio = Dio(BaseOptions(baseUrl: 'http://116.62.32.43:4000'));
      final res = await dio.get('/api/v1/solar-terms/current');
      if (res.data?['data'] != null) {
        final d = res.data['data'];
        if (mounted) {
          setState(() {
          _currentTerm = d['name'] ?? 'Qingming';
        });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
        _currentTerm = 'Qingming';
      });
      }
    }
    if (mounted && name != null) setState(() => _userName = name);
    if (mounted) setState(() => _isLoading = false);
  }

  String get _currentShiChen {
    final hour = DateTime.now().hour;
    const order = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    const startHours = [23, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21];
    for (int i = startHours.length - 1; i >= 0; i--) {
      if (hour >= startHours[i] || (startHours[i] == 23 && hour >= 23)) {
        return order[i];
      }
    }
    return '子';
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          SkeletonLoader(height: 28, width: 180, borderRadius: 8),
          const SizedBox(height: 24),
          SkeletonLoader(height: 180, borderRadius: 8),
          const SizedBox(height: 20),
          SkeletonLoader(height: 20, width: 100, borderRadius: 8),
          const SizedBox(height: 10),
          SkeletonLoader(height: 80, borderRadius: 8),
          const SizedBox(height: 20),
          SkeletonLoader(height: 20, width: 100, borderRadius: 8),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: SkeletonLoader(height: 100, borderRadius: 8)),
            const SizedBox(width: 12),
            Expanded(child: SkeletonLoader(height: 100, borderRadius: 8)),
          ]),
          const SizedBox(height: 20),
          SkeletonLoader(height: 80, borderRadius: 8),
          const SizedBox(height: 20),
          SkeletonLoader(height: 52, borderRadius: 8),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(backgroundColor: ShunShiColors.background, body: SafeArea(child: _buildSkeleton()));
    final sc = shiChenData[_currentShiChen]!;
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Hello, $_userName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary, letterSpacing: -0.5)),
                  IconButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications'), duration: Duration(seconds: 1))); }, icon: const Icon(Icons.notifications_none_rounded, color: ShunShiColors.textTertiary, size: 26)),
                ],
              ),
              const SizedBox(height: 24),

              // Season Hero
              SeasonalImage(termOverride: _currentTerm),
              const SizedBox(height: 8),
              // Time info bar — Stripe precise card style
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: ShunShiColors.surface,
                  borderRadius: ShunShiRadius.cardRadius,
                  border: Border.all(color: ShunShiColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: ShunShiColors.primary),
                    const SizedBox(width: 8),
                    Text(sc['time']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                    const SizedBox(width: 12),
                    Text('${sc['organ']} Meridian · ${sc['element']}', style: const TextStyle(fontSize: 14, color: ShunShiColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Wellness tip
              const Text('Wellness Focus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary, letterSpacing: -0.3)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ShunShiColors.surface,
                  borderRadius: ShunShiRadius.cardRadius,
                  border: Border.all(color: ShunShiColors.border),
                ),
                child: const Text('Nourish yin, clear heat, support kidney energy', style: TextStyle(fontSize: 15, color: ShunShiColors.textSecondary, height: 1.5)),
              ),
              const SizedBox(height: 20),

              // Constitution test
              GestureDetector(
                onTap: () => context.push('/constitution-test'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ShunShiColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: ShunShiRadius.cardRadius,
                    border: Border.all(color: ShunShiColors.primaryLight.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: const Text('🧬', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Constitution Assessment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                      const SizedBox(height: 2),
                      const Text('Discover your body type for personalized wellness', style: TextStyle(fontSize: 12, color: ShunShiColors.textSecondary)),
                    ])),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: ShunShiColors.textTertiary),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // Membership card (free tier only)
              if (!_isSubscribed) ...[
                const MembershipCard(),
                const SizedBox(height: 20),
              ],

              // Follow-up cards
              FollowUpCard(title: 'Explore More', subtitle: 'Based on your constitution', type: 'diet'),

              // Daily check-in card
              GestureDetector(
                onTap: () => context.push('/daily-checkin'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ShunShiColors.surface,
                    borderRadius: ShunShiRadius.cardRadius,
                    border: Border.all(color: ShunShiColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                      child: const Text('📝', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Daily Check-in', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                      const SizedBox(height: 2),
                      const Text('Track mood, sleep, and energy patterns', style: TextStyle(fontSize: 12, color: ShunShiColors.textSecondary)),
                    ])),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: ShunShiColors.textTertiary),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // Action recommendations
              const Text('Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary, letterSpacing: -0.3)),
              const SizedBox(height: 10),
              if (_loadingRecs)
                Row(children: [
                  Expanded(child: SkeletonCard(height: 120, margin: EdgeInsets.zero)),
                  const SizedBox(width: 12),
                  Expanded(child: SkeletonCard(height: 120, margin: EdgeInsets.zero)),
                ])
              else if (_recommendations.isNotEmpty)
                Row(
                  children: _recommendations.take(3).map((rec) {
                    final isFirst = rec == _recommendations.first;
                    return Expanded(child: Padding(padding: EdgeInsets.only(right: isFirst ? 12 : 0), child: _buildRecommendCard(rec)));
                  }).toList(),
                )
              else
                Row(
                  children: [
                    Expanded(child: GestureDetector(onTap: () => context.push('/wellness-category/tea'), child: _actionCard('Stay Hydrated', 'Warm water supports kidney meridian', Icons.water_drop_rounded))),
                    const SizedBox(width: 12),
                    Expanded(child: GestureDetector(onTap: () => context.push('/exercise-detail'), child: _actionCard('Foot Reflexology', 'Tap Yongquan point to ground energy', Icons.pan_tool_rounded))),
                  ],
                ),
              const SizedBox(height: 20),

              // AI Assistant — Stripe-style accent card
              GestureDetector(
                onTap: () => context.push('/chat'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ShunShiColors.primary.withValues(alpha: 0.06),
                    borderRadius: ShunShiRadius.cardRadius,
                    border: Border.all(color: ShunShiColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: Icon(Icons.auto_awesome, color: ShunShiColors.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('AI Wellness Assistant', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                        const SizedBox(height: 2),
                        const Text('Personalized guidance for this season', style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary)),
                      ])),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: ShunShiColors.textTertiary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bottom CTA
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => context.push('/solar-term-detail/$_currentTerm'),
                  style: ElevatedButton.styleFrom(backgroundColor: ShunShiColors.primary, shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.buttonRadius)),
                  child: const Text('View Full Seasonal Guide', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendCard(Map<String, dynamic> rec) {
    final icons = {'diet': Icons.restaurant, 'tea': Icons.local_cafe, 'exercise': Icons.fitness_center, 'sleep': Icons.bedtime, 'emotion': Icons.self_improvement, 'acupoint': Icons.accessibility_new};
    final type = rec['type'] ?? 'diet';
    return GestureDetector(
      onTap: () => context.push('/wellness-hub'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ShunShiColors.surface,
          borderRadius: ShunShiRadius.cardRadius,
          border: Border.all(color: ShunShiColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icons[type] ?? Icons.restaurant, color: ShunShiColors.primary, size: 22),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(rec['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (rec['is_premium'] == true) Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.1), borderRadius: ShunShiRadius.chipRadius),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_rounded, size: 10, color: ShunShiColors.primary),
                const SizedBox(width: 2),
                const Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: ShunShiColors.primary)),
              ]),
            ),
          ]),
          const SizedBox(height: 4),
          Text(rec['reason'] ?? '', style: const TextStyle(fontSize: 11, color: ShunShiColors.textTertiary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _actionCard(String title, String desc, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ShunShiColors.surface,
        borderRadius: ShunShiRadius.cardRadius,
        border: Border.all(color: ShunShiColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: ShunShiColors.textSecondary, size: 24),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, height: 1.4)),
      ]),
    );
  }
}

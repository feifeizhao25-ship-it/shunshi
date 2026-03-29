import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme.dart';
import '../../../data/network/api_client.dart';
import '../../widgets/components/components.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // 用户选择
  final _nameController = TextEditingController(text: '');
  String? _selectedFeeling;
  String? _selectedGoal;
  String? _selectedStage;
  int? _selectedHour;
  String? _selectedStyle;

  final _feelings = [
    ('平静', '😊'),
    ('压力大', '😰'),
    ('疲惫', '😴'),
    ('焦虑', '🥴'),
    ('好奇', '🤔'),
  ];

  final _goals = [
    '😴 改善睡眠',
    '🧘 减压放松',
    '🍵 饮食调理',
    '🏃 增强体质',
    '🌿 中医养生',
    '❤️ 情绪管理',
  ];

  final _stages = [
    ('20-30岁', '活力期'),
    ('30-40岁', '平衡期'),
    ('40-50岁', '调理期'),
    ('50-60岁', '保养期'),
    ('60岁以上', '颐养期'),
  ];

  final _hours = [
    '6:00', '7:00', '8:00', '9:00',
    '12:00', '15:00', '18:00', '20:00', '21:00',
  ];

  final _styles = [
    ('简约清新', '简约'),
    ('温暖柔和', 'gentle'),
    ('活力满满', 'energetic'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0: return true;
      case 1: return _selectedFeeling != null;
      case 2: return _selectedGoal != null;
      case 3: return _selectedStage != null;
      case 4: return _selectedHour != null;
      case 5: return _selectedStyle != null;
      case 6: return true;
      default: return true;
    }
  }

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  // Maps Chinese feeling to API value
  String _feelingToApi(String? feeling) {
    switch (feeling) {
      case '平静': return 'calm';
      case '压力大': return 'stressed';
      case '疲惫': return 'tired';
      case '焦虑': return 'anxious';
      case '好奇': return 'curious';
      default: return 'calm';
    }
  }

  // Maps Chinese goal to API value
  String _goalToApi(String? goal) {
    if (goal == null) return 'relax';
    if (goal.contains('睡眠')) return 'sleep';
    if (goal.contains('放松')) return 'relax';
    if (goal.contains('饮食')) return 'diet';
    if (goal.contains('体质')) return 'health';
    if (goal.contains('中医')) return 'tcm';
    if (goal.contains('情绪')) return 'emotion';
    return 'relax';
  }

  // Maps Chinese stage to API value
  String _stageToApi(String? stage) {
    if (stage == null) return 'professional';
    if (stage == '20-30岁') return 'student';
    if (stage == '30-40岁') return 'professional';
    if (stage == '40-50岁') return 'mid_career';
    if (stage == '50-60岁') return 'pre_retirement';
    if (stage == '60岁以上') return 'retired';
    return 'professional';
  }

  // Maps selected hour index to API time
  String _hourToApi(int? hourIndex) {
    if (hourIndex == null) return 'morning';
    final hour = [6, 7, 8, 9, 12, 15, 18, 20, 21][hourIndex];
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final name = _nameController.text.trim();
    if (name.isNotEmpty) await prefs.setString('user_name', name);
    if (_selectedFeeling != null) await prefs.setString('user_feeling', _selectedFeeling!);
    if (_selectedGoal != null) await prefs.setString('user_goal', _selectedGoal!);
    if (_selectedStage != null) await prefs.setString('user_stage', _selectedStage!);
    if (_selectedHour != null) await prefs.setInt('preferred_hour', _selectedHour!);
    if (_selectedStyle != null) await prefs.setString('style_preference', _selectedStyle!);
    await prefs.setString('hemisphere', 'north'); // Default hemisphere

    // Call onboarding complete API
    try {
      final apiClient = ApiClient();
      await apiClient.post('/api/v1/seasons/onboarding/complete', data: {
        'feeling': _feelingToApi(_selectedFeeling),
        'help_goal': _goalToApi(_selectedGoal),
        'life_stage': _stageToApi(_selectedStage),
        'support_time': _hourToApi(_selectedHour),
        'style_preference': _selectedStyle,
      });
    } catch (e) {
      // API call failed, fallback to local storage - don't block user
      debugPrint('Onboarding API call failed: $e');
    }

    await OnboardingPage.markCompleted();

    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/home');
    }
  }

  // ── 主题感知辅助 ──

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _bg(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.background : ShunshiColors.background;
  Color _primary(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.primary : ShunshiColors.primary;
  Color _primaryLight(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.primaryLight : ShunshiColors.primaryLight;
  Color _textPrimary(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textPrimary : ShunshiColors.textPrimary;
  Color _textSecondary(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textSecondary : ShunshiColors.textSecondary;
  Color _textHint(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textHint : ShunshiColors.textHint;
  Color _border(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.border : ShunshiColors.border;
  Color _surfaceDim(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.surfaceDim : ShunshiColors.surfaceDim;
  Color _surface(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.surface : ShunshiColors.surface;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Onboarding 页面按返回键不退出
      child: Scaffold(
        backgroundColor: _bg(context),
        body: SafeArea(
          child: Column(
            children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(ShunshiSpacing.md),
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    '跳过',
                    style: ShunshiTextStyles.caption.copyWith(
                      color: _textHint(context),
                    ),
                  ),
                ),
              ),
            ),

            // 页面内容
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: 7,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _buildStep(context, index),
              ),
            ),

            // 进度指示器
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ShunshiSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? _primary(context)
                          : _surfaceDim(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // 底部按钮
            Padding(
              padding: EdgeInsets.fromLTRB(
                ShunshiSpacing.pagePadding,
                ShunshiSpacing.md,
                ShunshiSpacing.pagePadding,
                ShunshiSpacing.xl,
              ),
              child: GentleButton(
                text: _currentPage == 6 ? '准备好了' : '下一步',
                isPrimary: true,
                onPressed: _canProceed ? _nextPage : null,
                horizontalPadding: ShunshiSpacing.xl * 2,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, int step) {
    switch (step) {
      case 0: return _buildWelcomeStep(context);
      case 1: return _buildFeelingStep(context);
      case 2: return _buildGoalStep(context);
      case 3: return _buildStageStep(context);
      case 4: return _buildTimeStep(context);
      case 5: return _buildStyleStep(context);
      case 6: return _buildCompleteStep(context);
      default: return const SizedBox.shrink();
    }
  }

  // ==================== Step 0: 欢迎 ====================
  // "Hi, I'm 顺时" + 大留白 + 品牌色渐变背景

  Widget _buildWelcomeStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShunshiSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 品牌色渐变背景logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primary(context), _primaryLight(context)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.eco, size: 48, color: Colors.white),
          ),
          const SizedBox(height: ShunshiSpacing.xxl),

          // 大留白 + 标题
          Text(
            'Hi，我是顺时',
            style: ShunshiTextStyles.greeting.copyWith(
              color: _textPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ShunshiSpacing.md),
          Text(
            '你的专属养生伙伴\n让健康融入每一天',
            textAlign: TextAlign.center,
            style: ShunshiTextStyles.bodySecondary.copyWith(
              color: _textSecondary(context),
              height: 1.8,
            ),
          ),
          const SizedBox(height: ShunshiSpacing.xl),

          // 昵称输入
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: _surfaceDim(context),
              borderRadius: BorderRadius.circular(ShunshiSpacing.radiusXL),
            ),
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: ShunshiTextStyles.bodyMedium.copyWith(
                color: _textPrimary(context),
              ),
              decoration: InputDecoration(
                hintText: '怎么称呼你？',
                hintStyle: ShunshiTextStyles.bodySecondary.copyWith(
                  color: _textHint(context),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '也可以跳过，之后随时修改',
            style: ShunshiTextStyles.caption.copyWith(
              color: _textHint(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Step 1: 情绪选择 (NEW) ====================

  Widget _buildFeelingStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShunshiSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: ShunshiSpacing.xl),
          Text(
            '你最近感觉如何？',
            style: ShunshiTextStyles.greeting.copyWith(
              color: _textPrimary(context),
              fontSize: 24,
            ),
          ),
          const SizedBox(height: ShunshiSpacing.sm),
          Text(
            '选择最符合你当前状态的一项',
            style: ShunshiTextStyles.bodySecondary.copyWith(
              color: _textSecondary(context),
            ),
          ),
          const SizedBox(height: ShunshiSpacing.xl),

          // 情绪选项
          ...List.generate(_feelings.length, (index) {
            final (label, emoji) = _feelings[index];
            final isSelected = _selectedFeeling == label;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _feelings.length - 1 ? ShunshiSpacing.sm : 0,
              ),
              child: SoftCard(
                borderRadius: ShunshiSpacing.radiusLarge,
                borderColor: isSelected ? _primary(context) : null,
                borderWidth: isSelected ? 1.5 : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: ShunshiSpacing.lg,
                  vertical: ShunshiSpacing.md + 4,
                ),
                onTap: () => setState(() => _selectedFeeling = label),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: ShunshiSpacing.md),
                    Expanded(
                      child: Text(
                        label,
                        style: ShunshiTextStyles.body.copyWith(
                          color: isSelected
                              ? _primary(context)
                              : _textPrimary(context),
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle,
                          color: _primary(context), size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
// =================== Step 2: 目标 ===================

  Widget _buildGoalStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShunshiSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: ShunshiSpacing.xl),
          Text(
            '你最想改善什么？',
            style: ShunshiTextStyles.greeting.copyWith(
              color: _textPrimary(context),
              fontSize: 24,
            ),
          ),
          const SizedBox(height: ShunshiSpacing.sm),
          Text(
            '选择一个你最关心的养生目标',
            style: ShunshiTextStyles.bodySecondary.copyWith(
              color: _textSecondary(context),
            ),
          ),
          const SizedBox(height: ShunshiSpacing.xl),

          // 卡片式选择
          ...List.generate(_goals.length, (index) {
            final goal = _goals[index];
            final isSelected = _selectedGoal == goal;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _goals.length - 1 ? ShunshiSpacing.sm : 0,
              ),
              child: SoftCard(
                borderRadius: ShunshiSpacing.radiusLarge,
                borderColor: isSelected ? _primary(context) : null,
                borderWidth: isSelected ? 1.5 : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: ShunshiSpacing.lg,
                  vertical: ShunshiSpacing.md + 4,
                ),
                onTap: () => setState(() => _selectedGoal = goal),
                child: Row(
                  children: [
                    Text(goal, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: ShunshiSpacing.md),
                    Expanded(
                      child: Text(
                        goal,
                        style: ShunshiTextStyles.body.copyWith(
                          color: isSelected
                              ? _primary(context)
                              : _textPrimary(context),
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle,
                          color: _primary(context), size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== Step 3: 阶段 ====================
  // 4个选项

  Widget _buildStageStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShunshiSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: ShunshiSpacing.xl),
          Text(
            '你现在处于哪个阶段？',
            style: ShunshiTextStyles.greeting.copyWith(
              color: _textPrimary(context),
              fontSize: 24,
            ),
          ),
          const SizedBox(height: ShunshiSpacing.sm),
          Text(
            '帮助我们为你定制方案',
            style: ShunshiTextStyles.bodySecondary.copyWith(
              color: _textSecondary(context),
            ),
          ),
          const SizedBox(height: ShunshiSpacing.xl),
          ...List.generate(_stages.length, (index) {
            final (age, label) = _stages[index];
            final isSelected = _selectedStage == age;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _stages.length - 1 ? ShunshiSpacing.sm : 0,
              ),
              child: SoftCard(
                borderRadius: ShunshiSpacing.radiusLarge,
                borderColor: isSelected ? _primary(context) : null,
                borderWidth: isSelected ? 1.5 : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: ShunshiSpacing.lg,
                  vertical: ShunshiSpacing.md + 4,
                ),
                onTap: () => setState(() => _selectedStage = age),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        age,
                        style: ShunshiTextStyles.body.copyWith(
                          color: isSelected
                              ? _primary(context)
                              : _textPrimary(context),
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      style: ShunshiTextStyles.caption.copyWith(
                        color: isSelected
                            ? _primary(context)
                            : _textHint(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== Step 4: 时间偏好 ====================

  Widget _buildTimeStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShunshiSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: ShunshiSpacing.xl),
          Text(
            '你通常什么时候使用？',
            style: ShunshiTextStyles.greeting.copyWith(
              color: _textPrimary(context),
              fontSize: 24,
            ),
          ),
          const SizedBox(height: ShunshiSpacing.sm),
          Text(
            '我们会在合适的时间提醒你',
            style: ShunshiTextStyles.bodySecondary.copyWith(
              color: _textSecondary(context),
            ),
          ),
          const SizedBox(height: ShunshiSpacing.xl),
          Wrap(
            spacing: ShunshiSpacing.sm,
            runSpacing: ShunshiSpacing.sm,
            children: _hours.map((hour) {
              final isSelected = _selectedHour == _hours.indexOf(hour);
              return InkWell(
                onTap: () =>
                    setState(() => _selectedHour = _hours.indexOf(hour)),
                borderRadius:
                    BorderRadius.circular(ShunshiSpacing.radiusFull),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: ShunshiSpacing.lg,
                    vertical: ShunshiSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _primary(context) : _surface(context),
                    borderRadius:
                        BorderRadius.circular(ShunshiSpacing.radiusFull),
                    border: Border.all(
                      color:
                          isSelected ? _primary(context) : _border(context),
                    ),
                  ),
                  child: Text(
                    hour,
                    style: ShunshiTextStyles.bodySecondary.copyWith(
                      color: isSelected
                          ? Colors.white
                          : _textPrimary(context),
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== Step 5: 风格选择 (NEW) ====================

  Widget _buildStyleStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShunshiSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: ShunshiSpacing.xl),
          Text(
            '顺时应该是什么风格？',
            style: ShunshiTextStyles.greeting.copyWith(
              color: _textPrimary(context),
              fontSize: 24,
            ),
          ),
          const SizedBox(height: ShunshiSpacing.sm),
          Text(
            '选择你喜欢的界面风格',
            style: ShunshiTextStyles.bodySecondary.copyWith(
              color: _textSecondary(context),
            ),
          ),
          const SizedBox(height: ShunshiSpacing.xl),

          // 风格选项
          ...List.generate(_styles.length, (index) {
            final (label, apiValue) = _styles[index];
            final isSelected = _selectedStyle == label;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _styles.length - 1 ? ShunshiSpacing.sm : 0,
              ),
              child: SoftCard(
                borderRadius: ShunshiSpacing.radiusLarge,
                borderColor: isSelected ? _primary(context) : null,
                borderWidth: isSelected ? 1.5 : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: ShunshiSpacing.lg,
                  vertical: ShunshiSpacing.md + 4,
                ),
                onTap: () => setState(() => _selectedStyle = label),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: ShunshiTextStyles.body.copyWith(
                          color: isSelected
                              ? _primary(context)
                              : _textPrimary(context),
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle,
                          color: _primary(context), size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
  // ==================== Step 6: 完成 ====================
  // "准备好了" + 进入首页

  Widget _buildCompleteStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShunshiSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primary(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 40, color: _primary(context)),
          ),
          const SizedBox(height: ShunshiSpacing.xxl),
          Text(
            '准备好了',
            style: ShunshiTextStyles.greeting.copyWith(
              color: _textPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ShunshiSpacing.md),
          Text(
            '开始你的养生之旅吧',
            textAlign: TextAlign.center,
            style: ShunshiTextStyles.bodySecondary.copyWith(
              color: _textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

// lib/presentation/pages/profile/profile_setup_page.dart
//
// 用户背景资料填写 — 首次进入 App 时显示

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_spacing.dart';
import '../../../core/theme/shunshi_text_styles.dart';
import '../../../data/network/api_client.dart';
import '../../../core/theme/app_localizations.dart';

/// TCM九种Body Type
const _constitutionTypes = [
  'Balanced',
  'Qi Deficient',
  'Yang Deficient',
  'Yin Deficient',
  'Phlegm-Damp',
  'Damp-Heat',
  'Blood Stasis',
  'Qi Stagnant',
  'Special',
];

/// 健康关注选项
const _healthConcerns = [
  'Sleep',
  'Digestion',
  'Emotions',
  'Immunity',
  'Weight',
  'Skin',
  'Menstruation',
  'Other',
];

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('profile_completed') ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_completed', true);
  }

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _pageController = PageController();
  int _currentStep = 0;

  // 必填
  final _nicknameController = TextEditingController();
  String _gender = '';
  int _birthYear = 1990;
  String _constitution = '';

  // 选填
  final Set<String> _healthConcerns = {};
  final _bodyDescController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  static const int _currentYear = 2026;

  @override
  void dispose() {
    _nicknameController.dispose();
    _bodyDescController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _nicknameController.text.trim().isNotEmpty;
      case 1:
        return _gender.isNotEmpty;
      case 2:
        return true; // birth year always has default
      case 3:
        return _constitution.isNotEmpty;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (!_canProceed) return;
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submitProfile();
    }
  }

  Future<void> _submitProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final profile = {
      'nickname': _nicknameController.text.trim(),
      'gender': _gender,
      'birth_year': _birthYear,
      'constitution_type': _constitution,
      'health_concerns': _healthConcerns.toList(),
      'body_description': _bodyDescController.text.trim(),
    };

    try {
      final client = ApiClient();
      await client.post('/api/v1/user/profile', data: profile);

      // Save到This 地
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', profile['nickname'] as String);
      await prefs.setString('user_gender', profile['gender'] as String);
      await prefs.setInt('user_birth_year', profile['birth_year'] as int);
      await prefs.setString(
          'user_constitution', profile['constitution_type'] as String);
      await prefs.setStringList(
          'user_health_concerns', _healthConcerns.toList());
      await ProfileSetupPage.markCompleted();

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      // 即使 API 失败也SaveThis 地，不阻塞用户
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', profile['nickname'] as String);
      await prefs.setString('user_gender', profile['gender'] as String);
      await prefs.setInt('user_birth_year', profile['birth_year'] as int);
      await prefs.setString(
          'user_constitution', profile['constitution_type'] as String);
      await prefs.setStringList(
          'user_health_concerns', _healthConcerns.toList());
      await ProfileSetupPage.markCompleted();
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunshiColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNicknameStep(),
                  _buildGenderStep(),
                  _buildBirthYearStep(),
                  _buildConstitutionStep(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: ShunshiSpacing.pagePadding, vertical: 16),
      child: Row(
        children: List.generate(4, (i) {
          final active = i <= _currentStep;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: active
                    ? ShunshiColors.primary
                    : ShunshiColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          ShunshiSpacing.pagePadding, 0, ShunshiSpacing.pagePadding, 32),
      child: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!,
                  style: ShunshiTextStyles.caption
                      .copyWith(color: ShunshiColors.error)),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canProceed
                    ? ShunshiColors.primary
                    : ShunshiColors.primary.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    ShunshiColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(ShunshiSpacing.radiusMedium),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _currentStep == 3 ? 'Done' : 'Next',
                      style: ShunshiTextStyles.button
                          .copyWith(color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          if (_currentStep > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                setState(() => _currentStep--);
              },
              child: Text(AppLocalizations.of(context).t('back'),
                  style: ShunshiTextStyles.caption
                      .copyWith(color: ShunshiColors.textHint)),
            ),
        ],
      ),
    );
  }

  // ── Step 0: Nickname ──

  Widget _buildNicknameStep() {
    return _stepWrapper(
      icon: '👋',
      title: AppLocalizations.of(context).t('profile_hello_what_should_we_call_you'),
      subtitle: AppLocalizations.of(context).t('profile_we_will_greet_you_by_this_name'),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: ShunshiColors.surfaceDim,
              borderRadius:
                  BorderRadius.circular(ShunshiSpacing.radiusMedium),
              border: Border.all(color: ShunshiColors.borderLight),
            ),
            child: TextField(
              controller: _nicknameController,
              style: ShunshiTextStyles.heading,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).t('profile_setup_enter_your_nickname'),
                hintStyle: ShunshiTextStyles.bodySecondary,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Gender ──

  Widget _buildGenderStep() {
    return _stepWrapper(
      icon: '✨',
      title: AppLocalizations.of(context).t('profile_what_is_your_gender'),
      subtitle: AppLocalizations.of(context).t('profile_used_for_personalized_wellness_tips'),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _genderOption('Male', Icons.male, '👨'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _genderOption('Female', Icons.female, '👩'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _genderOption(String label, IconData icon, String emoji) {
    final selected = _gender == label;
    return GestureDetector(
      onTap: () => setState(() => _gender = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 120,
        decoration: BoxDecoration(
          color: selected
              ? ShunshiColors.primary.withValues(alpha: 0.12)
              : ShunshiColors.surfaceDim,
          borderRadius:
              BorderRadius.circular(ShunshiSpacing.radiusLarge),
          border: Border.all(
            color: selected
                ? ShunshiColors.primary
                : ShunshiColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(label,
                style: ShunshiTextStyles.heading.copyWith(
                    color: selected
                        ? ShunshiColors.primary
                        : ShunshiColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── Step 2: 出生year份 ──

  Widget _buildBirthYearStep() {
    return _stepWrapper(
      icon: '🎂',
      title: AppLocalizations.of(context).t('profile_which_year_were_you_born_in'),
      subtitle: AppLocalizations.of(context).t('profile_used_to_recommend_wellness_plans_suitable_for'),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text('$_birthYear',
              style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w200,
                  color: ShunshiColors.textPrimary)),
          const SizedBox(height: 8),
          Text('${_currentYear - _birthYear} years old',
              style: ShunshiTextStyles.bodySecondary),
          const SizedBox(height: 32),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: ShunshiColors.primary,
              inactiveTrackColor: ShunshiColors.borderLight,
              thumbColor: ShunshiColors.primary,
              overlayColor:
                  ShunshiColors.primary.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: _birthYear.toDouble(),
              min: 1940,
              max: 2010,
              divisions: 70,
              onChanged: (v) => setState(() => _birthYear = v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1940', style: ShunshiTextStyles.caption),
                Text('2010', style: ShunshiTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 选填：健康关注
          const Divider(color: ShunshiColors.divider),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context).t('profile_main_health_concerns_optional'),
                style: ShunshiTextStyles.heading.copyWith(fontSize: 15)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _healthConcerns.map((c) {
              final selected = _healthConcerns.contains(c);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _healthConcerns.remove(c);
                    } else {
                      _healthConcerns.add(c);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? ShunshiColors.primary.withValues(alpha: 0.12)
                        : ShunshiColors.surfaceDim,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? ShunshiColors.primary
                          : ShunshiColors.borderLight,
                    ),
                  ),
                  child: Text(c,
                      style: ShunshiTextStyles.caption.copyWith(
                          color: selected
                              ? ShunshiColors.primary
                              : ShunshiColors.textSecondary)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Body Type类型 ──

  Widget _buildConstitutionStep() {
    return _stepWrapper(
      icon: '🌿',
      title: AppLocalizations.of(context).t('profile_discover_your_body_type'),
      subtitle: AppLocalizations.of(context).t('profile_select_your_tcm_body_type_to_get_personalized'),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _constitutionTypes.map((type) {
              final selected = _constitution == type;
              return GestureDetector(
                onTap: () => setState(() => _constitution = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? ShunshiColors.primary.withValues(alpha: 0.12)
                        : ShunshiColors.surfaceDim,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? ShunshiColors.primary
                          : ShunshiColors.borderLight,
                    ),
                  ),
                  child: Text(type,
                      style: ShunshiTextStyles.bodyMedium.copyWith(
                          color: selected
                              ? ShunshiColors.primary
                              : ShunshiColors.textSecondary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // "不知道" 按钮
          OutlinedButton.icon(
            onPressed: () async {
              // 跳转Body Type Quiz
              context.push('/constitution-test');
            },
            icon: const Icon(Icons.quiz_outlined, size: 18),
            label: Text(AppLocalizations.of(context).t('profile_not_sure_help_me_take_the_test')),
            style: OutlinedButton.styleFrom(
              foregroundColor: ShunshiColors.primary,
              side: const BorderSide(color: ShunshiColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(height: 24),
          // 身体描述（选填）
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context).t('profile_describe_your_physical_condition_optional'),
                style: ShunshiTextStyles.heading.copyWith(fontSize: 15)),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 100),
            decoration: BoxDecoration(
              color: ShunshiColors.surfaceDim,
              borderRadius:
                  BorderRadius.circular(ShunshiSpacing.radiusMedium),
              border: Border.all(color: ShunshiColors.borderLight),
            ),
            child: TextField(
              controller: _bodyDescController,
              maxLines: 3,
              style: ShunshiTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).t('profile_setup_for_example_often_tired_poor'),
                hintStyle: ShunshiTextStyles.caption
                    .copyWith(color: ShunshiColors.textHint),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepWrapper({
    required String icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: ShunshiSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child:
                Text(icon, style: const TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(title,
                style: ShunshiTextStyles.heading
                    .copyWith(fontSize: 20)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(subtitle,
                style: ShunshiTextStyles.bodySecondary
                    .copyWith(fontSize: 14)),
          ),
          child,
        ],
      ),
    );
  }
}

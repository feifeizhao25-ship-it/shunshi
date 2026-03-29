// lib/presentation/pages/reflection/reflection_page.dart
//
// 每日反思页面 — 像写日记，不严肃不复杂
// 用户操作≤10秒：选情绪 → 可选写一句话 → 记录
// 情绪：😊😌😢😰 | GentleButton | 跳过今天

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_spacing.dart';
import '../../../core/theme/shunshi_text_styles.dart';
import '../../widgets/components/gentle_button.dart';

// ── 情绪定义 ──────────────────────────────────────────

enum _ReflectionMood {
  happy,     // 开心 😊
  calm,      // 平静 😌
  sad,       // 难过 😢
  anxious,   // 焦虑 😰
}

class _MoodOption {
  final _ReflectionMood mood;
  final String emoji;
  final String label;

  const _MoodOption({
    required this.mood,
    required this.emoji,
    required this.label,
  });
}

const _moodOptions = [
  _MoodOption(mood: _ReflectionMood.happy, emoji: '😊', label: '开心'),
  _MoodOption(mood: _ReflectionMood.calm, emoji: '😌', label: '平静'),
  _MoodOption(mood: _ReflectionMood.sad, emoji: '😢', label: '难过'),
  _MoodOption(mood: _ReflectionMood.anxious, emoji: '😰', label: '焦虑'),
];

// ── 每日反思问题池 ────────────────────────────────────

const _questions = [
  '今天让你感恩的是什么？',
  '今天最美好的瞬间是什么？',
  '今天你想对自己说什么？',
  '今天有什么让你微笑？',
  '今天你学到了什么？',
  '今天什么让你感到平静？',
];

// ── 主页面 ────────────────────────────────────────────

class ReflectionPage extends StatefulWidget {
  const ReflectionPage({super.key});

  @override
  State<ReflectionPage> createState() => _ReflectionPageState();
}

class _ReflectionPageState extends State<ReflectionPage> {
  _ReflectionMood? _selectedMood;
  final _notesController = TextEditingController();
  bool _submitted = false;

  /// 根据日期取固定问题
  String get _todayQuestion {
    final dayOfYear = DateTime.now().difference(
      DateTime(DateTime.now().year),
    ).inDays;
    return _questions[dayOfYear % _questions.length];
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedMood == null) return;

    setState(() {
      _submitted = true;
    });

    // TODO: 调用provider保存数据

    // 2秒后重置
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _submitted = false;
          _selectedMood = null;
          _notesController.clear();
        });
      }
    });
  }

  void _skip() {
    // TODO: 记录跳过
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return const _SuccessView();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
      backgroundColor: ShunshiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: ShunshiSpacing.pagePadding,
          ),
          child: Column(
            children: [
              // ── 大留白顶部 ──
              const SizedBox(height: 80),

              // ── 问题居中 22sp insight样式 ──
              Text(
                _todayQuestion,
                style: ShunshiTextStyles.insight.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),

              // ── 思考空间 ──
              const SizedBox(height: 60),

              // ── 情绪选择：4个大圆圈emoji（😊😌😢😰）──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _moodOptions.map((opt) {
                  final isSelected = _selectedMood == opt.mood;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = opt.mood),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      height: 72,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? ShunshiColors.primaryLight.withValues(alpha: 0.3)
                            : ShunshiColors.surface,
                        border: Border.all(
                          color: isSelected
                              ? ShunshiColors.primary
                              : ShunshiColors.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          opt.emoji,
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 24,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // ── 情绪标签 ──
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _moodOptions.map((opt) {
                  final isSelected = _selectedMood == opt.mood;
                  return SizedBox(
                    width: 72,
                    child: Center(
                      child: Text(
                        opt.label,
                        style: ShunshiTextStyles.caption.copyWith(
                          color: isSelected
                              ? ShunshiColors.primary
                              : ShunshiColors.textHint,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // ── 可选文字输入框，大圆角 ──
              const SizedBox(height: 40),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: ShunshiTextStyles.body,
                decoration: InputDecoration(
                  hintText: '写点什么...',
                  hintStyle: ShunshiTextStyles.hint,
                  filled: true,
                  fillColor: ShunshiColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      ShunshiSpacing.radiusXL,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      ShunshiSpacing.radiusXL,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      ShunshiSpacing.radiusXL,
                    ),
                    borderSide: BorderSide(
                      color: ShunshiColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),

              // ── "记录下来" GentleButton ──
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: GentleButton(
                  text: '记录下来',
                  isPrimary: _selectedMood != null,
                  onPressed: _selectedMood != null ? _submit : null,
                  horizontalPadding: ShunshiSpacing.lg,
                ),
              ),

              // ── "跳过今天" textSecondary色文字链接 ──
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _skip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '跳过今天',
                    style: ShunshiTextStyles.caption.copyWith(
                      color: ShunshiColors.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

// ── 提交成功视图 ──────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunshiColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🌿',
              style: TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 20),
            Text(
              '已记录',
              style: ShunshiTextStyles.insight.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              '愿今天的你，温柔而坚定',
              style: ShunshiTextStyles.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }
}

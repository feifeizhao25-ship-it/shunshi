// lib/presentation/pages/reflection/reflection_page.dart
//
// Reflection 页面 — 极简日记感，大留白
// 英文问题 · 5个情绪选项 · 更大间距
// GentleButton

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_spacing.dart';
import '../../../core/theme/seasons_text_styles.dart';
import '../../../domain/entities/reflection.dart';
import '../../providers/reflection_provider.dart';
import '../../widgets/components/gentle_button.dart';

// ── 情绪选项 (5个) ────────────────────────────────────

enum _ReflectionMood {
  grateful,
  calm,
  happy,
  tired,
  reflective,
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
  _MoodOption(mood: _ReflectionMood.grateful, emoji: '🙏', label: 'Grateful'),
  _MoodOption(mood: _ReflectionMood.calm, emoji: '😌', label: 'Calm'),
  _MoodOption(mood: _ReflectionMood.happy, emoji: '😊', label: 'Happy'),
  _MoodOption(mood: _ReflectionMood.tired, emoji: '😴', label: 'Tired'),
  _MoodOption(mood: _ReflectionMood.reflective, emoji: '🌙', label: 'Reflective'),
];

// ── 每日问题池 ────────────────────────────────────────

const _questions = [
  'What are you grateful for today?',
  'What was the best moment of your day?',
  'What do you want to tell yourself today?',
  'What made you smile today?',
  'What did you learn today?',
  'What brought you peace today?',
  'What are you letting go of?',
];

// ── 主页面 ────────────────────────────────────────────

class ReflectionPage extends ConsumerStatefulWidget {
  const ReflectionPage({super.key});

  @override
  ConsumerState<ReflectionPage> createState() => _ReflectionPageState();
}

class _ReflectionPageState extends ConsumerState<ReflectionPage> {
  _ReflectionMood? _selectedMood;
  final _notesController = TextEditingController();
  bool _submitted = false;

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

    // Map to domain Mood
    final domainMood = _mapMood(_selectedMood!);
    ref.read(reflectionProvider.notifier).submitReflection(
          mood: domainMood,
          energy: EnergyLevel.medium,
          sleep: SleepQuality.good,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
        );

    setState(() => _submitted = true);

    Future.delayed(const Duration(milliseconds: 2500), () {
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
    Navigator.of(context).maybePop();
  }

  Mood _mapMood(_ReflectionMood mood) {
    switch (mood) {
      case _ReflectionMood.grateful:
        return Mood.grateful;
      case _ReflectionMood.calm:
        return Mood.calm;
      case _ReflectionMood.happy:
        return Mood.happy;
      case _ReflectionMood.tired:
        return Mood.tired;
      case _ReflectionMood.reflective:
        return Mood.hopeful;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return const _SuccessView();
    }

    return Scaffold(
      backgroundColor: SeasonsColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: SeasonsSpacing.pagePadding,
          ),
          child: Column(
            children: [
              // ── 大留白 (更大) ──
              const SizedBox(height: 100),

              // ── 英文问题 ──
              Text(
                _todayQuestion,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: SeasonsColors.textPrimary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              // ── 思考空间 (更大) ──
              const SizedBox(height: 72),

              // ── 情绪选择 (5个大圆圈emoji) ──
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _moodOptions.map((opt) {
                  final isSelected = _selectedMood == opt.mood;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedMood = opt.mood),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? SeasonsColors.primary.withValues(alpha: 0.12)
                                : SeasonsColors.surface,
                            border: Border.all(
                              color: isSelected
                                  ? SeasonsColors.primary
                                  : SeasonsColors.border,
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
                        const SizedBox(height: 8),
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: isSelected
                                ? SeasonsColors.primary
                                : SeasonsColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              // ── 输入框 ──
              const SizedBox(height: 48),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: SeasonsTextStyles.body.copyWith(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Write something...',
                  hintStyle: SeasonsTextStyles.hint,
                  filled: true,
                  fillColor: SeasonsColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      SeasonsSpacing.radiusXL,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      SeasonsSpacing.radiusXL,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      SeasonsSpacing.radiusXL,
                    ),
                    borderSide: BorderSide(
                      color: SeasonsColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),

              // ── Save GentleButton ──
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: GentleButton(
                  text: 'Save',
                  isPrimary: _selectedMood != null,
                  onPressed: _selectedMood != null ? _submit : null,
                  horizontalPadding: SeasonsSpacing.lg,
                ),
              ),

              // ── Skip today ──
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _skip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Skip today',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: SeasonsColors.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 提交成功视图 ──

class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeasonsColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🌿',
              style: TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 24),
            const Text(
              'Saved',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: SeasonsColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be gentle with yourself today',
              style: SeasonsTextStyles.bodySecondary.copyWith(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

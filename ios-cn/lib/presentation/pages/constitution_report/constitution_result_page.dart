/// 节气生活习惯自测结果页。没有传入类型和分数时不展示个人结果。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

class ConstitutionResultPage extends StatelessWidget {
  final String? constitutionType;
  final Map<String, double>? scores;

  const ConstitutionResultPage({
    super.key,
    this.constitutionType,
    this.scores,
  });

  bool get _hasResult {
    final type = constitutionType?.trim() ?? '';
    return type.isNotEmpty && scores != null && scores!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final seasonLabel = _getSeasonLabel(now.month);

    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ShunShiColors.surfaceVariant,
                      ),
                      child: const Icon(Icons.person, size: 20, color: ShunShiColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    const Text('顺时', style: TextStyle(
                      fontSize: 20, fontStyle: FontStyle.italic,
                      fontFamily: ShunShiTypography.serifFamily,
                      color: ShunShiColors.primary,
                    )),
                    const Spacer(),
                    const Icon(Icons.notifications_outlined, size: 22, color: ShunShiColors.primary),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: ShunShiColors.surfaceContainerLow, margin: const EdgeInsets.symmetric(horizontal: 20)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
              child: _hasResult
                  ? _result(now, seasonLabel)
                  : _empty(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 48),
        const Text('还没有你的问卷结果', style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700,
          fontFamily: ShunShiTypography.serifFamily,
          color: ShunShiColors.primary,
        )),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.push('/constitution-test'),
          child: const Text('去做问卷'),
        ),
      ],
    );
  }

  Widget _result(DateTime now, String seasonLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('节气生活习惯自测报告 · ${now.year}年$seasonLabel', style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: ShunShiColors.secondary, letterSpacing: 2,
        )),
        const SizedBox(height: 12),
        const Text('生活习惯倾向：', style: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w700,
          fontFamily: ShunShiTypography.serifFamily,
          color: ShunShiColors.primary, height: 1.3,
        )),
        Text(constitutionType!.trim(), style: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w700,
          fontFamily: ShunShiTypography.serifFamily,
          color: ShunShiColors.primary, height: 1.3,
        )),
        const SizedBox(height: 32),
        const Text('倾向对照', style: TextStyle(
          fontSize: 18, fontFamily: ShunShiTypography.serifFamily,
          color: ShunShiColors.primary,
        )),
        const SizedBox(height: 16),
        ...scores!.entries.map(_bar),
      ],
    );
  }

  Widget _bar(MapEntry<String, double> entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.key, style: TextStyle(fontSize: 12, color: ShunShiColors.secondary)),
              Text('${(entry.value * 100).round()}%', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: ShunShiColors.secondary,
              )),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: entry.value.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: ShunShiColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(ShunShiColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _getSeasonLabel(int month) {
    if (month >= 3 && month <= 5) return '春分';
    if (month >= 6 && month <= 8) return '夏至';
    if (month >= 9 && month <= 11) return '秋分';
    return '冬至';
  }
}

/// 生活习惯倾向页。没有传入类型和分数时不展示个人结果。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

class BodyTypeEssenceV2 extends StatelessWidget {
  final String? bodyType;
  final Map<String, double>? scores;
  const BodyTypeEssenceV2({super.key, this.bodyType, this.scores});

  bool get _hasResult {
    final type = bodyType?.trim() ?? '';
    return type.isNotEmpty && scores != null && scores!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: SafeArea(
        child: _hasResult ? _result() : _empty(context),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('还没有你的问卷结果', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: ShunShiColors.textPrimary,
            fontFamily: ShunShiTypography.serifFamily,
          )),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.push('/constitution-test'),
            child: const Text('去做问卷'),
          ),
        ],
      ),
    );
  }

  Widget _result() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        const Text('生活习惯倾向', style: TextStyle(fontSize: 12, color: Color(0xFF533afd), fontWeight: FontWeight.w500, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Text(bodyType!.trim(), style: const TextStyle(
          fontFamily: ShunShiTypography.serifFamily, fontSize: 24, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
        )),
        const SizedBox(height: 8),
        const Text('这是生活习惯参考，不是诊断。', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary, height: 1.5)),
        const SizedBox(height: 20),
        ...scores!.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            SizedBox(width: 88, child: Text(entry.key, style: const TextStyle(fontSize: 13, color: ShunShiColors.textSecondary))),
            Expanded(child: LinearProgressIndicator(value: entry.value.clamp(0.0, 1.0), minHeight: 8)),
            const SizedBox(width: 8),
            Text('${(entry.value * 100).round()}%', style: const TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
          ]),
        )),
      ],
    );
  }
}

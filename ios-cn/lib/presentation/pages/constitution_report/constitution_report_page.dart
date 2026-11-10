/// 节气生活习惯自测报告页。没有传入类型和分数时不展示个人结果。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

class ConstitutionReportPage extends StatelessWidget {
  final String? constitutionType;
  final Map<String, double>? scores;

  const ConstitutionReportPage({super.key, this.constitutionType, this.scores});

  bool get _hasResult {
    final type = constitutionType?.trim() ?? '';
    return type.isNotEmpty && scores != null && scores!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('节气生活习惯自测报告', style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: _hasResult ? _result() : _empty(context),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('还没有你的问卷结果', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: ShunShiColors.primary,
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
      padding: const EdgeInsets.all(20),
      children: [
        Text('生活习惯倾向：${constitutionType!.trim()}', style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: ShunShiColors.primary,
          fontFamily: ShunShiTypography.serifFamily,
        )),
        const SizedBox(height: 8),
        const Text('这些建议只是生活方式提示，不是诊断。', style: TextStyle(
          fontSize: 12, color: ShunShiColors.textTertiary, height: 1.5,
        )),
        const SizedBox(height: 20),
        const Text('倾向对照', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ShunShiColors.textPrimary)),
        const SizedBox(height: 12),
        ...scores!.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            SizedBox(width: 80, child: Text(entry.key, style: const TextStyle(fontSize: 13, color: ShunShiColors.textSecondary))),
            Expanded(child: LinearProgressIndicator(value: entry.value.clamp(0.0, 1.0), minHeight: 8, color: ShunShiColors.primary)),
            const SizedBox(width: 8),
            Text('${(entry.value * 100).round()}%', style: const TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
          ]),
        )),
      ],
    );
  }
}

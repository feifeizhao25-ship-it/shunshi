import '../../../core/router/safe_pop.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

/// 节气生活习惯自测结果页。类型或分数缺失时不展示个人结果。
class ConstitutionTestPage extends StatelessWidget {
  final String? constitutionType;
  final Map<String, double>? scores;
  const ConstitutionTestPage({super.key, this.constitutionType, this.scores});

  bool get _hasResult {
    final type = constitutionType?.trim() ?? '';
    return type.isNotEmpty && scores != null && scores!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('节气生活习惯自测结果', style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20), onPressed: () => safePop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _hasResult ? _result() : _empty(context),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 48),
        const Text('还没有你的问卷结果', style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700,
          fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary,
        )),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.push('/constitution-test'),
          child: const Text('去做问卷'),
        ),
      ],
    );
  }

  Widget _result() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [ShunShiColors.primary, Color(0xFF2D5A3D)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.spa, size: 48, color: Colors.white70),
              const SizedBox(height: 12),
              Text(constitutionType!.trim(), style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: ShunShiTypography.serifFamily,
              )),
              const SizedBox(height: 8),
              const Text('生活习惯倾向', style: TextStyle(fontSize: 13, color: Colors.white60)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('倾向对照', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700,
            fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary,
          )),
        ),
        const SizedBox(height: 12),
        ...scores!.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(width: 72, child: Text(entry.key, style: const TextStyle(fontSize: 13, color: ShunShiColors.textSecondary))),
              Expanded(child: LinearProgressIndicator(value: entry.value.clamp(0.0, 1.0), minHeight: 8)),
              const SizedBox(width: 8),
              Text('${(entry.value * 100).round()}%', style: const TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
            ],
          ),
        )),
      ],
    );
  }
}

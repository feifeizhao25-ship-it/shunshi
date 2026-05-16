import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/shunshi_colors.dart';
import 'constitution_data.dart';
import '../../../../core/theme/app_localizations.dart';
import '../../../../core/network/api_singleton.dart';

/// Body TypeResults Widget
class ConstitutionResultWidget extends StatelessWidget {
  final ConstitutionResult result;
  final bool reportUnlocked;
  final VoidCallback onUnlock;
  final VoidCallback onRetest;
  final VoidCallback onViewDetail;
  final VoidCallback onShare;

  const ConstitutionResultWidget({
    super.key,
    required this.result,
    required this.reportUnlocked,
    required this.onUnlock,
    required this.onRetest,
    required this.onViewDetail,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFree = !reportUnlocked;

    return Stack(children: [
      ListView(padding: EdgeInsets.only(bottom: isFree ? 220 : 80), children: [
        _buildHero(context),
        SizedBox(height: 20),
        _buildOverview(context),
        _buildScoreBars(context),
        SizedBox(height: 20),
        if (isFree) ..._buildBlurredSections(context),
        if (!isFree) ..._buildPremiumSections(context),
        SizedBox(height: 100),
      ]),
      Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar(context)),
    ]);
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ShunshiColors.primary, ShunshiColors.primaryDark],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(children: [
        Text(result.emoji, style: const TextStyle(fontSize: 56)),
        SizedBox(height: 8),
        Text(AppLocalizations.of(context).t('wellness_your_constitution_type_is'),
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
        SizedBox(height: 4),
        Text(result.typeName,
            style: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
        SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: Text('Test Date: ${DateTime.now().toString().substring(0, 16)}',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
        ),
      ]),
    );
  }

  Widget _buildOverview(BuildContext context) {
    return _Section([
      Text(result.description,
          style: const TextStyle(fontSize: 14, color: ShunshiColors.textSecondary, height: 1.7)),
      SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: result.characteristics
            .map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: ShunshiColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(c,
                      style: const TextStyle(
                          fontSize: 12, color: ShunshiColors.primaryDark, fontWeight: FontWeight.w500)),
                ))
            .toList(),
      ),
    ]);
  }

  Widget _buildScoreBars(BuildContext context) {
    return _Section([
      Row(children: [
        Text('📊', style: TextStyle(fontSize: 18)),
        SizedBox(width: 8),
        Text(AppLocalizations.of(context).t('constitutionrep_constitution_scores'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary))
      ]),
      SizedBox(height: 14),
      ...result.scores.map((s) {
        final name = s['name'] as String? ?? '';
        final score = (s['score'] as num?)?.toDouble() ?? 0;
        final level = s['level'] as String? ?? 'normal';
        final maxScore = 60.0;
        final ratio = (score / maxScore).clamp(0.0, 1.0);
        final isPrimary = name == result.typeName;
        final barColor = isPrimary
            ? ShunshiColors.primary
            : (ratio > 0.5 ? ShunshiColors.earth : ShunshiColors.primaryLight);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(
                width: 60,
                child: Text(name,
                    style: TextStyle(
                        fontSize: 12,
                        color: isPrimary ? ShunshiColors.primaryDark : ShunshiColors.textSecondary,
                        fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w400))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: ShunshiColors.divider,
                    valueColor: AlwaysStoppedAnimation(barColor)),
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
                width: 28,
                child: Text(score.toStringAsFixed(0),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPrimary ? ShunshiColors.primaryDark : ShunshiColors.textPrimary))),
            SizedBox(width: 4),
            if (level == 'obvious')
              Text(AppLocalizations.of(context).t('wellness_deviation'), style: TextStyle(fontSize: 10, color: ShunshiColors.earth))
            else if (level == 'tendency')
              Text(AppLocalizations.of(context).t('wellness_tendency'), style: TextStyle(fontSize: 10, color: Color(0xFFD4956A))),
          ]),
        );
      }),
    ]);
  }

  List<Widget> _buildBlurredSections(context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return result.advice.map((adv) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? ShunshiDarkColors.surface : Colors.white, borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(adv.icon, style: const TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text(adv.category,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary))
              ]),
              SizedBox(height: 14),
              ...adv.items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(item,
                        style:
                            const TextStyle(fontSize: 14, color: ShunshiColors.textSecondary, height: 1.6)),
                  )),
            ]),
            Positioned.fill(
                child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(color: Colors.white.withValues(alpha: 0.3)))),
          ]),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPremiumSections(context) {
    return [
      ...result.advice.map((adv) => _Section([
            ...adv.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 8),
                        decoration: const BoxDecoration(color: ShunshiColors.primary, shape: BoxShape.circle)),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text(item,
                            style: const TextStyle(
                                fontSize: 14, color: ShunshiColors.textSecondary, height: 1.7))),
                  ]),
                )),
          ])),
      if (result.avoidList.isNotEmpty)
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.5)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('⚠️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(AppLocalizations.of(context).t('wellness_precautions'),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E)))
            ]),
            SizedBox(height: 10),
            Text(result.avoidList,
                style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.7)),
          ]),
        ),
    ];
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))
          ]),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!reportUnlocked) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7ED), Color(0xFFFFF1E0)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5A84B).withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Text('👑', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(AppLocalizations.of(context).t('wellness_unlock_full_constitution_report'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                  SizedBox(height: 2),
                  Text(AppLocalizations.of(context).t('wellness_diet_tea_exercise_acupoints_seasonal_plans'),
                      style: TextStyle(fontSize: 11, color: Color(0xFFB07937))),
                ])),
                Icon(Icons.chevron_right, color: const Color(0xFFD4956A).withValues(alpha: 0.6)),
              ]),
            ),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onUnlock,
                  icon: Icon(Icons.lock_open, size: 18),
                  label: Text(AppLocalizations.of(context).t('wellness_unlock_report'),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A84B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ]),
          ] else ...[
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetest,
                  icon: Icon(Icons.refresh, size: 18),
                  label: Text(AppLocalizations.of(context).t('wellness_retest'), style: TextStyle(fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ShunshiColors.primary,
                    side: const BorderSide(color: ShunshiColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onViewDetail,
                  icon: Icon(Icons.auto_awesome, size: 18),
                  label: Text(AppLocalizations.of(context).t('solar_view_details'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ShunshiColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ]),
            SizedBox(height: 8),
            TextButton.icon(
              onPressed: onShare,
              icon: Icon(Icons.share_outlined, size: 16),
              label: Text(AppLocalizations.of(context).t('solar_share_result'), style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: ShunshiColors.textSecondary),
            ),
          ],
        ]),
      ),
    );
  }
}

/// 内部 Section 封装
class _Section extends StatelessWidget {
  final List<Widget> children;
  const _Section(this.children);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? ShunshiDarkColors.surface : Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

import '../../../core/router/safe_pop.dart';
import '../../../design_system/app_colors.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../data/network/session.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';
class DailyCheckinPage extends StatefulWidget {
  const DailyCheckinPage({super.key});
  @override
  State<DailyCheckinPage> createState() => _DailyCheckinPageState();
}

class _DailyCheckinPageState extends State<DailyCheckinPage> {
  double _mood = 3;
  double _sleep = 3;
  double _energy = 3;
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  static const _moodLabels = ['', 'Very Bad', 'Bad', 'Okay', 'Good', 'Great'];
  static const _moodEmojis = ['', '😞', '😔', '😐', '🙂', '😊'];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final dio = apiClient.dio;
      // 打卡 = 写一条今日日记（心情 / 精力 / 睡眠）；服务端同时记一次打卡、发积分。
      // 以前这里 POST 一个不存在的 /user/daily-checkin 且不带登录令牌，提交必然失败，「记录」「成就」页自然永远是 0。
      final token = await ensureSessionToken(dio);
      if (token == null) throw StateError('no session');
      final note = _noteController.text.trim();
      await dio.post('/api/v1/journal/entry', data: {
        'mood': _mood.round(),
        'energy': _energy.round(),
        'sleep_quality': _sleep.round(),
        if (note.isNotEmpty) 'notes': note,
      }, options: Options(headers: {'Authorization': 'Bearer $token'}));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).t('home_recorded_keep_it_up')), duration: Duration(seconds: 2), backgroundColor: AppColors.primary(context)),
        );
        safePop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).t('home_submit_failed_please_retry')), duration: Duration(seconds: 2)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSlider({
    required String label,
    required String emoji,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGhost(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
            const Spacer(),
            Text(
              '${value.round()} pts · ${_moodLabels[value.round()]}',
              style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 14, color: AppColors.primary(context), fontWeight: FontWeight.w500),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Text('1', style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context))),
            Expanded(child: SliderTheme(data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary(context),
              inactiveTrackColor: AppColors.primary(context).withValues(alpha: 0.15),
              thumbColor: AppColors.primary(context),
              overlayColor: AppColors.primary(context).withValues(alpha: 0.1),
            ), child: Slider(value: value, min: 1, max: 5, divisions: 4, onChanged: onChanged))),
            Text('5', style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context))),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : AppColors.background(context),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, size: 20, color: AppColors.textPrimary(context)), onPressed: () => safePop(context)),
        title: Text(AppLocalizations.of(context).t('notification_checkin'), style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'How do you feel today?',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
          ),
          const SizedBox(height: 6),
          Text(
            'Record your body and heart state for more precise suggestions',
            style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 14, color: AppColors.textTertiary(context)),
          ),
          const SizedBox(height: 24),
          _buildSlider(label: AppLocalizations.of(context).t('home_mood'), emoji: _moodEmojis[_mood.round()], value: _mood, onChanged: (v) => setState(() => _mood = v)),
          const SizedBox(height: 16),
          _buildSlider(label: AppLocalizations.of(context).t('diary_sleep_quality'), emoji: '😴', value: _sleep, onChanged: (v) => setState(() => _sleep = v)),
          const SizedBox(height: 16),
          _buildSlider(label: AppLocalizations.of(context).t('checkin_energy_level'), emoji: '⚡', value: _energy, onChanged: (v) => setState(() => _energy = v)),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context).t('home_what_would_you_like_to_record_today'), style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondary(context))),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderGhost(context))),
            child: TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).t('daily_checkin_for_example_did_baduanjin_today'),
                hintStyle: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 14, color: AppColors.textTertiary(context)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                disabledBackgroundColor: AppColors.primary(context).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(AppLocalizations.of(context).t('home_submit_checkin'), style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

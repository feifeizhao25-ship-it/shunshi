import '../../../core/router/safe_pop.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

const _baseUrl = 'http://116.62.32.43:4000';

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

  static const _moodLabels = ['', '很差', '较差', '一般', '不错', '很好'];
  static const _moodEmojis = ['', '😞', '😔', '😐', '🙂', '😊'];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      await dio.post('/api/v1/user/daily-checkin', data: {
        'mood': _mood.round(),
        'sleep_quality': _sleep.round(),
        'energy': _energy.round(),
        'notes': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记录成功！继续保持 💪'), duration: Duration(seconds: 2), backgroundColor: ShunShiColors.primary),
        );
        safePop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('提交失败，请稍后重试'), duration: Duration(seconds: 2)),
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
        color: ShunShiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ShunShiColors.borderGhost),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            const Spacer(),
            Text(
              '${value.round()}分 · ${_moodLabels[value.round()]}',
              style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 14, color: ShunShiColors.primary, fontWeight: FontWeight.w500),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Text('1', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
            Expanded(child: SliderTheme(data: SliderTheme.of(context).copyWith(
              activeTrackColor: ShunShiColors.primary,
              inactiveTrackColor: ShunShiColors.primary.withValues(alpha: 0.15),
              thumbColor: ShunShiColors.primary,
              overlayColor: ShunShiColors.primary.withValues(alpha: 0.1),
            ), child: Slider(value: value, min: 1, max: 5, divisions: 4, onChanged: onChanged))),
            Text('5', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    final textPrimary = isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    final textSecondary = isDark ? ShunShiColors.darkTextSecondary : ShunShiColors.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, size: 20, color: textPrimary), onPressed: () => safePop(context)),
        title: Text('每日打卡', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '今天感觉怎么样？',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 20, fontWeight: FontWeight.w700, color: ShunShiColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            '记录你的身心状态，我们会给出更精准的建议',
            style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 14, color: ShunShiColors.textTertiary),
          ),
          const SizedBox(height: 24),
          _buildSlider(label: '心情', emoji: _moodEmojis[_mood.round()], value: _mood, onChanged: (v) => setState(() => _mood = v)),
          const SizedBox(height: 16),
          _buildSlider(label: '睡眠质量', emoji: '😴', value: _sleep, onChanged: (v) => setState(() => _sleep = v)),
          const SizedBox(height: 16),
          _buildSlider(label: '精力水平', emoji: '⚡', value: _energy, onChanged: (v) => setState(() => _energy = v)),
          const SizedBox(height: 24),
          Text('今天有什么想记录的？', style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 15, fontWeight: FontWeight.w500, color: ShunShiColors.textSecondary)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: ShunShiColors.borderGhost)),
            child: TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '比如：今天做了八段锦，喝了枸杞茶...',
                hintStyle: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 14, color: ShunShiColors.textTertiary),
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
                backgroundColor: ShunShiColors.primary,
                disabledBackgroundColor: ShunShiColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('提交打卡', style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

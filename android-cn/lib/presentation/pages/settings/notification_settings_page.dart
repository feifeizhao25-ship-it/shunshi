import '../../../core/router/safe_pop.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';

/// 通知设置页
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _jieqiReminder = true;
  bool _dailyCheckin = true;
  TimeOfDay _dailyCheckinTime = const TimeOfDay(hour: 8, minute: 0);
  bool _exerciseReminder = false;
  bool _sleepReminder = true;
  TimeOfDay _sleepReminderTime = const TimeOfDay(hour: 21, minute: 30);
  bool _healthNews = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _jieqiReminder = prefs.getBool('notify_jieqi') ?? true;
      _dailyCheckin = prefs.getBool('notify_daily_checkin') ?? true;
      _exerciseReminder = prefs.getBool('notify_exercise') ?? false;
      _sleepReminder = prefs.getBool('notify_sleep') ?? true;
      _healthNews = prefs.getBool('notify_health_news') ?? true;
      final dh = prefs.getInt('notify_daily_checkin_hour') ?? 8;
      final dm = prefs.getInt('notify_daily_checkin_minute') ?? 0;
      _dailyCheckinTime = TimeOfDay(hour: dh, minute: dm);
      final sh = prefs.getInt('notify_sleep_hour') ?? 21;
      final sm = prefs.getInt('notify_sleep_minute') ?? 30;
      _sleepReminderTime = TimeOfDay(hour: sh, minute: sm);
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_jieqi', _jieqiReminder);
    await prefs.setBool('notify_daily_checkin', _dailyCheckin);
    await prefs.setBool('notify_exercise', _exerciseReminder);
    await prefs.setBool('notify_sleep', _sleepReminder);
    await prefs.setBool('notify_health_news', _healthNews);
    await prefs.setInt('notify_daily_checkin_hour', _dailyCheckinTime.hour);
    await prefs.setInt('notify_daily_checkin_minute', _dailyCheckinTime.minute);
    await prefs.setInt('notify_sleep_hour', _sleepReminderTime.hour);
    await prefs.setInt('notify_sleep_minute', _sleepReminderTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context),
        ),
        title: const Text('通知设置',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _buildSwitchTile(
            icon: Icons.eco_outlined,
            title: '节气提醒',
            subtitle: '每个节气到来时通知你',
            value: _jieqiReminder,
            onChanged: (v) { setState(() => _jieqiReminder = v); _save(); },
          ),
          _buildTimeTile(
            icon: Icons.check_circle_outline,
            title: '每日打卡提醒',
            subtitle: '每天提醒你完成养生打卡',
            value: _dailyCheckin,
            time: _dailyCheckinTime,
            onToggle: (v) { setState(() => _dailyCheckin = v); _save(); },
            onTimeChanged: (t) { setState(() => _dailyCheckinTime = t); _save(); },
          ),
          _buildSwitchTile(
            icon: Icons.fitness_center_outlined,
            title: '运动提醒',
            subtitle: '提醒你完成每日运动',
            value: _exerciseReminder,
            onChanged: (v) { setState(() => _exerciseReminder = v); _save(); },
          ),
          _buildTimeTile(
            icon: Icons.bedtime_outlined,
            title: '睡眠提醒',
            subtitle: '提醒你按时休息',
            value: _sleepReminder,
            time: _sleepReminderTime,
            onToggle: (v) { setState(() => _sleepReminder = v); _save(); },
            onTimeChanged: (t) { setState(() => _sleepReminderTime = t); _save(); },
          ),
          _buildSwitchTile(
            icon: Icons.article_outlined,
            title: '健康资讯推送',
            subtitle: '推送养生知识与节气资讯',
            value: _healthNews,
            onChanged: (v) { setState(() => _healthNews = v); _save(); },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, size: 22, color: ShunShiColors.textSecondary),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: ShunShiColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildTimeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required TimeOfDay time,
    required ValueChanged<bool> onToggle,
    required ValueChanged<TimeOfDay> onTimeChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(icon, size: 22, color: ShunShiColors.textSecondary),
            title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
            value: value,
            onChanged: onToggle,
            activeThumbColor: ShunShiColors.primary,
          ),
          if (value)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: InkWell(
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: time);
                  if (t != null) onTimeChanged(t);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: ShunShiColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('提醒时间', style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary)),
                      Row(children: [
                        Text(time.format(context),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.primary)),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time, size: 18, color: ShunShiColors.primary),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

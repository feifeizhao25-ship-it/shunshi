/// 设置页 — 参考UI _3
library;

import 'package:flutter/material.dart';
import '../../../design_system/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';

class SettingsPageV2 extends StatefulWidget {
  const SettingsPageV2({super.key});

  @override
  State<SettingsPageV2> createState() => _SettingsPageV2State();
}

class _SettingsPageV2State extends State<SettingsPageV2> {
  bool _solarReminder = true;
  bool _shichenReminder = true;
  bool _checkinReminder = false;
  bool _elderMode = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
      _solarReminder = prefs.getBool('solar_reminder') ?? true;
      _shichenReminder = prefs.getBool('shichen_reminder') ?? true;
      _checkinReminder = prefs.getBool('checkin_reminder') ?? false;
      _elderMode = prefs.getBool('elder_mode') ?? false;
    });
    }
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Settings', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // 用户信息
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(
                shape: BoxShape.circle, color: ShunShiColors.primaryContainer,
              ), child: Icon(Icons.person, color: AppColors.primary(context))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CloudWater', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                Text('Account: seasons_2024', style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context))),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // 账号安全
          _buildSectionCard([
            _buildNavTile(Icons.shield, 'Account security'),
            _buildNavTile(Icons.lock, 'Privacy settings'),
          ]),
          const SizedBox(height: 16),

          // 消息推送
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Push notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                const SizedBox(height: 12),
                _buildSwitchTile('Solar term reminder', 'Follow the 24 solar terms for wellness tips', Icons.eco, _solarReminder, (v) { setState(() => _solarReminder = v); _savePref('solar_reminder', v); }),
                _buildSwitchTile('Daily rhythm reminders', 'Gentle reminders through the day', Icons.schedule, _shichenReminder, (v) { setState(() => _shichenReminder = v); _savePref('shichen_reminder', v); }),
                _buildSwitchTile('Check-in reminder', 'Daily wellness task reminder', Icons.done_all, _checkinReminder, (v) { setState(() => _checkinReminder = v); _savePref('checkin_reminder', v); }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 老年人模式
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              SwitchListTile(
                value: _elderMode,
                onChanged: (v) { setState(() => _elderMode = v); _savePref('elder_mode', v); },
                title: Row(children: [
                  Icon(Icons.family_restroom, color: AppColors.primary(context), size: 20),
                  const SizedBox(width: 8),
                  Text('Senior mode', style: TextStyle(fontSize: 15, color: AppColors.textPrimary(context))),
                ]),
                subtitle: Text('Larger text and a simpler interface', style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context))),
                activeThumbColor: AppColors.primary(context),
              ),
              if (_elderMode) Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primary(context).withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                  child: Text('Preview: it\'s 3–5 a.m. · Lung meridian time\nMorning breathing practice', style: TextStyle(fontSize: 18, color: AppColors.primary(context), fontWeight: FontWeight.w500)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          _buildSectionCard([
            ListTile(
              key: const Key('settings-plan-usage'),
              leading: Icon(Icons.data_usage_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              title: Text('Plan & usage', style: const TextStyle(fontSize: 15)),
              trailing: Icon(Icons.chevron_right, size: 18),
              onTap: () => context.push('/plan-usage'),
            ),
            ListTile(
              key: const Key('settings-culture'),
              leading: Icon(Icons.public_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              title: const Text('Culture & units', style: TextStyle(fontSize: 15)),
              trailing: Icon(Icons.chevron_right, size: 18),
              onTap: () => context.push('/culture-settings'),
            ),
          ]),
          const SizedBox(height: 16),

          // 清除缓存 + 关于
          _buildSectionCard([
            ListTile(
              leading: Icon(Icons.cleaning_services, color: AppColors.primary(context), size: 20),
              title: Text('Clear cache', style: TextStyle(fontSize: 15, color: AppColors.textPrimary(context))),
              trailing: Text('124.5 MB', style: TextStyle(fontSize: 13, color: AppColors.textTertiary(context))),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.primary(context), size: 20),
              title: Text('About SEASONS', style: TextStyle(fontSize: 15, color: AppColors.textPrimary(context))),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Version 2.4.0', style: TextStyle(fontSize: 13, color: AppColors.textTertiary(context))),
                Icon(Icons.chevron_right, color: AppColors.textTertiary(context), size: 18),
              ]),
              onTap: () => context.push('/about'),
            ),
          ]),
          const SizedBox(height: 24),

          // 退出登录
          Center(
            child: GestureDetector(
              onTap: () => context.go('/login'),
              child: Text('Log out', style: TextStyle(fontSize: 15, color: Colors.red[400])),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text('DESIGNED BY SEASONS · WELLNESS IN RHYTHM', style: TextStyle(fontSize: 10, color: AppColors.textTertiary(context), letterSpacing: 1))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildNavTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary(context), size: 20),
      title: Text(title, style: TextStyle(fontSize: 15, color: AppColors.textPrimary(context))),
      trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary(context), size: 18),
      onTap: () {},
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value, onChanged: onChanged,
      title: Row(children: [
        Icon(icon, color: AppColors.primary(context), size: 18),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context))),
      ]),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textTertiary(context))),
      activeThumbColor: AppColors.primary(context),
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// 设置页 — 参考UI _3
library;

import 'package:flutter/material.dart';
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
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Settings', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // 用户信息
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(
                shape: BoxShape.circle, color: ShunShiColors.primaryContainer,
              ), child: const Icon(Icons.person, color: ShunShiColors.primary)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CloudWater', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                Text('Account: seasons_2024', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
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
            decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Push notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                const SizedBox(height: 12),
                _buildSwitchTile('Solar term reminder', 'Follow the 24 solar terms for wellness tips', Icons.eco, _solarReminder, (v) { setState(() => _solarReminder = v); _savePref('solar_reminder', v); }),
                _buildSwitchTile('Daily rhythm reminders', 'Timed reminders for the twelve two-hour periods', Icons.schedule, _shichenReminder, (v) { setState(() => _shichenReminder = v); _savePref('shichen_reminder', v); }),
                _buildSwitchTile('Check-in reminder', 'Daily wellness task reminder', Icons.done_all, _checkinReminder, (v) { setState(() => _checkinReminder = v); _savePref('checkin_reminder', v); }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 老年人模式
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              SwitchListTile(
                value: _elderMode,
                onChanged: (v) { setState(() => _elderMode = v); _savePref('elder_mode', v); },
                title: Row(children: [
                  Icon(Icons.family_restroom, color: ShunShiColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Senior mode', style: TextStyle(fontSize: 15, color: ShunShiColors.textPrimary)),
                ]),
                subtitle: Text('Larger text and a simpler interface', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
                activeThumbColor: ShunShiColors.primary,
              ),
              if (_elderMode) Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: ShunShiColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                  child: Text('Preview: it\'s 3–5 a.m. · Lung meridian time\nMorning breathing practice', style: TextStyle(fontSize: 18, color: ShunShiColors.primary, fontWeight: FontWeight.w500)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // 清除缓存 + 关于
          _buildSectionCard([
            ListTile(
              leading: Icon(Icons.cleaning_services, color: ShunShiColors.primary, size: 20),
              title: Text('Clear cache', style: TextStyle(fontSize: 15, color: ShunShiColors.textPrimary)),
              trailing: Text('124.5 MB', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: ShunShiColors.primary, size: 20),
              title: Text('About SEASONS', style: TextStyle(fontSize: 15, color: ShunShiColors.textPrimary)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Version 2.4.0', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
                const Icon(Icons.chevron_right, color: ShunShiColors.textTertiary, size: 18),
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
          Center(child: Text('DESIGNED BY SEASONS · WELLNESS IN RHYTHM', style: TextStyle(fontSize: 10, color: ShunShiColors.textTertiary, letterSpacing: 1))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildNavTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: ShunShiColors.primary, size: 20),
      title: Text(title, style: TextStyle(fontSize: 15, color: ShunShiColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: ShunShiColors.textTertiary, size: 18),
      onTap: () {},
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value, onChanged: onChanged,
      title: Row(children: [
        Icon(icon, color: ShunShiColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, color: ShunShiColors.textPrimary)),
      ]),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
      activeThumbColor: ShunShiColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}

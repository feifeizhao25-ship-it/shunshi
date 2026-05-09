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
        title: Text('设置', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
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
                Text('云水禅心', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                Text('账号：shunshi_2024', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // 账号安全
          _buildSectionCard([
            _buildNavTile(Icons.shield, '账号安全中心'),
            _buildNavTile(Icons.lock, '隐私设置'),
          ]),
          const SizedBox(height: 16),

          // 消息推送
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('消息推送', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                const SizedBox(height: 12),
                _buildSwitchTile('节气提醒', '跟随二十四节气，获取养生建议', Icons.eco, _solarReminder, (v) { setState(() => _solarReminder = v); _savePref('solar_reminder', v); }),
                _buildSwitchTile('时辰提醒', '按中医十二时辰定时提醒', Icons.schedule, _shichenReminder, (v) { setState(() => _shichenReminder = v); _savePref('shichen_reminder', v); }),
                _buildSwitchTile('打卡提醒', '每日养生任务完成提醒', Icons.done_all, _checkinReminder, (v) { setState(() => _checkinReminder = v); _savePref('checkin_reminder', v); }),
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
                  Text('老年人模式', style: TextStyle(fontSize: 15, color: ShunShiColors.textPrimary)),
                ]),
                subtitle: Text('提供更大字体与简洁界面', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
                activeThumbColor: ShunShiColors.primary,
              ),
              if (_elderMode) Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: ShunShiColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                  child: Text('预览效果：现在是 寅时 · 肺经当令\n早起呼吸训练', style: TextStyle(fontSize: 18, color: ShunShiColors.primary, fontWeight: FontWeight.w500)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // 清除缓存 + 关于
          _buildSectionCard([
            ListTile(
              leading: Icon(Icons.cleaning_services, color: ShunShiColors.primary, size: 20),
              title: Text('清除缓存', style: TextStyle(fontSize: 15, color: ShunShiColors.textPrimary)),
              trailing: Text('124.5 MB', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: ShunShiColors.primary, size: 20),
              title: Text('关于顺时', style: TextStyle(fontSize: 15, color: ShunShiColors.textPrimary)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('版本 2.4.0', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
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
              child: Text('退出登录', style: TextStyle(fontSize: 15, color: Colors.red[400])),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text('DESIGNED BY SHUNSHI · 顺时养生', style: TextStyle(fontSize: 10, color: ShunShiColors.textTertiary, letterSpacing: 1))),
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

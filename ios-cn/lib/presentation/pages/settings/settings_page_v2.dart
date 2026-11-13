/// 设置页 — 参考UI _3
library;

import 'package:flutter/material.dart';
import '../../../data/storage/local_session.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../../data/services/notification_service.dart';
import '../../../design_system/app_colors.dart';
import '../../account/account_surface.dart';
import '../../account/settings_account.dart';

class SettingsPageV2 extends StatefulWidget {
  const SettingsPageV2({super.key, this.loadAccount, this.loadPersonalization, this.savePersonalization});

  /// Defaults to the account record, entitlement status, and solar-term table.
  final Future<AccountSurface> Function()? loadAccount;

  /// 读「个性化推荐」开关。测试可以换成假的，避免请求网络。
  final Future<bool> Function()? loadPersonalization;

  /// 保存开关。关闭后首页卡片应和没开个性化时一样。
  final Future<void> Function(bool enabled)? savePersonalization;

  @override
  State<SettingsPageV2> createState() => _SettingsPageV2State();
}

class _SettingsPageV2State extends State<SettingsPageV2> {
  bool _solarReminder = true;
  bool _shichenReminder = true;
  bool _checkinReminder = false;
  bool _elderMode = false;
  bool _personalization = true;
  bool _savingPersonalization = false;
  AccountSurface? _account;

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
    if (widget.loadPersonalization != null) {
      try {
        final on = await widget.loadPersonalization!();
        if (mounted) setState(() => _personalization = on);
      } catch (_) {}
    }
    try {
      final account = await (widget.loadAccount ?? loadSettingsAccount)();
      if (mounted) setState(() => _account = account);
    } catch (_) {
      if (mounted) {
        setState(() => _account = accountSurface(loggedIn: false, beijingDay: DateTime.now()));
      }
    }
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (value && key == 'shichen_reminder') NotificationService().askForPermissionInContext();
  }

  Future<void> _setPersonalization(bool value) async {
    if (_savingPersonalization) return;
    final previous = _personalization;
    setState(() {
      _personalization = value;
      _savingPersonalization = true;
    });
    try {
      await widget.savePersonalization?.call(value);
      if (mounted) setState(() => _savingPersonalization = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _personalization = previous;
        _savingPersonalization = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('没能保存设置，请稍后再试')));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('设置', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
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
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_account?.name ?? '未登录', key: const Key('settings-account-name'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                Text(_account?.membership ?? '', key: const Key('settings-account-membership'), style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context))),
                if ((_account?.seasonText ?? '').isNotEmpty)
                  Text(_account!.seasonText, key: const Key('settings-account-season'), style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context))),
              ])),
            ]),
          ),
          const SizedBox(height: 16),

          // 账号安全
          _buildSectionCard([
            
            _buildNavTile(Icons.lock, '隐私与数据', '/privacy'),
          ]),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
            child: Material(
              color: Colors.transparent,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('推荐', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                const SizedBox(height: 4),
                SwitchListTile(
                  key: const Key('settings-personalization'),
                  value: _personalization,
                  onChanged: _savingPersonalization ? null : _setPersonalization,
                  title: Text('个性化推荐', style: TextStyle(fontSize: 15, color: AppColors.textPrimary(context))),
                  subtitle: Text('关掉之后，首页不再按你的目标和地区来排，卡片和大家看到的一样。', style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context))),
                  activeThumbColor: AppColors.primary(context),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            ),
          ),
          const SizedBox(height: 16),

          // 消息推送
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
            child: Material(
              color: Colors.transparent,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('消息推送', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                const SizedBox(height: 12),
                _buildSwitchTile('节气提醒', '跟随二十四节气，获取养生建议', Icons.eco, _solarReminder, (v) { setState(() => _solarReminder = v); _savePref('solar_reminder', v); }),
                _buildSwitchTile('时辰提醒', '按中医十二时辰定时提醒', Icons.schedule, _shichenReminder, (v) { setState(() => _shichenReminder = v); _savePref('shichen_reminder', v); }),
                _buildSwitchTile('打卡提醒', '每日养生任务完成提醒', Icons.done_all, _checkinReminder, (v) { setState(() => _checkinReminder = v); _savePref('checkin_reminder', v); }),
              ],
            ),
            ),
          ),
          const SizedBox(height: 16),

          // 老年人模式
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
            child: Material(color: Colors.transparent, child: Column(children: [
              SwitchListTile(
                value: _elderMode,
                onChanged: (v) { setState(() => _elderMode = v); _savePref('elder_mode', v); },
                title: Row(children: [
                  Icon(Icons.family_restroom, color: AppColors.primary(context), size: 20),
                  const SizedBox(width: 8),
                  Text('老年人模式', style: TextStyle(fontSize: 15, color: AppColors.textPrimary(context))),
                ]),
                subtitle: Text('提供更大字体与简洁界面', style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context))),
                activeThumbColor: AppColors.primary(context),
              ),
              if (_elderMode) Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primary(context).withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                  child: Text('预览效果：字号会像这样放大，页面也会更简洁\n今日节气提示', style: TextStyle(fontSize: 18, color: AppColors.primary(context), fontWeight: FontWeight.w500)),
                ),
              ),
            ]),
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionCard([
            ListTile(
              key: const Key('settings-plan-usage'),
              leading: Icon(Icons.data_usage_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              title: Text('套餐与用量', style: const TextStyle(fontSize: 15)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => context.push('/plan-usage'),
            ),
          ]),
          const SizedBox(height: 16),

          // 清除缓存 + 关于
          _buildSectionCard([
            ListTile(
              leading: Icon(Icons.cleaning_services, color: AppColors.primary(context), size: 20),
              title: Text('清除缓存', style: TextStyle(fontSize: 15, color: AppColors.textPrimary(context))),
              onTap: () {
                PaintingBinding.instance.imageCache.clear();
                PaintingBinding.instance.imageCache.clearLiveImages();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清除图片缓存')));
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.primary(context), size: 20),
              title: Text('关于顺时', style: TextStyle(fontSize: 15, color: AppColors.textPrimary(context))),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('版本 1.0.0', style: TextStyle(fontSize: 13, color: AppColors.textTertiary(context))),
                Icon(Icons.chevron_right, color: AppColors.textTertiary(context), size: 18),
              ]),
              onTap: () => context.push('/about'),
            ),
          ]),
          const SizedBox(height: 24),

          // 退出登录
          Center(
            child: GestureDetector(
              onTap: () async {
                await endLocalSession();
                if (!context.mounted) return;
                context.go('/login');
              },
              child: Text('退出登录', style: TextStyle(fontSize: 15, color: Colors.red[400])),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text('顺时 · 顺应节气的日常养生', style: TextStyle(fontSize: 10, color: AppColors.textTertiary(context), letterSpacing: 1))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
      child: Material(color: Colors.transparent, child: Column(children: children)),
    );
  }

  Widget _buildNavTile(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary(context), size: 20),
      title: Text(title, style: TextStyle(fontSize: 15, color: AppColors.textPrimary(context))),
      trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary(context), size: 18),
      onTap: () => context.push(route),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value, onChanged: onChanged,
      title: Row(children: [
        Icon(icon, color: AppColors.primary(context), size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(title, style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context)))),
      ]),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textTertiary(context))),
      activeThumbColor: AppColors.primary(context),
      contentPadding: EdgeInsets.zero,
    );
  }
}

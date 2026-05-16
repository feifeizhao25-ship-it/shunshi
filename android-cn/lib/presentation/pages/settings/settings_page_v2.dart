/// 设置页 — 参考UI _3（升级版）
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    final cardColor = isDark ? ShunShiColors.darkSurface : ShunShiColors.surface;
    final textPrimary = isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    final textTertiary = isDark ? ShunShiColors.darkTextTertiary : ShunShiColors.textTertiary;
    final primaryColor = isDark ? ShunShiColors.darkPrimary : ShunShiColors.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textPrimary),
            onPressed: () => context.pop()),
        title: Text('设置',
            style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── 用户信息卡 ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark ? [] : ShunShiShadows.sm,
            ),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [ShunShiColors.primary, ShunShiColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('云水禅心',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          fontFamily: ShunShiTypography.serifFamily,
                          color: textPrimary)),
                  const SizedBox(height: 2),
                  Text('账号：shunshi_2024',
                      style: TextStyle(fontSize: 12, color: textTertiary)),
                ]),
              ),
              Icon(Icons.chevron_right, color: textTertiary, size: 20),
            ]),
          ),
          const SizedBox(height: 24),

          // ── 分组标题：账号与安全 ──
          _buildSectionTitle('账号与安全', isDark),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark ? [] : ShunShiShadows.sm,
            ),
            child: Column(children: [
              _buildNavTile(context, Icons.shield_outlined, '账号安全中心',
                  const [Color(0xFF5C6BC0), Color(0xFF7986CB)]),
              _buildDivider(isDark),
              _buildNavTile(context, Icons.lock_outline, '隐私设置',
                  const [Color(0xFF4DB6AC), Color(0xFF80CBC4)]),
            ]),
          ),
          const SizedBox(height: 24),

          // ── 分组标题：消息推送 ──
          _buildSectionTitle('消息推送', isDark),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark ? [] : ShunShiShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSwitchTile(context, '节气提醒', '跟随二十四节气，获取养生建议',
                    Icons.eco, _solarReminder, (v) {
                  setState(() => _solarReminder = v);
                  _savePref('solar_reminder', v);
                }),
                const SizedBox(height: 8),
                _buildSwitchTile(context, '时辰提醒', '按中医十二时辰定时提醒',
                    Icons.schedule, _shichenReminder, (v) {
                  setState(() => _shichenReminder = v);
                  _savePref('shichen_reminder', v);
                }),
                const SizedBox(height: 8),
                _buildSwitchTile(context, '打卡提醒', '每日养生任务完成提醒',
                    Icons.done_all, _checkinReminder, (v) {
                  setState(() => _checkinReminder = v);
                  _savePref('checkin_reminder', v);
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 分组标题：显示与辅助 ──
          _buildSectionTitle('显示与辅助', isDark),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark ? [] : ShunShiShadows.sm,
            ),
            child: Column(children: [
              _buildSwitchTile(context, '老年人模式', '提供更大字体与简洁界面',
                  Icons.family_restroom, _elderMode, (v) {
                setState(() => _elderMode = v);
                _savePref('elder_mode', v);
              }),
              if (_elderMode)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '预览效果：现在是 寅时 · 肺经当令\n早起呼吸训练',
                      style: TextStyle(
                        fontSize: 20,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 24),

          // ── 分组标题：其他 ──
          _buildSectionTitle('其他', isDark),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark ? [] : ShunShiShadows.sm,
            ),
            child: Column(children: [
              _buildNavTile(context, Icons.cleaning_services_outlined, '清除缓存',
                  const [Color(0xFF90A4AE), Color(0xFFB0BEC5)],
                  trailing: Text('124.5 MB',
                      style: TextStyle(fontSize: 13, color: textTertiary))),
              _buildDivider(isDark),
              _buildNavTile(context, Icons.info_outline, '关于顺时',
                  const [Color(0xFF90A4AE), Color(0xFFB0BEC5)],
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('版本 2.4.0',
                    style: TextStyle(fontSize: 13, color: textTertiary)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right,
                    color: textTertiary, size: 18),
              ]), onTap: () => context.push('/about')),
            ]),
          ),
          const SizedBox(height: 32),

          // ── 退出登录 ──
          Center(
            child: GestureDetector(
              onTap: () => context.go('/login'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: ShunShiColors.error.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('退出登录',
                    style: TextStyle(
                      fontSize: 15,
                      color: ShunShiColors.error,
                      fontWeight: FontWeight.w500,
                    )),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
              child: Text('DESIGNED BY SHUNSHI · 顺时养生',
                  style: TextStyle(
                      fontSize: 10,
                      color: textTertiary,
                      letterSpacing: 1))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 分组标题 — 小号大写 + 间距
  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: isDark
              ? ShunShiColors.darkTextTertiary
              : ShunShiColors.textTertiary,
        ),
      ),
    );
  }

  /// 导航列表项 — 渐变图标 + 右箭头
  Widget _buildNavTile(BuildContext context, IconData icon, String title,
      List<Color> gradientColors,
      {Widget? trailing, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    final textTertiary =
        isDark ? ShunShiColors.darkTextTertiary : ShunShiColors.textTertiary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(icon, size: 17, color: Colors.white),
      ),
      title: Text(title,
          style: TextStyle(fontSize: 15, color: textPrimary)),
      trailing: trailing ??
          Icon(Icons.chevron_right, color: textTertiary, size: 20),
      onTap: onTap ?? () {},
    );
  }

  /// 自定义墨绿 toggle 开关项
  Widget _buildSwitchTile(BuildContext context, String title, String subtitle,
      IconData icon, bool value, ValueChanged<bool> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    final textTertiary =
        isDark ? ShunShiColors.darkTextTertiary : ShunShiColors.textTertiary;
    final primaryColor = isDark ? ShunShiColors.darkPrimary : ShunShiColors.primary;

    return Row(
      children: [
        // 图标
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor.withValues(alpha: 0.1),
          ),
          child: Icon(icon, size: 17, color: primaryColor),
        ),
        const SizedBox(width: 12),
        // 标题 + 副标题
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: textTertiary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 自定义墨绿 toggle
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: 46,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: value
                  ? ShunShiColors.primary
                  : (isDark
                      ? ShunShiColors.darkSurfaceContainerLowest
                      : ShunShiColors.surfaceContainerLow),
              boxShadow: value
                  ? [
                      BoxShadow(
                        color: ShunShiColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: isDark ? ShunShiColors.darkBorderGhost : ShunShiColors.borderGhost,
      ),
    );
  }
}

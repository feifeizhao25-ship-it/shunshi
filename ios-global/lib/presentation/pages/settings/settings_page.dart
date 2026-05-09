import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/theme_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _jieqiReminder = true;
  bool _shichenReminder = false;
  bool _yangshengReminder = true;
  bool _familyStatusReminder = false;
  bool _pushEnabled = true;
  bool _elderlyMode = false;
  bool _darkMode = false;
  int _fontScaleIndex = 1;
  bool _tempUnitC = true;  // true=°C (中国), false=°F (欧美)
  int _styleIndex = 1; // 0: 温和, 1: 标准, 2: 简洁
  int _freqIndex = 0; // 0: 每天, 1: 隔天, 2: 每周
  TimeOfDay _silentStart = const TimeOfDay(hour: 22, minute: 0);
  final TimeOfDay _silentEnd = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadDarkMode();
  }

  Future<void> _loadDarkMode() async {
    final notifier = ThemeNotifier();
    await notifier.load();
    if (mounted) setState(() => _darkMode = notifier.mode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('设置', style: ShunShiTypography.headlineSmall),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: ShunShiSpacing.screenPadding,
          vertical: ShunShiSpacing.sm,
        ),
        children: [
          _sectionHeader('账号与安全'),
          _buildTile(Icons.shield_outlined, '账号安全中心', onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('安全中心开发中'), duration: Duration(seconds: 1))); }),
          _buildTile(Icons.lock_outline, '数据与隐私', onTap: () => context.push('/privacy')),
          const SizedBox(height: ShunShiSpacing.lg),

          _sectionHeader('消息推送'),
          _buildTile(Icons.notifications_outlined, '通知设置', onTap: () => context.push('/notification-settings')),
          _buildSwitchTile('推送通知', '接收养生提醒与关怀通知', _pushEnabled, (v) => setState(() => _pushEnabled = v)),
          _buildSilentPeriodTile(),
          _buildSwitchTile('节气提醒', '每个节气到来时通知你', _jieqiReminder, (v) => setState(() => _jieqiReminder = v)),
          _buildSwitchTile('时辰提醒', '重要时辰养生建议', _shichenReminder, (v) => setState(() => _shichenReminder = v)),
          _buildSwitchTile('养生提醒', '每日养生小贴士', _yangshengReminder, (v) => setState(() => _yangshengReminder = v)),
          _buildSwitchTile('家庭状态提醒', '家人状态变化时通知你', _familyStatusReminder, (v) => setState(() => _familyStatusReminder = v)),
          _buildReminderStyleSelector(),
          _buildReminderFreqSelector(),
          const SizedBox(height: ShunShiSpacing.lg),

          _sectionHeader('显示与体验'),
          _buildDarkModeSwitch(),
          _buildFontScaleSelector(),
          _buildTempUnitSelector(),
          _buildSwitchTile('老年模式', '放大字体、简化界面', _elderlyMode, (v) => setState(() => _elderlyMode = v)),
          const SizedBox(height: ShunShiSpacing.lg),

          _buildTile(Icons.delete_forever_rounded, '删除账户与数据', onTap: () {
            showDialog(context: context, builder: (_) => AlertDialog(
              backgroundColor: ShunShiColors.surface,
              title: const Text('确认删除？', style: TextStyle(color: ShunShiColors.textPrimary)),
              content: const Text('删除后所有数据将无法恢复，包括体质测试记录、对话历史、打卡记录等。\n\n根据GDPR规定，您有权要求删除个人数据。', style: TextStyle(color: ShunShiColors.textSecondary, height: 1.6)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: ShunShiColors.textTertiary))),
                TextButton(onPressed: () {
                  // 清除本地数据
                  SharedPreferences.getInstance().then((prefs) => prefs.clear());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据已清除，感谢使用'), duration: Duration(seconds: 2)));
                }, child: const Text('确认删除', style: TextStyle(color: Colors.red))),
              ],
            ));
          }),
          _sectionHeader('关于'),
          _buildTile(Icons.description_outlined, '用户协议', onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('用户协议页面开发中'), duration: Duration(seconds: 1))); }),
          _buildTile(Icons.policy_outlined, '隐私政策', onTap: () => context.push('/privacy')),
          _buildTile(Icons.info_outline, '版本信息', trailing: Text('v1.0.0', style: ShunShiTypography.bodySmall)),
          const SizedBox(height: ShunShiSpacing.xxl),

          _buildLogoutButton(),
          const SizedBox(height: ShunShiSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ShunShiSpacing.sm),
      child: Text(title, style: ShunShiTypography.labelLarge.copyWith(
        color: ShunShiColors.textSecondary,
      )),
    );
  }

  Widget _buildTile(IconData icon, String title, {VoidCallback? onTap, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: ShunShiSpacing.xxs),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: ShunShiRadius.cardRadius,
      ),
      child: ListTile(
        leading: Icon(icon, size: 22, color: ShunShiColors.textSecondary),
        title: Text(title, style: ShunShiTypography.bodyMedium),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: ShunShiColors.textTertiary),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.cardRadius),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: ShunShiSpacing.xxs),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: ShunShiRadius.cardRadius,
      ),
      child: SwitchListTile(
        title: Text(title, style: ShunShiTypography.bodyMedium),
        subtitle: Text(subtitle, style: ShunShiTypography.caption),
        value: value,
        onChanged: onChanged,
        activeThumbColor: ShunShiColors.primary,
        shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.cardRadius),
      ),
    );
  }

  Widget _buildDarkModeSwitch() {
    return Container(
      margin: const EdgeInsets.only(bottom: ShunShiSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest(context),
        borderRadius: ShunShiRadius.cardRadius,
      ),
      child: SwitchListTile(
        title: Text('深色模式', style: ShunShiTypography.bodyMedium.copyWith(color: AppColors.textPrimary(context))),
        subtitle: Text('保护眼睛，减少蓝光', style: ShunShiTypography.caption),
        value: _darkMode,
        onChanged: (v) async {
          final notifier = ThemeNotifier();
          await notifier.load();
          await notifier.toggle();
          setState(() => _darkMode = notifier.mode == ThemeMode.dark);
        },
        activeThumbColor: AppColors.primary(context),
        shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.cardRadius),
      ),
    );
  }

  Widget _buildFontScaleSelector() {
    const labels = ['小', '标准', '大'];
    return Container(
      margin: const EdgeInsets.only(bottom: ShunShiSpacing.xxs),
      padding: const EdgeInsets.symmetric(horizontal: ShunShiSpacing.md, vertical: ShunShiSpacing.sm),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: ShunShiRadius.cardRadius,
      ),
      child: Row(
        children: [
          Text('字体大小', style: ShunShiTypography.bodyMedium),
          const Spacer(),
          ...List.generate(labels.length, (i) {
            final selected = i == _fontScaleIndex;
            return GestureDetector(
              onTap: () => setState(() => _fontScaleIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: selected ? ShunShiColors.primary : ShunShiColors.surfaceContainerLow,
                  borderRadius: ShunShiRadius.chipRadius,
                ),
                child: Text(labels[i], style: ShunShiTypography.labelMedium.copyWith(
                  color: selected ? Colors.white : ShunShiColors.textSecondary,
                )),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTempUnitSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: ShunShiSpacing.xxs),
      padding: const EdgeInsets.symmetric(horizontal: ShunShiSpacing.md, vertical: ShunShiSpacing.sm),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: ShunShiRadius.cardRadius,
      ),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('温度单位', style: ShunShiTypography.bodyMedium),
            const SizedBox(height: 2),
            Text(_tempUnitC ? '摄氏度 (°C)' : '华氏度 (°F)', style: ShunShiTypography.caption),
          ]),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: ShunShiColors.surfaceContainerLow,
              borderRadius: ShunShiRadius.chipRadius,
            ),
            child: Row(children: [
              _tempUnitToggle('°C', _tempUnitC, () => setState(() => _tempUnitC = true)),
              _tempUnitToggle('°F', !_tempUnitC, () => setState(() => _tempUnitC = false)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _tempUnitToggle(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? ShunShiColors.primary : Colors.transparent,
          borderRadius: ShunShiRadius.chipRadius,
        ),
        child: Text(label, style: ShunShiTypography.labelMedium.copyWith(
          color: selected ? Colors.white : ShunShiColors.textSecondary,
        )),
      ),
    );
  }

  Widget _buildSilentPeriodTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: ShunShiSpacing.xxs),
      padding: const EdgeInsets.symmetric(horizontal: ShunShiSpacing.md, vertical: ShunShiSpacing.sm),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: ShunShiRadius.cardRadius,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('静默时段', style: ShunShiTypography.bodyMedium),
        subtitle: Text('${_silentStart.format(context)} - ${_silentEnd.format(context)}', style: ShunShiTypography.caption),
        trailing: const Icon(Icons.schedule, size: 20, color: ShunShiColors.textTertiary),
        onTap: () async {
          final start = await showTimePicker(context: context, initialTime: _silentStart);
          if (start != null) setState(() => _silentStart = start);
        },
      ),
    );
  }

  Widget _buildReminderStyleSelector() {
    const labels = ['温和', '标准', '简洁'];
    return Container(
      margin: const EdgeInsets.only(bottom: ShunShiSpacing.xxs),
      padding: const EdgeInsets.symmetric(horizontal: ShunShiSpacing.md, vertical: ShunShiSpacing.sm),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: ShunShiRadius.cardRadius,
      ),
      child: Row(
        children: [
          Text('提醒风格', style: ShunShiTypography.bodyMedium),
          const Spacer(),
          ...List.generate(labels.length, (i) {
            final selected = i == _styleIndex;
            return GestureDetector(
              onTap: () => setState(() => _styleIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: selected ? ShunShiColors.primary : ShunShiColors.surfaceContainerLow,
                  borderRadius: ShunShiRadius.chipRadius,
                ),
                child: Text(labels[i], style: ShunShiTypography.labelMedium.copyWith(
                  color: selected ? Colors.white : ShunShiColors.textSecondary,
                )),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReminderFreqSelector() {
    const labels = ['每天', '隔天', '每周'];
    return Container(
      margin: const EdgeInsets.only(bottom: ShunShiSpacing.xxs),
      padding: const EdgeInsets.symmetric(horizontal: ShunShiSpacing.md, vertical: ShunShiSpacing.sm),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: ShunShiRadius.cardRadius,
      ),
      child: Row(
        children: [
          Text('提醒频率', style: ShunShiTypography.bodyMedium),
          const Spacer(),
          ...List.generate(labels.length, (i) {
            final selected = i == _freqIndex;
            return GestureDetector(
              onTap: () => setState(() => _freqIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: selected ? ShunShiColors.primary : ShunShiColors.surfaceContainerLow,
                  borderRadius: ShunShiRadius.chipRadius,
                ),
                child: Text(labels[i], style: ShunShiTypography.labelMedium.copyWith(
                  color: selected ? Colors.white : ShunShiColors.textSecondary,
                )),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: ShunShiColors.surface,
              title: Text('退出登录', style: ShunShiTypography.titleMedium),
              content: Text('确定要退出当前账号吗？', style: ShunShiTypography.bodyMedium),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // TODO: logout logic
                    Navigator.pop(ctx);
                    context.go('/login');
                  },
                  child: Text('确定', style: TextStyle(color: ShunShiColors.error)),
                ),
              ],
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: ShunShiColors.error.withValues(alpha: 0.3)),
          foregroundColor: ShunShiColors.error,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.buttonRadius),
        ),
        child: Text('退出登录', style: ShunShiTypography.labelLarge),
      ),
    );
  }
}

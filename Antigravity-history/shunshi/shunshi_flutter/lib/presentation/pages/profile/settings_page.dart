import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 设置页 — 关怀/记忆/静默/通知/责任边界
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _enableMorningCare = true;
  bool _enableNoonCare = true;
  bool _enableEveningCare = true;
  bool _enableWeatherCare = true;
  bool _enableEmotionCare = true;
  bool _lifePhaseEnabled = true;
  bool _silentModeActive = false;
  bool _notificationsEnabled = true;
  TimeOfDay _silentStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _silentEnd = const TimeOfDay(hour: 7, minute: 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // ─── 智能关怀 ──────────────
          _SectionHeader('智能关怀'),
          SwitchListTile(
            title: const Text('早安问候'),
            subtitle: const Text('每日清晨温暖问候'),
            secondary: const Icon(Icons.wb_sunny_outlined),
            value: _enableMorningCare,
            onChanged: (v) => setState(() => _enableMorningCare = v),
          ),
          SwitchListTile(
            title: const Text('午间关怀'),
            subtitle: const Text('午间提醒休息放松'),
            secondary: const Icon(Icons.wb_twilight_outlined),
            value: _enableNoonCare,
            onChanged: (v) => setState(() => _enableNoonCare = v),
          ),
          SwitchListTile(
            title: const Text('晚安叮嘱'),
            subtitle: const Text('睡前养生叮嘱'),
            secondary: const Icon(Icons.nights_stay_outlined),
            value: _enableEveningCare,
            onChanged: (v) => setState(() => _enableEveningCare = v),
          ),

          // ─── 动态感知 ──────────────
          _SectionHeader('动态感知'),
          SwitchListTile(
            title: const Text('天气感应'),
            subtitle: const Text('降温、干燥时自动提醒'),
            value: _enableWeatherCare,
            onChanged: (v) => setState(() => _enableWeatherCare = v),
          ),
          SwitchListTile(
            title: const Text('情绪共鸣'),
            subtitle: const Text('检测到负面情绪时主动安慰'),
            value: _enableEmotionCare,
            onChanged: (v) => setState(() => _enableEmotionCare = v),
          ),

          // ─── 记忆与隐私 ────────────
          _SectionHeader('记忆与隐私'),
          SwitchListTile(
            title: const Text('阶段记忆'),
            subtitle: const Text('关闭后，顺时将不再记忆你的阶段偏好'),
            value: _lifePhaseEnabled,
            onChanged: (v) => setState(() => _lifePhaseEnabled = v),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('清空记忆', style: TextStyle(color: Colors.red)),
            subtitle: const Text('清除所有历史关怀记录和对话上下文'),
            onTap: () => _showClearMemoryDialog(context),
          ),

          // ─── 静默时段 ──────────────
          _SectionHeader('静默时段'),
          SwitchListTile(
            title: const Text('静默模式'),
            subtitle: Text(
              _silentModeActive
                  ? '${_silentStart.format(context)} - ${_silentEnd.format(context)} 不打扰'
                  : '关闭中',
            ),
            value: _silentModeActive,
            onChanged: (v) => setState(() => _silentModeActive = v),
          ),

          // ─── 通知 ─────────────────
          _SectionHeader('通知'),
          SwitchListTile(
            title: const Text('通知总开关'),
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
          ),

          // ─── 责任边界 ──────────────
          _SectionHeader('责任边界'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '「顺时」是您的养生陪伴助手，提供中医养生参考建议。\n\n'
                '⚠️ 重要声明：\n'
                '• 本应用不提供医疗诊断、治疗方案或用药指导\n'
                '• 如有身体不适，请及时就医\n'
                '• 内容仅供养生参考，不能替代专业医疗建议\n'
                '• 我们鼓励回归现实生活，不制造依赖',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showClearMemoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清除记忆？'),
        content: const Text('这将删除所有历史关怀记录和对话上下文，且无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Clear memory
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('记忆已清除')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class ActionCompleteButton extends StatefulWidget {
  final String actionType;
  final String title;
  final String skillName;
  final VoidCallback? onComplete;

  const ActionCompleteButton({
    super.key,
    required this.actionType,
    required this.title,
    this.skillName = '',
    this.onComplete,
  });

  @override
  State<ActionCompleteButton> createState() => _ActionCompleteButtonState();
}

class _ActionCompleteButtonState extends State<ActionCompleteButton>
    with SingleTickerProviderStateMixin {
  bool _completed = false;

  void _handleComplete() {
    if (_completed) return;
    setState(() => _completed = true);
    widget.onComplete?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getEncouragement()),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getEncouragement() {
    final msgs = [
      '做得好！坚持就是力量 💪',
      '完成了一个行动，继续保持！',
      '你的身体在感谢你 🌿',
      '好习惯正在形成！',
      '每一步都算数 🌱',
    ];
    return msgs[DateTime.now().millisecond % msgs.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleComplete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _completed ? ShunShiColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _completed ? ShunShiColors.primary : ShunShiColors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: _completed
              ? [BoxShadow(color: ShunShiColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: _completed ? Colors.white : ShunShiColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _completed ? '已完成！' : '标记完成',
              style: TextStyle(
                color: _completed ? Colors.white : ShunShiColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

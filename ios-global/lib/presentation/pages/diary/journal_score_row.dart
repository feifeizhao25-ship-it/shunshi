import 'package:flutter/material.dart';

/// 1–5 分选择行（精力、睡眠质量）。后端要求这两项必填，页面以前没有入口，保存只能失败。
class JournalScoreRow extends StatelessWidget {
  const JournalScoreRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.activeColor,
    required this.textColor,
    this.lowHint = '',
    this.highHint = '',
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final Color activeColor;
  final Color textColor;
  final String lowHint;
  final String highHint;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor)),
      const SizedBox(height: 8),
      Row(children: [
        for (var i = 1; i <= 5; i++) ...[
          Expanded(
            child: GestureDetector(
              key: Key('${label}_score_$i'),
              onTap: () => onChanged(i),
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == value ? activeColor : activeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$i',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: i == value ? Colors.white : textColor)),
              ),
            ),
          ),
          if (i < 5) const SizedBox(width: 6),
        ],
      ]),
      if (lowHint.isNotEmpty || highHint.isNotEmpty) ...[
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(lowHint, style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6))),
          Text(highHint, style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6))),
        ]),
      ],
    ]);
  }
}

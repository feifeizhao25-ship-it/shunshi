import 'dart:async';

import 'package:flutter/material.dart';

/// 陪伴对话的身份告知，以及连续使用满 2 小时的休息提醒。
/// 文案与后端 continuous_use 的间隔一致。这里不做法务签署。
class CompanionSessionNotice extends StatefulWidget {
  const CompanionSessionNotice({super.key, this.remindAfter = const Duration(hours: 2), this.forceReminder = false});

  final Duration remindAfter;
  final bool forceReminder;

  @override
  State<CompanionSessionNotice> createState() => _CompanionSessionNoticeState();
}

class _CompanionSessionNoticeState extends State<CompanionSessionNotice> {
  Timer? _timer;
  bool _due = false;

  @override
  void initState() {
    super.initState();
    _due = widget.forceReminder;
    if (!_due) {
      _timer = Timer(widget.remindAfter, () {
        if (mounted) setState(() => _due = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '你在和人工智能对话，不是真人。',
            key: Key('companion-identity'),
            style: TextStyle(fontSize: 12, height: 1.4),
          ),
          if (_due)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '你已经连续使用超过 2 小时了。起来走动走动、看看远处、喝口温水。',
                key: Key('companion-duration-reminder'),
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}

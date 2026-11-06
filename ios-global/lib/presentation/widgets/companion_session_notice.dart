import 'dart:async';

import 'package:flutter/material.dart';

/// Identity line and a two-hour break reminder for the companion chat.
/// The interval matches the backend continuous-use reminder. This is not a legal sign-off.
class CompanionSessionNotice extends StatefulWidget {
  const CompanionSessionNotice({super.key, this.remindAfter = const Duration(hours: 2), this.forceReminder = false, this.showIdentity = true});

  final Duration remindAfter;
  final bool forceReminder;
  final bool showIdentity;

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
          if (widget.showIdentity)
            const Text(
              'You are talking with an AI, not a person.',
              key: Key('companion-identity'),
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          if (_due)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                "You've been chatting for about two hours. Stand up, look away, and have some water.",
                key: Key('companion-duration-reminder'),
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}

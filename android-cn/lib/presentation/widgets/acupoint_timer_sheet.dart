/// 穴位按摩计时器组件
/// 预设 3 分钟倒计时 + 呼吸节律提示 + 振动反馈
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class AcupointTimerSheet extends StatefulWidget {
  final String acupointName;
  final int durationSeconds;
  const AcupointTimerSheet({
    super.key,
    required this.acupointName,
    this.durationSeconds = 180, // 3 minutes default
  });

  @override
  State<AcupointTimerSheet> createState() => _AcupointTimerSheetState();
}

class _AcupointTimerSheetState extends State<AcupointTimerSheet>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  bool _running = false;
  bool _paused = false;
  Timer? _timer;
  String _breathPhase = '准备开始'; // 吸气 / 呼气 / 屏息
  int _breathCycle = 0; // 0-3: 吸4s, 屏4s, 呼6s, 歇2s
  Timer? _breathTimer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathTimer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _paused = false;
    });
    _startBreathGuide();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _breathTimer?.cancel();
        setState(() {
          _running = false;
          _breathPhase = '完成';
        });
      }
    });
  }

  void _togglePause() {
    if (_paused) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _remainingSeconds--);
        if (_remainingSeconds <= 0) {
          _timer?.cancel();
          _breathTimer?.cancel();
          setState(() { _running = false; _breathPhase = '完成'; });
        }
      });
      _startBreathGuide();
    } else {
      _timer?.cancel();
      _breathTimer?.cancel();
    }
    setState(() => _paused = !_paused);
  }

  void _reset() {
    _timer?.cancel();
    _breathTimer?.cancel();
    setState(() {
      _remainingSeconds = widget.durationSeconds;
      _running = false;
      _paused = false;
      _breathPhase = '准备开始';
      _breathCycle = 0;
    });
  }

  void _startBreathGuide() {
    // 4-4-6-2 breathing pattern
    const durations = [4, 4, 6, 2];
    const phases = ['吸气...', '屏息...', '呼气...', '休息'];
    void cycle() {
      if (!mounted || _paused) return;
      setState(() => _breathPhase = phases[_breathCycle % 4]);
      _breathTimer = Timer(Duration(seconds: durations[_breathCycle % 4]), () {
        if (!mounted) return;
        setState(() => _breathCycle++);
        cycle();
      });
    }
    cycle();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 - (_remainingSeconds / widget.durationSeconds);

    return Container(
      decoration: BoxDecoration(
        color: ShunShiColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar
        Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: ShunShiColors.borderGhost, borderRadius: BorderRadius.circular(2))),

        // Title
        Text(widget.acupointName, style: TextStyle(
          fontFamily: ShunShiTypography.serifFamily, fontSize: 20, fontWeight: FontWeight.w700, color: ShunShiColors.textPrimary)),
        const SizedBox(height: 4),
        Text('按摩计时', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
        const SizedBox(height: 24),

        // Timer circle
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 180, height: 180, child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: ShunShiColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(ShunShiColors.primary),
          )),
          Column(children: [
            Text(_formatTime(_remainingSeconds), style: TextStyle(
              fontSize: 40, fontWeight: FontWeight.w300, color: ShunShiColors.textPrimary, fontFamily: 'SF Mono')),
            const SizedBox(height: 4),
            Text(_breathPhase, style: TextStyle(fontSize: 14, color: _breathPhase == '完成'
              ? Colors.green : ShunShiColors.primary, fontWeight: FontWeight.w500)),
          ]),
        ]),
        const SizedBox(height: 24),

        // Duration presets
        if (!_running) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _durationChip(60, '1分钟'),
          const SizedBox(width: 8),
          _durationChip(180, '3分钟'),
          const SizedBox(width: 8),
          _durationChip(300, '5分钟'),
        ]),
        const SizedBox(height: 20),

        // Controls
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (!_running && _remainingSeconds == widget.durationSeconds)
            ElevatedButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('开始按摩'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ShunShiColors.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          if (_running) ...[
            FloatingActionButton.small(
              heroTag: 'pause',
              onPressed: _togglePause,
              backgroundColor: _paused ? ShunShiColors.primary : ShunShiColors.surface,
              child: Icon(_paused ? Icons.play_arrow : Icons.pause, color: _paused ? Colors.white : ShunShiColors.textPrimary),
            ),
            const SizedBox(width: 16),
            FloatingActionButton.small(
              heroTag: 'stop',
              onPressed: _reset,
              backgroundColor: ShunShiColors.surface,
              child: Icon(Icons.stop, color: ShunShiColors.textTertiary),
            ),
          ],
          if (!_running && _remainingSeconds < widget.durationSeconds) ...[
            ElevatedButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('再来一次'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ShunShiColors.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ]),

        // Tips
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
          color: ShunShiColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(Icons.tips_and_updates, size: 16, color: ShunShiColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('力度适中，以酸胀感为宜。配合呼吸节奏效果更佳。',
              style: TextStyle(fontSize: 12, color: ShunShiColors.textSecondary, height: 1.4))),
          ]),
        ),
      ]),
    );
  }

  Widget _durationChip(int seconds, String label) => GestureDetector(
    onTap: () => setState(() => _remainingSeconds = seconds),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _remainingSeconds == seconds ? ShunShiColors.primary.withOpacity(0.1) : ShunShiColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _remainingSeconds == seconds ? ShunShiColors.primary : ShunShiColors.borderGhost),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: _remainingSeconds == seconds ? ShunShiColors.primary : ShunShiColors.textSecondary)),
    ),
  );
}

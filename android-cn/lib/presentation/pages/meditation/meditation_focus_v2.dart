/// Meditation Focus V2 — 播放器界面：Breathing/Meditation音频
/// 增加：播放/暂停计时器、冥想场景选择、打卡功能
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';

class MeditationFocusV2 extends StatefulWidget {
  const MeditationFocusV2({super.key});

  @override
  State<MeditationFocusV2> createState() => _MeditationFocusV2State();
}

class _MeditationFocusV2State extends State<MeditationFocusV2>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _totalSeconds = 600; // 10 min default
  bool _isPlaying = false;
  String _atmosphere = '细雨';
  int _selectedScene = 0;

  static const _scenes = [
    _MeditationScene('晨间冥想', '唤醒身体，开启元气满满的一天', 600, Icons.wb_sunny),
    _MeditationScene('午后静心', '缓解疲劳，恢复专注力', 480, Icons.self_improvement),
    _MeditationScene('睡前放松', '放下一天的疲惫，安然入睡', 720, Icons.bedtime),
  ];

  static const _atmospheres = [
    ('细雨', Icons.water_drop),
    ('Morning Forest', Icons.forest),
    ('Sanctuary', Icons.spa),
    ('节气', Icons.wb_sunny),
  ];

  @override
  void initState() {
    super.initState();
    _totalSeconds = _scenes[_selectedScene].durationSeconds;
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_elapsedSeconds < _totalSeconds && mounted) {
          setState(() {
            _elapsedSeconds++;
            _progressController.value = _elapsedSeconds / _totalSeconds;
          });
        } else {
          _timer?.cancel();
          setState(() => _isPlaying = false);
          _onMeditationComplete();
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  void _onMeditationComplete() {
    _incrementMeditationCount();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('冥想完成！已完成 ${_scenes[_selectedScene].name}'),
        backgroundColor: const Color(0xFF533afd),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _incrementMeditationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('meditation_count') ?? 0) + 1;
    await prefs.setInt('meditation_count', count);
    final streak = (prefs.getInt('meditation_streak') ?? 0) + 1;
    await prefs.setInt('meditation_streak', streak);
  }

  void _selectScene(int index) {
    if (_isPlaying) {
      _timer?.cancel();
      setState(() => _isPlaying = false);
    }
    setState(() {
      _selectedScene = index;
      _totalSeconds = _scenes[index].durationSeconds;
      _elapsedSeconds = 0;
    });
    _progressController.dispose();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0 ? _elapsedSeconds / _totalSeconds : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white54, size: 20),
                ),
                const SizedBox(width: 12),
                Text('顺时', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF7c5cfc))),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showSceneSelector(),
                  child: Icon(Icons.tune, color: Colors.white54, size: 20),
                ),
              ]),
            ),
            const Spacer(),

            // Scene title
            Text(_scenes[_selectedScene].name, style: TextStyle(
              fontFamily: ShunShiTypography.serifFamily,
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white,
            )),
            const SizedBox(height: 4),
            Text('${_totalSeconds ~/ 60} Min · ${_scenes[_selectedScene].label}', style: TextStyle(fontSize: 14, color: Colors.white54)),

            const SizedBox(height: 40),

            // Progress ring
            SizedBox(
              width: 200, height: 200,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(width: 200, height: 200, child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  color: Color(0xFF7c5cfc),
                  strokeWidth: 4,
                )),
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_formatTime(_elapsedSeconds),
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(_formatTime(_totalSeconds), style: TextStyle(fontSize: 14, color: Colors.white38)),
                ]),
              ]),
            ),

            const SizedBox(height: 30),

            // Controls
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(onPressed: () {
                setState(() {
                  _elapsedSeconds = (_elapsedSeconds - 10).clamp(0, _totalSeconds);
                });
              }, icon: Icon(Icons.replay_10, color: Colors.white54, size: 28)),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: Color(0xFF533afd), shape: BoxShape.circle),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white, size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              IconButton(onPressed: () {
                setState(() {
                  _elapsedSeconds = (_elapsedSeconds + 10).clamp(0, _totalSeconds);
                });
              }, icon: Icon(Icons.forward_10, color: Colors.white54, size: 28)),
            ]),

            const Spacer(),

            // Atmosphere Layer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('氛围层', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70)),
                const SizedBox(height: 10),
                Wrap(spacing: 10, children: _atmospheres.map((a) => GestureDetector(
                  onTap: () => setState(() => _atmosphere = a.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _atmosphere == a.$1 ? Color(0xFF533afd).withOpacity(0.3) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _atmosphere == a.$1 ? Color(0xFF533afd) : Colors.white12),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(a.$2, size: 16, color: _atmosphere == a.$1 ? Color(0xFF7c5cfc) : Colors.white38),
                      const SizedBox(width: 6),
                      Text(a.$1, style: TextStyle(fontSize: 12, color: _atmosphere == a.$1 ? Colors.white : Colors.white54)),
                    ]),
                  ),
                )).toList()),
              ]),
            ),

            // Check-in button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _incrementMeditationCount();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('冥想打卡成功！'), backgroundColor: Color(0xFF533afd)),
                    );
                  },
                  icon: const Icon(Icons.self_improvement, size: 18, color: Color(0xFF7c5cfc)),
                  label: Text('打卡', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF7c5cfc))),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF7c5cfc).withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSceneSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('选择冥想场景', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: ShunShiTypography.serifFamily)),
            const SizedBox(height: 16),
            ...List.generate(_scenes.length, (i) {
              final s = _scenes[i];
              final selected = i == _selectedScene;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _selectScene(i);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected ? Color(0xFF533afd).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selected ? Color(0xFF533afd) : Colors.white12),
                  ),
                  child: Row(children: [
                    Icon(s.icon, color: selected ? Color(0xFF7c5cfc) : Colors.white38, size: 28),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.white54)),
                      Text('${s.durationSeconds ~/ 60}分钟 · ${s.label}', style: TextStyle(fontSize: 12, color: Colors.white38)),
                    ])),
                    if (selected) Icon(Icons.check_circle, color: Color(0xFF7c5cfc), size: 20),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MeditationScene {
  final String name;
  final String label;
  final int durationSeconds;
  final IconData icon;
  const _MeditationScene(this.name, this.label, this.durationSeconds, this.icon);
}

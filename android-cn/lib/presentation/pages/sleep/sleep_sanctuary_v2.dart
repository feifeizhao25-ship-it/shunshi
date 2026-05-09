/// Sleep Sanctuary — 参考 sleep_sanctuary
/// Dark player for sleep sounds
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class SleepSanctuaryV2 extends StatefulWidget {
  const SleepSanctuaryV2({super.key});

  @override
  State<SleepSanctuaryV2> createState() => _SleepSanctuaryV2State();
}

class _SleepSanctuaryV2State extends State<SleepSanctuaryV2> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      body: SafeArea(
        child: Column(
          children: [
            // Back
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                Icon(Icons.arrow_back, color: Colors.white54),
                const Spacer(),
                Text('睡眠圣殿', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70)),
                const Spacer(),
                const SizedBox(width: 24),
              ]),
            ),
            const Spacer(flex: 2),

            // Moon icon
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF1a1a3e), Color(0xFF2d2d5e)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: Color(0xFF533afd).withOpacity(0.3), blurRadius: 40)],
              ),
              child: Icon(Icons.bedtime, color: Color(0xFF7c5cfc), size: 48),
            ),
            const SizedBox(height: 24),

            Text('夜幕静心', style: TextStyle(
              fontFamily: ShunShiTypography.serifFamily,
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white,
            )),
            const SizedBox(height: 4),
            Text('30 Min · Deep Sleep', style: TextStyle(fontSize: 14, color: Colors.white38)),

            const Spacer(),

            // Controls
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(onPressed: () {}, icon: Icon(Icons.replay_10, color: Colors.white38, size: 28)),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => setState(() => _isPlaying = !_isPlaying),
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: Color(0xFF533afd), shape: BoxShape.circle),
                  child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(onPressed: () {}, icon: Icon(Icons.forward_10, color: Colors.white38, size: 28)),
            ]),

            const Spacer(),

            // Story list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('助眠故事', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70)),
                const SizedBox(height: 10),
                _buildStory('Rain on Leaves', '25 min'),
                _buildStory('午夜花园', '20 min'),
                _buildStory('山间溪流', '30 min'),
              ]),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStory(String title, String duration) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(Icons.bedtime, color: Color(0xFF7c5cfc), size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, color: Colors.white70))),
          Text(duration, style: TextStyle(fontSize: 12, color: Colors.white38)),
        ]),
      ),
    );
  }
}

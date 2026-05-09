import 'package:flutter/material.dart';
import 'solar_term_data.dart';

class CurrentTermCard extends StatelessWidget {
  final SolarTermInfo term;
  const CurrentTermCard({super.key, required this.term});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF8B9E7E), Color(0xFF6B7E5E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF8B9E7E).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(term.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text('今日节气：${term.name}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3)),
            ]),
            const SizedBox(height: 12),
            Text('「${term.poem}」', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.9), height: 1.5)),
            const Spacer(),
            Row(children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text('2026年${term.date} · ${term.seasonLabel} · ${term.durationDays}天',
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
            ]),
          ],
        ),
      ),
    );
  }
}

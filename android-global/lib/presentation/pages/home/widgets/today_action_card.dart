import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/theme.dart';

class TodayActionCard extends StatelessWidget {
  final String currentTerm;
  final String shiChen;
  final String primaryReason;
  final String? constitutionType;
  const TodayActionCard({
    super.key,
    required this.currentTerm,
    required this.shiChen,
    required this.primaryReason,
    this.constitutionType,
  });

  (String, IconData, Color, String, String) _getTodayFocus(int h) {
    if (h >= 5 && h < 9) return ('Nourish Yang in the morning — a glass of warm water awakens the body', Icons.wb_twilight, const Color(0xFF43A047), 'Start Today', '/daily-checkin');
    if (h >= 9 && h < 12) return ('Chen (7-9) Stomach Meridian active — a light breakfast nourishes the Spleen-Stomach', Icons.restaurant_rounded, const Color(0xFFFF8A65), 'ViewWellnessRecipes', '/diet-recommend');
    if (h >= 12 && h < 14) return ('Wu (11-13) Heart Meridian active — rest for 15 min to nourish the Heart', Icons.self_improvement, const Color(0xFFEC407A), 'Heart Meridian Acupressure Guide', '/meridian-detail');
    if (h >= 14 && h < 18) return ('Shen (15-17) Bladder Meridian active — drink water to support detoxification', Icons.water_drop_rounded, const Color(0xFF29B6F6), 'Log Water', '/daily-checkin');
    if (h >= 18 && h < 22) return ('Xu (19-21) Pericardium Meridian — a relaxing walk is ideal', Icons.directions_walk_rounded, const Color(0xFFAB47BC), 'Pericardium Meridian Acupressure', '/meridian-detail');
    return ('Hai (21-23) Triple Burner Meridian — prepare for restful sleep', Icons.bedtime_rounded, const Color(0xFF5C6BC0), 'Pre-Sleep Log', '/daily-checkin');
  }

  /// Map shichen to corresponding meridian ID
  String? _getMeridianId(int h) {
    if (h >= 23 || h < 1) return 'meridian_gallbladder';
    if (h >= 1 && h < 3) return 'meridian_liver';
    if (h >= 3 && h < 5) return 'meridian_lung';
    if (h >= 5 && h < 7) return 'meridian_large_intestine';
    if (h >= 7 && h < 9) return 'meridian_stomach';
    if (h >= 9 && h < 11) return 'meridian_spleen';
    if (h >= 11 && h < 13) return 'meridian_heart';
    if (h >= 13 && h < 15) return 'meridian_small_intestine';
    if (h >= 15 && h < 17) return 'meridian_bladder';
    if (h >= 17 && h < 19) return 'meridian_kidney';
    if (h >= 19 && h < 21) return 'meridian_pericardium';
    if (h >= 21 && h < 23) return 'meridian_triple_energizer';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var (title, icon, color, actionLabel, actionRoute) = _getTodayFocus(h);

    // If route goes to meridian detail, add the correct meridian ID
    Map<String, dynamic>? routeExtra;
    if (actionRoute == '/meridian-detail') {
      final meridianId = _getMeridianId(h);
      if (meridianId != null) {
        routeExtra = {'meridianId': meridianId};
      }
    } else if (actionRoute == '/diet-recommend') {
      routeExtra = {'constitutionType': constitutionType};
    }

    return GestureDetector(
      onTap: () => context.push(actionRoute, extra: routeExtra),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.85), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                  Text('$currentTerm · $shiChen',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(title,
              style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700,
                fontFamily: ShunShiTypography.serifFamily, height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(primaryReason,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.5,
                fontFamily: ShunShiTypography.sansFamily,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 14, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

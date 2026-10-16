import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../core/solar_term/solar_term_table.dart';

/// 获取当前节气：查天文计算的节气表（与后端同一份数据）；超出表的年份才回退到下面的旧近似
String _getCurrentSolarTerm() {
  final fromTable = currentSolarTermName();
  if (fromTable != null) return fromTable;
  // 超出节气表年份时的近似：24 节气完整月日表（误差约 ±1 天），按日期顺序查找，不会再回落到错误节气。
  final now = beijingNow();
  const approx = [
    (1, 6, '小寒'), (1, 20, '大寒'), (2, 4, '立春'), (2, 19, '雨水'), (3, 6, '惊蛰'), (3, 21, '春分'),
    (4, 5, '清明'), (4, 20, '谷雨'), (5, 6, '立夏'), (5, 21, '小满'), (6, 6, '芒种'), (6, 21, '夏至'),
    (7, 7, '小暑'), (7, 23, '大暑'), (8, 8, '立秋'), (8, 23, '处暑'), (9, 8, '白露'), (9, 23, '秋分'),
    (10, 8, '寒露'), (10, 23, '霜降'), (11, 7, '立冬'), (11, 22, '小雪'), (12, 7, '大雪'), (12, 22, '冬至'),
  ];
  var term = '冬至';
  for (final t in approx) {
    if (now.month > t.$1 || (now.month == t.$1 && now.day >= t.$2)) term = t.$3;
  }
  return term;
}

/// 季节信息
class _SeasonInfo {
  final String term;
  final String subtitle;
  final String description;
  final Color gradientTop;
  final Color gradientBottom;
  final IconData seasonIcon;

  const _SeasonInfo({
    required this.term,
    required this.subtitle,
    required this.description,
    required this.gradientTop,
    required this.gradientBottom,
    required this.seasonIcon,
  });
}

_SeasonInfo _getSeasonInfo(String term) {
  const Map<String, _SeasonInfo> seasons = {
    '立春': _SeasonInfo(
      term: '立春',
      subtitle: 'Beginning of Spring',
      description: '东风解冻，万物始生。宜早起舒展，养肝护阳。',
      gradientTop: Color(0xFF8B9E7E),
      gradientBottom: Color(0xFFB5C7A8),
      seasonIcon: Icons.eco,
    ),
    '雨水': _SeasonInfo(
      term: '雨水',
      subtitle: 'Rain Water',
      description: '春雨润物，养肝健脾。宜食山药薏米，祛湿养胃。',
      gradientTop: Color(0xFF7E9E8B),
      gradientBottom: Color(0xFFA8C7B5),
      seasonIcon: Icons.water_drop,
    ),
    '惊蛰': _SeasonInfo(
      term: '惊蛰',
      subtitle: 'Awakening of Insects',
      description: '春雷响动，万物复苏。宜疏肝理气，适度运动。',
      gradientTop: Color(0xFF6B9E5E),
      gradientBottom: Color(0xFF95C788),
      seasonIcon: Icons.thunderstorm,
    ),
    '春分': _SeasonInfo(
      term: '春分',
      subtitle: 'Spring Equinox',
      description: '阴阳相半，昼夜均分。宜调和阴阳，平衡饮食。',
      gradientTop: Color(0xFF7E9E6B),
      gradientBottom: Color(0xFFA8C795),
      seasonIcon: Icons.balance,
    ),
    '清明': _SeasonInfo(
      term: '清明',
      subtitle: 'Clear & Bright',
      description: '春意渐深，万物清洁而明净。宜踏青舒肝，食荠菜香椿。',
      gradientTop: Color(0xFF5E8B6B),
      gradientBottom: Color(0xFF88B895),
      seasonIcon: Icons.park,
    ),
    '谷雨': _SeasonInfo(
      term: '谷雨',
      subtitle: 'Grain Rain',
      description: '雨生百谷，春将尽。宜健脾祛湿，食香椿品春茶。',
      gradientTop: Color(0xFF6B8B5E),
      gradientBottom: Color(0xFF95B888),
      seasonIcon: Icons.grain,
    ),
  };
  final known = seasons[term];
  if (known != null) return known;
  // 表里只写了 6 个春季节气：其它节气显示真实节气名 + 通用提示，不再冒充「清明」
  final fallback = seasons['清明']!;
  return _SeasonInfo(
    term: term,
    subtitle: '二十四节气',
    description: '顺应节气，规律作息，饮食清淡，适度运动。',
    gradientTop: fallback.gradientTop,
    gradientBottom: fallback.gradientBottom,
    seasonIcon: fallback.seasonIcon,
  );
}

/// 季节 Hero 图片组件
class SeasonalImage extends StatelessWidget {
  final String? termOverride;
  final String? descriptionOverride;

  const SeasonalImage({super.key, this.termOverride, this.descriptionOverride});

  @override
  Widget build(BuildContext context) {
    final term = termOverride ?? _getCurrentSolarTerm();
    final info = _getSeasonInfo(term);
    final desc = descriptionOverride ?? info.description;

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [info.gradientTop, info.gradientBottom],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Season icon
          Positioned(
            right: 20,
            top: 20,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(info.seasonIcon, color: Colors.white, size: 26),
            ),
          ),
          // Text content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${info.term} · ${info.subtitle}',
                  style: TextStyle(
                    fontFamily: ShunShiTypography.serifFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: TextStyle(
                    fontFamily: ShunShiTypography.sansFamily,
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Bottom gradient overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    info.gradientBottom.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

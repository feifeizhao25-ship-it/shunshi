import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

/// 养生日记页
class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  int _selectedFilter = 0;
  final _filters = ['全部', '饮食', '运动', '情绪'];
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
        title: const Text('养生日记', style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
        backgroundColor: ShunShiColors.background, elevation: 0,
      ),
      body: Column(
        children: [
          // ── Calendar Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
                ),
                Text('${_selectedMonth.year}年${_selectedMonth.month}月', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
                ),
              ],
            ),
          ),

          // ── Filter Tabs ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _filters.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: _selectedFilter == e.key,
                  onSelected: (_) => setState(() => _selectedFilter = e.key),
                  selectedColor: ShunShiColors.primaryLight.withValues(alpha: 0.2),
                  backgroundColor: ShunShiColors.surfaceContainerLow,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: _selectedFilter == e.key ? ShunShiColors.primary : ShunShiColors.textTertiary,
                    fontFamily: ShunShiTypography.sansFamily,
                  ),
                  side: BorderSide.none,
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // ── 日记列表 ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _diaryCard('4月4日 周六', '😊', '清明时节，早起散步30分钟。饮了枸杞红枣茶，感觉精神不错。', '运动 · 饮食'),
                _diaryCard('4月3日 周五', '😌', '今天按计划做了八段锦，晚上泡脚15分钟。睡眠质量较好。', '运动'),
                _diaryCard('4月2日 周四', '😐', '工作较忙，没来得及运动。晚餐吃了山药粥，清淡养胃。', '饮食'),
                _diaryCard('4月1日 周三', '😄', '心情愉悦！和家人一起去了公园，采集了新鲜荠菜做春卷。', '情绪 · 饮食'),
                _diaryCard('3月31日 周二', '😴', '昨晚失眠，今天精神欠佳。尝试冥想10分钟，稍有缓解。', '情绪'),
                _diaryCard('3月30日 周一', '😊', '开始新的一个月。制定了养生计划，坚持早起和适量运动。', '运动'),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      // ── 写日记 FAB ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('写日记功能开发中'), duration: Duration(seconds: 1))); },
        backgroundColor: ShunShiColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit, size: 20),
        label: const Text('写日记', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _diaryCard(String date, String emoji, String content, String tags) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: ShunShiColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: ShunShiColors.borderGhost)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(child: Text(date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily))),
            Text(tags, style: const TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
          ],
        ),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.5)),
      ],
    ),
  );
}

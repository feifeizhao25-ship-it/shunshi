import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../data/network/api_client.dart';
import '../../widgets/components/components.dart';

// ═══════════════════════════════════════════════════════════════════
// 养生记录页面 — 3个Tab：睡眠 | 情绪 | 关怀
// ═══════════════════════════════════════════════════════════════════

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;
  final ApiClient _api = ApiClient();

  // ── 数据汇总 ──
  Map<String, dynamic>? _summary;
  bool _summaryLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
    _loadSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    try {
      final res = await _api.get('/api/v1/records/summary');
      if (mounted) {
        setState(() {
          _summary = res.data is Map<String, dynamic>
              ? res.data as Map<String, dynamic>
              : {};
          _summaryLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _summaryLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
      backgroundColor: ShunshiColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 4),
            _buildCapsuleTabs(),
            _buildSummary(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SleepTab(api: _api),
                  _EmotionTab(api: _api),
                  _CareTab(api: _api),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ── 顶部导航栏 ──

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ShunshiSpacing.md,
        ShunshiSpacing.md,
        ShunshiSpacing.md,
        ShunshiSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.go('/home'),
            color: ShunshiColors.textPrimary,
          ),
          const SizedBox(width: ShunshiSpacing.xs),
          Text('养生记录', style: ShunshiTextStyles.heading),
        ],
      ),
    );
  }

  // ── 胶囊Tab ──

  Widget _buildCapsuleTabs() {
    const tabs = ['😴 睡眠', '😊 情绪', '💝 关怀'];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ShunshiSpacing.pagePadding,
      ),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final isActive = _currentTab == index;
            return GestureDetector(
              onTap: () => _tabController.animateTo(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? ShunshiColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : ShunshiColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── 数据汇总条 ──

  Widget _buildSummary() {
    if (_summaryLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LoadingState(inline: true, size: 20),
      );
    }
    if (_summary == null) return const SizedBox.shrink();

    final avgSleep = _summary!['avg_sleep_hours'];
    final emotionDist = _summary!['emotion_distribution'];
    final careCount = _summary!['care_count_month'];

    return Container(
      margin: const EdgeInsets.fromLTRB(
        ShunshiSpacing.pagePadding,
        12,
        ShunshiSpacing.pagePadding,
        8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ShunshiSpacing.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: ShunshiColors.surfaceDim,
        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            icon: '😴',
            label: '本周均睡',
            value: avgSleep != null ? '${(avgSleep as num).toStringAsFixed(1)}h' : '--',
          ),
          Container(
            width: 1,
            height: 32,
            color: ShunshiColors.divider,
          ),
          _SummaryItem(
            icon: '😊',
            label: '本周情绪',
            value: emotionDist != null ? _topEmotion(emotionDist) : '--',
          ),
          Container(
            width: 1,
            height: 32,
            color: ShunshiColors.divider,
          ),
          _SummaryItem(
            icon: '💝',
            label: '本月关怀',
            value: careCount != null ? '$careCount次' : '--',
          ),
        ],
      ),
    );
  }

  String _topEmotion(dynamic dist) {
    if (dist is! Map) return '--';
    final sorted = dist.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    return sorted.first.key.toString();
  }
}

// ── 汇总条子组件 ──

class _SummaryItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(
          value,
          style: ShunshiTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        Text(
          label,
          style: ShunshiTextStyles.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 睡眠记录 Tab
// ═══════════════════════════════════════════════════════════════════

class _SleepTab extends StatefulWidget {
  final ApiClient api;
  const _SleepTab({required this.api});

  @override
  State<_SleepTab> createState() => _SleepTabState();
}

class _SleepTabState extends State<_SleepTab> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        widget.api.get('/api/v1/records/sleep'),
        widget.api.get('/api/v1/records/sleep/stats'),
      ]);
      if (mounted) {
        setState(() {
          final sleepData = results[0].data;
          _records = sleepData is List
              ? sleepData.cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[];
          // stats API called for side effects
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '加载失败'; _loading = false; });
    }
  }

  // ── 睡眠柱状图颜色 ──

  Color _barColor(double hours) {
    if (hours >= 7) return ShunshiColors.success;
    if (hours >= 6) return ShunshiColors.warning;
    return ShunshiColors.error;
  }

  // ── 7天柱状图 ──

  Widget _buildWeeklyChart() {
    final data = _records.length >= 7 ? _records.sublist(0, 7) : _records;
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text('暂无睡眠记录', style: ShunshiTextStyles.caption),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.asMap().entries.map((entry) {
          final record = entry.value;
          final hours = (record['hours'] as num?)?.toDouble() ?? 0.0;
          final maxHeight = 120.0;
          final barHeight = (hours / 10.0 * maxHeight).clamp(8.0, maxHeight);

          final weekday = record['date'] ?? '';
          final label = weekday.length > 2 ? weekday.substring(weekday.length - 2) : weekday;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${hours.toStringAsFixed(1)}h',
                    style: ShunshiTextStyles.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: ShunshiAnimations.cardExpand,
                    curve: ShunshiAnimations.slowEase,
                    width: 28,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: _barColor(hours),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: ShunshiTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 记录卡片 ──

  Widget _buildRecordCard(Map<String, dynamic> record, int index) {
    final bedtime = record['bedtime'] ?? '--:--';
    final wakeup = record['wakeup'] ?? '--:--';
    final hours = (record['hours'] as num?)?.toDouble() ?? 0.0;
    final quality = (record['quality'] as num?)?.toInt() ?? 0;

    return Container(
      margin: EdgeInsets.only(
        bottom: index == _records.length - 1 ? 0 : 12,
      ),
      padding: const EdgeInsets.all(ShunshiSpacing.md),
      decoration: BoxDecoration(
        color: ShunshiColors.surface,
        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _barColor(hours).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '😴',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: ShunshiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$bedtime → $wakeup',
                      style: ShunshiTextStyles.body,
                    ),
                    const Spacer(),
                    _QualityStars(quality: quality),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '睡眠 ${hours.toStringAsFixed(1)} 小时',
                      style: ShunshiTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 记录睡眠 BottomSheet ──

  void _showSleepSheet() {
    TimeOfDay? selectedBedtime;
    TimeOfDay? selectedWakeup;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                ShunshiSpacing.lg,
                ShunshiSpacing.lg,
                ShunshiSpacing.lg,
                MediaQuery.of(context).viewInsets.bottom + ShunshiSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ShunshiColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: ShunshiSpacing.lg),
                  Text('记录睡眠', style: ShunshiTextStyles.heading),
                  const SizedBox(height: ShunshiSpacing.xl),
                  _TimePickerRow(
                    label: '入睡时间',
                    time: selectedBedtime,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedBedtime ?? const TimeOfDay(hour: 22, minute: 0),
                        builder: (ctx, child) => MediaQuery(
                          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        ),
                      );
                      if (picked != null) setSheetState(() => selectedBedtime = picked);
                    },
                  ),
                  const SizedBox(height: ShunshiSpacing.lg),
                  _TimePickerRow(
                    label: '起床时间',
                    time: selectedWakeup,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedWakeup ?? const TimeOfDay(hour: 7, minute: 0),
                        builder: (ctx, child) => MediaQuery(
                          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        ),
                      );
                      if (picked != null) setSheetState(() => selectedWakeup = picked);
                    },
                  ),
                  const SizedBox(height: ShunshiSpacing.xl),
                  GentleButton(
                    text: '保存记录',
                    isPrimary: true,
                    onPressed: (selectedBedtime != null && selectedWakeup != null)
                        ? () {
                            final bedMinutes = selectedBedtime!.hour * 60 + selectedBedtime!.minute;
                            var wakeMinutes = selectedWakeup!.hour * 60 + selectedWakeup!.minute;
                            if (wakeMinutes <= bedMinutes) wakeMinutes += 24 * 60;
                            final hours = (wakeMinutes - bedMinutes) / 60.0;

                            Navigator.pop(context);
                            setState(() {
                              _records.insert(0, {
                                'date': '今天',
                                'bedtime':
                                    '${selectedBedtime!.hour.toString().padLeft(2, '0')}:${selectedBedtime!.minute.toString().padLeft(2, '0')}',
                                'wakeup':
                                    '${selectedWakeup!.hour.toString().padLeft(2, '0')}:${selectedWakeup!.minute.toString().padLeft(2, '0')}',
                                'hours': hours,
                                'quality': hours >= 7
                                    ? 5
                                    : hours >= 6
                                        ? 3
                                        : 1,
                              });
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '已记录睡眠 ${hours.toStringAsFixed(1)} 小时',
                                  style: ShunshiTextStyles.caption
                                      .copyWith(color: Colors.white),
                                ),
                                backgroundColor: ShunshiColors.primary,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    ShunshiSpacing.radiusMedium,
                                  ),
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: LoadingState(message: '加载睡眠记录...'));
    }
    if (_error != null) {
      return ErrorState(
        message: _error!,
        onRetry: _loadData,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ShunshiSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本周睡眠趋势', style: ShunshiTextStyles.caption),
          const SizedBox(height: ShunshiSpacing.sm),
          SoftCard(
            padding: const EdgeInsets.all(ShunshiSpacing.md),
            child: _buildWeeklyChart(),
          ),
          const SizedBox(height: ShunshiSpacing.xl),
          Text('睡眠记录', style: ShunshiTextStyles.caption),
          const SizedBox(height: ShunshiSpacing.sm),
          ..._records.asMap().entries.map((e) => _buildRecordCard(e.value, e.key)),
          const SizedBox(height: ShunshiSpacing.xl),
          Center(
            child: GentleButton(
              text: '记录睡眠',
              icon: Icons.bedtime,
              onPressed: _showSleepSheet,
            ),
          ),
          const SizedBox(height: ShunshiSpacing.xxl),
        ],
      ),
    );
  }
}

// ── 睡眠质量星级 ──

class _QualityStars extends StatelessWidget {
  final int quality; // 1-5

  const _QualityStars({required this.quality});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < quality ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 14,
          color: i < quality ? ShunshiColors.warning : ShunshiColors.textHint,
        );
      }),
    );
  }
}

// ── BottomSheet 时间选择行 ──

class _TimePickerRow extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimePickerRow({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ShunshiSpacing.md,
          vertical: ShunshiSpacing.md,
        ),
        decoration: BoxDecoration(
          color: ShunshiColors.surfaceDim,
          borderRadius: BorderRadius.circular(ShunshiSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            Text(label, style: ShunshiTextStyles.body),
            const Spacer(),
            Text(
              time != null
                  ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
                  : '请选择',
              style: ShunshiTextStyles.body.copyWith(
                color: time != null
                    ? ShunshiColors.textPrimary
                    : ShunshiColors.textHint,
              ),
            ),
            const SizedBox(width: ShunshiSpacing.xs),
            const Icon(Icons.chevron_right, size: 18, color: ShunshiColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 情绪记录 Tab
// ═══════════════════════════════════════════════════════════════════

class _EmotionTab extends StatefulWidget {
  final ApiClient api;
  const _EmotionTab({required this.api});

  @override
  State<_EmotionTab> createState() => _EmotionTabState();
}

class _EmotionTabState extends State<_EmotionTab> {
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _trends = [];
  bool _loading = true;
  String? _error;

  static const List<_EmojiChoice> _emojis = [
    _EmojiChoice(emoji: '😊', label: '开心', value: 4),
    _EmojiChoice(emoji: '😐', label: '平静', value: 3),
    _EmojiChoice(emoji: '😔', label: '低落', value: 2),
    _EmojiChoice(emoji: '😢', label: '难过', value: 1),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        widget.api.get('/api/v1/records/emotion'),
        widget.api.get('/api/v1/records/emotion/trends'),
      ]);
      if (mounted) {
        setState(() {
          final emotionData = results[0].data;
          _records = emotionData is List
              ? emotionData.cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[];
          final trendsData = results[1].data;
          _trends = trendsData is List
              ? trendsData.cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _error = '加载失败'; _loading = false; });
    }
  }

  // ── 7天情绪折线 ──

  Widget _buildTrendChart() {
    final data = _trends.length >= 7 ? _trends.sublist(0, 7) : _trends;
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text('暂无情绪趋势', style: ShunshiTextStyles.caption),
        ),
      );
    }

    return CustomPaint(
      size: const Size(double.infinity, 140),
      painter: _EmotionLinePainter(data: data),
    );
  }

  // ── 记录卡片 ──

  Widget _buildRecordCard(Map<String, dynamic> record, int index) {
    final emoji = record['emoji'] ?? '😐';
    final label = record['label'] ?? '';
    final note = record['note'] ?? '';
    final date = record['date'] ?? '';
    final time = record['time'] ?? '';

    return Container(
      margin: EdgeInsets.only(
        bottom: index == _records.length - 1 ? 0 : 12,
      ),
      padding: const EdgeInsets.all(ShunshiSpacing.md),
      decoration: BoxDecoration(
        color: ShunshiColors.surface,
        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: ShunshiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: ShunshiTextStyles.body),
                    const Spacer(),
                    Text(
                      time.isNotEmpty ? time : date,
                      style: ShunshiTextStyles.caption,
                    ),
                  ],
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(note, style: ShunshiTextStyles.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 记录情绪 BottomSheet ──

  void _showEmotionSheet() {
    int selected = -1;
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                ShunshiSpacing.lg,
                ShunshiSpacing.lg,
                ShunshiSpacing.lg,
                MediaQuery.of(context).viewInsets.bottom + ShunshiSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ShunshiColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: ShunshiSpacing.lg),
                  Text('今天心情如何？', style: ShunshiTextStyles.heading),
                  const SizedBox(height: ShunshiSpacing.xl),
                  // 4个emoji按钮 64x64
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_emojis.length, (i) {
                      final choice = _emojis[i];
                      final isActive = selected == i;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selected = i),
                        child: AnimatedContainer(
                          duration: ShunshiAnimations.tapFeedback,
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isActive
                                ? ShunshiColors.primary.withValues(alpha: 0.15)
                                : ShunshiColors.surfaceDim,
                            borderRadius: BorderRadius.circular(16),
                            border: isActive
                                ? Border.all(
                                    color: ShunshiColors.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              choice.emoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  if (selected >= 0)
                    Center(
                      child: Text(
                        _emojis[selected].label,
                        style: ShunshiTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: ShunshiSpacing.xl),
                  TextField(
                    controller: noteController,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: '写点什么吧...',
                      hintStyle: ShunshiTextStyles.hint,
                      filled: true,
                      fillColor: ShunshiColors.surfaceDim,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: ShunshiSpacing.md,
                        vertical: ShunshiSpacing.md,
                      ),
                    ),
                    style: ShunshiTextStyles.body,
                  ),
                  const SizedBox(height: ShunshiSpacing.lg),
                  GentleButton(
                    text: '保存记录',
                    isPrimary: true,
                    onPressed: selected >= 0
                        ? () {
                            final choice = _emojis[selected];
                            Navigator.pop(context);
                            noteController.dispose();
                            setState(() {
                              _records.insert(0, {
                                'date': '今天',
                                'emoji': choice.emoji,
                                'label': choice.label,
                                'value': choice.value,
                                'note': noteController.text.trim(),
                                'time': _nowLabel(),
                              });
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '已记录：${choice.label}',
                                  style: ShunshiTextStyles.caption
                                      .copyWith(color: Colors.white),
                                ),
                                backgroundColor: ShunshiColors.primary,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    ShunshiSpacing.radiusMedium,
                                  ),
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _nowLabel() {
    final now = DateTime.now();
    final h = now.hour;
    if (h < 6) return '凌晨$h:${now.minute.toString().padLeft(2, '0')}';
    if (h < 12) return '上午$h:${now.minute.toString().padLeft(2, '0')}';
    if (h < 18) return '下午${h - 12}:${now.minute.toString().padLeft(2, '0')}';
    return '晚上${h - 12}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: LoadingState(message: '加载情绪记录...'));
    }
    if (_error != null) {
      return ErrorState(
        message: _error!,
        onRetry: _loadData,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ShunshiSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本周情绪趋势', style: ShunshiTextStyles.caption),
          const SizedBox(height: ShunshiSpacing.sm),
          SoftCard(
            padding: const EdgeInsets.all(ShunshiSpacing.md),
            child: _buildTrendChart(),
          ),
          const SizedBox(height: ShunshiSpacing.xl),
          Text('情绪记录', style: ShunshiTextStyles.caption),
          const SizedBox(height: ShunshiSpacing.sm),
          ..._records.asMap().entries.map((e) => _buildRecordCard(e.value, e.key)),
          const SizedBox(height: ShunshiSpacing.xl),
          Center(
            child: GentleButton(
              text: '记录情绪',
              icon: Icons.sentiment_satisfied_alt,
              onPressed: _showEmotionSheet,
            ),
          ),
          const SizedBox(height: ShunshiSpacing.xxl),
        ],
      ),
    );
  }
}

// ── emoji 数据 ──

class _EmojiChoice {
  final String emoji;
  final String label;
  final int value;

  const _EmojiChoice({
    required this.emoji,
    required this.label,
    required this.value,
  });
}

// ── 情绪折线画板 ──

class _EmotionLinePainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  _EmotionLinePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 12);
    final chartWidth = size.width - padding.horizontal * 2;
    final chartHeight = size.height - padding.vertical * 2;

    // 底部日期标签
    final labelStyle = TextStyle(
      fontSize: 11,
      color: ShunshiColors.textHint,
    );
    final labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? padding.left + chartWidth / 2
          : padding.left + (i / (data.length - 1)) * chartWidth;

      labelPainter.text = TextSpan(
        text: data[i]['date']?.toString() ?? '',
        style: labelStyle,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(x - labelPainter.width / 2, size.height - 10),
      );
    }

    // 计算点坐标
    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final value = (data[i]['value'] as num?)?.toDouble() ?? 1.0;
      final x = data.length == 1
          ? padding.left + chartWidth / 2
          : padding.left + (i / (data.length - 1)) * chartWidth;
      final y = padding.top + chartHeight - ((value - 1) / 3) * chartHeight;
      points.add(Offset(x, y.clamp(padding.top, padding.top + chartHeight)));
    }

    // 画填充区域
    if (points.length >= 2) {
      final fillPath = Path()
        ..moveTo(points.first.dx, padding.top + chartHeight)
        ..lineTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final cp1x = (points[i - 1].dx + points[i].dx) / 2;
        final cp1y = points[i - 1].dy;
        final cp2x = cp1x;
        final cp2y = points[i].dy;
        fillPath.cubicTo(cp1x, cp1y, cp2x, cp2y, points[i].dx, points[i].dy);
      }
      fillPath.lineTo(points.last.dx, padding.top + chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..color = ShunshiColors.warm.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);

      // 画线
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final cp1x = (points[i - 1].dx + points[i].dx) / 2;
        final cp1y = points[i - 1].dy;
        final cp2x = cp1x;
        final cp2y = points[i].dy;
        linePath.cubicTo(cp1x, cp1y, cp2x, cp2y, points[i].dx, points[i].dy);
      }

      final linePaint = Paint()
        ..color = ShunshiColors.warm
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(linePath, linePaint);
    }

    // 画点
    for (final point in points) {
      canvas.drawCircle(
        point,
        4,
        Paint()
          ..color = ShunshiColors.warm
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        point,
        2,
        Paint()
          ..color = ShunshiColors.surface
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EmotionLinePainter oldDelegate) =>
      oldDelegate.data != data;
}

// ═══════════════════════════════════════════════════════════════════
// 关怀记录 Tab
// ═══════════════════════════════════════════════════════════════════

class _CareTab extends StatefulWidget {
  final ApiClient api;
  const _CareTab({required this.api});

  @override
  State<_CareTab> createState() => _CareTabState();
}

class _CareTabState extends State<_CareTab> {
  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic>? _todayCare;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        widget.api.get('/api/v1/records/care'),
        widget.api.get('/api/v1/records/care/today'),
      ]);
      if (mounted) {
        setState(() {
          final careData = results[0].data;
          _records = careData is List
              ? careData.cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[];
          final todayData = results[1].data;
          _todayCare = todayData is Map<String, dynamic> ? todayData : {};
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _error = '加载失败'; _loading = false; });
    }
  }

  // ── 今日关怀打卡卡片 ──

  Widget _buildTodayCard() {
    final done = _todayCare?['completed'] == true;
    final target = _todayCare?['target'] ?? '家人';

    return Container(
      padding: const EdgeInsets.all(ShunshiSpacing.md),
      decoration: BoxDecoration(
        color: done
            ? ShunshiColors.success.withValues(alpha: 0.08)
            : ShunshiColors.surface,
        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
        border: done
            ? Border.all(color: ShunshiColors.success.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: done
                  ? ShunshiColors.success.withValues(alpha: 0.12)
                  : ShunshiColors.warm.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                done ? '✅' : '💝',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: ShunshiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? '今日已关怀 $target' : '今日关怀待完成',
                  style: ShunshiTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  done
                      ? '继续保持，关怀是最长情的陪伴'
                      : '今天给 $target 一句问候吧',
                  style: ShunshiTextStyles.caption,
                ),
              ],
            ),
          ),
          if (!done)
            GentleButton(
              text: '打卡',
              isPrimary: true,
              horizontalPadding: ShunshiSpacing.md,
              onPressed: () {
                setState(() {
                  _todayCare = {'completed': true, 'target': target};
                  _records.insert(0, {
                    'target': target,
                    'content': '关怀打卡',
                    'date': '今天',
                    'time': _nowLabel(),
                  });
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '关怀打卡成功 💝',
                      style: ShunshiTextStyles.caption
                          .copyWith(color: Colors.white),
                    ),
                    backgroundColor: ShunshiColors.primary,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ShunshiSpacing.radiusMedium,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── 记录卡片 ──

  Widget _buildRecordCard(Map<String, dynamic> record, int index) {
    final target = record['target'] ?? '';
    final content = record['content'] ?? '';
    final date = record['date'] ?? '';
    final time = record['time'] ?? '';

    return Container(
      margin: EdgeInsets.only(
        bottom: index == _records.length - 1 ? 0 : 12,
      ),
      padding: const EdgeInsets.all(ShunshiSpacing.md),
      decoration: BoxDecoration(
        color: ShunshiColors.surface,
        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ShunshiColors.blush.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('💝', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: ShunshiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '关怀 $target',
                      style: ShunshiTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      time.isNotEmpty ? '$date $time' : date,
                      style: ShunshiTextStyles.caption,
                    ),
                  ],
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(content, style: ShunshiTextStyles.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _nowLabel() {
    final now = DateTime.now();
    final h = now.hour;
    if (h < 6) return '凌晨$h:${now.minute.toString().padLeft(2, '0')}';
    if (h < 12) return '上午$h:${now.minute.toString().padLeft(2, '0')}';
    if (h < 18) return '下午${h - 12}:${now.minute.toString().padLeft(2, '0')}';
    return '晚上${h - 12}:${now.minute.toString().padLeft(2, '0')}';
  }

  // ── 记录关怀 BottomSheet ──

  void _showCareSheet() {
    final targetController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            ShunshiSpacing.lg,
            ShunshiSpacing.lg,
            ShunshiSpacing.lg,
            MediaQuery.of(context).viewInsets.bottom + ShunshiSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ShunshiColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: ShunshiSpacing.lg),
              Text('记录关怀', style: ShunshiTextStyles.heading),
              const SizedBox(height: ShunshiSpacing.xl),
              TextField(
                controller: targetController,
                decoration: InputDecoration(
                  hintText: '关怀对象',
                  hintStyle: ShunshiTextStyles.hint,
                  filled: true,
                  fillColor: ShunshiColors.surfaceDim,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ShunshiSpacing.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ShunshiSpacing.md,
                    vertical: ShunshiSpacing.md,
                  ),
                ),
                style: ShunshiTextStyles.body,
              ),
              const SizedBox(height: ShunshiSpacing.md),
              TextField(
                controller: contentController,
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '关怀内容',
                  hintStyle: ShunshiTextStyles.hint,
                  filled: true,
                  fillColor: ShunshiColors.surfaceDim,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ShunshiSpacing.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ShunshiSpacing.md,
                    vertical: ShunshiSpacing.md,
                  ),
                ),
                style: ShunshiTextStyles.body,
              ),
              const SizedBox(height: ShunshiSpacing.lg),
              GentleButton(
                text: '保存记录',
                isPrimary: true,
                onPressed: () {
                  final target = targetController.text.trim();
                  final content = contentController.text.trim();
                  if (target.isEmpty) return;
                  Navigator.pop(context);
                  targetController.dispose();
                  contentController.dispose();
                  setState(() {
                    _records.insert(0, {
                      'target': target,
                      'content': content,
                      'date': '今天',
                      'time': _nowLabel(),
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '已记录关怀 $target 💝',
                        style: ShunshiTextStyles.caption
                            .copyWith(color: Colors.white),
                      ),
                      backgroundColor: ShunshiColors.primary,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ShunshiSpacing.radiusMedium,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: LoadingState(message: '加载关怀记录...'));
    }
    if (_error != null) {
      return ErrorState(
        message: _error!,
        onRetry: _loadData,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ShunshiSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今日关怀', style: ShunshiTextStyles.caption),
          const SizedBox(height: ShunshiSpacing.sm),
          _buildTodayCard(),
          const SizedBox(height: ShunshiSpacing.xl),
          Text('关怀记录', style: ShunshiTextStyles.caption),
          const SizedBox(height: ShunshiSpacing.sm),
          ..._records.asMap().entries.map((e) => _buildRecordCard(e.value, e.key)),
          const SizedBox(height: ShunshiSpacing.xl),
          Center(
            child: GentleButton(
              text: '记录关怀',
              icon: Icons.favorite,
              onPressed: _showCareSheet,
            ),
          ),
          const SizedBox(height: ShunshiSpacing.xxl),
        ],
      ),
    );
  }
}

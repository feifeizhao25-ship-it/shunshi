import 'dart:math';
import 'package:flutter/material.dart';
import 'package:seasons/core/theme/seasons_colors.dart';
import 'package:seasons/core/theme/seasons_spacing.dart';
import 'package:seasons/core/theme/seasons_text_styles.dart';
import 'package:seasons/core/theme/seasons_animations.dart';
import 'package:seasons/presentation/widgets/components/components.dart';

/// Health Records — Journal-style, calm, minimal
/// 4 Tabs: Mood / Sleep / Exercise / Diet
class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  // ── Mock 7-day mood data ──
  final List<_MoodRecord> _moodRecords = [
    _MoodRecord(date: 'Mon', emoji: '😊', label: 'Happy', value: 7.0, note: 'Work went well', time: '3:20 PM'),
    _MoodRecord(date: 'Tue', emoji: '😄', label: 'Great', value: 9.0, note: 'Dinner with friends', time: '8:10 PM'),
    _MoodRecord(date: 'Wed', emoji: '😐', label: 'Okay', value: 5.0, note: 'A bit tired', time: '12:30 PM'),
    _MoodRecord(date: 'Thu', emoji: '🙂', label: 'Fine', value: 6.0, note: '', time: '10:00 AM'),
    _MoodRecord(date: 'Fri', emoji: '😊', label: 'Happy', value: 8.0, note: 'Finished project', time: '5:45 PM'),
    _MoodRecord(date: 'Sat', emoji: '😔', label: 'Low', value: 3.0, note: 'Rainy day', time: '2:15 PM'),
    _MoodRecord(date: 'Today', emoji: '😊', label: 'Happy', value: 7.0, note: '', time: null),
  ];

  // ── Mock 7-day sleep data ──
  final List<_SleepRecord> _sleepRecords = [
    _SleepRecord(date: 'Mon', hours: 7.5, quality: _SleepQuality.good, bedtime: '10:30 PM', wakeup: '6:00 AM'),
    _SleepRecord(date: 'Tue', hours: 6.0, quality: _SleepQuality.poor, bedtime: '1:00 AM', wakeup: '7:00 AM'),
    _SleepRecord(date: 'Wed', hours: 8.0, quality: _SleepQuality.excellent, bedtime: '10:00 PM', wakeup: '6:00 AM'),
    _SleepRecord(date: 'Thu', hours: 7.0, quality: _SleepQuality.good, bedtime: '11:00 PM', wakeup: '6:00 AM'),
    _SleepRecord(date: 'Fri', hours: 7.5, quality: _SleepQuality.good, bedtime: '10:30 PM', wakeup: '6:00 AM'),
    _SleepRecord(date: 'Sat', hours: 5.5, quality: _SleepQuality.fair, bedtime: '12:30 AM', wakeup: '6:00 AM'),
    _SleepRecord(date: 'Today', hours: 8.5, quality: _SleepQuality.excellent, bedtime: '10:00 PM', wakeup: '6:30 AM'),
  ];

  // ── Mock 7-day exercise data ──
  final List<_ExerciseRecord> _exerciseRecords = [
    _ExerciseRecord(date: 'Mon', minutes: 30, type: 'Walking', intensity: 'Light'),
    _ExerciseRecord(date: 'Tue', minutes: 0, type: '', intensity: ''),
    _ExerciseRecord(date: 'Wed', minutes: 45, type: 'Yoga', intensity: 'Medium'),
    _ExerciseRecord(date: 'Thu', minutes: 20, type: 'Stretching', intensity: 'Light'),
    _ExerciseRecord(date: 'Fri', minutes: 60, type: 'Running', intensity: 'High'),
    _ExerciseRecord(date: 'Sat', minutes: 15, type: 'Walking', intensity: 'Light'),
    _ExerciseRecord(date: 'Today', minutes: 40, type: 'Swimming', intensity: 'Medium'),
  ];

  // ── Mock 7-day diet data ──
  final List<_DietRecord> _dietRecords = [
    _DietRecord(date: 'Mon', score: 8, meals: 'Three balanced meals', emoji: '🥗'),
    _DietRecord(date: 'Tue', score: 6, meals: 'Too much takeout', emoji: '🍔'),
    _DietRecord(date: 'Wed', score: 9, meals: 'Home-cooked, nutritious', emoji: '🍲'),
    _DietRecord(date: 'Thu', score: 5, meals: 'Skipped breakfast', emoji: '☕'),
    _DietRecord(date: 'Fri', score: 8, meals: 'Lots of fruits & veggies', emoji: '🍎'),
    _DietRecord(date: 'Sat', score: 7, meals: 'Dinner with friends', emoji: '🥘'),
    _DietRecord(date: 'Today', score: 9, meals: 'Light & clean eating', emoji: '🥬'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeasonsColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MoodTab(records: _moodRecords),
                  _SleepTab(records: _sleepRecords),
                  _ExerciseTab(records: _exerciseRecords),
                  _DietTab(records: _dietRecords),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SeasonsSpacing.md,
        SeasonsSpacing.md,
        SeasonsSpacing.md,
        SeasonsSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            color: SeasonsColors.textPrimary,
          ),
          const SizedBox(width: SeasonsSpacing.xs),
          Text('Health Records', style: SeasonsTextStyles.heading),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    const tabs = ['Mood', 'Sleep', 'Exercise', 'Diet'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SeasonsSpacing.pagePadding),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _currentTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(i),
              child: Column(
                children: [
                  Text(
                    tabs[i],
                    style: SeasonsTextStyles.caption.copyWith(
                      color: isActive
                          ? SeasonsColors.primary
                          : SeasonsColors.textHint,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w300,
                      fontSize: isActive ? 15 : 14,
                    ),
                  ),
                  const SizedBox(height: SeasonsSpacing.sm),
                  AnimatedContainer(
                    duration: SeasonsAnimations.stateChange,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: isActive
                          ? SeasonsColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Mood Tab
// ═══════════════════════════════════════════

class _MoodTab extends StatefulWidget {
  final List<_MoodRecord> records;
  const _MoodTab({required this.records});

  @override
  State<_MoodTab> createState() => _MoodTabState();
}

class _MoodTabState extends State<_MoodTab> {
  int _selectedEmojiIndex = -1;
  final TextEditingController _noteController = TextEditingController();

  static const List<_EmojiChoice> _emojis = [
    _EmojiChoice(emoji: '😊', label: 'Happy', value: 7.0),
    _EmojiChoice(emoji: '😌', label: 'Calm', value: 6.0),
    _EmojiChoice(emoji: '😢', label: 'Sad', value: 3.0),
    _EmojiChoice(emoji: '😰', label: 'Anxious', value: 4.0),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _record() {
    if (_selectedEmojiIndex < 0) return;
    final choice = _emojis[_selectedEmojiIndex];
    final now = DateTime.now();
    final h = now.hour;
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final timeLabel = '$h12:${now.minute.toString().padLeft(2, '0')} $period';

    setState(() {
      widget.records.last = _MoodRecord(
        date: 'Today',
        emoji: choice.emoji,
        label: choice.label,
        value: choice.value,
        note: _noteController.text.trim(),
        time: timeLabel,
      );
      _selectedEmojiIndex = -1;
      _noteController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recorded: ${choice.label}',
            style: SeasonsTextStyles.caption.copyWith(color: Colors.white)),
        backgroundColor: SeasonsColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(SeasonsSpacing.radiusMedium)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.records.map((r) => r.value).toList();
    final labels = widget.records.map((r) => r.date).toList();
    final today = widget.records.last;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SeasonsSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week\'s Mood', style: SeasonsTextStyles.caption),
          const SizedBox(height: SeasonsSpacing.sm),
          SoftCard(
            padding: const EdgeInsets.all(SeasonsSpacing.md),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: _MoodLineChart(
                data: values,
                labels: labels,
                lineColor: SeasonsColors.primary,
              ),
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xl),

          Text('Today', style: SeasonsTextStyles.caption),
          const SizedBox(height: SeasonsSpacing.sm),
          SoftCard(
            padding: const EdgeInsets.all(SeasonsSpacing.md),
            child: Row(
              children: [
                Text(today.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: SeasonsSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(today.label, style: SeasonsTextStyles.body),
                      if (today.note.isNotEmpty)
                        Text(today.note, style: SeasonsTextStyles.caption),
                    ],
                  ),
                ),
                if (today.time != null)
                  Text(today.time!, style: SeasonsTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xl),

          Text('Record This Moment', style: SeasonsTextStyles.caption),
          const SizedBox(height: SeasonsSpacing.sm),
          SoftCard(
            padding: const EdgeInsets.all(SeasonsSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How are you feeling right now?',
                    style: SeasonsTextStyles.body),
                const SizedBox(height: SeasonsSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_emojis.length, (i) {
                    final e = _emojis[i];
                    final selected = _selectedEmojiIndex == i;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedEmojiIndex = i),
                      child: AnimatedContainer(
                        duration: SeasonsAnimations.stateChange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: SeasonsSpacing.sm,
                          vertical: SeasonsSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? SeasonsColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                              SeasonsSpacing.radiusMedium),
                          border: Border.all(
                            color: selected
                                ? SeasonsColors.primary.withValues(alpha: 0.4)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(e.emoji,
                                style: TextStyle(
                                    fontSize: selected ? 28 : 24)),
                            const SizedBox(height: 2),
                            Text(e.label,
                                style: SeasonsTextStyles.caption
                                    .copyWith(fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: SeasonsSpacing.md),
                TextField(
                  controller: _noteController,
                  style: SeasonsTextStyles.hint,
                  decoration: InputDecoration(
                    hintText: 'Write something (optional)...',
                    hintStyle: SeasonsTextStyles.hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          SeasonsSpacing.radiusMedium),
                      borderSide: BorderSide(color: SeasonsColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          SeasonsSpacing.radiusMedium),
                      borderSide: BorderSide(color: SeasonsColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          SeasonsSpacing.radiusMedium),
                      borderSide: BorderSide(
                          color: SeasonsColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: SeasonsSpacing.md,
                      vertical: SeasonsSpacing.sm + 4,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: SeasonsSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: GentleButton(
                    text: 'Record',
                    isPrimary: true,
                    onPressed: _selectedEmojiIndex >= 0 ? _record : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xxl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Sleep Tab
// ═══════════════════════════════════════════

class _SleepTab extends StatefulWidget {
  final List<_SleepRecord> records;
  const _SleepTab({required this.records});

  @override
  State<_SleepTab> createState() => _SleepTabState();
}

class _SleepTabState extends State<_SleepTab> {
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeup = const TimeOfDay(hour: 6, minute: 50);
  int _qualityIndex = 2; // default "Good"

  void _pickBedtime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _bedtime,
    );
    if (t != null) setState(() => _bedtime = t);
  }

  void _pickWakeup() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _wakeup,
    );
    if (t != null) setState(() => _wakeup = t);
  }

  String _fmt(TimeOfDay t) => t.format(context);

  void _record() {
    final bedMin = _bedtime.hour * 60 + _bedtime.minute;
    var wakeMin = _wakeup.hour * 60 + _wakeup.minute;
    if (wakeMin <= bedMin) wakeMin += 24 * 60;
    final hours = (wakeMin - bedMin) / 60;
    final quality = _SleepQuality.values[_qualityIndex];
    setState(() {
      widget.records.last = _SleepRecord(
        date: 'Today',
        hours: hours,
        quality: quality,
        bedtime: _fmt(_bedtime),
        wakeup: _fmt(_wakeup),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recorded ${hours.toStringAsFixed(1)}h of sleep',
            style: SeasonsTextStyles.caption.copyWith(color: Colors.white)),
        backgroundColor: SeasonsColors.sky,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(SeasonsSpacing.radiusMedium)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.records.map((r) => r.hours).toList();
    final labels = widget.records.map((r) => r.date).toList();
    final last = widget.records.last;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SeasonsSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week\'s Sleep', style: SeasonsTextStyles.caption),
          const SizedBox(height: SeasonsSpacing.sm),
          SoftCard(
            padding: const EdgeInsets.all(SeasonsSpacing.md),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: _BarChart(
                data: values,
                labels: labels,
                barColor: SeasonsColors.sky,
                suffix: 'h',
              ),
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xl),

          Text('Last Night', style: SeasonsTextStyles.caption),
          const SizedBox(height: SeasonsSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${last.hours.toInt()}',
                style: SeasonsTextStyles.greeting.copyWith(
                  fontSize: 52,
                  fontWeight: FontWeight.w200,
                  color: SeasonsColors.primary,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'h ${(last.hours % 1 * 60).toInt()}m',
                  style: SeasonsTextStyles.body.copyWith(
                    color: SeasonsColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SeasonsSpacing.xs),
          Row(
            children: [
              Text('Quality: ', style: SeasonsTextStyles.caption),
              Text(
                last.quality.label,
                style: SeasonsTextStyles.body.copyWith(
                  color: last.quality.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: SeasonsSpacing.xl),

          Text('Record Sleep', style: SeasonsTextStyles.caption),
          const SizedBox(height: SeasonsSpacing.sm),
          SoftCard(
            padding: const EdgeInsets.all(SeasonsSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bedtime', style: SeasonsTextStyles.caption),
                const SizedBox(height: SeasonsSpacing.xs),
                GestureDetector(
                  onTap: _pickBedtime,
                  child: SoftCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SeasonsSpacing.md,
                      vertical: SeasonsSpacing.sm + 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmt(_bedtime),
                            style: SeasonsTextStyles.body),
                        Icon(Icons.access_time,
                            size: 18, color: SeasonsColors.textHint),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: SeasonsSpacing.md),
                Text('Wake Up', style: SeasonsTextStyles.caption),
                const SizedBox(height: SeasonsSpacing.xs),
                GestureDetector(
                  onTap: _pickWakeup,
                  child: SoftCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SeasonsSpacing.md,
                      vertical: SeasonsSpacing.sm + 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmt(_wakeup),
                            style: SeasonsTextStyles.body),
                        Icon(Icons.access_time,
                            size: 18, color: SeasonsColors.textHint),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: SeasonsSpacing.md),
                Text('Sleep Quality', style: SeasonsTextStyles.caption),
                const SizedBox(height: SeasonsSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                      _SleepQuality.values.length, (i) {
                    final q = _SleepQuality.values[i];
                    final selected = _qualityIndex == i;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _qualityIndex = i),
                      child: AnimatedContainer(
                        duration: SeasonsAnimations.stateChange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: SeasonsSpacing.sm + 4,
                          vertical: SeasonsSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? q.color.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                              SeasonsSpacing.radiusMedium),
                          border: Border.all(
                            color: selected
                                ? q.color.withValues(alpha: 0.4)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(q.emoji,
                                style: TextStyle(
                                    fontSize: selected ? 28 : 24)),
                            const SizedBox(height: 2),
                            Text(q.label,
                                style: SeasonsTextStyles.caption
                                    .copyWith(fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: SeasonsSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: GentleButton(
                    text: 'Record',
                    isPrimary: true,
                    onPressed: _record,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xxl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Exercise Tab
// ═══════════════════════════════════════════

class _ExerciseTab extends StatefulWidget {
  final List<_ExerciseRecord> records;
  const _ExerciseTab({required this.records});

  @override
  State<_ExerciseTab> createState() => _ExerciseTabState();
}

class _ExerciseTabState extends State<_ExerciseTab> {
  static const List<String> _types = [
    'Walk', 'Run', 'Yoga', 'Swim', 'Cycle', 'Stretch'
  ];
  int _typeIndex = 0;
  double _duration = 30.0;
  int _intensityIndex = 0;

  static const List<String> _intensities = ['Light', 'Medium', 'High'];

  void _record() {
    setState(() {
      widget.records.last = _ExerciseRecord(
        date: 'Today',
        minutes: _duration.round(),
        type: _types[_typeIndex],
        intensity: _intensities[_intensityIndex],
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_types[_typeIndex]} ${_duration.round()} min',
            style: SeasonsTextStyles.caption.copyWith(color: Colors.white)),
        backgroundColor: SeasonsColors.sage,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(SeasonsSpacing.radiusMedium)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.records.map((r) => r.minutes.toDouble()).toList();
    final labels = widget.records.map((r) => r.date).toList();
    final last = widget.records.last;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SeasonsSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week\'s Exercise', style: SeasonsTextStyles.caption),
          const SizedBox(height: SeasonsSpacing.sm),
          SoftCard(
            padding: const EdgeInsets.all(SeasonsSpacing.md),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: _BarChart(
                data: values,
                labels: labels,
                barColor: SeasonsColors.sage,
                suffix: 'm',
              ),
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xl),

          Text('Today', style: SeasonsTextStyles.caption),
          const SizedBox(height: SeasonsSpacing.sm),
          SoftCard(
            padding: const EdgeInsets.all(SeasonsSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${last.minutes} min',
                        style: SeasonsTextStyles.heading.copyWith(
                          color: SeasonsColors.primary,
                        ),
                      ),
                      if (last.type.isNotEmpty)
                        Text(last.type,
                            style: SeasonsTextStyles.bodySecondary),
                    ],
                  ),
                ),
                if (last.intensity.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SeasonsSpacing.sm,
                      vertical: SeasonsSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: SeasonsColors.primaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(
                          SeasonsSpacing.radiusFull),
                    ),
                    child: Text(
                      last.intensity,
                      style: SeasonsTextStyles.caption.copyWith(
                        color: SeasonsColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xl),

          Text('Record Exercise', style: SeasonsTextStyles.caption),
          const SizedBox(height: SeasonsSpacing.sm),
          SoftCard(
            padding: const EdgeInsets.all(SeasonsSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activity Type', style: SeasonsTextStyles.caption),
                const SizedBox(height: SeasonsSpacing.sm),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _types.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: SeasonsSpacing.sm),
                    itemBuilder: (context, i) {
                      final selected = _typeIndex == i;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _typeIndex = i),
                        child: AnimatedContainer(
                          duration: SeasonsAnimations.stateChange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: SeasonsSpacing.md,
                            vertical: SeasonsSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? SeasonsColors.primary.withValues(alpha: 0.12)
                                : SeasonsColors.surfaceDim,
                            borderRadius: BorderRadius.circular(
                                SeasonsSpacing.radiusFull),
                            border: Border.all(
                              color: selected
                                  ? SeasonsColors.primary.withValues(alpha: 0.4)
                                  : SeasonsColors.divider,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(_types[i],
                                style: SeasonsTextStyles.caption.copyWith(
                                  color: selected
                                      ? SeasonsColors.primary
                                      : SeasonsColors.textSecondary,
                                )),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: SeasonsSpacing.lg),

                Text('Duration', style: SeasonsTextStyles.caption),
                const SizedBox(height: SeasonsSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: SeasonsColors.sage,
                          inactiveTrackColor:
                              SeasonsColors.sage.withValues(alpha: 0.2),
                          thumbColor: SeasonsColors.sage,
                          overlayColor:
                              SeasonsColors.sage.withValues(alpha: 0.1),
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: _duration,
                          min: 5,
                          max: 120,
                          onChanged: (v) =>
                              setState(() => _duration = v),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${_duration.round()} min',
                        style: SeasonsTextStyles.body.copyWith(
                          color: SeasonsColors.sage,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SeasonsSpacing.md),

                Text('Intensity', style: SeasonsTextStyles.caption),
                const SizedBox(height: SeasonsSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                      _intensities.length, (i) {
                    final selected = _intensityIndex == i;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _intensityIndex = i),
                      child: AnimatedContainer(
                        duration: SeasonsAnimations.stateChange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: SeasonsSpacing.md + 4,
                          vertical: SeasonsSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? SeasonsColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                              SeasonsSpacing.radiusMedium),
                          border: Border.all(
                            color: selected
                                ? SeasonsColors.primary.withValues(alpha: 0.4)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _intensities[i],
                          style: SeasonsTextStyles.body.copyWith(
                            color: selected
                                ? SeasonsColors.primary
                                : SeasonsColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: SeasonsSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: GentleButton(
                    text: 'Record',
                    isPrimary: true,
                    onPressed: _record,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xxl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Diet Tab
// ═══════════════════════════════════════════

class _DietTab extends StatefulWidget {
  final List<_DietRecord> records;
  const _DietTab({required this.records});

  @override
  State<_DietTab> createState() => _DietTabState();
}

class _DietTabState extends State<_DietTab> {
  int _score = 7;
  final TextEditingController _noteController = TextEditingController();

  void _record() {
    setState(() {
      widget.records.last = _DietRecord(
        date: 'Today',
        score: _score,
        meals: _noteController.text.trim().isEmpty
            ? 'Not recorded'
            : _noteController.text.trim(),
        emoji: _score >= 8 ? '🥗' : _score >= 6 ? '🍔' : '☕',
      );
      _noteController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Diet score ${_score}/10',
            style: SeasonsTextStyles.caption.copyWith(color: Colors.white)),
        backgroundColor: SeasonsColors.warm,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(SeasonsSpacing.radiusMedium)),
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.records.map((r) => r.score.toDouble()).toList();
    final labels = widget.records.map((r) => r.date).toList();
    final last = widget.records.last;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SeasonsSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week\'s Diet', style: SeasonsTextStyles.caption),
          const SizedBox(height: SeasonsSpacing.sm),
          SoftCard(
            padding: const EdgeInsets.all(SeasonsSpacing.md),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: _MoodLineChart(
                data: values,
                labels: labels,
                lineColor: SeasonsColors.warm,
              ),
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xl),

          Text('Today', style: SeasonsTextStyles.caption),
          const SizedBox(height: SeasonsSpacing.sm),
          SoftCard(
            padding: const EdgeInsets.all(SeasonsSpacing.md),
            child: Row(
              children: [
                Text(last.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: SeasonsSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(last.meals, style: SeasonsTextStyles.body),
                      Text('Health score ${last.score}/10',
                          style: SeasonsTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xl),

          Text('Record Diet', style: SeasonsTextStyles.caption),
          const SizedBox(height: SeasonsSpacing.sm),
          SoftCard(
            padding: const EdgeInsets.all(SeasonsSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What did you eat today?',
                    style: SeasonsTextStyles.body),
                const SizedBox(height: SeasonsSpacing.sm),
                TextField(
                  controller: _noteController,
                  style: SeasonsTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Write something...',
                    hintStyle: SeasonsTextStyles.hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          SeasonsSpacing.radiusMedium),
                      borderSide: BorderSide(color: SeasonsColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          SeasonsSpacing.radiusMedium),
                      borderSide: BorderSide(color: SeasonsColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          SeasonsSpacing.radiusMedium),
                      borderSide: BorderSide(
                          color: SeasonsColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: SeasonsSpacing.md,
                      vertical: SeasonsSpacing.sm + 4,
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: SeasonsSpacing.md),

                Text('Health Score', style: SeasonsTextStyles.caption),
                const SizedBox(height: SeasonsSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: SeasonsColors.warm,
                          inactiveTrackColor:
                              SeasonsColors.warm.withValues(alpha: 0.2),
                          thumbColor: SeasonsColors.warm,
                          overlayColor:
                              SeasonsColors.warm.withValues(alpha: 0.1),
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: _score.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          onChanged: (v) =>
                              setState(() => _score = v.round()),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '$_score/10',
                        style: SeasonsTextStyles.body.copyWith(
                          color: SeasonsColors.warm,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SeasonsSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: GentleButton(
                    text: 'Record',
                    isPrimary: true,
                    onPressed: _record,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xxl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Charts — CustomPainter
// ═══════════════════════════════════════════

class _MoodLineChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;

  const _MoodLineChart({
    required this.data,
    required this.labels,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text('No data yet', style: SeasonsTextStyles.hint));
    }
    return CustomPaint(
      painter: _SoftLinePainter(
        data: data,
        labels: labels,
        lineColor: lineColor,
        dotColor: lineColor,
      ),
      size: Size.infinite,
    );
  }
}

class _SoftLinePainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;
  final Color dotColor;

  _SoftLinePainter({
    required this.data,
    required this.labels,
    required this.lineColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const padL = 8.0, padR = 8.0, padT = 16.0, padB = 24.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;

    final minV = data.reduce(min);
    final maxV = data.reduce(max);
    final range = (maxV - minV == 0) ? 1.0 : maxV - minV;
    final aMin = minV - range * 0.15;
    final aMax = maxV + range * 0.15;
    final aRange = aMax - aMin;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = padL +
          (data.length > 1 ? i / (data.length - 1) * w : w / 2);
      final y = padT + h - ((data[i] - aMin) / aRange) * h;
      points.add(Offset(x, y));
    }

    final fillPath = Path()
      ..moveTo(points.first.dx, padT + h)
      ..lineTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final c1 =
          Offset((points[i].dx + points[i - 1].dx) / 2, points[i - 1].dy);
      final c2 =
          Offset((points[i].dx + points[i - 1].dx) / 2, points[i].dy);
      fillPath.cubicTo(
          c1.dx, c1.dy, c2.dx, c2.dy, points[i].dx, points[i].dy);
    }
    fillPath.lineTo(points.last.dx, padT + h);
    fillPath.close();

    final rect = Rect.fromLTRB(padL, padT, size.width - padR, padT + h);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.12),
            lineColor.withValues(alpha: 0.02)
          ],
        ).createShader(rect),
    );
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.18),
            lineColor.withValues(alpha: 0.03)
          ],
        ).createShader(rect),
    );

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final c1 =
          Offset((points[i].dx + points[i - 1].dx) / 2, points[i - 1].dy);
      final c2 =
          Offset((points[i].dx + points[i - 1].dx) / 2, points[i].dy);
      linePath.cubicTo(
          c1.dx, c1.dy, c2.dx, c2.dy, points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3, Paint()..color = dotColor);
    }

    for (int i = 0; i < labels.length; i++) {
      final x = padL +
          (labels.length > 1 ? i / (labels.length - 1) * w : w / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(fontSize: 10, color: SeasonsColors.textHint),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, padT + h + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _SoftLinePainter old) =>
      old.data != data || old.lineColor != lineColor;
}

class _BarChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color barColor;
  final String suffix;

  const _BarChart({
    required this.data,
    required this.labels,
    required this.barColor,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text('No data yet', style: SeasonsTextStyles.hint));
    }
    return CustomPaint(
      painter: _SoftBarPainter(
        data: data,
        labels: labels,
        barColor: barColor,
        suffix: suffix,
      ),
      size: Size.infinite,
    );
  }
}

class _SoftBarPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color barColor;
  final String suffix;

  _SoftBarPainter({
    required this.data,
    required this.labels,
    required this.barColor,
    required this.suffix,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const padL = 4.0, padR = 4.0, padT = 16.0, padB = 24.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;

    final maxV = data.reduce(max).toDouble();
    final aMax = maxV * 1.15;

    final barWidth = w / data.length * 0.5;
    final gap = w / data.length;

    for (int i = 0; i < data.length; i++) {
      final barH = (data[i] / aMax) * h;
      final x = padL + gap * i + (gap - barWidth) / 2;
      final y = padT + h - barH;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        const Radius.circular(4),
      );

      canvas.drawRRect(rrect, Paint()..color = barColor.withValues(alpha: 0.5));

      final valText = suffix.isEmpty
          ? data[i].toStringAsFixed(0)
          : '${data[i].toStringAsFixed(0)}$suffix';
      final tp = TextPainter(
        text: TextSpan(
          text: valText,
          style: TextStyle(fontSize: 9, color: barColor.withValues(alpha: 0.7)),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x + barWidth / 2 - tp.width / 2, y - 14));

      final lp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(fontSize: 10, color: SeasonsColors.textHint),
        ),
        textDirection: TextDirection.ltr,
      );
      lp.layout();
      lp.paint(
        canvas,
        Offset(padL + gap * i + gap / 2 - lp.width / 2, padT + h + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoftBarPainter old) =>
      old.data != data || old.barColor != barColor;
}

// ═══════════════════════════════════════════
// Data Models
// ═══════════════════════════════════════════

class _EmojiChoice {
  final String emoji;
  final String label;
  final double value;
  const _EmojiChoice(
      {required this.emoji, required this.label, required this.value});
}

class _MoodRecord {
  String date;
  String emoji;
  String label;
  double value;
  String note;
  String? time;
  _MoodRecord({
    required this.date,
    required this.emoji,
    required this.label,
    required this.value,
    required this.note,
    this.time,
  });
}

enum _SleepQuality {
  poor(emoji: '😫', label: 'Poor', color: SeasonsColors.error),
  fair(emoji: '🥱', label: 'Fair', color: SeasonsColors.warning),
  good(emoji: '😌', label: 'Good', color: SeasonsColors.sky),
  excellent(emoji: '😴', label: 'Excellent', color: SeasonsColors.primary);

  const _SleepQuality({
    required this.emoji,
    required this.label,
    required this.color,
  });

  final String emoji;
  final String label;
  final Color color;
}

class _SleepRecord {
  String date;
  double hours;
  _SleepQuality quality;
  String bedtime;
  String wakeup;
  _SleepRecord({
    required this.date,
    required this.hours,
    required this.quality,
    required this.bedtime,
    required this.wakeup,
  });
}

class _ExerciseRecord {
  String date;
  int minutes;
  String type;
  String intensity;
  _ExerciseRecord({
    required this.date,
    required this.minutes,
    required this.type,
    required this.intensity,
  });
}

class _DietRecord {
  String date;
  int score;
  String meals;
  String emoji;
  _DietRecord({
    required this.date,
    required this.score,
    required this.meals,
    required this.emoji,
  });
}

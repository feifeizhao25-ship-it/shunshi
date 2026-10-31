/// 冥想音频库（国内版）— 原创中文脚本 + AI 合成语音 + 程序合成配乐。
///
/// 数据来自后端 GET /api/v1/meditation/library：
/// - 加载中：转圈 + 文案；
/// - 失败：中文提示 + 重试；
/// - 后端没有任何可播放条目：显示空状态，不放任何示例条目；
/// - 音频不打进安装包，由后端（或 CDN）提供。
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/theme.dart';
import 'meditation_player_page.dart';

class MeditationLibraryPage extends StatefulWidget {
  /// 测试时可注入自定义 Dio；正式使用不传。
  final Dio? dio;
  const MeditationLibraryPage({super.key, this.dio});

  @override
  State<MeditationLibraryPage> createState() => _MeditationLibraryPageState();
}

class _MeditationLibraryPageState extends State<MeditationLibraryPage> {
  late final Dio _dio = widget.dio ??
      Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
      ));

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, String>> _categories = [];
  String _activeCategory = '';
  String _aiLabel = 'AI 合成语音';
  String _disclaimer = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _dio.get('/api/v1/meditation/library');
      final data = (resp.data is Map ? resp.data['data'] : null) as Map?;
      if (data == null) throw const FormatException('empty');
      final items = ((data['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final cats = ((data['categories'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => {'id': '${e['id']}', 'label': '${e['label']}'})
          .toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _categories = cats;
        _aiLabel = '${data['ai_label'] ?? 'AI 合成语音'}';
        _disclaimer = '${data['disclaimer'] ?? ''}';
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout)
            ? '网络连接不稳定，请检查网络后重试。'
            : '冥想音频暂时无法加载，请稍后重试。';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '冥想音频暂时无法加载，请稍后重试。';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visible => _activeCategory.isEmpty
      ? _items
      : _items.where((e) => '${e['category']}' == _activeCategory).toList();

  String _duration(dynamic seconds) {
    final s = seconds is num ? seconds.toInt() : 0;
    if (s <= 0) return '时长待定';
    final m = s ~/ 60;
    final r = s % 60;
    return r == 0 ? '$m 分钟' : '$m 分 $r 秒';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text('冥想音频', style: TextStyle(
          fontFamily: ShunShiTypography.serifFamily,
          color: AppColors.textPrimary(context),
        )),
        backgroundColor: AppColors.background(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary(context)),
      ),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('正在加载冥想音频…', style: TextStyle(color: AppColors.textSecondary(context))),
        ]),
      );
    }
    if (_error != null) {
      return _message(context, Icons.cloud_off_outlined, _error!, actionLabel: '重新加载');
    }
    if (_items.isEmpty) {
      return _message(
        context,
        Icons.spa_outlined,
        '冥想音频正在准备中，暂时没有可播放的内容。\n稍后再来看看，或先试试呼吸练习。',
        actionLabel: '刷新',
      );
    }
    final visible = _visible;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(children: [
            _badge(context, Icons.record_voice_over_outlined, _aiLabel),
            const SizedBox(width: 8),
            _badge(context, Icons.edit_note_outlined, '原创文稿'),
          ]),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _chip(context, '全部', _activeCategory.isEmpty, () => setState(() => _activeCategory = '')),
              for (final c in _categories)
                if (_items.any((e) => '${e['category']}' == c['id']))
                  _chip(context, c['label']!, _activeCategory == c['id'],
                      () => setState(() => _activeCategory = c['id']!)),
            ]),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('这个分类下暂时没有音频。', style: TextStyle(color: AppColors.textSecondary(context)))),
            ),
          for (final item in visible) _card(context, item),
          const SizedBox(height: 12),
          if (_disclaimer.isNotEmpty)
            Text(_disclaimer, style: TextStyle(fontSize: 11, height: 1.6, color: AppColors.textTertiary(context))),
        ],
      ),
    );
  }

  Widget _message(BuildContext context, IconData icon, String text, {required String actionLabel}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: AppColors.textTertiary(context)),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.7, color: AppColors.textSecondary(context))),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: _load, child: Text(actionLabel)),
        ]),
      ),
    );
  }

  Widget _badge(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.primary(context)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
      ]),
    );
  }

  Widget _chip(BuildContext context, String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> item) {
    final recommended = item['recommended'] == true;
    final term = item['term'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MeditationPlayerPage(track: item)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textTertiary(context).withValues(alpha: 0.12)),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.play_arrow_rounded, color: AppColors.primary(context), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${item['title']}', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  fontFamily: ShunShiTypography.serifFamily,
                  color: AppColors.textPrimary(context),
                )),
                const SizedBox(height: 4),
                Text('${item['subtitle']}', maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary(context))),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  _tag(context, '${item['category_label']}'),
                  if (term != null) _tag(context, '$term'),
                  _tag(context, _duration(item['duration_seconds'])),
                  if (recommended) _tag(context, '当季推荐', highlight: true),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, String text, {bool highlight = false}) {
    return Text(text, style: TextStyle(
      fontSize: 11,
      fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
      color: highlight ? AppColors.primary(context) : AppColors.textTertiary(context),
    ));
  }
}

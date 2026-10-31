/// 冥想音频播放页（国内版）。
///
/// - 播放界面常驻显示「AI 合成语音」标识与免责声明（含 12356 热线），不可隐藏；
/// - 加载失败显示中文提示并可重试；
/// - 可展开查看全文文稿，听障或不方便出声时也能阅读。
library;

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/config/app_config.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/theme.dart';

class MeditationPlayerPage extends StatefulWidget {
  final Map<String, dynamic> track;
  const MeditationPlayerPage({super.key, required this.track});

  @override
  State<MeditationPlayerPage> createState() => _MeditationPlayerPageState();
}

class _MeditationPlayerPageState extends State<MeditationPlayerPage> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSub;
  bool _loading = true;
  String? _error;
  bool _playing = false;
  bool _completed = false;
  String _transcript = '';
  String _disclaimer = '';

  String get _id => '${widget.track['id']}';

  String _absoluteUrl() {
    final url = '${widget.track['audio_url'] ?? ''}';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${AppConfig.apiBaseUrl}$url';
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _stateSub = _player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() {
        _playing = s.playing && s.processingState != ProcessingState.completed;
        _completed = s.processingState == ProcessingState.completed;
      });
    });
    _prepare();
    _loadTranscript();
  }

  Future<void> _prepare() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _player.setUrl(_absoluteUrl());
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '音频加载失败，请检查网络后重试。';
      });
    }
  }

  Future<void> _loadTranscript() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
      ));
      final resp = await dio.get('/api/v1/meditation/library/$_id');
      final data = (resp.data is Map ? resp.data['data'] : null) as Map?;
      if (!mounted || data == null) return;
      setState(() {
        _transcript = '${data['transcript'] ?? ''}';
        _disclaimer = '${data['disclaimer'] ?? ''}';
      });
    } catch (_) {
      // 文稿拿不到不影响播放；页面会显示「文稿暂时无法加载」
      if (!mounted) return;
      setState(() => _transcript = '');
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _seekBy(int seconds) async {
    final total = _player.duration ?? Duration.zero;
    var target = _player.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (total > Duration.zero && target > total) target = total;
    await _player.seek(target);
  }

  Future<void> _toggle() async {
    if (_completed) {
      await _player.seek(Duration.zero);
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      unawaited(_player.play());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ai = '${widget.track['ai_label'] ?? 'AI 合成语音'}';
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text('${widget.track['title']}', style: TextStyle(
          fontFamily: ShunShiTypography.serifFamily,
          color: AppColors.textPrimary(context),
        )),
        backgroundColor: AppColors.background(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary(context)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.record_voice_over_outlined, size: 16, color: AppColors.primary(context)),
                const SizedBox(width: 6),
                Text(ai, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
              ]),
            )),
            const SizedBox(height: 16),
            Text('${widget.track['subtitle']}', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary(context))),
            const SizedBox(height: 28),
            _controls(context),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _disclaimer.isNotEmpty
                    ? _disclaimer
                    : '本音频由 AI 合成语音朗读，仅用于放松与作息参考，不是医疗服务。练习中感到不适请立即停止；如长期睡不好或情绪持续低落，请咨询医生或拨打 12356 心理援助热线。',
                style: TextStyle(fontSize: 12, height: 1.7, color: AppColors.textSecondary(context)),
              ),
            ),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('查看文稿', style: TextStyle(color: AppColors.textPrimary(context))),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _transcript.isEmpty ? '文稿暂时无法加载。' : _transcript,
                      style: TextStyle(fontSize: 14, height: 1.9, color: AppColors.textSecondary(context)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(BuildContext context) {
    if (_loading) {
      return Column(children: [
        const SizedBox(height: 12),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 12),
        Center(child: Text('正在加载音频…', style: TextStyle(color: AppColors.textSecondary(context)))),
      ]);
    }
    if (_error != null) {
      return Column(children: [
        Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.textTertiary(context)),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary(context))),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _prepare, child: const Text('重试')),
      ]);
    }
    return Column(children: [
      StreamBuilder<Duration>(
        stream: _player.positionStream,
        builder: (context, snap) {
          final pos = snap.data ?? Duration.zero;
          final total = _player.duration ?? Duration.zero;
          final max = total.inMilliseconds <= 0 ? 1.0 : total.inMilliseconds.toDouble();
          final value = pos.inMilliseconds.clamp(0, max.toInt()).toDouble();
          return Column(children: [
            Slider(
              value: value,
              max: max,
              onChanged: total == Duration.zero ? null : (v) => _player.seek(Duration(milliseconds: v.toInt())),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_fmt(pos), style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context))),
                Text(_fmt(total), style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context))),
              ]),
            ),
          ]);
        },
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
          tooltip: '后退 15 秒',
          iconSize: 32,
          icon: const Icon(Icons.replay_10),
          color: AppColors.textSecondary(context),
          onPressed: () => _seekBy(-15),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          tooltip: _playing ? '暂停' : '播放',
          iconSize: 44,
          icon: Icon(_playing ? Icons.pause : (_completed ? Icons.replay : Icons.play_arrow)),
          onPressed: _toggle,
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: '前进 15 秒',
          iconSize: 32,
          icon: const Icon(Icons.forward_10),
          color: AppColors.textSecondary(context),
          onPressed: () => _seekBy(15),
        ),
      ]),
    ]);
  }
}

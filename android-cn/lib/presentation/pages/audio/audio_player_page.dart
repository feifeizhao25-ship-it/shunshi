import 'package:audioplayers/audioplayers.dart';
import '../../../data/network/api_client.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_spacing.dart';
import '../../../core/theme/shunshi_text_styles.dart';
import '../../../core/theme/shunshi_animations.dart';
import '../../widgets/components/components.dart';

/// 音频播放器 — 沉浸式设计
///
/// 全屏深色渐变背景，中心呼吸动画，极简控制
/// 真实音频播放 via audioplayers + 后端 API
class AudioPlayerPage extends StatefulWidget {
  /// 音频 ID，从 API 获取完整数据
  final String? audioId;
  /// 直接传入音频 URL（可选）
  final String? audioUrl;
  /// 音频标题（可选，不传则从 API 获取）
  final String? title;
  /// 音频副标题（可选）
  final String? subtitle;

  const AudioPlayerPage({
    super.key,
    this.audioId,
    this.audioUrl,
    this.title,
    this.subtitle,
  });

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage>
    with TickerProviderStateMixin {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  late AnimationController _breathController;
  late Animation<double> _breathScale;

  String _title = '呼吸引导';
  String _subtitle = '3秒呼吸节奏';
  String _category = 'guided';
  bool _isPremium = false;
  String? _audioUrl;

  final _dio = Dio(BaseOptions(
    baseUrl: ApiClient.baseUrl,
    connectTimeout: const Duration(seconds: 10),
  ));

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _breathController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _breathScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: ShunshiAnimations.slowEase,
      ),
    );
    _breathController.repeat(reverse: true);

    _positionSub = _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _durationSub = _player.onDurationChanged.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() { _isPlaying = false; });
        _onCompleted();
      }
    });

    // 优先使用直接传入的 audioUrl
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      _audioUrl = widget.audioUrl;
      _title = widget.title ?? _title;
      _subtitle = widget.subtitle ?? _subtitle;
      setState(() => _isLoading = false);
      _loadAudio(_audioUrl!);
    } else if (widget.audioId != null && widget.audioId!.isNotEmpty) {
      _loadAudioFromId();
    } else {
      // 无数据，回退到静态 UI
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAudioFromId() async {
    try {
      final response = await _dio.get('/api/v1/seasons/audio/${widget.audioId}');
      if (response.statusCode == 200 && mounted) {
        final data = response.data as Map<String, dynamic>;
        final audioUrl = data['audio_url'] as String?;
        setState(() {
          _title = widget.title ?? data['title'] ?? _title;
          _subtitle = widget.subtitle ?? data['subtitle'] ?? _subtitle;
          _category = data['type'] ?? _category;
          _isPremium = data['is_premium'] ?? false;
          _audioUrl = audioUrl;
          _isLoading = false;
        });

        if (audioUrl != null && audioUrl.isNotEmpty) {
          await _loadAudio(audioUrl);
        } else {
          setState(() { _hasError = true; _errorMessage = '无音频地址'; });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _hasError = true; _errorMessage = '加载失败，请重试'; });
      }
    }
  }

  Future<void> _loadAudio(String url) async {
    try {
      await _player.play(UrlSource(url));
      if (mounted) setState(() => _isPlaying = true);
    } catch (e) {
      if (mounted) {
        setState(() { _hasError = true; _errorMessage = '音频播放失败'; _isLoading = false; });
      }
    }
  }

  Future<void> _onCompleted() async {
    try {
      await _dio.post(
        '/api/v1/seasons/audio/progress',
        data: {
          'audio_id': widget.audioId ?? '',
          'user_id': 'current_user', // TODO: 从认证模块获取
          'progress_seconds': _duration.inSeconds,
          'completed': true,
        },
      );
    } catch (_) {}
  }

  Future<void> _reportProgress() async {
    try {
      await _dio.post(
        '/api/v1/seasons/audio/progress',
        data: {
          'audio_id': widget.audioId ?? '',
          'user_id': 'current_user',
          'progress_seconds': _position.inSeconds,
          'completed': false,
        },
      );
    } catch (_) {}
  }

  Future<void> _togglePlay() async {
    if (_hasError || _isLoading) return;
    if (_isPlaying) {
      await _player.pause();
      _reportProgress();
    } else {
      await _player.resume();
    }
  }

  void _seekRelative(int seconds) {
    final newPos = _position + Duration(seconds: seconds);
    _player.seek(Duration(seconds: newPos.inSeconds.clamp(0, _duration.inSeconds)));
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _categoryEmoji {
    switch (_category.toLowerCase()) {
      case 'soundscape': return '🌧️';
      case 'meditation': return '🧘';
      default: return '🌿';
    }
  }

  String get _categoryLabel {
    switch (_category.toLowerCase()) {
      case 'soundscape': return '自然音';
      case 'meditation': return '冥想';
      default: return '呼吸引导';
    }
  }

  @override
  void dispose() {
    _reportProgress();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();
    _breathController.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A18), Color(0xFF252523), Color(0xFF1A1A18)],
          ),
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ShunshiDarkColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text('加载中...',
              style: TextStyle(color: ShunshiDarkColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    if (_hasError) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(ShunshiSpacing.md),
              child: IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.of(context).pop(),
                color: ShunshiDarkColors.textSecondary,
              ),
            ),
          ),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                size: 48, color: ShunshiDarkColors.textSecondary),
              const SizedBox(height: 16),
              Text(_errorMessage,
                style: const TextStyle(color: ShunshiDarkColors.textSecondary)),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  setState(() { _isLoading = true; _hasError = false; });
                  _loadAudioFromId();
                },
                child: const Text('重试',
                  style: TextStyle(color: ShunshiDarkColors.primary)),
              ),
            ],
          ),
          const Spacer(),
        ],
      );
    }

    final progress = _duration.inSeconds > 0
        ? _position.inSeconds / _duration.inSeconds : 0.0;

    return Column(
      children: [
        // 关闭按钮
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(ShunshiSpacing.md),
            child: IconButton(
              icon: const Icon(Icons.close, size: 22),
              onPressed: () => Navigator.of(context).pop(),
              color: ShunshiDarkColors.textSecondary,
            ),
          ),
        ),

        const Spacer(flex: 1),

        // 中心呼吸动画
        AnimatedBuilder(
          animation: _breathScale,
          builder: (context, child) {
            return Transform.scale(
              scale: _breathScale.value,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ShunshiDarkColors.primary.withValues(alpha: 0.15),
                      ShunshiDarkColors.primary.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                  border: Border.all(
                    color: ShunshiDarkColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_categoryEmoji, style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: ShunshiSpacing.sm),
                      Text(_categoryLabel,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w300,
                          color: ShunshiDarkColors.primary, letterSpacing: 2)),
                      const SizedBox(height: ShunshiSpacing.xs),
                      Text(_isPlaying ? '呼吸中...' : '点击开始',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300,
                          color: ShunshiDarkColors.textHint)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        const Spacer(flex: 1),

        // 标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ShunshiSpacing.xl),
          child: Text(_title,
            style: ShunshiTextStyles.body.copyWith(
              color: ShunshiDarkColors.textPrimary, fontWeight: FontWeight.w300),
            textAlign: TextAlign.center),
        ),
        const SizedBox(height: ShunshiSpacing.xl),

        // 进度条
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ShunshiSpacing.xl),
          child: Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: ShunshiDarkColors.primary,
                  inactiveTrackColor: ShunshiDarkColors.surfaceDim,
                  thumbColor: ShunshiDarkColors.primary,
                  overlayColor: ShunshiDarkColors.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (val) {
                    _player.seek(Duration(milliseconds: (val * _duration.inMilliseconds).round()));
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position),
                    style: ShunshiTextStyles.caption.copyWith(
                      color: ShunshiDarkColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()])),
                  Text(_formatDuration(_duration),
                    style: ShunshiTextStyles.caption.copyWith(
                      color: ShunshiDarkColors.textHint,
                      fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: ShunshiSpacing.xl),

        // 控制按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous, size: 28),
              onPressed: () => _seekRelative(-10),
              color: ShunshiDarkColors.textSecondary,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            const SizedBox(width: ShunshiSpacing.lg),
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ShunshiDarkColors.primary.withValues(alpha: 0.15),
                  border: Border.all(
                    color: ShunshiDarkColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 36,
                  color: ShunshiDarkColors.primary,
                ),
              ),
            ),
            const SizedBox(width: ShunshiSpacing.lg),
            IconButton(
              icon: const Icon(Icons.skip_next, size: 28),
              onPressed: () => _seekRelative(30),
              color: ShunshiDarkColors.textSecondary,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
          ],
        ),

        const Spacer(flex: 2),
      ],
    );
  }
}

import 'package:just_audio/just_audio.dart';
import '../../../core/constants/app_constants.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:seasons/core/theme/seasons_colors.dart';
import 'package:seasons/core/theme/seasons_spacing.dart';
import 'package:seasons/core/theme/seasons_text_styles.dart';
import 'package:seasons/core/theme/seasons_animations.dart';

/// Audio Player — Immersive, minimal, calm
/// Full-screen dark gradient, centered breathing animation, thin progress line
/// Real audio playback via just_audio + backend API
class AudioPlayerPage extends StatefulWidget {
  final String audioId;

  const AudioPlayerPage({super.key, required this.audioId});

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

  String _title = 'Breathing Guide';
  String _subtitle = '3-second rhythm';
  String _category = 'guided';
  bool _isPremium = false;
  String? _audioUrl;

  final _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
  ));

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _breathController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _breathScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: SeasonsAnimations.slowEase,
      ),
    );
    _breathController.repeat(reverse: true);

    _positionSub = _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _durationSub = _player.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
        if (state.processingState == ProcessingState.completed) {
          _onCompleted();
        }
      }
    });

    _loadAudioData();
  }

  Future<void> _loadAudioData() async {
    if (widget.audioId.isEmpty) {
      setState(() { _isLoading = false; _hasError = true; _errorMessage = 'No audio ID'; });
      return;
    }

    try {
      final response = await _dio.get('/api/v1/seasons/audio/${widget.audioId}');
      if (response.statusCode == 200 && mounted) {
        final data = response.data as Map<String, dynamic>;
        final audioUrl = data['audio_url'] as String?;
        setState(() {
          _title = data['title'] ?? _title;
          _subtitle = data['subtitle'] ?? _subtitle;
          _category = data['type'] ?? _category;
          _isPremium = data['is_premium'] ?? false;
          _audioUrl = audioUrl;
          _isLoading = false;
        });

        if (audioUrl != null && audioUrl.isNotEmpty) {
          await _player.setUrl(audioUrl);
          await _player.play();
          setState(() => _isPlaying = true);
        } else {
          setState(() { _hasError = true; _errorMessage = 'No audio URL available'; });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _hasError = true; _errorMessage = 'Failed to load audio'; });
      }
    }
  }

  Future<void> _onCompleted() async {
    try {
      await _dio.post(
        '/api/v1/seasons/audio/progress',
        data: {
          'audio_id': widget.audioId,
          'user_id': 'current_user', // TODO: get from auth
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
          'audio_id': widget.audioId,
          'user_id': 'current_user', // TODO: get from auth
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
      await _player.play();
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
      case 'soundscape': return 'Soundscape';
      case 'meditation': return 'Meditation';
      default: return 'Guided Breath';
    }
  }

  @override
  void dispose() {
    _reportProgress();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
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
            colors: [Color(0xFF181818), Color(0xFF222222), Color(0xFF181818)],
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: SeasonsDarkColors.primary)),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: SeasonsDarkColors.textSecondary, fontSize: 14)),
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
              padding: const EdgeInsets.all(SeasonsSpacing.md),
              child: IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.of(context).pop(),
                color: SeasonsDarkColors.textSecondary,
              ),
            ),
          ),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: SeasonsDarkColors.textSecondary),
              const SizedBox(height: 16),
              Text(_errorMessage, style: const TextStyle(color: SeasonsDarkColors.textSecondary)),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () { setState(() { _isLoading = true; _hasError = false; }); _loadAudioData(); },
                child: const Text('Retry', style: TextStyle(color: SeasonsDarkColors.primary)),
              ),
            ],
          ),
          const Spacer(),
        ],
      );
    }

    final progress = _duration.inSeconds > 0 ? _position.inSeconds / _duration.inSeconds : 0.0;

    return Column(
      children: [
        // Header
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(SeasonsSpacing.md),
            child: IconButton(
              icon: const Icon(Icons.close, size: 22),
              onPressed: () => Navigator.of(context).pop(),
              color: SeasonsDarkColors.textSecondary,
            ),
          ),
        ),

        const Spacer(flex: 1),

        // Breathing circle
        AnimatedBuilder(
          animation: _breathScale,
          builder: (context, child) {
            return Transform.scale(
              scale: _breathScale.value,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      SeasonsDarkColors.primary.withValues(alpha: 0.12),
                      SeasonsDarkColors.primary.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                  border: Border.all(
                    color: SeasonsDarkColors.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_categoryEmoji, style: const TextStyle(fontSize: 44)),
                      const SizedBox(height: SeasonsSpacing.sm),
                      Text(_categoryLabel,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w200,
                          color: SeasonsDarkColors.primary, letterSpacing: 3)),
                      const SizedBox(height: SeasonsSpacing.xs),
                      Text(_isPlaying ? 'breathe...' : 'tap to begin',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300,
                          color: SeasonsDarkColors.textHint)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        const Spacer(flex: 1),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SeasonsSpacing.xxl),
          child: Text(_title,
            style: SeasonsTextStyles.body.copyWith(color: SeasonsDarkColors.textPrimary, fontWeight: FontWeight.w200),
            textAlign: TextAlign.center),
        ),
        const SizedBox(height: SeasonsSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SeasonsSpacing.xxl),
          child: Text(_subtitle,
            style: SeasonsTextStyles.caption.copyWith(color: SeasonsDarkColors.textSecondary),
            textAlign: TextAlign.center),
        ),
        const SizedBox(height: SeasonsSpacing.xl),

        // Progress bar with slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SeasonsSpacing.xxl),
          child: Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: SeasonsDarkColors.primary,
                  inactiveTrackColor: SeasonsDarkColors.surfaceDim,
                  thumbColor: SeasonsDarkColors.primary,
                  overlayColor: SeasonsDarkColors.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (val) {
                    _player.seek(Duration(seconds: (val * _duration.inSeconds).round()));
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position),
                    style: SeasonsTextStyles.caption.copyWith(color: SeasonsDarkColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()])),
                  Text(_formatDuration(_duration),
                    style: SeasonsTextStyles.caption.copyWith(color: SeasonsDarkColors.textHint,
                      fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: SeasonsSpacing.xl),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10, size: 28),
              onPressed: () => _seekRelative(-10),
              color: SeasonsDarkColors.textSecondary,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            const SizedBox(width: SeasonsSpacing.lg),
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SeasonsDarkColors.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: SeasonsDarkColors.primary.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 38,
                  color: SeasonsDarkColors.primary,
                ),
              ),
            ),
            const SizedBox(width: SeasonsSpacing.lg),
            IconButton(
              icon: const Icon(Icons.forward_30, size: 28),
              onPressed: () => _seekRelative(30),
              color: SeasonsDarkColors.textSecondary,
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

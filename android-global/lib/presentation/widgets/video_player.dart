// 视频播放器组件 - 使用 video_player 包
import 'package:flutter/material.dart';
import '../../core/theme/shunshi_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart' as vp;

/// 视频播放器状态
enum VideoPlayerState {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

/// 视频播放器 Controller (ChangeNotifier wrapper)
/// 
/// 当添加 video_player 包后，此处内部的 [_innerController] 应替换为
/// package:video_player 中的 VideoPlayerController。
class VideoPlayerController extends ChangeNotifier {
  VideoPlayerState _state = VideoPlayerState.idle;
  String? _errorMessage;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isFullScreen = false;
  bool _isPlaying = false;

  VideoPlayerState get state => _state;
  String? get errorMessage => _errorMessage;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  bool get isFullScreen => _isFullScreen;
  bool get isInitialized => _state != VideoPlayerState.idle && _state != VideoPlayerState.loading && _state != VideoPlayerState.error;
  double get progress => _duration.inMilliseconds > 0 
      ? _position.inMilliseconds / _duration.inMilliseconds 
      : 0;
  
  /// 初始化视频 - 使用 video_player 包
  vp.VideoPlayerController? _vpController;

  /// Access the underlying video_player controller
  vp.VideoPlayerController? get vpController => _vpController;

  Future<void> initialize(String videoUrl) async {
    _state = VideoPlayerState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _vpController = vp.VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _vpController!.initialize();
      _vpController!.setLooping(false);

      _vpController!.addListener(() {
        final pos = _vpController!.value.position;
        final dur = _vpController!.value.duration;
        _position = pos;
        _duration = dur;
        _isPlaying = _vpController!.value.isPlaying;

        if (_vpController!.value.hasError) {
          _state = VideoPlayerState.error;
          _errorMessage = _vpController!.value.errorDescription;
        } else if (_vpController!.value.isCompleted) {
          _state = VideoPlayerState.completed;
        } else if (_isPlaying) {
          _state = VideoPlayerState.playing;
        } else {
          _state = VideoPlayerState.paused;
        }
        notifyListeners();
      });

      _duration = _vpController!.value.duration;
      _state = VideoPlayerState.paused;
      notifyListeners();
    } catch (e) {
      _state = VideoPlayerState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  /// 播放
  Future<void> play() async {
    await _vpController?.play();
    _isPlaying = true;
    _state = VideoPlayerState.playing;
    notifyListeners();
  }
  
  /// 暂停
  Future<void> pause() async {
    await _vpController?.pause();
    _isPlaying = false;
    _state = VideoPlayerState.paused;
    notifyListeners();
  }
  
  /// 切换播放/暂停
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }
  
  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    await _vpController?.seekTo(position);
    _position = position;
    notifyListeners();
  }
  
  /// 跳转到百分比位置
  Future<void> seekToPercent(double percent) async {
    final position = Duration(
      milliseconds: (_duration.inMilliseconds * percent).toInt(),
    );
    await seekTo(position);
  }
  
  /// 切换全屏
  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  @override
  void dispose() {
    _vpController?.dispose();
    super.dispose();
  }
}

/// 视频播放器 Provider
final videoPlayerProvider = ChangeNotifierProvider.autoDispose.family<
    VideoPlayerController, 
    String
>((ref, videoUrl) {
  final controller = VideoPlayerController();
  controller.initialize(videoUrl);
  return controller;
});

/// 视频播放器组件
class ShunshiVideoPlayer extends ConsumerWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoPlay;
  final bool showControls;
  final bool showFullScreenButton;
  final Function()? onComplete;
  
  const ShunshiVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoPlay = false,
    this.showControls = true,
    this.showFullScreenButton = true,
    this.onComplete,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(videoPlayerProvider(videoUrl));
    
    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 视频内容区域
            if (controller.isInitialized && controller.vpController != null)
              vp.VideoPlayer(controller.vpController!)
            else if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            
            // Loading
            if (controller.state == VideoPlayerState.loading)
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            
            // 错误
            if (controller.state == VideoPlayerState.error)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Video load failed',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            
            // 控制栏
            if (showControls && 
                controller.state != VideoPlayerState.loading &&
                controller.state != VideoPlayerState.error)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoControls(controller: controller),
              ),
            
            // 播放按钮
            if ((controller.state == VideoPlayerState.idle || 
                 controller.state == VideoPlayerState.paused ||
                 controller.state == VideoPlayerState.completed) &&
                controller.state != VideoPlayerState.loading)
              GestureDetector(
                onTap: () => controller.play(),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 视频控制栏
class VideoControls extends ConsumerWidget {
  final VideoPlayerController controller;
  
  const VideoControls({super.key, required this.controller});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black54,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: controller.progress.clamp(0.0, 1.0),
              onChanged: (value) => controller.seekToPercent(value),
              activeColor: Colors.green,
              inactiveColor: Colors.white30,
            ),
          ),
          
          // 时间和按钮
          Row(
            children: [
              // 时间
              Text(
                '${_formatDuration(controller.position)} / ${_formatDuration(controller.duration)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              
              const Spacer(),
              
              // 播放/暂停
              IconButton(
                icon: Icon(
                  controller.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () => controller.togglePlayPause(),
              ),
              
              // 全屏
              IconButton(
                icon: Icon(
                  controller.isFullScreen 
                      ? Icons.fullscreen_exit 
                      : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: () => controller.toggleFullScreen(),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// 全屏视频播放器
class FullScreenVideoPlayer extends StatelessWidget {
  final String videoUrl;
  
  const FullScreenVideoPlayer({super.key, required this.videoUrl});
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.black,
      body: ShunshiVideoPlayer(
        videoUrl: videoUrl,
        showControls: true,
      ),
    );
  }
}

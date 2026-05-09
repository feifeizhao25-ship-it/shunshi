// 视频播放器组件
// TODO: 添加 video_player 依赖后启用完整功能
// flutter pub add video_player
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  
  /// 初始化视频
  Future<void> initialize(String videoUrl) async {
    _state = VideoPlayerState.loading;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // TODO: 替换为真正的视频初始化
      // _innerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      // await _innerController!.initialize();
      
      _duration = Duration.zero;
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
    _isPlaying = true;
    _state = VideoPlayerState.playing;
    notifyListeners();
  }
  
  /// 暂停
  Future<void> pause() async {
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
            if (controller.isInitialized)
              const Center(
                child: Text(
                  '视频播放 (需安装 video_player)',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            else if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            
            // 加载中
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
                    '视频加载失败',
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: ShunshiVideoPlayer(
        videoUrl: videoUrl,
        showControls: true,
      ),
    );
  }
}

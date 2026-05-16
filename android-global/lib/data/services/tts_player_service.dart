// TTS 播报服务 — 下载后端音频并播放
import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/config/app_config.dart';

class TtsPlayerService {
  static final TtsPlayerService _instance = TtsPlayerService._();
  factory TtsPlayerService() => _instance;
  TtsPlayerService._();

  static final String _baseUrl = AppConfig.baseUrl;
  // TTS 单次最大字符数（后端限制约 500-1000 字）
  static const _maxChars = 500;

  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String _currentText = '';
  StreamSubscription? _completionListener;

  bool get isPlaying => _isPlaying;
  String get currentText => _currentText;

  /// 播报文本（自动截断过长内容）
  Future<void> speak(String text) async {
    if (_isPlaying) await stop();
    if (text.isEmpty) return;

    // 截断到合理长度
    final truncated = text.length > _maxChars
        ? '${text.substring(0, _maxChars)}...'
        : text;

    _currentText = truncated;

    try {
      final response = await _dio.post(
        '/api/v1/speech/tts',
        data: {'text': truncated},
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data is List<int>) {
        final audioBytes = response.data as List<int>;

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await file.writeAsBytes(audioBytes);

        // 取消旧的监听器，防止重复
        await _completionListener?.cancel();
        _completionListener = _player.onPlayerComplete.listen((_) {
          _isPlaying = false;
          _currentText = '';
          try { file.delete(); } catch (_) {}
        });

        await _player.play(DeviceFileSource(file.path));
        _isPlaying = true;
      }
    } catch (e) {
      _isPlaying = false;
    }
  }

  /// 暂停
  Future<void> pause() async {
    await _player.pause();
  }

  /// 恢复
  Future<void> resume() async {
    await _player.resume();
    _isPlaying = true;
  }

  /// 停止
  Future<void> stop() async {
    await _completionListener?.cancel();
    _completionListener = null;
    await _player.stop();
    _isPlaying = false;
    _currentText = '';
  }

  /// 播放状态流
  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;
}

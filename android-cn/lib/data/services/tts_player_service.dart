import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../network/session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/config/app_config.dart';
import 'speech_text.dart';

/// Playback the chat page can toggle. Tests supply their own implementation.
abstract class SpeechPlayback extends ChangeNotifier {
  String? get activeKey;
  bool get isSpeaking;
  String get errorMsg;

  /// Starts speaking [text]. Returns false immediately when there is nothing
  /// to say. A later engine failure clears [isSpeaking] and sets [errorMsg].
  Future<bool> speak(String text, {String key = 'default'});

  Future<void> stop();
}

class SpeechToggle {
  SpeechToggle(this.playback);
  final SpeechPlayback playback;

  /// True when speech is now playing for [key].
  Future<bool> toggle(String key, String text) async {
    if (playback.isSpeaking && playback.activeKey == key) {
      await playback.stop();
      return false;
    }
    return playback.speak(text, key: key);
  }
}

/// On-device speech first (system voice / browser speechSynthesis), then the
/// existing `POST /api/v1/speech/tts` endpoint. No API key is embedded here.
class TtsPlayerService extends SpeechPlayback {
  static final TtsPlayerService _instance = TtsPlayerService._();
  factory TtsPlayerService() => _instance;

  TtsPlayerService._() : this.detached();

  TtsPlayerService.detached({
    Dio? dio,
    String? baseUrl,
    this.language = 'zh-CN',
    this.emptyMessage = '没有可以朗读的文字',
    this.failedMessage = '语音播报暂不可用，请稍后再试',
    this.noVoiceMessage = '这台设备没有中文朗读语音，暂时读不了。可以在系统设置里添加中文语音后再试。',
    bool? checkDeviceVoices,
    FlutterTts? tts,
    AudioPlayer? player,
  }) : _dio = dio ??
            withSessionAuth(Dio(BaseOptions(
              baseUrl: _root(baseUrl ?? AppConfig.apiBaseUrl),
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 60),
            ))),
        _checkDeviceVoices = checkDeviceVoices ?? kIsWeb,
        _injectedTts = tts,
        _player = player;

  static String _root(String url) => normalizeApiBaseUrl(url);

  final Dio _dio;
  final String language;
  final String emptyMessage;
  final String failedMessage;
  final String noVoiceMessage;

  /// 浏览器里没有中文语音时 speechSynthesis 不报错、也不出声（问题 50），
  /// 所以网页端先查一遍语音列表。手机端照旧：系统语言设置失败时走原来的服务器朗读。
  final bool _checkDeviceVoices;
  final FlutterTts? _injectedTts;
  AudioPlayer? _player;
  FlutterTts? _tts;

  @override
  String? activeKey;

  @override
  bool isSpeaking = false;

  @override
  String errorMsg = '';

  int _generation = 0;

  @override
  Future<bool> speak(String text, {String key = 'default'}) async {
    await stop();
    final spoken = speakablePlainText(text).trim();
    if (spoken.isEmpty) {
      errorMsg = emptyMessage;
      notifyListeners();
      return false;
    }
    errorMsg = '';
    activeKey = key;
    isSpeaking = true;
    notifyListeners();
    final generation = _generation;
    unawaited(_run(generation, spoken));
    return true;
  }

  Future<void> _run(int generation, String spoken) async {
    if (_checkDeviceVoices && await _hasChineseVoice() == false) {
      if (generation != _generation) return;
      // 只提示，不改走服务器朗读（那条路要不要在网页端开、费用怎么算，留给主人定）。
      isSpeaking = false;
      activeKey = null;
      errorMsg = noVoiceMessage;
      notifyListeners();
      return;
    }
    if (generation != _generation) return;
    var ok = await _speakDevice(generation, spoken);
    if (generation != _generation) return;
    if (!ok) ok = await _speakServer(generation, spoken);
    if (generation != _generation) return;
    isSpeaking = false;
    activeKey = null;
    if (!ok) errorMsg = failedMessage;
    notifyListeners();
  }

  Future<bool> _speakDevice(int generation, String spoken) async {
    try {
      final tts = _tts ??= _injectedTts ?? FlutterTts();
      await tts.awaitSpeakCompletion(true);
      final lang = await tts.setLanguage(language);
      if (lang == false || lang == 0) return false;
      await tts.setSpeechRate(0.45);
      await tts.setVolume(1.0);
      for (final chunk in speechChunks(spoken, maxChars: 320)) {
        if (generation != _generation) return false;
        final result = await tts.speak(chunk);
        if (result == 0 || result == false) return false;
      }
      return true;
    } catch (e) {
      debugPrint('[TtsPlayer] device voice failed: $e');
      return false;
    }
  }

  /// true：有中文语音；false：确定没有；null：查不到（照旧尝试朗读）。
  /// 浏览器的语音列表是异步加载的，空列表时稍等再查两次。
  Future<bool?> _hasChineseVoice() async {
    try {
      final tts = _tts ??= _injectedTts ?? FlutterTts();
      for (var attempt = 0; attempt < 3; attempt++) {
        final voices = await tts.getVoices;
        if (voices is! List) return null;
        if (voices.isNotEmpty) {
          return voices.any((v) {
            if (v is! Map) return false;
            final locale = (v['locale'] ?? v['lang'] ?? '').toString().toLowerCase();
            return locale.startsWith('zh') || locale.startsWith('cmn');
          });
        }
        if (attempt < 2) await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      return false;
    } catch (e) {
      debugPrint('[TtsPlayer] voice list unavailable: $e');
      return null;
    }
  }

  Future<bool> _speakServer(int generation, String spoken) async {
    final player = _player ??= AudioPlayer();
    try {
      for (final chunk in speechChunks(spoken, maxChars: 800)) {
        if (generation != _generation) return false;
        final response = await _dio.post(
          '/api/v1/speech/tts',
          data: {'text': chunk, 'response_format': 'mp3'},
          options: Options(responseType: ResponseType.bytes),
        );
        final data = response.data;
        if (response.statusCode != 200 || data is! List<int> || data.length < 32) {
          return false;
        }
        if (generation != _generation) return false;
        await player.setAudioSource(Mp3BytesSource(Uint8List.fromList(data)));
        await player.play();
        await player.playerStateStream.firstWhere((state) {
          return generation != _generation || state.processingState == ProcessingState.completed;
        });
        if (generation != _generation) return false;
      }
      return true;
    } catch (e) {
      debugPrint('[TtsPlayer] server voice failed: $e');
      return false;
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    try {
      await _tts?.stop();
    } catch (_) {}
    try {
      await _player?.stop();
    } catch (_) {}
    final was = isSpeaking || activeKey != null;
    isSpeaking = false;
    activeKey = null;
    if (was) notifyListeners();
  }
}

class Mp3BytesSource extends StreamAudioSource {
  Mp3BytesSource(this.bytes);
  final Uint8List bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}

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
    FlutterTts? tts,
    AudioPlayer? player,
  }) : _dio = dio ??
            withSessionAuth(Dio(BaseOptions(
              baseUrl: _root(baseUrl ?? AppConfig.apiBaseUrl),
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 60),
            ))),
        _injectedTts = tts,
        _player = player;

  static String _root(String url) => url.replaceAll(RegExp(r'/api/v1/?$'), '');

  final Dio _dio;
  final String language;
  final String emptyMessage;
  final String failedMessage;
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

// ignore_for_file: unused_field
// 语音输入服务 (国内版 - SiliconFlow ASR)
// 不依赖 Google 服务，兼容华为/小米等国产手机

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._();
  factory VoiceService() => _instance;
  VoiceService._();

  final _recorder = AudioRecorder();
  static final String _baseUrl = AppConfig.baseUrl;
  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'ngrok-skip-browser-warning': 'true'},
  ));

  bool _isListening = false;
  String _lastWords = '';
  String _errorMsg = '';
  String _recordPath = '';

  /// 是否正在录音
  bool get isListening => _isListening;

  /// 最近识别结果
  String get lastWords => _lastWords;

  /// 错误信息
  String get errorMsg => _errorMsg;

  /// 是否有录音权限
  Future<bool> _checkPermission() async {
    final has = await _recorder.hasPermission();
    if (!has) {
      _errorMsg = 'Please grant microphone permission';
    }
    return has;
  }

  /// 开始录音
  Future<bool> startRecording() async {
    try {
      if (await _recorder.isRecording()) return true;

      final dir = await getTemporaryDirectory();
      _recordPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.start(const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 16000,
        numChannels: 1,
      ), path: _recordPath);
      _isListening = true;
      _errorMsg = '';
      return true;
    } catch (e) {
      _errorMsg = 'Recording failed: $e';
      debugPrint('[VoiceService] startRecording error: $e');
      return false;
    }
  }

  /// 停止录音并识别
  /// 返回识别出的文字，失败返回 null
  Future<String?> stopAndRecognize() async {
    try {
      _isListening = false;
      if (!(await _recorder.isRecording())) return null;

      final path = await _recorder.stop();
      if (path == null || path.isEmpty) {
        _errorMsg = 'Recording save failed';
        return null;
      }

      final file = File(path);
      if (!await file.exists() || await file.length() < 500) {
        _errorMsg = 'Recording too short, press and hold to speak';
        return null;
      }

      return await _recognizeFile(file);
    } catch (e) {
      _errorMsg = 'Speech recognition failed: $e';
      debugPrint('[VoiceService] stopAndRecognize error: $e');
      return null;
    }
  }

  /// 用 SiliconFlow ASR 识别音频文件
  Future<String?> _recognizeFile(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: 'voice.aac'),
        'model': 'sensevoice',
      });

      final response = await Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'ngrok-skip-browser-warning': 'true'},
      )).post(
        '/api/v1/speech/asr',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final text = data['text'] as String? ?? '';
        if (text.isNotEmpty) {
          _lastWords = text;
          return text;
        }
        _errorMsg = 'No speech detected';
        return null;
      } else {
        _errorMsg = 'Recognition failed (${response.statusCode})';
        return null;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        _errorMsg = 'Network connection failed';
      } else {
        _errorMsg = 'Recognition service error';
      }
      debugPrint('[VoiceService] _recognizeFile error: ${e.message}');
      return null;
    } catch (e) {
      _errorMsg = 'Recognition failed: $e';
      debugPrint('[VoiceService] _recognizeFile error: $e');
      return null;
    } finally {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  /// 停止录音（不识别）
  Future<void> stopListening() async {
    _isListening = false;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  /// 取消录音
  Future<void> cancel() async {
    _isListening = false;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    try {
      if (_recordPath.isNotEmpty) {
        final f = File(_recordPath);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {}
  }

  /// 重置
  void reset() {
    _lastWords = '';
    _errorMsg = '';
  }

  /// 旧接口兼容
  @Deprecated('Use startRecording + stopAndRecognize')
  Future<bool> startListening({Function(String)? onResult}) async {
    final ok = await _checkPermission();
    if (!ok) return false;
    return await startRecording();
  }

  /// 总是可用（SiliconFlow ASR）
  bool get isAvailable => true;
}

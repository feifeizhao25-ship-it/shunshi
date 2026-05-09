// lib/data/services/voice_input_service.dart
// SEASONS Voice Input Service
// Handles speech-to-text for voice input feature

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Voice input state
enum VoiceInputState {
  idle,
  listening,
  processing,
  error,
}

/// Voice input result
class VoiceResult {
  final String text;
  final bool isFinal;
  final double confidence;

  VoiceResult({
    required this.text,
    required this.isFinal,
    this.confidence = 1.0,
  });
}

/// Voice input service for SEASONS app
class VoiceInputService extends ChangeNotifier {
  stt.SpeechToText? _speech;

  VoiceInputState _state = VoiceInputState.idle;
  String _lastWords = '';
  String _errorMessage = '';
  double _confidence = 1.0;

  bool _isAvailable = false;
  bool _isInitialized = false;

  // Getters
  VoiceInputState get state => _state;
  String get lastWords => _lastWords;
  String get errorMessage => _errorMessage;
  double get confidence => _confidence;
  bool get isAvailable => _isAvailable;
  bool get isListening => _state == VoiceInputState.listening;
  bool get isInitialized => _isInitialized;

  /// Initialize speech service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _speech = stt.SpeechToText();

      _isAvailable = await _speech!.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );

      _isInitialized = true;
      notifyListeners();

      return _isAvailable;
    } catch (e) {
      _errorMessage = 'Failed to initialize voice: $e';
      _state = VoiceInputState.error;
      notifyListeners();
      return false;
    }
  }

  /// Start listening
  Future<void> startListening({
    String localeId = 'en_US',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    if (!_isAvailable) {
      _errorMessage = 'Speech recognition not available';
      _state = VoiceInputState.error;
      notifyListeners();
      return;
    }

    _lastWords = '';
    _errorMessage = '';
    _state = VoiceInputState.listening;
    notifyListeners();

    try {
      await _speech!.listen(
        onResult: _onResult,
        listenFor: listenFor,
        pauseFor: pauseFor,
        localeId: localeId,
        cancelOnError: true,
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      _errorMessage = 'Failed to start listening: $e';
      _state = VoiceInputState.error;
      notifyListeners();
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_speech != null) {
      await _speech!.stop();
      _state = VoiceInputState.idle;
      notifyListeners();
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (_speech != null) {
      await _speech!.cancel();
      _lastWords = '';
      _state = VoiceInputState.idle;
      notifyListeners();
    }
  }

  /// Get available locales
  Future<List<stt.LocaleName>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    if (_speech != null) {
      return await _speech!.locales();
    }
    return [];
  }

  // Handlers
  void _onResult(dynamic result) {
    _lastWords = (result as dynamic).recognizedWords as String? ?? '';
    _confidence = (result as dynamic).confidence as double? ?? 0.0;

    if ((result as dynamic).finalResult as bool? ?? false) {
      _state = VoiceInputState.idle;
    }

    notifyListeners();
  }

  void _onError(dynamic error) {
    _errorMessage = error.toString();
    _state = VoiceInputState.error;
    notifyListeners();
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _state = VoiceInputState.idle;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _speech?.cancel();
    super.dispose();
  }
}

/// Voice button UI state helper
class VoiceButtonState {
  final bool isListening;
  final bool isProcessing;
  final String? transcript;
  final double? soundLevel;

  VoiceButtonState({
    this.isListening = false,
    this.isProcessing = false,
    this.transcript,
    this.soundLevel,
  });
}

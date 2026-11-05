import 'voice_contract.dart';
import 'web_speech.dart';

/// Flutter web voice input: the browser speech recognizer.
class VoiceService implements VoiceInput {
  static final VoiceService _instance = VoiceService._();
  factory VoiceService() => _instance;
  VoiceService._();

  final _session = WebSpeechSession(
    localeId: 'en_US',
    permissionMessage: 'Please allow microphone access',
    unavailableMessage: 'This browser cannot use speech recognition. Try Chrome, or type instead.',
    emptyMessage: 'No speech detected',
    missedMessage: "Didn't catch that. Please try again.",
  );

  bool _isListening = false;
  String _lastWords = '';

  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  @override
  String get errorMsg => _session.errorMsg;
  bool get isAvailable => true;

  @override
  Future<bool> startRecording() async {
    if (_isListening) return true;
    final ok = await _session.start();
    _isListening = ok;
    return ok;
  }

  @override
  Future<String?> stopAndRecognize() async {
    _isListening = false;
    final text = await _session.stop();
    if (text != null) _lastWords = text;
    return text;
  }

  @override
  Future<void> cancel() async {
    _isListening = false;
    await _session.cancel();
  }

  Future<void> stopListening() => cancel();

  void reset() {
    _lastWords = '';
  }

  Future<bool> startListening({Function(String)? onResult}) => startRecording();
}

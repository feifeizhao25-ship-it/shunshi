import 'voice_contract.dart';
import 'web_speech.dart';

/// Flutter web voice input: the browser speech recognizer, Chinese locale.
class VoiceService implements VoiceInput {
  static final VoiceService _instance = VoiceService._();
  factory VoiceService() => _instance;
  VoiceService._();

  final _session = WebSpeechSession(
    localeId: 'zh_CN',
    permissionMessage: '请授予麦克风权限',
    unavailableMessage: '当前浏览器不支持语音识别，请改用文字，或换用支持语音的浏览器。',
    emptyMessage: '未识别到语音内容',
    missedMessage: '没有听清，请再说一遍',
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

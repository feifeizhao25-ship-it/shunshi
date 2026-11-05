import 'package:speech_to_text/speech_to_text.dart';

/// Browser (and any platform) speech-to-text session.
/// Used for Flutter web, where the file recorder cannot upload audio.
class WebSpeechSession {
  WebSpeechSession({
    required this.localeId,
    required this.permissionMessage,
    required this.unavailableMessage,
    required this.emptyMessage,
    required this.missedMessage,
    SpeechToText? speech,
  }) : _speech = speech ?? SpeechToText();

  final String localeId;
  final String permissionMessage;
  final String unavailableMessage;
  final String emptyMessage;
  final String missedMessage;
  final SpeechToText _speech;

  String _transcript = '';
  String errorMsg = '';
  bool permissionDenied = false;

  Future<bool> start() async {
    _transcript = '';
    errorMsg = '';
    permissionDenied = false;
    try {
      final ready = await _speech.initialize(
        onError: (error) {
          final code = error.errorMsg.toLowerCase();
          if (code.contains('not-allowed') || code.contains('permission')) {
            permissionDenied = true;
            errorMsg = permissionMessage;
          } else if (errorMsg.isEmpty) {
            errorMsg = missedMessage;
          }
        },
      );
      if (!ready) {
        errorMsg = errorMsg.isEmpty ? unavailableMessage : errorMsg;
        return false;
      }
      await _speech.listen(
        onResult: (result) => _transcript = result.recognizedWords,
        localeId: localeId,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 4),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
      return true;
    } catch (_) {
      errorMsg = unavailableMessage;
      return false;
    }
  }

  Future<String?> stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
    final text = _transcript.trim();
    if (text.isEmpty) {
      if (errorMsg.isEmpty) errorMsg = emptyMessage;
      return null;
    }
    errorMsg = '';
    return text;
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {}
    _transcript = '';
  }
}

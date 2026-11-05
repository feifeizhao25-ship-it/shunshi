/// Shared voice-input surface for the handset recorder and the browser session.
abstract class VoiceInput {
  String get errorMsg;
  Future<bool> startRecording();
  Future<String?> stopAndRecognize();
  Future<void> cancel();
}

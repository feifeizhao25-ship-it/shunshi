import 'dart:io';

Future<bool> voiceFileUsable(String path) async {
  final file = File(path);
  return await file.exists() && await file.length() >= 500;
}

Future<void> deleteVoiceFile(String path) async {
  final file = File(path);
  if (path.isEmpty || !await file.exists()) return;
  await file.delete();
}

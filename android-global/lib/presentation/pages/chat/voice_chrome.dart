import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Phone: a thumb-sized mic and a small speaker on the reply.
/// Web: read the note like a letter ("Read this"), and dictate from a labeled
/// control under the writing field. The two surfaces are not the same layout.
enum VoiceChrome { handset, browser }

VoiceChrome resolveVoiceChrome(VoiceChrome? override) =>
    override ?? (kIsWeb ? VoiceChrome.browser : VoiceChrome.handset);

class ReplySpeaker extends StatelessWidget {
  const ReplySpeaker({
    super.key,
    required this.chrome,
    required this.speaking,
    required this.onPressed,
    this.readTip = 'Read aloud',
    this.stopTip = 'Stop reading',
    this.unavailableTip = 'Voice playback is not connected',
    this.readLabel = 'Read this',
    this.stopLabel = 'Stop',
  });

  final VoiceChrome chrome;
  final bool speaking;
  final VoidCallback? onPressed;
  final String readTip;
  final String stopTip;
  final String unavailableTip;
  final String readLabel;
  final String stopLabel;

  @override
  Widget build(BuildContext context) {
    if (chrome == VoiceChrome.browser) {
      return TextButton.icon(
        key: const ValueKey('reply-speaker'),
        onPressed: onPressed,
        icon: Icon(speaking ? Icons.stop_rounded : Icons.menu_book_outlined, size: 18),
        label: Text(speaking ? stopLabel : readLabel),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      );
    }
    final tip = onPressed == null ? unavailableTip : (speaking ? stopTip : readTip);
    return IconButton(
      key: const ValueKey('reply-speaker'),
      tooltip: tip,
      onPressed: onPressed,
      icon: Icon(speaking ? Icons.stop_circle : Icons.volume_up, size: 18),
    );
  }
}

class BrowserCompose extends StatelessWidget {
  const BrowserCompose({
    super.key,
    required this.field,
    required this.recording,
    required this.onMic,
    required this.onSend,
    required this.accent,
    required this.ink,
    required this.muted,
    required this.line,
    this.micLabel = 'Speak',
    this.stopLabel = 'Stop and transcribe',
    this.sendLabel = 'Send',
    this.listeningHint = 'Listening. Tap again and the words stay in the box.',
  });

  final Widget field;
  final bool recording;
  final VoidCallback onMic;
  final VoidCallback onSend;
  final Color accent;
  final Color ink;
  final Color muted;
  final Color line;
  final String micLabel;
  final String stopLabel;
  final String sendLabel;
  final String listeningHint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field,
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                key: const ValueKey('voice-input'),
                onPressed: onMic,
                icon: Icon(recording ? Icons.stop_rounded : Icons.mic_none_rounded, size: 18),
                label: Text(recording ? stopLabel : micLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: recording ? const Color(0xFFB85450) : ink,
                  side: BorderSide(color: recording ? const Color(0xFFB85450) : line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onSend,
                icon: const Icon(Icons.send_outlined, size: 16),
                label: Text(sendLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          if (recording) ...[
            const SizedBox(height: 8),
            Text(listeningHint, style: TextStyle(fontSize: 12, height: 1.4, color: muted)),
          ],
        ],
      ),
    );
  }
}

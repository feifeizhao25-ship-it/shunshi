import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Phone is a one-hand companion: round controls, words only while listening.
/// Web is where someone reads the season's note: the reply offers "read this"
/// in words, and speech sits under the writing field instead of beside it.
enum VoiceChrome { handset, browser }

VoiceChrome resolveVoiceChrome(VoiceChrome? override) =>
    override ?? (kIsWeb ? VoiceChrome.browser : VoiceChrome.handset);

class ReplySpeaker extends StatelessWidget {
  const ReplySpeaker({
    super.key,
    required this.chrome,
    required this.speaking,
    required this.onPressed,
    this.readTip = '朗读回复',
    this.stopTip = '停止朗读',
    this.unavailableTip = '语音播报尚未接通',
    this.readLabel = '朗读这段',
    this.stopLabel = '停止',
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
      final enabled = onPressed != null;
      return TextButton.icon(
        key: const ValueKey('reply-speaker'),
        onPressed: onPressed,
        icon: Icon(speaking ? Icons.stop_rounded : Icons.menu_book_outlined, size: 18),
        label: Text(speaking ? stopLabel : readLabel),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          foregroundColor: enabled ? null : Theme.of(context).disabledColor,
        ),
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

/// Web compose: a writing field, then a labeled voice action. Not the phone's
/// thumb row of round buttons.
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
    this.micLabel = '用语音说',
    this.stopLabel = '停止并转写',
    this.sendLabel = '写下发送',
    this.listeningHint = '正在听。说完后再点一次，文字会留在上面的格子里。',
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
                icon: const Icon(Icons.edit_outlined, size: 16),
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

import 'package:flutter/material.dart';

import '../../../../data/services/speech_text.dart';
import '../../../../data/services/tts_player_service.dart';
import '../../../../data/services/voice_service.dart';
import '../../chat/voice_chrome.dart';

const kTodayVoiceReadLabel = '朗读今日';
const kTodayVoiceStopLabel = '停止';
const kTodayVoiceMicLabel = '用语音说';
const kTodayVoiceStopMicLabel = '停止并转写';
const kTodayVoiceListeningHint = '正在听。说完后再点一次，文字会留在这里。';
const kTodayVoiceEmptyHint = '没有识别到语音。可以再试一次，或改用文字。';

const kTodayVoiceStaticCopy = <String>[
  kTodayVoiceReadLabel,
  kTodayVoiceStopLabel,
  kTodayVoiceMicLabel,
  kTodayVoiceStopMicLabel,
  kTodayVoiceListeningHint,
  kTodayVoiceEmptyHint,
];

/// Voice input and a tap-to-speak control for Today.
///
/// Web uses the labeled browser chrome from chat. The phone uses a tooltip
/// on the same actions. Speech goes through [SpeechPlayback] (markdown is
/// stripped). The microphone is [VoiceInput]; tests pass a fake and do not
/// claim the browser captured audio.
class TodayVoiceBar extends StatefulWidget {
  const TodayVoiceBar({
    super.key,
    required this.spokenText,
    this.voiceInput,
    this.playback,
    this.chrome,
    this.onTranscript,
    this.readLabel = kTodayVoiceReadLabel,
    this.stopLabel = kTodayVoiceStopLabel,
    this.micLabel = kTodayVoiceMicLabel,
    this.stopMicLabel = kTodayVoiceStopMicLabel,
    this.listeningHint = kTodayVoiceListeningHint,
    this.emptyHint = kTodayVoiceEmptyHint,
  });

  final String spokenText;
  final VoiceInput? voiceInput;
  final SpeechPlayback? playback;
  final VoiceChrome? chrome;
  final ValueChanged<String>? onTranscript;
  final String readLabel;
  final String stopLabel;
  final String micLabel;
  final String stopMicLabel;
  final String listeningHint;
  final String emptyHint;

  @override
  State<TodayVoiceBar> createState() => _TodayVoiceBarState();
}

class _TodayVoiceBarState extends State<TodayVoiceBar> {
  VoiceInput? _voice;
  SpeechPlayback? _playback;
  bool _recording = false;
  bool _busy = false;
  String? _note;

  VoiceChrome get _chrome => resolveVoiceChrome(widget.chrome);

  @override
  void initState() {
    super.initState();
    final playback = widget.playback;
    if (playback != null) {
      _playback = playback;
      playback.addListener(_onPlayback);
    }
  }

  @override
  void dispose() {
    _playback?.removeListener(_onPlayback);
    if (_playback?.activeKey == 'today') _playback?.stop();
    _voice?.cancel().catchError((Object _) {});
    super.dispose();
  }

  void _onPlayback() {
    if (mounted) setState(() {});
  }

  SpeechPlayback _ensurePlayback() {
    final current = _playback;
    if (current != null) return current;
    final created = widget.playback ?? TtsPlayerService();
    created.addListener(_onPlayback);
    _playback = created;
    return created;
  }

  Future<void> _onSpeak() async {
    final spoken = speakablePlainText(widget.spokenText);
    await SpeechToggle(_ensurePlayback()).toggle('today', spoken);
    if (mounted) setState(() {});
  }

  Future<void> _onMic() async {
    if (_busy) return;
    final voice = _voice ??= widget.voiceInput ?? VoiceService();
    setState(() => _busy = true);
    try {
      if (_recording) {
        final text = (await voice.stopAndRecognize())?.trim();
        if (!mounted) return;
        setState(() {
          _recording = false;
          if (text == null || text.isEmpty) {
            _note = voice.errorMsg.isEmpty ? widget.emptyHint : voice.errorMsg;
          } else {
            _note = text;
          }
        });
        if (text != null && text.isNotEmpty) widget.onTranscript?.call(text);
        return;
      }
      final started = await voice.startRecording();
      if (!mounted) return;
      setState(() {
        _recording = started;
        _note = started ? null : (voice.errorMsg.isEmpty ? widget.emptyHint : voice.errorMsg);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recording = false;
        _note = voice.errorMsg.isEmpty ? widget.emptyHint : voice.errorMsg;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final speaking = (_playback?.isSpeaking ?? false) && _playback?.activeKey == 'today';
    final micLabel = _recording ? widget.stopMicLabel : widget.micLabel;
    final readLabel = speaking ? widget.stopLabel : widget.readLabel;
    final ink = Theme.of(context).colorScheme.onSurface;
    final line = Theme.of(context).dividerColor;

    final Widget speaker;
    final Widget mic;
    if (_chrome == VoiceChrome.browser) {
      speaker = TextButton.icon(
        key: const ValueKey('today-speaker'),
        onPressed: _onSpeak,
        icon: Icon(speaking ? Icons.stop_rounded : Icons.volume_up_outlined, size: 18),
        label: Text(readLabel),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: ink),
      );
      mic = OutlinedButton.icon(
        key: const ValueKey('today-voice-input'),
        onPressed: _busy ? null : _onMic,
        icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_none_rounded, size: 18),
        label: Text(micLabel),
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          foregroundColor: _recording ? const Color(0xFFB85450) : ink,
          side: BorderSide(color: _recording ? const Color(0xFFB85450) : line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    } else {
      speaker = IconButton(
        key: const ValueKey('today-speaker'),
        tooltip: readLabel,
        onPressed: _onSpeak,
        icon: Icon(speaking ? Icons.stop_circle : Icons.volume_up),
      );
      mic = IconButton(
        key: const ValueKey('today-voice-input'),
        tooltip: micLabel,
        onPressed: _busy ? null : _onMic,
        icon: Icon(_recording ? Icons.stop : Icons.mic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [speaker, mic]),
        if (_recording)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(widget.listeningHint, style: TextStyle(fontSize: 12, height: 1.4, color: Theme.of(context).hintColor)),
          ),
        if (!_recording && _note != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_note!, key: const ValueKey('today-voice-note'), style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
      ],
    );
  }
}

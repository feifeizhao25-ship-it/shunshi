import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seasons/data/services/voice_service.dart';

/// Voice input button widget for SEASONS
/// Now integrated with real speech_to_text
class VoiceInputButton extends StatefulWidget {
  final Function(String text) onResult;
  final bool isListening;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.isListening = false,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  bool _isListening = false;
  bool _initialized = false;
  final VoiceService _voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _initVoice();
    _isListening = widget.isListening;
  }

  Future<void> _initVoice() async {
    final ok = await _voiceService.initialize();
    if (mounted) {
      setState(() => _initialized = ok);
    }
  }

  Future<void> _toggleListening() async {
    HapticFeedback.lightImpact();

    if (_isListening) {
      await _voiceService.stopListening();
      if (_voiceService.lastWords.isNotEmpty) {
        widget.onResult(_voiceService.lastWords);
      }
      setState(() => _isListening = false);
    } else {
      final ok = await _voiceService.startListening(
        onResult: (text) {
          widget.onResult(text);
        },
      );
      if (ok) {
        setState(() => _isListening = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: Icon(
        _isListening ? Icons.mic : Icons.mic_none,
        color: _isListening
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onPressed: _toggleListening,
      tooltip: _isListening ? 'Stop listening' : 'Start voice input',
    );
  }

  @override
  void dispose() {
    if (_isListening) {
      _voiceService.stopListening();
    }
    super.dispose();
  }
}

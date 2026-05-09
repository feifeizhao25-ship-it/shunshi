import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/ai_safety.dart';
import '../../widgets/feedback_sheet.dart';
import '../../../design_system/theme.dart';

const String _systemPrompt =
    'You are SEASONS, a calm and thoughtful AI companion focused on seasonal '
    'living, gentle rituals, and emotional well-being.';

enum _Confidence { high, medium, low }

class SeasonsChatPage extends StatefulWidget {
  const SeasonsChatPage({super.key});
  @override
  State<SeasonsChatPage> createState() => _SeasonsChatPageState();
}

class _SeasonsChatPageState extends State<SeasonsChatPage>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  late AnimationController _dotController;

  static const int _maxInputLength = 500;
  static const int _maxHistory = 50;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _initChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _dotController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadHistory(prefs);
    if (_messages.isEmpty) {
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          text: 'Welcome to SEASONS. How are you feeling today?',
        ));
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = _messages.length > _maxHistory
        ? _messages.sublist(_messages.length - _maxHistory)
        : _messages;
    final jsonList = trimmed.map((m) => {
      'role': m.role,
      'text': m.text,
      if (m.structured != null) 'structured': m.structured,
    }).toList();
    await prefs.setString('seasons_chat_history', jsonEncode(jsonList));
  }

  Future<void> _loadHistory(SharedPreferences prefs) async {
    final raw = prefs.getString('seasons_chat_history');
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      for (final item in list) {
        _messages.add(_ChatMessage(
          role: item['role'] as String,
          text: item['text'] as String,
          structured: item['structured'] as Map<String, dynamic>?,
        ));
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Map<String, dynamic>? _tryParseStructured(String text) {
    final patterns = [
      RegExp(r'\{[^{}]*"insight"[^{}]*\}', dotAll: true),
      RegExp(r'```json\s*(\{[^}]+\})\s*```', dotAll: true),
      RegExp(r'```\s*(\{[^}]+\})\s*```', dotAll: true),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        try {
          return jsonDecode(m.group(1) ?? '{}') as Map<String, dynamic>;
        } catch (_) {}
      }
    }
    return null;
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    if (text.length > _maxInputLength) return;
    _controller.clear();

    if (AISafetyService.isPromptInjection(text)) {
      setState(() {
        _messages.add(_ChatMessage(role: 'user', text: text));
        _messages.add(_ChatMessage(
          role: 'assistant',
          text: 'Unusual input detected. Please rephrase your question.',
        ));
      });
      _saveHistory();
      _scrollToBottom();
      return;
    }

    final riskLevel = AISafetyService.assessRisk(text);
    if (riskLevel == RiskLevel.crisis || riskLevel == RiskLevel.high) {
      final crisisResponse =
          AISafetyService.getCrisisResponse(riskLevel, isEnglish: true);
      setState(() {
        _messages.add(_ChatMessage(role: 'user', text: text));
        _messages.add(_ChatMessage(
          role: 'assistant',
          text: crisisResponse,
          isCrisis: true,
        ));
      });
      _saveHistory();
      _scrollToBottom();
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: text));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'http://116.62.32.43:4000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ));
      final response = await dio.post('/ai/chat', data: {'message': text});

      final structured =
          response.data?['structured_output'] as Map<String, dynamic>?;
      final reply = response.data?['reply'] ?? '';
      var aiText = structured?['insight'] ?? reply;
      if (aiText.isEmpty) aiText = "I'm here. Take your time.";

      final disclaimer = structured?['disclaimer'] ?? '';
      if (disclaimer.isNotEmpty) {
        aiText = '$aiText\n\n$disclaimer';
      }

      final parsed = _tryParseStructured(aiText);
      final mergedStructured = structured ?? parsed;

      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          text: aiText,
          structured: mergedStructured,
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          text: "I'm having trouble connecting right now. Please try again in a moment.",
        ));
        _isLoading = false;
      });
    }
    _saveHistory();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFFDF9F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(child: _buildMessageList()),
            _buildDisclaimer(),
            _buildInputBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'SEASONS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : ShunShiColors.textPrimary,
                letterSpacing: 2,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1E1E2E) : ShunShiColors.surface,
                border: Border.all(
                  color: isDark ? const Color(0xFF2E2E3E) : ShunShiColors.border,
                ),
              ),
              child: Icon(
                Icons.close,
                size: 18,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : ShunShiColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildTypingIndicator();
        }
        if (index >= _messages.length) return const SizedBox.shrink();
        final msg = _messages[index];
        return msg.role == 'user'
            ? _buildUserBubble(msg)
            : _buildAssistantBubble(msg);
      },
    );
  }

  Widget _buildUserBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF533AFD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(_ChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final msgIndex = _messages.indexOf(msg);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5EBE0),
            ),
            child: const Center(
              child: Text('🌿', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: 1.0,
                  child: msg.isCrisis
                      ? _buildCrisisBubble(msg, isDark)
                      : (msg.structured != null
                          ? _buildStructuredBubble(msg, isDark)
                          : _buildPlainBubble(msg, isDark)),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => FeedbackSheet.show(
                      context, contentId: 'chat-$msgIndex', type: 'chat'),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thumb_up_outlined,
                          size: 14,
                          color: ShunShiColors.textTertiary.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.thumb_down_outlined,
                          size: 14,
                          color: ShunShiColors.textTertiary.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlainBubble(_ChatMessage msg, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5EBE0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        msg.text,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : ShunShiColors.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildCrisisBubble(_ChatMessage msg, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1A1A) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF5A2A2A) : const Color(0xFFFFCCCC),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_border,
                size: 18,
                color: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F),
              ),
              const SizedBox(width: 8),
              Text(
                'We care about you',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            msg.text,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : ShunShiColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredBubble(_ChatMessage msg, bool isDark) {
    final s = msg.structured!;

    final insight = s['insight'] as String? ?? '';
    final actionTitle = s['action_title'] as String? ??
        (s['actionCard'] as Map<String, dynamic>?)?['title'] as String? ?? '';
    final actionDuration = s['duration'] as String? ??
        (s['actionCard'] as Map<String, dynamic>?)?['duration'] as String? ?? '';
    final steps = (s['steps'] as List<dynamic>?) ??
        (s['stepList'] as List<dynamic>?) ?? [];
    final confStr = (s['confidence'] as String? ?? 'MEDIUM').toUpperCase();
    final confidence = confStr == 'HIGH'
        ? _Confidence.high
        : confStr == 'LOW'
            ? _Confidence.low
            : _Confidence.medium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Insight Block
        if (insight.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFFFE8CC),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: isDark ? const Color(0xFFFFD166) : const Color(0xFFE07A00),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Why this matters',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFFFD166) : const Color(0xFFE07A00),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : ShunShiColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 2. Action Card
        if (actionTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E3A) : const Color(0xFFF0EDFF),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF533AFD).withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                border: Border.all(
                  color: isDark ? const Color(0xFF2E2E4E) : const Color(0xFFD4CBFF),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: isDark ? const Color(0xFF533AFD) : const Color(0xFF533AFD),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          actionTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : ShunShiColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (actionDuration.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: 24),
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: ShunShiColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          actionDuration,
                          style: TextStyle(
                            fontSize: 12,
                            color: ShunShiColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

        // 3. Step List
        if (steps.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5EBE0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_list_numbered,
                        size: 16,
                        color: isDark ? const Color(0xFF533AFD) : const Color(0xFF533AFD),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'How to do it',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF533AFD) : const Color(0xFF533AFD),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...steps.asMap().entries.map<Widget>((entry) {
                    final idx = entry.key;
                    final step = entry.value.toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF2E2E4E)
                                  : const Color(0xFFEDE8FF),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF533AFD)
                                      : const Color(0xFF533AFD),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              step,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : ShunShiColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],

        // 4. Confidence Badge
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _buildConfidenceBadge(confidence, isDark),
        ),
      ],
    );
  }

  Widget _buildConfidenceBadge(_Confidence confidence, bool isDark) {
    final (label, bgColor, textColor) = switch (confidence) {
      _Confidence.high => (
          'HIGH',
          isDark ? const Color(0xFF1A3A2A) : const Color(0xFFE8F5E9),
          isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32),
        ),
      _Confidence.low => (
          'LOW',
          isDark ? const Color(0xFF3A2A1A) : const Color(0xFFFFF3E0),
          isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00),
        ),
      _Confidence.medium => (
          'MEDIUM',
          isDark ? const Color(0xFF2A2A3A) : const Color(0xFFEDE7F6),
          isDark ? const Color(0xFF9575CD) : const Color(0xFF5E35B1),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5EBE0),
            ),
            child: const Center(
              child: Text('🌿', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5EBE0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _dotController,
                  builder: (context, child) {
                    final progress =
                        (_dotController.value * 3 - i).clamp(0.0, 1.0);
                    final scale =
                        0.5 + 0.5 * (1 - (2 * progress - 1).abs());
                    return Padding(
                      padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : ShunShiColors.textTertiary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Text(
        'SEASONS uses AI. This is not therapy or medical advice.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: ShunShiColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFFDF9F4),
        border: Border(
          top: BorderSide(color: ShunShiColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 100),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLength: _maxInputLength,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: "Share what's on your mind...",
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: ShunShiColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: ShunShiColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isLoading
                    ? ShunShiColors.textDisabled
                    : const Color(0xFF533AFD),
              ),
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String text;
  final bool isCrisis;
  final Map<String, dynamic>? structured;

  const _ChatMessage({
    required this.role,
    required this.text,
    this.isCrisis = false,
    this.structured,
  });
}

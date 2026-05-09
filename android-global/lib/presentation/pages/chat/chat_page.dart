import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../widgets/membership_widgets.dart';

const _baseUrl = 'http://116.62.32.43:4000';

/// Chat Page — AI Wellness Assistant
/// Stripe-inspired messaging with purple accent
class ChatPage extends StatefulWidget {
  final String? conversationId;
  const ChatPage({super.key, this.conversationId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  static const _blockedKeywords = [
    '自杀', '自残', '死亡', '想死', '不想活', '抑郁症', 'depression', 'suicide', 'kill', 'self-harm', 'die', 'end my life',
    '手术', '开刀', '癌症', '肿瘤', 'cancer', 'tumor', 'surgery',
    '怀孕', '流产', '堕胎', 'pregnancy', 'abortion', 'miscarriage',
    '过敏休克', '呼吸困难', '胸痛', '昏迷', 'anaphylaxis', 'breathing difficulty', 'chest pain', 'unconscious',
  ];

  static const _riskKeywords = [
    '发烧', '咳嗽', '头痛', '腹痛', '腹泻', '呕吐', '皮疹', '出血', 'fever', 'cough', 'headache', 'stomach pain', 'diarrhea', 'vomiting', 'rash', 'bleeding',
    '高血压', '糖尿病', '心脏病', '肝病', '肾病', 'hypertension', 'diabetes', 'heart disease', 'liver disease', 'kidney disease',
    '吃药', '用药', '停药', '药物', 'medication', 'prescription', 'drug',
  ];

  bool _containsBlocked(String text) => _blockedKeywords.any((k) => text.contains(k));
  bool _containsRisk(String text) => _riskKeywords.any((k) => text.contains(k));

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  final _dio = Dio(BaseOptions(baseUrl: _baseUrl));
  bool _isLoading = false;
  int _quotaRemaining = 10;
  int _quotaLimit = 10;
  bool _isVip = false;
  String _userName = '';
  String _token = '';
  final String _currentSolarTerm = 'Qingming';
  final String _solarTermDesc = 'Spring deepens, all things clean and bright. A time for outdoor activities and expansive moods.';
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _initChat();
  }

  Future<void> _initChat() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('auth_token') ?? '';
      _userName = prefs.getString('user_name') ?? 'Friend';
    });
    if (_token.isEmpty) {
      try {
        final res = await _dio.post('/api/v1/intl/auth/guest-login', data: {
          'device_id': 'shunshi_${DateTime.now().millisecondsSinceEpoch}',
        });
        if (res.data != null && res.data['data']?['token'] != null) {
          _token = res.data['data']['token'];
          await prefs.setString('auth_token', _token);
        }
      } catch (_) {}
    }
    await _loadConversation(prefs);
    if (_messages.isEmpty) {
      setState(() {
        _messages.add(_ChatMessage(
          role: 'ai',
          text: 'The ${_currentSolarTerm}n season is here, and the energy of the earth is shifting. How have you been feeling lately?',
          cards: [_SuggestionCard(type: 'greeting', title: 'Current: $_currentSolarTerm', subtitle: _solarTermDesc)],
          time: _fmt(DateTime.now()),
        ));
      });
    }
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    try {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      final res = await _dio.get('/api/v1/subscription/status');
      if (res.data != null && res.data['data'] != null) {
        final data = res.data['data'];
        setState(() {
          _quotaLimit = data['limit'] ?? 10;
          _quotaRemaining = data['remaining'] ?? (data['limit'] ?? 10);
          _isVip = data['tier'] != 'free';
        });
      }
    } catch (_) {}
  }

  Future<void> _saveConversation() async {
    final prefs = await SharedPreferences.getInstance();
    final msgs = _messages.map((m) => '${m.role}|${m.text}').join('\n');
    await prefs.setString('chat_history', msgs);
    await prefs.setString('conversation_id', _conversationId ?? '');
  }

  Future<void> _loadConversation(SharedPreferences prefs) async {
    final saved = prefs.getString('chat_history');
    _conversationId = prefs.getString('conversation_id') ?? widget.conversationId;
    if (saved != null && saved.isNotEmpty) {
      final lines = saved.split('\n');
      final recent = lines.length > 10 ? lines.sublist(lines.length - 10) : lines;
      for (final line in recent) {
        final sepIdx = line.indexOf('|');
        if (sepIdx > 0) {
          _messages.add(_ChatMessage(
            role: line.substring(0, sepIdx),
            text: line.substring(sepIdx + 1),
            time: _fmt(DateTime.now()),
          ));
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    if (!_isVip && _quotaRemaining <= 0) {
      _showUpgradePrompt();
      return;
    }
    _controller.clear();

    if (_containsBlocked(text)) {
      setState(() {
        _messages.add(_ChatMessage(role: 'user', text: text, time: _fmt(DateTime.now())));
      });
      _showSafetyDialog();
      _saveConversation();
      _scrollToBottom();
      return;
    }

    final hasRisk = _containsRisk(text);

    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: text, time: _fmt(DateTime.now())));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      final res = await _dio.post('/ai/chat', data: {
        'message': text,
        'solar_term': _currentSolarTerm,
        'conversation_id': _conversationId,
      });
      // Use structured_output if available (Rule #4: ALWAYS structured)
      final structured = res.data?['structured_output'] as Map<String, dynamic>?;
      final reply = res.data?['reply'] ?? res.data?['text'] ?? '';
      var aiText = structured?['insight'] ?? reply;
      if (aiText.isEmpty) aiText = 'I\'m here. Take your time.';

      List<_SuggestionCard> cards = [];
      // Build cards from structured actions
      if (structured?['actions'] != null) {
        for (var a in structured!['actions']) {
          cards.add(_SuggestionCard(
            type: 'tip',
            title: a['title'] ?? '',
            subtitle: '${a['description'] ?? ''} (${a['duration_min'] ?? 3} min)',
            icon: Icons.arrow_forward_rounded,
          ));
        }
      } else if (res.data?['suggestions'] != null) {
        for (var s in res.data['suggestions']) {
          cards.add(_SuggestionCard(type: s['type'] ?? 'tip', title: s['title'] ?? '', subtitle: s['content'] ?? '', icon: _iconFor(s['type'])));
        }
      }
      if (cards.isEmpty) {
        cards = [_SuggestionCard(type: 'insight', title: AppLocalizations.of(context).t('chat_seasonal_guidance'), subtitle: AppLocalizations.of(context).t('chat_a_gentle_moment_with_nature'))];
      }

      if (hasRisk) {
        aiText = '⚠️ This is general wellness information, not medical advice. Please consult a healthcare professional.\n\n$aiText';
      }
      // Confidence badge
      final conf = structured?['confidence'] ?? '';
      if (conf.isNotEmpty) aiText = '$aiText\n\nConfidence: $conf';
      final disclaimer = structured?['disclaimer'] ?? 'Based on seasonal wellness principles, for reference only.';
      aiText = '$aiText\n\n💡 $disclaimer';

      final sources = (res.data?['sources'] as List?)?.cast<String>() ?? [];
      if (structured?['source'] != null) sources.add(structured!['source'].toString());

      if (res.data?['conversation_id'] != null) {
        _conversationId = res.data['conversation_id'];
      }

      setState(() {
        _messages.add(_ChatMessage(role: 'ai', text: aiText, cards: cards, sources: sources, time: _fmt(DateTime.now())));
        _isLoading = false;
        if (!_isVip) _quotaRemaining--;
      });
      _saveConversation();
    } catch (_) {
      var offlineText = _offlineReply(text);
      if (hasRisk) {
        offlineText = '⚠️ For reference only. Please consult a doctor if you feel unwell.\n\n$offlineText';
      }
      offlineText = '$offlineText\n\n💡 Based on traditional Chinese wellness principles, for reference only';

      setState(() {
        _messages.add(_ChatMessage(
          role: 'ai',
          text: offlineText,
          cards: [
            _SuggestionCard(type: 'diet', title: AppLocalizations.of(context).t('chat_dietary_care'), subtitle: AppLocalizations.of(context).t('chat_nourish_with_tremella_and_lily'), icon: Icons.restaurant),
            _SuggestionCard(type: 'rest', title: AppLocalizations.of(context).t('chat_rest_suggestions'), subtitle: 'Sleep early, wake early, follow nature\'s rhythm', icon: Icons.bedtime),
          ],
          sources: const ['Huangdi Neijing · Suwen', 'Compendium of Materia Medica'],
          time: _fmt(DateTime.now()),
        ));
        _isLoading = false;
        if (!_isVip) _quotaRemaining--;
      });
      _saveConversation();
    }
    _scrollToBottom();
  }

  void _showUpgradePrompt() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: ShunShiRadius.bottomSheetRadius),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: ShunShiColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.star_rounded, size: 32, color: ShunShiColors.primary)),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context).get('chat_quota_used'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
        const SizedBox(height: 8),
        Text('Upgrade for $_quotaLimit AI wellness messages daily\nUnlock all assessments + family features', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: ShunShiColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.buttonRadius)), onPressed: () { Navigator.pop(context); context.push('/subscription'); }, child: Text(AppLocalizations.of(context).get('chat_upgrade_now'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)))),
        const SizedBox(height: 10),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).get('chat_later'), style: TextStyle(color: ShunShiColors.textTertiary))),
        const SizedBox(height: 8),
      ]),
    ));
  }

  void _showSafetyDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: ShunShiColors.surface,
      shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.cardRadius),
      title: Row(children: [
        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).get('chat_health_notice'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
      ]),
      content: const Text(
        'The content you mentioned involves health safety risks. Please contact a professional medical facility immediately:\n\n'
        '• 24/7 Mental Health Hotline: 400-161-9995\n'
        '• Emergency: 120\n\n'
        'SEASONS AI cannot replace professional medical diagnosis.',
        style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).get('chat_understand'), style: TextStyle(color: ShunShiColors.primary, fontWeight: FontWeight.w600)))],
    ));
  }

  String _offlineReply(String msg) {
    if (msg.contains('sleep') || msg.contains('insomnia') || msg.contains('tired')) return 'Sleep issues often relate to an unsettled mind. During $_currentSolarTerm, try soaking your feet in warm water for 15 minutes before bed, put down your phone, and let your mind quiet down.';
    if (msg.contains('fatigue') || msg.contains('exhausted') || msg.contains('worn out')) return 'Feeling tired during seasonal transitions is normal. Consider reducing workload and eating warming, nourishing foods. A cup of ginger-date tea in the morning can help restore vitality.';
    return 'I hear you. During $_currentSolarTerm, the energy between heaven and earth is shifting. Would you like to talk about what specifically concerns you?';
  }

  IconData _iconFor(String? t) {
    switch (t) {
      case 'diet': case 'food': return Icons.restaurant;
      case 'rest': case 'sleep': return Icons.bedtime;
      case 'exercise': return Icons.self_improvement;
      case 'emotion': return Icons.favorite;
      case 'acupoint': return Icons.accessibility_new;
      default: return Icons.auto_awesome;
    }
  }

  String _fmt(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
      body: SafeArea(child: Column(children: [_buildTopBar(), Expanded(child: _buildList()), _buildInput()])),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(color: ShunShiColors.background, border: Border(bottom: BorderSide(color: ShunShiColors.border, width: 0.5))),
      child: Column(
        children: [
          if (!_isVip)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TokenBalanceBar(
                remaining: _quotaRemaining,
                limit: _quotaLimit,
                isVip: _isVip,
                onTapUpgrade: _showUpgradePrompt,
              ),
            ),
          Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: ShunShiColors.primary, shape: BoxShape.circle, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('🌿', style: TextStyle(fontSize: 16)))),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SEASONS AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary, letterSpacing: 0.3)),
          Text('Wellness Companion', style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _isVip ? ShunShiColors.primary.withValues(alpha: 0.1) : ShunShiColors.primary.withValues(alpha: 0.06),
            borderRadius: ShunShiRadius.chipRadius,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (_isVip) ...[
              const Icon(Icons.star_rounded, size: 14, color: ShunShiColors.primary),
              const SizedBox(width: 2),
              const Text('PRO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ShunShiColors.primary)),
            ] else ...[
              Icon(_quotaRemaining > 3 ? Icons.chat_bubble_outline_rounded : Icons.chat_bubble_rounded, size: 13, color: _quotaRemaining > 3 ? ShunShiColors.primary : Colors.orange),
              const SizedBox(width: 3),
              Text('$_quotaRemaining/$_quotaLimit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _quotaRemaining > 3 ? ShunShiColors.primary : Colors.orange)),
            ],
          ]),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 22, color: ShunShiColors.textTertiary),
          onSelected: (v) { if (v == 'clear') { setState(() => _messages.clear()); _saveConversation(); _initChat(); } },
          itemBuilder: (_) => [PopupMenuItem(value: 'clear', child: Text(AppLocalizations.of(context).t('chat_clear_chat')))],
        ),
      ]),
        ],
      ),
    );
  }

  void _showCrisisResources() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ShunShiColors.surface,
          borderRadius: ShunShiRadius.bottomSheetRadius,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: ShunShiColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.phone_in_talk, size: 36, color: ShunShiColors.error),
          const SizedBox(height: 12),
          const Text('If you\'re in crisis:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 12),
          const Text('US: 988 Suicide & Crisis Lifeline\nUK: 111 NHS Mental Health\nAU: 13 11 14 Beyond Blue\nInternational: findahelpline.com', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.8)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ShunShiColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.buttonRadius)),
            onPressed: () => Navigator.pop(context),
            child: const Text('I understand', style: TextStyle(fontSize: 15)),
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  int get _aiMessageCount => _messages.where((m) => m.role == 'ai').length;

  Widget _buildList() {
    final showUpgradeNudge = _aiMessageCount >= 5 && !_isVip;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _messages.length + (_isLoading ? 1 : 0) + (showUpgradeNudge ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == 0 && showUpgradeNudge) {
          return Column(children: [
            GestureDetector(
              onTap: _showUpgradePrompt,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: ShunShiColors.primary.withValues(alpha: 0.04),
                  borderRadius: ShunShiRadius.cardRadius,
                  border: Border.all(color: ShunShiColors.primary.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: ShunShiColors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: const Text('Keep the conversation going — unlock Premium', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ShunShiColors.primary))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: ShunShiColors.primary, borderRadius: ShunShiRadius.chipRadius), child: const Text('Unlock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ]);
        }
        final idx = showUpgradeNudge ? i - 1 : i;
        if (idx == _messages.length && _isLoading) return _buildTyping();
        if (idx >= _messages.length) return const SizedBox.shrink();
        final m = _messages[idx];
        return m.role == 'ai' ? _buildAI(m) : _buildUser(m);
      },
    );
  }

  Widget _buildAI(_ChatMessage m) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: ShunShiColors.primary, shape: BoxShape.circle, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('🌿', style: TextStyle(fontSize: 14)))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: ShunShiColors.border)),
          child: Text(m.text, style: const TextStyle(fontSize: 14, color: ShunShiColors.textPrimary, height: 1.6))),
        if (m.cards != null) ...m.cards!.map((c) => Padding(padding: const EdgeInsets.only(top: 8), child: _buildCard(c))),
        if (m.sources != null && m.sources!.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 8), child: _buildSources(m.sources!)),
        const SizedBox(height: 4),
        Row(children: [
          Text(m.time, style: const TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
          const SizedBox(width: 8),
          GestureDetector(onTap: () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).t('chat_playing_audio')), duration: Duration(seconds: 2))); }, child: const Icon(Icons.volume_up, size: 14, color: ShunShiColors.textTertiary)),
        ]),
      ])),
    ]));
  }

  Widget _buildSources(List<String> sources) {
    return Wrap(spacing: 6, runSpacing: 4, children: sources.map((s) => GestureDetector(
      onTap: () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Source: $s'), duration: const Duration(seconds: 2))); },
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.06), borderRadius: ShunShiRadius.chipRadius, border: Border.all(color: ShunShiColors.primary.withValues(alpha: 0.12))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('📚', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(s, style: const TextStyle(fontSize: 11, color: ShunShiColors.primary, fontWeight: FontWeight.w500)),
        ]),
      ),
    )).toList());
  }

  Widget _buildCard(_SuggestionCard c) {
    return Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8), border: Border.all(color: ShunShiColors.primary.withValues(alpha: 0.1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(c.icon ?? Icons.auto_awesome, size: 14, color: ShunShiColors.primary), const SizedBox(width: 6), Text(c.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ShunShiColors.primary))]),
        const SizedBox(height: 4),
        Text(c.subtitle, style: const TextStyle(fontSize: 12, color: ShunShiColors.textSecondary, height: 1.4)),
      ]),
    );
  }

  Widget _buildUser(_ChatMessage m) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: ShunShiColors.primary, borderRadius: BorderRadius.circular(8)),
          child: Text(m.text, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5))),
        const SizedBox(height: 4),
        Text(m.time, style: const TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
      ])),
    ]));
  }

  Widget _buildTyping() {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: ShunShiColors.primary, shape: BoxShape.circle, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('🌿', style: TextStyle(fontSize: 14)))),
      const SizedBox(width: 10),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: ShunShiColors.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => Padding(padding: EdgeInsets.only(left: i > 0 ? 4 : 0), child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: ShunShiColors.primary.withValues(alpha: 0.4))))))),
    ]));
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(color: ShunShiColors.background, border: Border(top: BorderSide(color: ShunShiColors.border, width: 0.5))),
      child: Row(children: [
        GestureDetector(onTap: _showQuickTopics, child: Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: ShunShiColors.surface, border: Border.all(color: ShunShiColors.border)), child: const Icon(Icons.add_circle_outline, size: 18, color: ShunShiColors.textTertiary))),
        const SizedBox(width: 8),
        Expanded(child: Container(constraints: const BoxConstraints(maxHeight: 120), child: TextField(controller: _controller, focusNode: _focusNode, maxLines: null, textInputAction: TextInputAction.send, onSubmitted: (_) => _sendMessage(),
          decoration: InputDecoration(hintText: AppLocalizations.of(context).t('chat_ask_about_wellness'), hintStyle: const TextStyle(fontSize: 14, color: ShunShiColors.textTertiary), filled: true, fillColor: ShunShiColors.surface, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)))),
        ),
        const SizedBox(width: 8),
        InkWell(onTap: _showVoiceInput, borderRadius: BorderRadius.circular(18), child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: ShunShiColors.textPrimary), child: const Icon(Icons.mic, color: Colors.white, size: 20))),
        const SizedBox(width: 6),
        GestureDetector(onTap: _sendMessage, child: Container(width: 36, height: 36, decoration: const BoxDecoration(shape: BoxShape.circle, color: ShunShiColors.primary), child: const Icon(Icons.send, color: Colors.white, size: 16))),
      ]),
    );
  }

  void _showVoiceInput() {
    showDialog(context: context, barrierDismissible: true, builder: (dc) {
      return StatefulBuilder(builder: (dc, setDialogState) {
        bool closed = false;
        Future.delayed(const Duration(seconds: 3), () {
          if (!closed && Navigator.of(dc).canPop()) {
            closed = true;
            Navigator.of(dc).pop();
            if (mounted) setState(() => _controller.text = 'I\'ve been feeling a bit tired lately');
          }
        });
        return PopScope(canPop: true, child: AlertDialog(
          backgroundColor: ShunShiColors.surface,
          shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.cardRadius),
          title: const Text('Voice Input', style: TextStyle(color: ShunShiColors.textPrimary, fontSize: 17)),
          content: SizedBox(height: 80, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const CircularProgressIndicator(color: ShunShiColors.primary),
            const SizedBox(height: 12),
            const Text('Simulating recognition...', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
          ])),
          actions: [TextButton(onPressed: () { closed = true; Navigator.of(dc).pop(); }, child: Text(AppLocalizations.of(context).t('chat_cancel')))],
        ));
      });
    });
  }

  void _showQuickTopics() {
    showModalBottomSheet(context: context, backgroundColor: Theme.of(context).brightness == Brightness.dark ? ShunShiColors.darkBackground : ShunShiColors.background, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
      builder: (context) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick Topics', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: ['Sleep issues', 'Seasonal wellness', 'Recipe ideas', 'Exercise tips', 'Mood balance', 'Ba Duan Jin', 'Herbal teas', 'Constitution test'].map((t) => ActionChip(
          label: Text(t), labelStyle: const TextStyle(fontSize: 13, color: ShunShiColors.textPrimary),
          backgroundColor: ShunShiColors.surface, side: BorderSide(color: ShunShiColors.border), shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.chipRadius),
          onPressed: () { Navigator.pop(context); _controller.text = t; _sendMessage(); },
        )).toList()),
        const SizedBox(height: 16),
      ])),
    );
  }
}

class _ChatMessage {
  final String role;
  final String text;
  final List<_SuggestionCard>? cards;
  final List<String>? sources;
  final String time;
  _ChatMessage({required this.role, required this.text, this.cards, this.sources, required this.time});
}

class _SuggestionCard {
  final String type;
  final String title;
  final String subtitle;
  final IconData? icon;
  _SuggestionCard({required this.type, required this.title, required this.subtitle, this.icon});
}

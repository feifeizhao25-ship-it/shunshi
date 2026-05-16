// ignore_for_file: unused_field
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/theme/shunshi_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/ai_safety.dart';
import '../../../data/services/voice_service.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/theme_helper.dart';
import '../widgets/feedback_sheet.dart';
import '../widgets/membership_widgets.dart';
import 'chat/chat_models.dart';
import 'chat/chat_widgets.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';
import '../../core/config/app_config.dart';
class ChatPage extends StatefulWidget {
  final String? conversationId;
  const ChatPage({super.key, this.conversationId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  static const _blockedKeywords = [
    '自杀', '自残', '死亡', '想死', '不想活', '抑郁症', 'depression', 'suicide', 'kill',
    '手术', '开刀', '癌症', '肿瘤', 'cancer', 'tumor',
    '怀孕', '流产', '堕胎', 'pregnancy', 'abortion',
    '过敏休克', '呼吸困难', '胸痛', '昏迷',
  ];
  static const _riskKeywords = [
    '发烧', '咳嗽', '头痛', '腹痛', '腹泻', '呕吐', '皮疹', '出血',
    '高血压', '糖尿病', '心脏病', '肝病', '肾病',
    '吃药', '用药', '停药', '药物',
  ];

  bool _containsBlocked(String text) => _blockedKeywords.any((k) => text.contains(k));
  bool _containsRisk(String text) => _riskKeywords.any((k) => text.contains(k));

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  final _dio = apiClient.dio;
  bool _isLoading = false;
  bool _isRecording = false;
  int _quotaRemaining = 10;
  int _quotaLimit = 10;
  bool _isVip = false;

  String _userName = '';
  String _token = '';
  String _currentSolarTerm = 'Lixia';
  String _solarTermDesc = 'The beginning of summer. Nourish the heart, eat lightly, rest properly.';
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _fetchSolarTerm();
    _initChat();
  }

  Future<void> _fetchSolarTerm() async {
    try {
      final res = await _dio.get('/api/v1/solar-terms/current');
      if (res.data is Map && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        if (mounted) setState(() {
          _currentSolarTerm = data['name']?.toString() ?? 'Lixia';
          _solarTermDesc = data['description']?.toString() ?? _solarTermDesc;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── 初始化 & 数据加载 ──

  Future<void> _initChat() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _token = prefs.getString('auth_token') ?? '';
      _userName = prefs.getString('user_name') ?? 'Friend';
    });
    if (_token.isEmpty) {
      try {
        final res = await _dio.post('/api/v1/auth/guest-login', data: {
          'device_id': 'shunshi_${DateTime.now().millisecondsSinceEpoch}',
        });
        if (res.data != null && res.data['data']?['token'] != null) {
          _token = res.data['data']['token'];
          await prefs.setString('auth_token', _token);
        }
      } catch (_) {}
    }
    await _loadConversation(prefs);
    if (_messages.isEmpty && mounted) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'ai',
          text: 'During $_currentSolarTerm, the energy between heaven and earth is shifting. How have you been feeling lately?',
          cards: [SuggestionCard(type: 'greeting', title: 'Current: $_currentSolarTerm', subtitle: _solarTermDesc)],
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

  // ── 对话持久化 ──

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
          _messages.add(ChatMessage(
            role: line.substring(0, sepIdx),
            text: line.substring(sepIdx + 1),
            time: _fmt(DateTime.now()),
          ));
        }
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  // ── 发送消息 ──

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    if (!_isVip && _quotaRemaining <= 0) { _showUpgradePrompt(); return; }
    _controller.clear();

    // Prompt Injection 防护
    if (AISafetyService.isPromptInjection(text)) {
      setState(() {
        _messages.add(ChatMessage(role: 'user', text: text, time: _fmt(DateTime.now())));
        _messages.add(ChatMessage(role: 'ai', text: 'Unusual input detected, please rephrase your question.', time: _fmt(DateTime.now())));
      });
      _saveConversation(); _scrollToBottom(); return;
    }

    // 健康风险评估
    final riskLevel = AISafetyService.assessRisk(text);
    if (riskLevel == RiskLevel.crisis || riskLevel == RiskLevel.high) {
      final crisisResponse = AISafetyService.getCrisisResponse(riskLevel);
      setState(() {
        _messages.add(ChatMessage(role: 'user', text: text, time: _fmt(DateTime.now())));
        _messages.add(ChatMessage(
          role: 'ai', text: crisisResponse,
          cards: riskLevel == RiskLevel.crisis
              ? [SuggestionCard(type: 'crisis', title: AppLocalizations.of(context).t('chatpagedart_crisis_hotline'), subtitle: AppLocalizations.of(context).t('chatpagedart_4001619995_24h_mental_health_helpline'), icon: Icons.phone_in_talk)]
              : [SuggestionCard(type: 'health', title: AppLocalizations.of(context).t('chatpagedart_see_a_doctor'), subtitle: AppLocalizations.of(context).t('chatpagedart_please_consult_a_medical_professional'), icon: Icons.local_hospital)],
          time: _fmt(DateTime.now()),
        ));
      });
      _saveConversation(); _scrollToBottom(); return;
    }

    if (_containsBlocked(text)) {
      setState(() { _messages.add(ChatMessage(role: 'user', text: text, time: _fmt(DateTime.now()))); });
      _showSafetyDialog(); _saveConversation(); _scrollToBottom(); return;
    }

    final hasRisk = riskLevel == RiskLevel.medium || _containsRisk(text);

    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text, time: _fmt(DateTime.now())));
      _isLoading = true;
    });
    _scrollToBottom();

    void handleAIReply(String aiText, {List<SuggestionCard>? cards, List<String>? sources, String? convId}) {
      var reply = aiText;
      final c = cards ?? [SuggestionCard(type: 'insight', title: AppLocalizations.of(context).t('chatpagedart_solar_term_care_tips'), subtitle: AppLocalizations.of(context).t('chatpagedart_follow_natural_rhythms_harmonize_body_and_min'))];
      if (hasRisk) reply = '⚠️ The following suggestions are for reference only and do not replace medical diagnosis. Please see a doctor if you feel unwell.\n\n$reply';
      reply = '$reply\n\n💡 The above is based on TCM wellness principles, for reference only';
      if (convId != null) _conversationId = convId;
      setState(() {
        _messages.add(ChatMessage(role: 'ai', text: reply, cards: c, sources: sources ?? [], time: _fmt(DateTime.now())));
        _isLoading = false;
        if (!_isVip) _quotaRemaining--;
        _incrementChatCount();
      });
      _saveConversation();
    }

    try {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      final res = await _dio.post('/ai/chat', data: {'message': text, 'solar_term': _currentSolarTerm, 'conversation_id': _conversationId});
      var aiText = res.data?['text'] ?? 'Sorry, unable to respond right now.';
      List<SuggestionCard> cards = [];
      if (res.data?['suggestions'] != null) {
        for (var s in res.data['suggestions']) {
          cards.add(SuggestionCard(type: s['type'] ?? 'tip', title: s['title'] ?? '', subtitle: s['content'] ?? '', icon: iconForType(s['type'])));
        }
      }
      final sources = (res.data?['sources'] as List?)?.cast<String>() ?? [];
      handleAIReply(aiText, cards: cards, sources: sources, convId: res.data?['conversation_id']);
    } catch (_) {
      try {
        final v2Dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 60)));
        v2Dio.options.headers['Authorization'] = 'Bearer $_token';
        final v2Res = await v2Dio.post('/api/v1/chat', data: {'message': text, 'context': {'solar_term': _currentSolarTerm}, 'conversation_id': _conversationId});  // CN uses Chinese endpoint
        final aiText = v2Res.data?['reply'] ?? 'Sorry, unable to respond right now.';
        List<SuggestionCard> v2Cards = [];
        final so = v2Res.data?['structured_output'];
        if (so != null) {
          final actions = so['actions'] as List?;
          if (actions != null) {
            for (var a in actions) {
              final duration = a['duration_min'] != null ? 'About ${a['duration_min']} min' : '';
              v2Cards.add(SuggestionCard(type: a['type'] ?? 'tip', title: a['title'] ?? '', subtitle: '${a['description'] ?? ''} $duration'.trim(), icon: iconForType(a['type'])));
            }
          }
          if (v2Cards.isEmpty) {
            v2Cards.add(SuggestionCard(type: 'insight', title: so['title'] ?? 'Wellness Tip', subtitle: so['insight'] ?? aiText, icon: iconForType('insight')));
          }
        } else {
          v2Cards.add(SuggestionCard(type: 'insight', title: AppLocalizations.of(context).t('chat_solar_term_care_tips'), subtitle: AppLocalizations.of(context).t('chat_follow_natural_rhythms_harmonize_body')));
        }
        final v2Sources = (so?['disclaimer'] != null) ? ['⚠️ ${so?["disclaimer"]}'] : <String>[];
        handleAIReply(aiText, cards: v2Cards, sources: v2Sources, convId: v2Res.data?['conversation_id']);
      } catch (_) {
        handleAIReply(_offlineReply(text),
          cards: [
            SuggestionCard(type: 'diet', title: AppLocalizations.of(context).t('solar_dietary_care'), subtitle: AppLocalizations.of(context).t('chatpagedart_try_snow_fungus_and_lily_bulb_to_moisten_dryn'), icon: Icons.restaurant),
            SuggestionCard(type: 'rest', title: AppLocalizations.of(context).t('chatpagedart_rest_routine'), subtitle: AppLocalizations.of(context).t('chatpagedart_sleep_early_rise_early_follow_natural_rhythms'), icon: Icons.bedtime),
          ],
          sources: const ['Huangdi Neijing · Suwen', 'Bencao Gangmu'],
        );
      }
    }
    _scrollToBottom();
  }

  String _offlineReply(String msg) {
    if (msg.contains('sleep') || msg.contains('insomnia')) return 'Sleep issues often relate to an unsettled mind. During $_currentSolarTerm, try soaking your feet in warm water for 15 minutes before bed, put down your phone, and let your mind quiet down.';
    if (msg.contains('tired') || msg.contains('fatigue')) return 'Feeling tired during seasonal transitions is normal. Consider reducing workload and eating warming, nourishing foods. A cup of ginger-date tea in the morning can help restore vitality.';
    return 'I hear you. During $_currentSolarTerm, the energy between heaven and earth is shifting. Would you like to talk about what specifically concerns you?';
  }

  String _fmt(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _incrementChatCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('chat_count') ?? 0) + 1;
    await prefs.setInt('chat_count', count);
  }

  int get _aiMessageCount => _messages.where((m) => m.role == 'ai').length;

  // ── 弹窗 ──

  void _showUpgradePrompt() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: ShunShiColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Container(padding: EdgeInsets.all(14), decoration: BoxDecoration(color: ShunShiColors.gold.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.star_rounded, size: 36, color: ShunShiColors.gold)),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context).t('chatpagedart_daily_free_messages_used_up'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
        const SizedBox(height: 8),
        Text('Upgrade for $_quotaLimit daily AI wellness tips\nUnlock full body type test + family member management', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: ShunShiColors.primary, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () { Navigator.pop(context); context.push('/subscription'); }, child: Text(AppLocalizations.of(context).t('chat_upgrade_now'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
        const SizedBox(height: 10),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).t('chat_later'), style: TextStyle(color: ShunShiColors.textTertiary))),
        const SizedBox(height: 8),
      ]),
    ));
  }

  void _showSafetyDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: ShunShiColors.surface,
      title: Row(children: [
        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).t('chat_health_notice'), style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
      ]),
      content: const Text(
        'The content you mentioned involves health safety risks. Please contact a medical professional immediately or call:\n\n'
        '• 24h Mental Health Helpline: 400-161-9995\n'
        '• Emergency: 120\n\n'
        'SEASONS AI cannot replace professional medical diagnosis.',
        style: TextStyle(fontSize: 15, color: ShunShiColors.textSecondary, height: 1.6),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).t('chat_understand'), style: TextStyle(color: ShunShiColors.primary, fontWeight: FontWeight.w600)))],
    ));
  }

  // ── 语音 ──

  void _showVoiceInput() async {
    if (_isRecording) {
      setState(() => _isRecording = false);
      try {
        final voice = VoiceService();
        final text = await voice.stopAndRecognize();
        if (text != null && text.isNotEmpty && mounted) {
          setState(() => _controller.text = text);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Speech recognition failed: $e'), duration: const Duration(seconds: 2)));
      }
      return;
    }
    try {
      final voice = VoiceService();
      final started = await voice.startRecording();
      if (!started) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).t('chat_failed_to_start_recording_please')), duration: Duration(seconds: 2)));
        return;
      }
      setState(() => _isRecording = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recording failed: $e'), duration: const Duration(seconds: 2)));
    }
  }

  void _showQuickTopics() {
    showModalBottomSheet(context: context, backgroundColor: ShunShiColors.background, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(initialChildSize: 0.72, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
        builder: (_, controller) => ListView(
          controller: controller, padding: const EdgeInsets.all(24),
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: ShunShiColors.borderGhost, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).t('chatpagedart_quick_topics'), style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: ['Poor sleep lately', 'Seasonal wellness tips', 'Solar term recipes', 'What exercise suits me', 'Feeling down', 'Learn Baduanjin', 'Wellness tea recommendations', 'Body type quiz'].map((t) => ActionChip(
              label: Text(t), labelStyle: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 13, color: ShunShiColors.textPrimary),
              backgroundColor: ShunShiColors.surface, side: BorderSide(color: ShunShiColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () { Navigator.pop(context); _controller.text = t; _sendMessage(); },
            )).toList()),
            const SizedBox(height: 24),
          ],
        )),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      body: SafeArea(child: Column(children: [
        _buildTopBar(),
        Expanded(child: _buildList()),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text('Content generated by AI, for wellness reference only, not medical advice. See a doctor if unwell.', style: TextStyle(fontSize: 11, color: Colors.grey[500]), textAlign: TextAlign.center)),
        _buildInput(),
      ])),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(color: ShunShiColors.background, border: Border(bottom: BorderSide(color: ShunShiColors.borderGhost, width: 0.5))),
      child: Column(children: [
        if (!_isVip) Padding(padding: const EdgeInsets.only(bottom: 8), child: TokenBalanceBar(remaining: _quotaRemaining, limit: _quotaLimit, isVip: _isVip, onTapUpgrade: _showUpgradePrompt)),
        Row(children: [
          Container(width: 36, height: 36, decoration: const BoxDecoration(color: ShunShiColors.primary, shape: BoxShape.circle), child: const Center(child: Text('🌱', style: TextStyle(fontSize: 18)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppLocalizations.of(context).t('home_ai_assistant'), style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            Text(AppLocalizations.of(context).t('chatpagedart_warm_companion'), style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 12, color: ShunShiColors.textTertiary)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _isVip ? ShunShiColors.gold.withValues(alpha: 0.15) : ShunShiColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (_isVip) ...[Icon(Icons.star_rounded, size: 14, color: ShunShiColors.gold), SizedBox(width: 2), Text(AppLocalizations.of(context).t('premium_badge'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ShunShiColors.gold))]
              else ...[Icon(_quotaRemaining > 3 ? Icons.chat_bubble_outline_rounded : Icons.chat_bubble_rounded, size: 13, color: _quotaRemaining > 3 ? ShunShiColors.primary : Colors.orange), const SizedBox(width: 3), Text('$_quotaRemaining/$_quotaLimit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _quotaRemaining > 3 ? ShunShiColors.primary : Colors.orange))],
            ]),
          ),
          PopupMenuButton<String>(icon: Icon(Icons.more_vert, size: 22, color: ShunShiColors.textTertiary), onSelected: (v) { if (v == 'clear') { setState(() => _messages.clear()); _saveConversation(); _initChat(); } }, itemBuilder: (_) => [PopupMenuItem(value: 'clear', child: Text(AppLocalizations.of(context).t('chatpagedart_clear_chat')))]),
        ]),
      ]),
    );
  }

  Widget _buildList() {
    final showUpgradeNudge = _aiMessageCount >= 5 && !_isVip;
    if (_messages.isEmpty && _isLoading) {
      return ListView(children: [const SkeletonMessage(isAI: true), const SkeletonMessage(isAI: false), const SkeletonMessage(isAI: true)]);
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _messages.length + (_isLoading ? 1 : 0) + (showUpgradeNudge ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == 0 && showUpgradeNudge) {
          return Column(children: [UpgradeNudge(onTap: _showUpgradePrompt), const SizedBox(height: 16)]);
        }
        final idx = showUpgradeNudge ? i - 1 : i;
        if (idx == _messages.length && _isLoading) return const TypingIndicator();
        if (idx >= _messages.length) return const SizedBox.shrink();
        final m = _messages[idx];
        if (m.role == 'ai') return AIBubble(message: m, onFeedback: () => FeedbackSheet.show(context, contentId: 'chat-$idx', type: 'chat'));
        return UserBubble(message: m);
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(color: ShunShiColors.background, border: Border(top: BorderSide(color: ShunShiColors.borderGhost, width: 0.5))),
      child: Row(children: [
        GestureDetector(onTap: _showQuickTopics, child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: ShunShiColors.surface, border: Border.all(color: ShunShiColors.border)), child: Icon(Icons.add_circle_outline, size: 20, color: ShunShiColors.textTertiary))),
        const SizedBox(width: 8),
        Expanded(child: Container(constraints: const BoxConstraints(maxHeight: 120), child: TextField(controller: _controller, focusNode: _focusNode, maxLines: null, textInputAction: TextInputAction.send, onSubmitted: (_) => _sendMessage(),
          decoration: InputDecoration(hintText: AppLocalizations.of(context).t('chat_chat_with_seasons'), hintStyle: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 15, color: ShunShiColors.textTertiary), filled: true, fillColor: ShunShiColors.surface, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none))))),
        const SizedBox(width: 8),
        InkWell(onTap: _showVoiceInput, borderRadius: BorderRadius.circular(20), child: Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: _isRecording ? Colors.red : ShunShiColors.secondary), child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 22))),
        const SizedBox(width: 8),
        GestureDetector(onTap: _sendMessage, child: Container(width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle, color: ShunShiColors.primary), child: const Icon(Icons.send, color: Colors.white, size: 18))),
      ]),
    );
  }
}

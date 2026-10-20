// ignore_for_file: unused_field
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/ai_safety.dart';
import '../../data/services/voice_service.dart';
import '../../design_system/theme.dart';
import '../../design_system/theme_helper.dart';
import '../widgets/feedback_sheet.dart';
import '../../core/config/app_config.dart';
import '../widgets/membership_widgets.dart';
import 'chat/chat_models.dart';
import 'chat/chat_history_store.dart';
import 'chat/chat_membership.dart';
import 'chat/chat_api.dart';
import 'chat/chat_widgets.dart';

final String _baseUrl = AppConfig.apiBaseUrl.replaceAll('/api/v1', '');

class ChatPage extends StatefulWidget {
  final String? conversationId;
  final Dio? client;
  const ChatPage({super.key, this.conversationId, this.client});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  static const _blockedKeywords = [
    '自杀',
    '自残',
    '死亡',
    '想死',
    '不想活',
    '抑郁症',
    'depression',
    'suicide',
    'kill',
    '手术',
    '开刀',
    '癌症',
    '肿瘤',
    'cancer',
    'tumor',
    '怀孕',
    '流产',
    '堕胎',
    'pregnancy',
    'abortion',
    '过敏休克',
    '呼吸困难',
    '胸痛',
    '昏迷',
  ];
  static const _riskKeywords = [
    '发烧',
    '咳嗽',
    '头痛',
    '腹痛',
    '腹泻',
    '呕吐',
    '皮疹',
    '出血',
    '高血压',
    '糖尿病',
    '心脏病',
    '肝病',
    '肾病',
    '吃药',
    '用药',
    '停药',
    '药物',
  ];

  bool _containsBlocked(String text) =>
      _blockedKeywords.any((k) => text.contains(k));
  bool _containsRisk(String text) => _riskKeywords.any((k) => text.contains(k));

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  late final _dio = widget.client ?? Dio(BaseOptions(baseUrl: _baseUrl, connectTimeout: const Duration(seconds: 10)));
  bool _isLoading = false;
  String? _chatError;
  bool _isRecording = false;
  bool _membershipKnown = false;
  bool _membershipLoading = false;
  bool _isVip = false;

  String _userName = '';
  String _token = '';
  String _currentSolarTerm = '立夏';
  String _solarTermDesc = '夏之始，养心安神。清淡饮食，适当午睡，防暑防晒。';
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
        if (mounted)
          setState(() {
            _currentSolarTerm = data['name']?.toString() ?? '立夏';
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
      _userName = prefs.getString('user_name') ?? '朋友';
    });
    if (_token.isEmpty) {
      try {
        final res = await _dio.post(
          '/api/v1/auth/guest-login',
          options: Options(receiveTimeout: const Duration(seconds: 10)),
          data: {
            'device_id': 'shunshi_${DateTime.now().millisecondsSinceEpoch}',
          },
        );
        final token = parseGuestToken(res.data);
        if (!mounted || (prefs.getString('auth_token') ?? '').isNotEmpty) return;
        await prefs.setString('auth_token', token);
        if (!mounted) return;
        setState(() => _token = token);
      } catch (_) {
        if (mounted) setState(() => _chatError = '暂时无法建立访客登录，请检查网络或登录账户后重试。');
      }
    }
    await _loadConversation(prefs);
    if (_messages.isEmpty && mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            role: 'ai',
            text: '$_currentSolarTerm时节，大地之气正在变化。你近来身心感觉如何？',
            cards: [
              SuggestionCard(
                type: 'greeting',
                title: '当前：$_currentSolarTerm',
                subtitle: _solarTermDesc,
              ),
            ],
            time: _fmt(DateTime.now()),
          ),
        );
      });
    }
    _loadMembership();
  }

  Future<void> _loadMembership() async {
    if (_membershipLoading || !mounted) return;
    setState(() => _membershipLoading = true);
    try {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      final res = await _dio.get('/api/v1/subscription/status',
          options: Options(receiveTimeout: const Duration(seconds: 10)));
      final paid = parseChatMembership(res.data);
      if (!mounted) return;
      setState(() {
        _isVip = paid;
        _membershipKnown = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVip = false;
        _membershipKnown = false;
      });
    } finally {
      if (mounted) setState(() => _membershipLoading = false);
    }
  }

  // ── 对话持久化 ──

  Future<void> _saveConversation() async {
    final token = _token;
    final messages = List<ChatMessage>.of(_messages);
    final conversation = _conversationId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await ChatHistoryStore(prefs, token).save(messages, conversation);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('聊天记录未能保存，请先复制重要内容再重试')),
        );
      }
    }
  }

  Future<void> _loadConversation(SharedPreferences prefs) async {
    final stored = ChatHistoryStore(prefs, _token)
        .load(conversationId: widget.conversationId);
    if (!mounted) return;
    setState(() {
      _conversationId = stored.conversationId;
      _messages
        ..clear()
        ..addAll(stored.messages);
    });
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

  // ── 发送消息 ──

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    if (_token.isEmpty) {
      setState(() => _chatError = '尚未完成登录，请稍后重试或登录账户。');
      return;
    }
    setState(() => _chatError = null);
    _controller.clear();

    // Prompt Injection 防护
    if (AISafetyService.isPromptInjection(text)) {
      setState(() {
        _messages.add(
          ChatMessage(role: 'user', text: text, time: _fmt(DateTime.now())),
        );
        _messages.add(
          ChatMessage(
            role: 'ai',
            text: '检测到异常输入，请重新描述您的问题。',
            time: _fmt(DateTime.now()),
          ),
        );
      });
      _saveConversation();
      _scrollToBottom();
      return;
    }

    // 健康风险评估
    final riskLevel = AISafetyService.assessRisk(text);
    if (riskLevel == RiskLevel.crisis || riskLevel == RiskLevel.high) {
      final crisisResponse = AISafetyService.getCrisisResponse(riskLevel);
      setState(() {
        _messages.add(
          ChatMessage(role: 'user', text: text, time: _fmt(DateTime.now())),
        );
        _messages.add(
          ChatMessage(
            role: 'ai',
            text: crisisResponse,
            cards: riskLevel == RiskLevel.crisis
                ? [
                    SuggestionCard(
                      type: 'crisis',
                      title: '紧急求助热线',
                      subtitle: '400-161-9995 · 24小时心理援助',
                      icon: Icons.phone_in_talk,
                    ),
                  ]
                : [
                    SuggestionCard(
                      type: 'health',
                      title: '建议就医',
                      subtitle: '请及时咨询专业医师',
                      icon: Icons.local_hospital,
                    ),
                  ],
            time: _fmt(DateTime.now()),
          ),
        );
      });
      _saveConversation();
      _scrollToBottom();
      return;
    }

    if (_containsBlocked(text)) {
      setState(() {
        _messages.add(
          ChatMessage(role: 'user', text: text, time: _fmt(DateTime.now())),
        );
      });
      _showSafetyDialog();
      _saveConversation();
      _scrollToBottom();
      return;
    }

    final hasRisk = riskLevel == RiskLevel.medium || _containsRisk(text);

    setState(() {
      _messages.add(
        ChatMessage(role: 'user', text: text, time: _fmt(DateTime.now())),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    void handleAIReply(
      String aiText, {
      List<SuggestionCard>? cards,
      List<String>? sources,
      String? convId,
    }) {
      var reply = aiText;
      final c =
          cards ??
          [
            SuggestionCard(
              type: 'insight',
              title: '节气调护建议',
              subtitle: '顺应天时，调和身心',
            ),
          ];
      if (hasRisk) reply = '⚠️ 以下建议仅供参考，不能替代医生诊断。如有不适请及时就医。\n\n$reply';
      reply = '$reply\n\n💡 以上建议基于中医养生理论，仅供参考';
      if (convId != null) _conversationId = convId;
      setState(() {
        _messages.add(
          ChatMessage(
            role: 'ai',
            text: reply,
            cards: c,
            sources: sources ?? [],
            time: _fmt(DateTime.now()),
          ),
        );
        _isLoading = false;
        _incrementChatCount();
      });
      _saveConversation();
    }

    final requestToken = _token;
    try {
      final reply = await sendChat(_dio, requestToken, text);
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || prefs.getString('auth_token') != requestToken) return;
      handleAIReply(reply.text, cards: [], sources: reply.sources);
    } catch (error) {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || prefs.getString('auth_token') != requestToken) return;
      setState(() {
        _chatError = chatFailureMessage(error);
        if (_controller.text.isEmpty) _controller.text = text;
      });
      await _saveConversation();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    _scrollToBottom();
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _incrementChatCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('chat_count') ?? 0) + 1;
    await prefs.setInt('chat_count', count);
  }

  int get _aiMessageCount => _messages.where((m) => m.role == 'ai').length;

  // ── 弹窗 ──

  void _showUpgradePrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: ShunShiColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ShunShiColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ShunShiColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 36,
                color: ShunShiColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '查看会员权益',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ShunShiColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '查看各档会员的对话、养生建议与家庭功能\n具体权益以套餐页面为准',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: ShunShiColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShunShiColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/subscription');
                },
                child: const Text(
                  '立即升级',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '稍后再说',
                style: TextStyle(color: ShunShiColors.textTertiary),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSafetyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ShunShiColors.surface,
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              '健康安全提示',
              style: TextStyle(
                fontFamily: ShunShiTypography.sansFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ShunShiColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          '您提到的内容涉及健康安全风险。请您立即联系专业医疗机构或拨打：\n\n'
          '• 24小时心理援助热线：400-161-9995\n'
          '• 急救电话：120\n\n'
          '顺时AI不能替代专业医疗诊断。',
          style: TextStyle(
            fontSize: 15,
            color: ShunShiColors.textSecondary,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '我知道了',
              style: TextStyle(
                color: ShunShiColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('语音识别失败: $e'),
              duration: const Duration(seconds: 2),
            ),
          );
      }
      return;
    }
    try {
      final voice = VoiceService();
      final started = await voice.startRecording();
      if (!started) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('录音启动失败，请检查麦克风权限'),
              duration: Duration(seconds: 2),
            ),
          );
        return;
      }
      setState(() => _isRecording = true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('录音失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  void _showQuickTopics() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? ShunShiColors.darkBackground
          : ShunShiColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ShunShiColors.borderGhost,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '快捷话题',
              style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ShunShiColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  [
                        '最近睡眠不好',
                        '换季怎么调理',
                        '推荐节气食谱',
                        '适合什么运动',
                        '情绪低落怎么办',
                        '想学八段锦',
                        '推荐养生茶饮',
                        '体质测试',
                      ]
                      .map(
                        (t) => ActionChip(
                          label: Text(t),
                          labelStyle: TextStyle(
                            fontFamily: ShunShiTypography.sansFamily,
                            fontSize: 13,
                            color: ShunShiColors.textPrimary,
                          ),
                          backgroundColor: ShunShiColors.surface,
                          side: BorderSide(color: ShunShiColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _controller.text = t;
                            _sendMessage();
                          },
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildList()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '内容由AI生成，仅供健康养生参考，不构成医疗诊断建议。如有不适请及时就医。',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? ShunShiColors.darkBorderGhost
                : ShunShiColors.borderGhost,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          if (!_membershipKnown)
            TextButton(
              onPressed: _membershipLoading ? null : _loadMembership,
              child: Text(_membershipLoading
                  ? '正在查询会员状态'
                  : '会员状态暂未查到，点击重试'),
            ),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: ShunShiColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🌱', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '顺时 AI 助手',
                      style: TextStyle(
                        fontFamily: ShunShiTypography.sansFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ShunShiColors.textPrimary,
                      ),
                    ),
                    Text(
                      '温暖陪伴',
                      style: TextStyle(
                        fontFamily: ShunShiTypography.sansFamily,
                        fontSize: 12,
                        color: ShunShiColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isVip
                      ? ShunShiColors.gold.withValues(alpha: 0.15)
                      : ShunShiColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isVip) ...[
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: ShunShiColors.gold,
                      ),
                      const SizedBox(width: 2),
                      const Text(
                        '会员',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ShunShiColors.gold,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        _membershipKnown
                            ? Icons.chat_bubble_outline_rounded
                            : Icons.chat_bubble_rounded,
                        size: 13,
                        color: _membershipKnown
                            ? ShunShiColors.primary
                            : Colors.orange,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _membershipKnown ? '免费版' : '状态待查询',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _membershipKnown
                              ? ShunShiColors.primary
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 22,
                  color: ShunShiColors.textTertiary,
                ),
                onSelected: (v) async {
                  if (v == 'clear') {
                    setState(() => _messages.clear());
                    await _saveConversation();
                    if (mounted) await _initChat();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'clear', child: Text('清空对话')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final showUpgradeNudge = _aiMessageCount >= 5 && _membershipKnown && !_isVip;
    if (_messages.isEmpty && _isLoading) {
      return ListView(
        children: [
          const SkeletonMessage(isAI: true),
          const SkeletonMessage(isAI: false),
          const SkeletonMessage(isAI: true),
        ],
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount:
          _messages.length + (_isLoading ? 1 : 0) + (showUpgradeNudge ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == 0 && showUpgradeNudge) {
          return Column(
            children: [
              UpgradeNudge(onTap: _showUpgradePrompt),
              const SizedBox(height: 16),
            ],
          );
        }
        final idx = showUpgradeNudge ? i - 1 : i;
        if (idx == _messages.length && _isLoading)
          return const TypingIndicator();
        if (idx >= _messages.length) return const SizedBox.shrink();
        final m = _messages[idx];
        if (m.role == 'ai')
          return AIBubble(
            message: m,
            onFeedback: () => FeedbackSheet.show(
              context,
              contentId: 'chat-$idx',
              type: 'chat',
            ),
          );
        return UserBubble(message: m);
      },
    );
  }

  Widget _buildInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark
        ? ShunShiColors.darkSurfaceContainerLowest
        : ShunShiColors.surfaceContainerLowest;
    final borderC = isDark
        ? ShunShiColors.darkBorderGhost
        : ShunShiColors.borderGhost;
    final hintC = isDark
        ? ShunShiColors.darkTextTertiary
        : ShunShiColors.textTertiary;
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 12),
      decoration: BoxDecoration(
        color: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
        border: Border(top: BorderSide(color: borderC, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_chatError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(_chatError!, key: const ValueKey('chat-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          // 快捷提问标签
          QuickQuestionChips(
            onTap: (q) {
              _controller.text = q;
              _sendMessage();
            },
          ),
          const SizedBox(height: 8),
          // 输入行
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showQuickTopics,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: inputBg,
                      border: Border.all(color: borderC),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 20,
                      color: hintC,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _focusNode,
                    builder: (context, child) {
                      final focused = _focusNode.hasFocus;
                      return Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: focused
                              ? Border.all(
                                  color: ShunShiColors.primary.withValues(
                                    alpha: 0.6,
                                  ),
                                  width: 1.5,
                                )
                              : Border.all(color: Colors.transparent, width: 0),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: '输入想和顺时聊的...',
                            hintStyle: TextStyle(
                              fontFamily: ShunShiTypography.sansFamily,
                              fontSize: 15,
                              color: hintC,
                            ),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showVoiceInput,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? Colors.red
                          : ShunShiColors.secondary,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GradientSendButton(onTap: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

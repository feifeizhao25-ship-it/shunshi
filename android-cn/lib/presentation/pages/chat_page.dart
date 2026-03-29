// 顺时 AI对话页面 — 国内版 v2
// 重构版：遵循 FINAL_UI_STRUCTURE.md + UI_SYSTEM.md 规范

import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/services/api_service.dart';
import '../../data/services/voice_service.dart';
import '../../data/network/api_client.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/shunshi_colors.dart';
import '../../core/theme/shunshi_text_styles.dart';
import '../../core/theme/shunshi_spacing.dart';

/// 聊天页面 - 核心对话界面 (国内版)
class ChatPage extends ConsumerStatefulWidget {
  final String? conversationId;

  const ChatPage({super.key, this.conversationId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _showVoiceInput = false; // 微信风格语音/键盘切换

  // 语音输入
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  String _speakingMsgId = ''; // 正在朗读的消息ID
  final AudioPlayer _ttsPlayer = AudioPlayer();

  // 图片
  final List<String> _selectedImagePaths = [];

  // 消息列表
  final List<_ChatMessage> _messages = [];

  // 快捷建议（空状态用）
  final List<String> _quickQuestions = [
    '最近总失眠怎么办',
    '适合秋季喝什么茶',
    '如何缓解工作压力',
  ];

  bool _hasWelcomed = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _ttsPlayer.dispose();
    super.dispose();
  }

  /// 朗读 AI 消息
  Future<void> _speakMessage(String content) async {
    // 去掉 markdown 格式
    final cleanText = content
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'#+\s'), '')
        .replaceAll(RegExp(r'\n+'), '。')
        .trim();
    if (cleanText.isEmpty) return;

    // 如果正在朗读同一条消息，停止
    if (_speakingMsgId.isNotEmpty) {
      await _ttsPlayer.stop();
      setState(() => _speakingMsgId = '');
      return;
    }

    try {
      final msgId = _messages.firstWhere((m) => m.content == content, orElse: () => _messages.first).id;
      setState(() => _speakingMsgId = msgId);

      final dio = Dio(BaseOptions(
        baseUrl: ApiClient.baseUrl,
        headers: {'ngrok-skip-browser-warning': 'true'},
        responseType: ResponseType.bytes,
      ));
      final resp = await dio.post('/api/v1/speech/tts', data: {
        'text': cleanText,
        'model': 'cosyvoice2',
        'voice': 'alex',
      });
      if (resp.statusCode == 200 && resp.data != null) {
        final bytes = resp.data is Uint8List
            ? resp.data as Uint8List
            : Uint8List.fromList(resp.data as List<int>);
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await file.writeAsBytes(bytes);
        await _ttsPlayer.play(DeviceFileSource(file.path));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _speakingMsgId = '');
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImagePaths.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasWelcomed = true;
      _messages.add(_ChatMessage(
        content: text.isEmpty ? '[图片]' : text,
        isUser: true,
        time: DateTime.now(),
        imagePaths:
            _selectedImagePaths.isNotEmpty ? List.from(_selectedImagePaths) : null,
      ));
    });

    _messageController.clear();
    _selectedImagePaths.clear();
    _voiceService.reset();
    _scrollToBottom();

    try {
      final apiService = ApiService();
      final result =
          await apiService.chat(userId: 'user_001', message: text);

      // 检查API返回的错误
      if (result['error'] != null) {
        setState(() {
          _isLoading = false;
          _messages.add(_ChatMessage(
            content: '抱歉，连接出了问题，请稍后再试～',
            isUser: false,
            time: DateTime.now(),
          ));
        });
        _scrollToBottom();
        return;
      }

      final data = result['data'] ?? result;
      final aiResponse =
          data['message'] ?? data['text'] ?? '抱歉，我现在有点累，稍后再试试吧～';

      setState(() {
        _isLoading = false;
        _messages.add(_ChatMessage(
          content: aiResponse,
          isUser: false,
          time: DateTime.now(),
        ));
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(_ChatMessage(
          content: '抱歉，连接出了问题。请检查网络后重试～',
          isUser: false,
          time: DateTime.now(),
        ));
      });
    }

    _scrollToBottom();
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

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
          source: source, maxWidth: 1024, imageQuality: 85);
      if (image != null) setState(() => _selectedImagePaths.add(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInShell = GoRouterState.of(context).uri.path == '/companion';

    return PopScope(
      canPop: isInShell,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!isInShell) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: ShunshiColors.background,
        appBar: AppBar(
          backgroundColor: ShunshiColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                size: 18, color: ShunshiColors.textPrimary),
            onPressed: () {
              final loc = GoRouterState.of(context).uri.path;
              if (loc != '/companion') {
                context.go('/home');
              }
            },
          ),
          title: const Text(
            '顺时',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: ShunshiColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // 消息列表 / 空状态
            Expanded(child: _buildBody()),
            // 图片预览
            if (_selectedImagePaths.isNotEmpty) _buildImagePreview(),
            // 输入区域
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 主体：空状态 or 消息列表
  // ──────────────────────────────────────────────

  Widget _buildBody() {
    if (!_hasWelcomed && _messages.isEmpty && !_isLoading) {
      return _buildWelcomeState();
    }
    return _buildMessageList();
  }

  // ──────────────────────────────────────────────
  // 空状态 — 欢迎卡片
  // ──────────────────────────────────────────────

  Widget _buildWelcomeState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ShunshiSpacing.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ShunshiSpacing.xl),
          decoration: BoxDecoration(
            color: ShunshiColors.surface,
            borderRadius: BorderRadius.circular(ShunshiSpacing.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 头像
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: ShunshiColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🌱', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: ShunshiSpacing.lg),
              // 标题
              const Text(
                '你好，我是顺时',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: ShunshiColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: ShunshiSpacing.sm),
              // 副标题
              const Text(
                '我是你的AI养生助手\n有什么想聊的都可以问我',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: ShunshiColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: ShunshiSpacing.xl),
              // 分割线
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: ShunshiColors.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: ShunshiSpacing.lg),
              // 建议问题
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    const Text(
                      '试试问我:',
                      style: TextStyle(
                        fontSize: 14,
                        color: ShunshiColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ShunshiSpacing.md),
              ..._quickQuestions.map((q) => _buildWelcomeSuggestion(q)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSuggestion(String question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ShunshiSpacing.sm),
      child: GestureDetector(
        onTap: () {
          _messageController.text = question;
          _sendMessage();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: ShunshiSpacing.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: ShunshiColors.background,
            borderRadius: BorderRadius.circular(ShunshiSpacing.radiusMedium),
            border: Border.all(color: ShunshiColors.borderLight),
          ),
          child: Text(
            '"$question"',
            style: const TextStyle(
              fontSize: 14,
              color: ShunshiColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 消息列表
  // ──────────────────────────────────────────────

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: ShunshiSpacing.md,
        vertical: ShunshiSpacing.md,
      ),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildTypingRow();
        }
        final msg = _messages[index];
        return _AnimatedMessageEntry(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: ShunshiSpacing.md),
            child: msg.isUser
                ? _buildUserMessage(msg)
                : _buildAIMessage(msg),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // AI消息行：头像 + 气泡
  // ──────────────────────────────────────────────

  Widget _buildAIMessage(_ChatMessage msg) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI头像
        Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(right: ShunshiSpacing.sm),
          decoration: const BoxDecoration(
            color: ShunshiColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🌱', style: TextStyle(fontSize: 20)),
          ),
        ),
        // 气泡
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.80,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ShunshiSpacing.md,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: ShunshiColors.surface,
                    borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._parseAIContent(msg.content),
                    ],
                  ),
                ),
              ),
              // 时间戳 + 朗读按钮
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(msg.time),
                      style: ShunshiTextStyles.overline.copyWith(
                        color: ShunshiColors.textHint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 朗读按钮
                    GestureDetector(
                      onTap: () => _speakMessage(msg.content),
                      child: Icon(
                        _speakingMsgId == msg.id ? Icons.volume_up : Icons.volume_down,
                        size: 14,
                        color: ShunshiColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // 用户消息：右侧绿色气泡
  // ──────────────────────────────────────────────

  Widget _buildUserMessage(_ChatMessage msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ShunshiSpacing.md,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: ShunshiColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (msg.imagePaths != null && msg.imagePaths!.isNotEmpty)
                    Wrap(
                      spacing: ShunshiSpacing.sm,
                      runSpacing: ShunshiSpacing.sm,
                      children: msg.imagePaths!.map((path) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(
                              ShunshiSpacing.radiusSmall),
                          child: Image.file(File(path),
                              width: 120, height: 120, fit: BoxFit.cover),
                        );
                      }).toList(),
                    ),
                  if (msg.imagePaths != null && msg.imagePaths!.isNotEmpty)
                    const SizedBox(height: ShunshiSpacing.sm),
                  Text(
                    msg.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            // 时间戳
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                _formatTime(msg.time),
                style: ShunshiTextStyles.overline.copyWith(
                  color: ShunshiColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 打字指示器行：头像 + 动画气泡
  // ──────────────────────────────────────────────

  Widget _buildTypingRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: ShunshiSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI头像
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: ShunshiSpacing.sm),
            decoration: const BoxDecoration(
              color: ShunshiColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🌱', style: TextStyle(fontSize: 20)),
            ),
          ),
          // 跳动圆点气泡
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: ShunshiColors.surface,
              borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // AI内容解析：提取建议卡片
  // ──────────────────────────────────────────────

  /// 解析AI消息内容，检测建议卡格式
  /// 匹配以 emoji+标题 开头，后跟 • 列表项的段落
  List<Widget> _parseAIContent(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];
    final textLines = <String>[];
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // 检测建议卡：emoji+空格+标题 格式
      if (_isCardTitleLine(line)) {
        // flush 前面的文字
        if (textLines.isNotEmpty) {
          widgets.add(Text(
            textLines.join('\n'),
            style: const TextStyle(
              fontSize: 15,
              color: ShunshiColors.textPrimary,
              height: 1.6,
            ),
          ));
          if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
          textLines.clear();
        }

        // 收集卡片内容
        final emoji = _extractEmoji(line);
        final title = line.replaceFirst(RegExp(r'^\s*[\p{Emoji}\s]+\s*'), '').trim();
        final cardItems = <String>[];
        String? cardLink;

        // 读取后续行直到空行或非卡片内容
        int j = i + 1;
        while (j < lines.length) {
          final nextLine = lines[j].trim();
          if (nextLine.isEmpty) {
            j++;
            break;
          }
          if (nextLine.startsWith('•') || nextLine.startsWith('-')) {
            cardItems.add(nextLine.replaceFirst(RegExp(r'^[•\-]\s*'), '').trim());
          } else if (nextLine.contains('→') || nextLine.contains('试试看')) {
            cardLink = nextLine;
          } else if (_isCardTitleLine(nextLine)) {
            break;
          } else {
            cardItems.add(nextLine);
          }
          j++;
        }

        widgets.add(_SuggestionCard(
          emoji: emoji,
          title: title,
          items: cardItems,
          link: cardLink,
        ));
        widgets.add(const SizedBox(height: 4));
        i = j;
      } else {
        textLines.add(line);
        i++;
      }
    }

    // flush 剩余文字
    if (textLines.isNotEmpty) {
      widgets.add(Text(
        textLines.join('\n'),
        style: const TextStyle(
          fontSize: 15,
          color: ShunshiColors.textPrimary,
          height: 1.6,
        ),
      ));
    }

    if (widgets.isEmpty) {
      widgets.add(Text(
        content,
        style: const TextStyle(
          fontSize: 15,
          color: ShunshiColors.textPrimary,
          height: 1.6,
        ),
      ));
    }

    return widgets;
  }

  bool _isCardTitleLine(String line) {
    final trimmed = line.trim();
    // 常见emoji前缀匹配
    return trimmed.isNotEmpty &&
        (RegExp(r'^[\p{Emoji}]').hasMatch(trimmed)) &&
        trimmed.length > 2 &&
        !trimmed.startsWith('•') &&
        !trimmed.startsWith('-');
  }

  String _extractEmoji(String line) {
    final match = RegExp(r'([\p{Emoji}])').firstMatch(line.trim());
    return match?.group(1) ?? '💡';
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ──────────────────────────────────────────────
  // 图片预览
  // ──────────────────────────────────────────────

  Widget _buildImagePreview() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(
          horizontal: ShunshiSpacing.md, vertical: ShunshiSpacing.sm),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImagePaths.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: ShunshiSpacing.sm),
        itemBuilder: (context, index) {
          if (index < _selectedImagePaths.length) {
            final path = _selectedImagePaths[index];
            return Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(ShunshiSpacing.radiusSmall),
                  child: Image.file(File(path),
                      width: 64, height: 64, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedImagePaths.removeAt(index)),
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }
          return GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(color: ShunshiColors.divider),
                borderRadius:
                    BorderRadius.circular(ShunshiSpacing.radiusSmall),
              ),
              child:
                  const Icon(Icons.add_photo_alternate, color: ShunshiColors.textHint),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 输入区域 — 圆角24，浅灰背景
  // ──────────────────────────────────────────────

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ShunshiSpacing.md,
        ShunshiSpacing.sm,
        ShunshiSpacing.md,
        ShunshiSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: ShunshiColors.background,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 输入框
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _messageController,
                builder: (context, value, _) {
                  final hasContent = value.text.trim().isNotEmpty;
                  return Row(
                    children: [
                      // 语音/键盘切换按钮
                      GestureDetector(
                        onTap: () => setState(() => _showVoiceInput = !_showVoiceInput),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, right: 4),
                          child: Icon(
                            _showVoiceInput ? Icons.keyboard : Icons.mic_none,
                            color: ShunshiColors.textHint,
                            size: 22,
                          ),
                        ),
                      ),
                      // 文字输入 / 语音按钮 二选一
                      Expanded(
                        child: _showVoiceInput
                            // 微信风格：按住说话
                            ? GestureDetector(
                                onTapDown: (_) async {
                                  setState(() => _isListening = true);
                                  final ok = await _voiceService.startRecording();
                                  if (!ok && mounted) {
                                    setState(() => _isListening = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(_voiceService.errorMsg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
                                    );
                                  }
                                },
                                onTapUp: (_) async {
                                  if (!_isListening) return;
                                  final text = await _voiceService.stopAndRecognize();
                                  if (mounted) setState(() => _isListening = false);
                                  if (text != null && text.isNotEmpty && mounted) {
                                    setState(() => _messageController.text = text);
                                    _sendMessage();
                                  } else if (mounted && _voiceService.errorMsg.isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(_voiceService.errorMsg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
                                    );
                                  }
                                },
                                onTapCancel: () async {
                                  await _voiceService.cancel();
                                  if (mounted) setState(() => _isListening = false);
                                },
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _isListening
                                        ? ShunshiColors.primary.withValues(alpha: 0.2)
                                        : ShunshiColors.surfaceDim,
                                    borderRadius: BorderRadius.circular(ShunshiSpacing.radiusXL),
                                    border: Border.all(color: ShunshiColors.primary.withValues(alpha: 0.3), width: 1.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: _isListening
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const _RecordingWave(),
                                            const SizedBox(width: 12),
                                            Text('松开发送', style: ShunshiTextStyles.hint.copyWith(color: ShunshiColors.primary)),
                                          ],
                                        )
                                      : Text('按住 说话', style: ShunshiTextStyles.hint.copyWith(color: ShunshiColors.textSecondary)),
                                ),
                              )
                            // 普通文字输入
                            : Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: ShunshiColors.surfaceDim.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(ShunshiSpacing.radiusXL),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: TextField(
                                        controller: _messageController,
                                        style: const TextStyle(fontSize: 15, color: ShunshiColors.textPrimary),
                                        decoration: InputDecoration(
                                          hintText: '输入消息...',
                                          hintStyle: ShunshiTextStyles.hint,
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          isDense: true,
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(width: ShunshiSpacing.sm),
                      // 发送按钮：有内容时显示
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: hasContent
                            ? GestureDetector(
                                key: const ValueKey('send'),
                                onTap: _isLoading ? null : _sendMessage,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _isLoading
                                        ? ShunshiColors.divider
                                        : ShunshiColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Icon(Icons.send,
                                          color: Colors.white, size: 18),
                                ),
                              )
                            : const SizedBox(
                                key: ValueKey('empty'),
                                width: 40,
                                height: 40,
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 录音波形动画 — 微信风格
// ═══════════════════════════════════════════════
class _RecordingWave extends StatefulWidget {
  const _RecordingWave();

  @override
  State<_RecordingWave> createState() => _RecordingWaveState();
}

class _RecordingWaveState extends State<_RecordingWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = i * 0.15;
            final t = (_controller.value - delay) % 1.0;
            final h = 6.0 + 14.0 * (0.5 + 0.5 * sin(t * pi * 2));
            return Container(
              width: 3,
              height: h,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: ShunshiColors.primary,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          },
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════
// 建议卡片 — 带左边框的卡片组件
// ═══════════════════════════════════════════════

class _SuggestionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final List<String> items;
  final String? link;

  const _SuggestionCard({
    required this.emoji,
    required this.title,
    required this.items,
    this.link,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F0),
        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusMedium),
        border: Border(
          left: BorderSide(
            color: ShunshiColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ShunshiSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: ShunshiSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: ShunshiColors.textPrimary,
                  ),
                ),
              ],
            ),
            // 分割线
            if (items.isNotEmpty) ...[
              const SizedBox(height: ShunshiSpacing.sm),
              Container(
                height: 1,
                color: ShunshiColors.divider,
                margin: const EdgeInsets.only(right: ShunshiSpacing.sm),
              ),
              const SizedBox(height: ShunshiSpacing.sm),
            ],
            // 列表项
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '•',
                        style: TextStyle(
                          fontSize: 15,
                          color: ShunshiColors.primary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            color: ShunshiColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            // 链接
            if (link != null) ...[
              const SizedBox(height: ShunshiSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  link!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ShunshiColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 消息出现动画 — 淡入 + 上滑
// ═══════════════════════════════════════════════

class _AnimatedMessageEntry extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedMessageEntry({required this.index, required this.child});

  @override
  State<_AnimatedMessageEntry> createState() => _AnimatedMessageEntryState();
}

class _AnimatedMessageEntryState extends State<_AnimatedMessageEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    // 延迟启动，让列表渲染稳定
    Future.delayed(Duration(milliseconds: widget.index * 30), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// 打字指示器 — 三个跳动圆点
// ═══════════════════════════════════════════════

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = ((_controller.value + delay) % 1.0);
            final bounce = (value * 2 - 1).abs();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: ShunshiColors.primary.withValues(alpha: 0.3 + bounce * 0.7),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// Data Model
// ═══════════════════════════════════════════════

class _ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime time;
  final List<String>? imagePaths;

  _ChatMessage({
    String? id,
    required this.content,
    required this.isUser,
    required this.time,
    this.imagePaths,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}

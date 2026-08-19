import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/message.dart';

import '../../domain/entities/care_status.dart';
import '../../domain/entities/user.dart';
import '../../core/di/injection.dart';
import 'subscription_providers.dart';

/// 当前会话 ID
final currentSessionIdProvider = StateProvider<String?>((ref) => null);

/// 聊天消息列表
final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, List<Message>>((ref) {
  return ChatMessagesNotifier(ref);
});

class ChatMessagesNotifier extends StateNotifier<List<Message>> {
  final Ref _ref;

  ChatMessagesNotifier(this._ref) : super([]);

  /// 发送消息
  Future<void> sendMessage(String content) async {
    final sessionId = _ref.read(currentSessionIdProvider);
    if (sessionId == null) return;

    // 添加用户消息
    final userMsg = Message.userMessage(content);
    state = [...state, userMsg];

    // 添加 loading
    state = [...state, Message.loading];

    try {
      final sendUseCase = _ref.read(sendMessageUseCaseProvider);
      final flags = _ref.read(featureFlagsProvider);
      final isPremium = _ref.read(isPremiumProvider);

      final userContext = UserContext(
        userId: 'current_user', // TODO: from auth
        memory: const UserMemory(),
        isPremium: isPremium,
      );

      final response = await sendUseCase.execute(
        sessionId: sessionId,
        message: content,
        userContext: userContext,
        promptVersions: {
          'core': flags.promptCoreVersion,
          'policy': flags.promptPolicyVersion,
          'task': flags.promptTaskVersion,
        },
      );

      // 移除 loading，添加 AI 回复
      state = [
        ...state.where((m) => !m.isLoading),
        response.toMessage(),
      ];

      // 更新安全标记
      _ref.read(currentSafetyFlagProvider.notifier).state =
          response.safetyFlag;

      // 更新关怀状态
      _ref.read(currentCareStatusProvider.notifier).state =
          response.careStatus;

      // 更新建议问题
      if (response.followUpQuestions.isNotEmpty) {
        _ref.read(suggestedQuestionsProvider.notifier).state =
            response.followUpQuestions;
      }
    } catch (e) {
      // 移除 loading
      state = state.where((m) => !m.isLoading).toList();
      // TODO: Error handling
    }
  }

  void addGreeting(String greeting, List<String> suggestions) {
    final msg = Message.assistantMessage(
      greeting,
      followUpQuestions: suggestions,
    );
    state = [msg];
    _ref.read(suggestedQuestionsProvider.notifier).state = suggestions;
  }

  void clear() {
    state = [];
  }
}

/// 当前安全标记
final currentSafetyFlagProvider =
    StateProvider<SafetyFlag>((ref) => SafetyFlag.green);

/// 当前关怀状态
final currentCareStatusProvider =
    StateProvider<CareStatus>((ref) => CareStatus.stable);

/// 建议问题列表
final suggestedQuestionsProvider = StateProvider<List<String>>((ref) => [
      '现在吃什么比较养生？',
      '推荐一些适合我的运动',
      '有哪些穴位按摩可以保健？',
      '最近总是睡不好怎么办？',
    ]);

/// 是否处于 SafeMode
final isSafeModeProvider = Provider<bool>((ref) {
  final flag = ref.watch(currentSafetyFlagProvider);
  return flag.requiresSafeMode;
});

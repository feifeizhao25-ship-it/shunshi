import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/safety/safety_guard.dart';
import '../../data/models/message.dart';
import '../../domain/usecases/apply_presence_policy.dart';
import '../../domain/usecases/schedule_followup.dart';
import '../../domain/usecases/send_message.dart';
import 'app_state_provider.dart';
import 'infrastructure_providers.dart';

final chatProvider = AsyncNotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

class ChatState {
  final List<Message> messages;
  final bool isSending;
  final SafeModeState safeMode;
  final int consecutiveUnanswered;
  final String presenceLevel;

  const ChatState({
    this.messages = const [],
    this.isSending = false,
    this.safeMode = const SafeModeState(isActive: false),
    this.consecutiveUnanswered = 0,
    this.presenceLevel = 'normal',
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isSending,
    SafeModeState? safeMode,
    int? consecutiveUnanswered,
    String? presenceLevel,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      safeMode: safeMode ?? this.safeMode,
      consecutiveUnanswered: consecutiveUnanswered ?? this.consecutiveUnanswered,
      presenceLevel: presenceLevel ?? this.presenceLevel,
    );
  }
}

class ChatNotifier extends AsyncNotifier<ChatState> {
  final _uuid = const Uuid();
  final _presencePolicy = ApplyPresencePolicy();

  @override
  Future<ChatState> build() async {
    final repo = ref.watch(aiRepositoryProvider);
    final userAsync = ref.watch(userContextProvider);
    final userId = userAsync.value?.userId ?? '';
    if (userId.isEmpty) return const ChatState();
    final history = await repo.getChatHistory(userId: userId);
    return ChatState(messages: history);
  }

  Future<void> sendMessage(String text) async {
    final userAsync = ref.read(userContextProvider);
    final user = userAsync.value;
    if (user == null) return;

    final userMsgId = _uuid.v4();
    final replyMsgId = _uuid.v4();
    final userMsg = Message.userMessage(id: userMsgId, text: text);

    final current = state.value ?? const ChatState();
    state = AsyncData(current.copyWith(
      messages: [...current.messages, userMsg],
      isSending: true,
    ));

    final useCase = SendMessage(ref.read(aiRepositoryProvider));
    final scheduleUseCase = ScheduleFollowup(ref.read(followUpRepositoryProvider));

    final (response, replyMsg) = await useCase.call(
      userId: user.userId,
      context: user,
      text: text,
      messageId: replyMsgId,
    );

    final safeModeState = SafetyGuard.evaluate(response);

    if (response.followUp != null) {
      await scheduleUseCase.call(
        userId: user.userId,
        plan: response.followUp!,
      );
    }

    final policyResult = _presencePolicy.apply(
      consecutiveUnansweredCount: current.consecutiveUnanswered,
      currentPresenceLevel: current.presenceLevel,
    );
    final newPresence = policyResult == PresencePolicyResult.reduce
        ? 'reduced'
        : policyResult == PresencePolicyResult.restore
            ? 'normal'
            : current.presenceLevel;

    state = AsyncData(current.copyWith(
      messages: [...current.messages, userMsg, replyMsg],
      isSending: false,
      safeMode: safeModeState,
      consecutiveUnanswered: response.isSafe ? 0 : current.consecutiveUnanswered + 1,
      presenceLevel: newPresence,
    ));
  }

  Future<void> clearMemory() async {
    final user = ref.read(userContextProvider).value;
    if (user == null) return;
    await ref.read(aiRepositoryProvider).clearMemory(user.userId);
    state = AsyncData(const ChatState());
  }
}

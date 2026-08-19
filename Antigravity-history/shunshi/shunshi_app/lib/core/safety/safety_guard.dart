import '../../data/models/ai_response.dart';
import 'system_notice_messages.dart';

/// SafeMode 守卫
/// 当 safety_flag != none 时进入 SafeMode：
/// - 显示 system notice card
/// - 禁止订阅弹窗/促销入口
class SafetyGuard {
  SafetyGuard._();

  static SafeModeState evaluate(AiResponse response) {
    if (response.isSafe) {
      return const SafeModeState(isActive: false);
    }
    final notice = _selectNotice(response);
    return SafeModeState(
      isActive: true,
      safetyFlag: response.safetyFlag,
      noticeMessage: notice,
      blockPromotion: true,
      offlineEncouraged: response.offlineEncouraged,
    );
  }

  static String _selectNotice(AiResponse response) {
    switch (response.safetyFlag) {
      case 'sensitive':
        return SystemNoticeMessages.safeModeBanner;
      case 'crisis':
        return SystemNoticeMessages.safeModeBanner;
      default:
        return SystemNoticeMessages.gentleCheck;
    }
  }
}

class SafeModeState {
  final bool isActive;
  final String? safetyFlag;
  final String? noticeMessage;
  final bool blockPromotion;
  final bool offlineEncouraged;

  const SafeModeState({
    required this.isActive,
    this.safetyFlag,
    this.noticeMessage,
    this.blockPromotion = false,
    this.offlineEncouraged = false,
  });
}

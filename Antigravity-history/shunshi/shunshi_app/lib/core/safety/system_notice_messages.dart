/// SafeMode 系统提示文案
/// 人格化边界，温和克制，不外显诊断信息
class SystemNoticeMessages {
  SystemNoticeMessages._();

  /// 进入 SafeMode 时显示的边界说明
  static const String safeModeBanner =
      '我注意到你现在可能需要更多支持。我在这里陪着你，但也想提醒你，如果感到很沉重，和身边信任的人说说话会有帮助。';

  /// 安抚性提示（tone=sensitive）
  static const String gentleCheck =
      '你现在感觉怎么样？我们可以慢慢聊，不用急。';

  /// 鼓励线下连接
  static const String offlineEncouraged =
      '有时候，面对面的陪伴是最有温度的。如果可以，试试和朋友或家人见一面？';

  /// 记忆被清空后的提示
  static const String memoryCleared =
      '记忆已清空。从这一刻开始，我们重新认识。';

  /// 记忆开关关闭提示
  static const String memoryDisabled =
      '记忆已关闭。我不会记录我们的对话，每次对话都是全新开始。';

  /// 记忆开关开启提示
  static const String memoryEnabled =
      '记忆已开启。我会记住一些重要的事，帮助我更好地陪伴你。';

  /// 降频提示（presence_level=reduced）
  static const String presenceReduced =
      '我会少一些主动问候，让你有更多安静的空间。随时来找我都可以。';

  /// 功能不可用时的降级文案
  static const String featureUnavailable =
      '这个功能暂时无法使用，稍后再试试。';

  /// 网络错误
  static const String networkError =
      '网络连接有点问题，请稍后再试。';

  /// 内容加载失败
  static const String contentLoadFailed =
      '内容暂时加载不出来，稍等一下或刷新试试。';

  /// 空聊天记录
  static const String emptyChatHistory =
      '这里还没有对话记录。有什么想聊的，直接说就好。';

  /// 今日计划加载中
  static const String dailyPlanLoading =
      '正在为你准备今日的安排，稍等片刻…';

  /// 今日计划降级（网络不可用）
  static const String dailyPlanOffline =
      '暂时无法获取今日计划，不妨先喝杯水，做几次深呼吸。';
}

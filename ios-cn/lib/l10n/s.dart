/// 简单 i18n 层 — 后续可替换为 flutter_localizations
/// 目前 CN 版使用中文硬编码，Global 版使用英文
class S {
  static const bool isZh = true;

  // 通用
  static const String appName = '顺时';
  static const String loading = '加载中...';
  static const String error = '加载失败';
  static const String retry = '重试';
  static const String confirm = '确认';
  static const String cancel = '取消';
  static const String save = '保存';
  static const String search = '搜索';
  static const String searchHint = '搜索养生知识...';

  // Tab 标签
  static const String tabHome = '今日';
  static const String tabSolar = '节气';
  static const String tabChat = '对话';
  static const String tabDiscover = '养生';
  static const String tabProfile = '我的';

  // 首页
  static const String todayWellness = '今日养生';
  static const String dailyInsight = '每日洞见';
  static const String suggestions = '养生建议';

  // 搜索热门
  static const String hotSearch = '热门搜索';

  // Profile
  static const String myFavorites = '我的收藏';
  static const String myAchievements = '养生成就';
  static const String settings = '设置';
  static const String about = '关于顺时';
  static const String feedback = '意见反馈';
  static const String subscription = '订阅管理';

  // 反馈
  static const String feedbackHint = '请描述您的问题或建议...';
  static const String feedbackSuccess = '感谢您的反馈！';
  static const String submit = '提交反馈';

  // 收藏
  static const String noFavorites = '还没有收藏内容';
  static const String removeFavorite = '取消收藏';

  // 通知
  static const String notifications = '通知';
  static const String noNotifications = '暂无通知';

  // 搜索页类型
  static const String typeAll = '全部';
  static const String typeDiet = '饮食';
  static const String typeTea = '茶饮';
  static const String typeExercise = '运动';
  static const String typeRecipe = '药膳';
  static const String typeMeridian = '经络';
  static const String typeAcupoint = '穴位';

  // 设置
  static const String solarReminder = '节气提醒';
  static const String shichenReminder = '时辰提醒';
  static const String checkinReminder = '打卡提醒';
  static const String elderMode = '长辈模式';
  static const String darkMode = '深色模式';
}

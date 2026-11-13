// 个性化区块的中文文字（国内版专用）。国际版不包含这个文件，避免中文进入国际版界面。
import 'personal_home_section.dart';

String _minutes(int n) => '$n 分钟';
String _days(int n) => '已连续 $n 天打开';
String _weekDone(String d) => '$d 做了小行动';
String _weekNone(String d) => '$d 没有记录';

const PersonalHomeStrings kPersonalHomeStringsZh = PersonalHomeStrings(
  heading: '今天为你准备的',
  why: '为什么推荐',
  notRecommend: '不再推荐',
  turnOff: '关闭个性化',
  turnOn: '重新打开',
  offTitle: '个性化已关闭',
  offBody: '现在显示的是通用内容，你的记录没有被删除。',
  offSame: '个性化推荐已关闭。下面的卡片和大家看到的一样。',
  confirmTitle: '关闭个性化推荐？',
  confirmBody: '关闭后首页只显示通用内容，之前的记录不会被删除，随时可以重新打开。',
  cancel: '取消',
  confirm: '关闭',
  errorTitle: '暂时没能加载',
  errorBody: '请检查网络后再试一次。',
  retry: '重试',
  loginTitle: '请先登录',
  loginBody: '登录后就能看到为你准备的内容。',
  loginAction: '去登录',
  emptyTitle: '今天暂时没有新的建议',
  emptyBody: '晚点再来看看。',
  saveFailed: '没能保存设置，请稍后再试',
  loading: '加载中',
  letterSpacing: 1,
  minutes: _minutes,
  days: _days,
  weekHeading: '本周',
  weekdays: '一二三四五六日',
  weekDone: _weekDone,
  weekNone: _weekNone,
  recallDismiss: '知道了',
  recallLabel: '欢迎回来',
);

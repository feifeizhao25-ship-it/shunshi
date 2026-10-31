// 个性化区块的中文文字（国内版专用）。国际版不包含这个文件，避免中文进入国际版界面。
import 'personal_home_section.dart';

String _minutes(int n) => '$n 分钟';
String _days(int n) => '已连续 $n 天打开';

const PersonalHomeStrings kPersonalHomeStringsZh = PersonalHomeStrings(
  heading: '今天为你准备的',
  why: '为什么看到这个',
  turnOff: '关闭个性化',
  turnOn: '重新打开',
  offTitle: '个性化已关闭',
  offBody: '现在显示的是通用内容，你的记录没有被删除。',
  confirmTitle: '关闭个性化推荐？',
  confirmBody: '关闭后首页只显示通用内容，之前的记录不会被删除，随时可以重新打开。',
  cancel: '取消',
  confirm: '关闭',
  errorTitle: '暂时没能加载',
  errorBody: '请检查网络后再试一次。',
  retry: '重试',
  emptyTitle: '今天暂时没有新的建议',
  emptyBody: '晚点再来看看。',
  saveFailed: '没能保存设置，请稍后再试',
  loading: '加载中',
  letterSpacing: 1,
  minutes: _minutes,
  days: _days,
);

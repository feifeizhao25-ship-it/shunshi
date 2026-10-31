// 资料库页面的中文文字（国内版专用）。国际版不包含这个文件，避免中文进入国际版界面。
import 'library_live.dart';
import 'reference_library_page.dart';

String _zhDate(String d) {
  final m = RegExp(r'^(\d{4})-(\d{2})(?:-(\d{2}))?$').firstMatch(d);
  if (m == null) return d;
  final month = int.parse(m.group(2)!);
  if (m.group(3) == null) return '${m.group(1)}年$month月';
  return '${m.group(1)}年$month月${int.parse(m.group(3)!)}日';
}

const LiveStrings kLiveStringsZh = LiveStrings(
  forYouTitle: '为你推荐',
  whyLabel: '为什么推荐',
  newBadge: '新',
  updatedBadge: '已更新',
  settingsTitle: '推荐设置',
  settingsTooltip: '推荐设置',
  switchTitle: '个性化推荐',
  switchOnHint: '根据你填写的目标、关注的主题和读过的内容挑选资料。只在应用内显示，不会发通知。',
  switchOffTitle: '个性化推荐已关闭',
  switchOffBody: '现在不会为你挑选资料，也不会记录你读过什么。随时可以重新打开。',
  topicsTitle: '关注的主题',
  topicsHint: '点一下关注，有新增或更新时会优先推荐给你；长按可以不再推荐某个主题。',
  followAction: '关注',
  followedState: '已关注',
  mutedState: '不再推荐',
  muteAction: '不再推荐',
  unmuteAction: '恢复推荐',
  changeNoteLabel: '更新说明',
  offlineNote: '当前显示的是随应用保存的离线内容，联网后会自动更新。',
  nothingForYou: '暂时没有适合你的新内容',
  close: '完成',
  saveFailed: '没有保存成功，请稍后再试',
  moreInLibrary: '下面是全部资料',
);

/// 国内版文字。[title] / [intro] / [footer] 每个产品自己写。
LibraryStrings libraryStringsZh({required String title, required String intro, required String footer}) => LibraryStrings(
      title: title,
      intro: intro,
      searchHint: '搜索关键词',
      allLabel: '全部',
      statusAll: '全部状态',
      statusLabels: const ['现行', '征求意见稿', '已废止', '待核实'],
      pendingLabel: '待审核',
      approvedLabel: '已审核',
      previewBanner: '预览模式：下面的条目已对照官方原文整理，但还在等待人工审核，请不要当作最终结论。',
      emptyReviewTitle: '资料正在审核中',
      emptyReviewBody: '新整理的资料要先经过人工核对原文，通过后才会在这里出现。审核期间，请以官方公告为准。',
      emptySearchTitle: '没有找到相关资料',
      emptySearchBody: '换一个关键词，或者清除分类和状态筛选再试试。',
      loading: '正在加载资料…',
      loadFailed: '资料加载失败',
      retry: '重试',
      countLabel: (n) => '共 $n 条',
      sourceLabel: '出处',
      publishedLabel: '发布',
      retrievedLabel: '读取于',
      effectiveLabel: '生效日期',
      pointsTitle: '要点',
      tipTitle: '通俗理解',
      cautionTitle: '注意',
      sourceTitle: '出处',
      fileLabel: '文件',
      publisherLabel: '发文机关',
      docNoLabel: '文号',
      readScopeLabel: '读到的范围',
      linkLabel: '原文链接',
      openSource: '打开官方原文',
      copyLink: '复制原文链接',
      copiedHint: '链接已复制，可粘贴到浏览器打开',
      statusNoteLabel: '状态说明',
      footer: footer,
      formatDate: _zhDate,
      live: kLiveStringsZh,
    );

// 资料库页面（顺时 / 新能源智库 共用的一份实现，各自拷贝到自己的 lib/ 下）。
//
// 数据是 assets 里的 JSON：每一条都带出处、文号、状态、读取日期和审核状态。
// 审核门禁：默认只展示 review_status 为“已审核”的条目；“待审核”的条目只有在
// 构建时传入 --dart-define=SHOW_PENDING_LIBRARY=true（预览/审核环境）才显示，
// 并且每张卡片都带“待审核”标记。本页面不进入检索索引，AI 回答不会引用未审核条目。
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;

const bool kShowPendingLibrary = bool.fromEnvironment('SHOW_PENDING_LIBRARY');

/// 页面用到的所有文字。国内版用 [LibraryStrings.zh]，国际版用 [LibraryStrings.en]。
class LibraryStrings {
  const LibraryStrings({
    required this.title,
    required this.intro,
    required this.searchHint,
    required this.allLabel,
    required this.statusAll,
    required this.statusLabels,
    required this.pendingLabel,
    required this.approvedLabel,
    required this.previewBanner,
    required this.emptyReviewTitle,
    required this.emptyReviewBody,
    required this.emptySearchTitle,
    required this.emptySearchBody,
    required this.loading,
    required this.loadFailed,
    required this.retry,
    required this.countLabel,
    required this.sourceLabel,
    required this.publishedLabel,
    required this.retrievedLabel,
    required this.effectiveLabel,
    required this.pointsTitle,
    required this.tipTitle,
    required this.cautionTitle,
    required this.sourceTitle,
    required this.fileLabel,
    required this.publisherLabel,
    required this.docNoLabel,
    required this.readScopeLabel,
    required this.linkLabel,
    required this.openSource,
    required this.copyLink,
    required this.copiedHint,
    required this.statusNoteLabel,
    required this.footer,
    required this.formatDate,
  });

  final String title;
  final String intro;
  final String searchHint;
  final String allLabel;
  final String statusAll;

  /// 顺序固定：现行 / 征求意见稿 / 已废止 / 待核实（英文版同序）。
  final List<String> statusLabels;
  final String pendingLabel;
  final String approvedLabel;
  final String previewBanner;
  final String emptyReviewTitle;
  final String emptyReviewBody;
  final String emptySearchTitle;
  final String emptySearchBody;
  final String loading;
  final String loadFailed;
  final String retry;
  final String Function(int) countLabel;
  final String sourceLabel;
  final String publishedLabel;
  final String retrievedLabel;
  final String effectiveLabel;
  final String pointsTitle;
  final String tipTitle;
  final String cautionTitle;
  final String sourceTitle;
  final String fileLabel;
  final String publisherLabel;
  final String docNoLabel;
  final String readScopeLabel;
  final String linkLabel;
  final String openSource;
  final String copyLink;
  final String copiedHint;
  final String statusNoteLabel;
  final String footer;
  final String Function(String) formatDate;

  static String _zhDate(String d) {
    final m = RegExp(r'^(\d{4})-(\d{2})(?:-(\d{2}))?$').firstMatch(d);
    if (m == null) return d;
    final month = int.parse(m.group(2)!);
    if (m.group(3) == null) return '${m.group(1)}年$month月';
    return '${m.group(1)}年$month月${int.parse(m.group(3)!)}日';
  }

  /// 国内版文字。[title] / [intro] / [footer] 每个产品自己写。
  static LibraryStrings zh({required String title, required String intro, required String footer}) => LibraryStrings(
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
      );

}

class LibrarySource {
  LibrarySource({required this.title, required this.publisher, required this.docNo, required this.url, required this.urlNote, required this.readScope});

  factory LibrarySource.fromJson(Map<String, dynamic> j) => LibrarySource(
        title: (j['title'] ?? '') as String,
        publisher: (j['publisher'] ?? '') as String,
        docNo: (j['doc_no'] ?? '') as String,
        url: (j['url'] ?? '') as String,
        urlNote: (j['url_note'] ?? '') as String,
        readScope: (j['read_scope'] ?? '') as String,
      );

  final String title;
  final String publisher;
  final String docNo;
  final String url;
  final String urlNote;
  final String readScope;
}

class LibraryEntry {
  LibraryEntry({
    required this.id,
    required this.title,
    required this.summary,
    required this.points,
    required this.plainTip,
    required this.caution,
    required this.category,
    required this.tags,
    required this.source,
    required this.status,
    required this.statusNote,
    required this.publishDate,
    required this.effectiveDate,
    required this.retrievedAt,
    required this.reviewStatus,
  });

  factory LibraryEntry.fromJson(Map<String, dynamic> j) => LibraryEntry(
        id: j['id'] as String,
        title: j['title'] as String,
        summary: (j['summary'] ?? '') as String,
        points: [for (final p in (j['points'] as List? ?? const [])) p as String],
        plainTip: (j['plain_tip'] ?? '') as String,
        caution: (j['caution'] ?? '') as String,
        category: (j['category'] ?? '') as String,
        tags: [for (final t in (j['tags'] as List? ?? const [])) t as String],
        source: LibrarySource.fromJson(Map<String, dynamic>.from(j['source'] as Map)),
        status: (j['status'] ?? '') as String,
        statusNote: (j['status_note'] ?? '') as String,
        publishDate: (j['publish_date'] ?? '') as String,
        effectiveDate: (j['effective_date'] ?? '') as String,
        retrievedAt: (j['retrieved_at'] ?? '') as String,
        reviewStatus: (j['review_status'] ?? '') as String,
      );

  final String id;
  final String title;
  final String summary;
  final List<String> points;
  final String plainTip;
  final String caution;
  final String category;
  final List<String> tags;
  final LibrarySource source;
  final String status;
  final String statusNote;
  final String publishDate;
  final String effectiveDate;
  final String retrievedAt;
  final String reviewStatus;
}

/// 解析 JSON 文本里的 entries。
List<LibraryEntry> parseLibrary(String jsonText) {
  final data = jsonDecode(jsonText) as Map<String, dynamic>;
  return [for (final e in (data['entries'] as List)) LibraryEntry.fromJson(Map<String, dynamic>.from(e as Map))];
}

/// 审核门禁：[pendingLabel] 是“待审核”的文字，[approvedLabel] 是“已审核”的文字。
List<LibraryEntry> visibleLibraryEntries(
  List<LibraryEntry> all, {
  required bool showPending,
  required String pendingLabel,
  required String approvedLabel,
}) =>
    [
      for (final e in all)
        if (e.reviewStatus == approvedLabel || (showPending && e.reviewStatus == pendingLabel)) e,
    ];

/// 读取并按审核门禁过滤。[loader] 优先（测试用），否则读 [assetPath]。
Future<List<LibraryEntry>> loadVisibleLibrary({
  required LibraryStrings strings,
  String? assetPath,
  Future<String> Function()? loader,
  bool showPending = kShowPendingLibrary,
}) async {
  final text = loader != null ? await loader() : await rootBundle.loadString(assetPath!);
  return visibleLibraryEntries(parseLibrary(text), showPending: showPending, pendingLabel: strings.pendingLabel, approvedLabel: strings.approvedLabel);
}

/// 搜索 + 分类 + 状态筛选。关键词按空格分词，全部命中才算。
List<LibraryEntry> filterLibrary(List<LibraryEntry> entries, {String query = '', String? category, String? status}) {
  final words = query.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  return [
    for (final e in entries)
      if ((category == null || e.category == category) &&
          (status == null || e.status == status) &&
          (words.isEmpty ||
              words.every((w) => [e.title, e.summary, ...e.points, ...e.tags, e.source.title, e.source.docNo, e.source.publisher]
                  .join('\n')
                  .toLowerCase()
                  .contains(w))))
        e,
  ];
}

/// 给子树套上产品自己的正文字体（国内版 Flutter 里英文字体没有汉字，不套的话汉字会走系统回退）。
Widget _withFont(BuildContext context, String? family, Widget child) {
  if (family == null) return child;
  final base = Theme.of(context);
  return Theme(data: base.copyWith(textTheme: base.textTheme.apply(fontFamily: family)), child: child);
}

Color _statusColor(int index) {
  switch (index) {
    case 0:
      return const Color(0xFF2E7D32);
    case 1:
      return const Color(0xFF1565C0);
    case 2:
      return const Color(0xFF757575);
    default:
      return const Color(0xFFEF6C00);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.filled = false});
  final String label;
  final Color color;
  final bool filled;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: filled ? Colors.white : color, fontWeight: FontWeight.w600)),
      );
}

class ReferenceLibraryPage extends StatefulWidget {
  const ReferenceLibraryPage({
    super.key,
    required this.strings,
    this.assetPath,
    this.loader,
    this.showPending = kShowPendingLibrary,
    this.openUrl,
    this.fontFamily,
  });

  final LibraryStrings strings;

  /// 产品自己的正文字体（例如顺时的 NotoSansSC）；不传则沿用主题。
  final String? fontFamily;

  /// 资料 JSON 在 assets 里的路径。
  final String? assetPath;

  /// 测试用：直接提供 JSON 文本（不读 assets）。
  final Future<String> Function()? loader;
  final bool showPending;

  /// 接入了浏览器跳转的产品传入（例如 launchUrl）；不传则只复制链接。
  final Future<void> Function(String url)? openUrl;

  @override
  State<ReferenceLibraryPage> createState() => _ReferenceLibraryPageState();
}

class _ReferenceLibraryPageState extends State<ReferenceLibraryPage> {
  List<LibraryEntry>? _entries;
  Object? _error;
  String _query = '';
  String? _category;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _entries = null;
      _error = null;
    });
    try {
      final visible = await loadVisibleLibrary(strings: widget.strings, assetPath: widget.assetPath, loader: widget.loader, showPending: widget.showPending);
      if (mounted) setState(() => _entries = visible);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return _withFont(
      context,
      widget.fontFamily,
      Scaffold(
        appBar: AppBar(title: Text(s.title)),
        body: Builder(builder: (inner) => SafeArea(child: _body(inner, s))),
      ),
    );
  }

  Widget _body(BuildContext context, LibraryStrings s) {
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(s.loadFailed),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _load, child: Text(s.retry)),
        ]),
      );
    }
    final all = _entries;
    if (all == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(s.loading),
        ]),
      );
    }
    final theme = Theme.of(context);
    final shown = filterLibrary(all, query: _query, category: _category, status: _status);
    final categories = <String, int>{};
    for (final e in all) {
      categories[e.category] = (categories[e.category] ?? 0) + 1;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(s.intro, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
        if (widget.showPending)
          Container(
            key: const Key('library-preview-banner'),
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD54F)),
            ),
            child: Text(s.previewBanner, style: const TextStyle(fontSize: 13, color: Color(0xFF5D4037), height: 1.4)),
          ),
        if (all.isEmpty)
          Container(
            key: const Key('library-empty-review'),
            margin: const EdgeInsets.only(top: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Icon(Icons.fact_check_outlined, size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(s.emptyReviewTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(s.emptyReviewBody, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
            ]),
          )
        else ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('library-search'),
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: s.searchHint,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  key: const Key('library-cat-all'),
                  label: Text('${s.allLabel}（${all.length}）'),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
              ),
              for (final c in categories.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('library-cat-${c.key}'),
                    label: Text('${c.key}（${c.value}）'),
                    selected: _category == c.key,
                    onSelected: (_) => setState(() => _category = c.key),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(label: Text(s.statusAll), selected: _status == null, onSelected: (_) => setState(() => _status = null)),
              ),
              for (var i = 0; i < s.statusLabels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    key: Key('library-status-${s.statusLabels[i]}'),
                    label: Text(s.statusLabels[i]),
                    selected: _status == s.statusLabels[i],
                    onSelected: (_) => setState(() => _status = s.statusLabels[i]),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          Text(s.countLabel(shown.length), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Container(
              key: const Key('library-empty-search'),
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Icon(Icons.search_off, size: 36, color: theme.colorScheme.outline),
                const SizedBox(height: 8),
                Text(s.emptySearchTitle, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(s.emptySearchBody, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ]),
            )
          else
            for (final e in shown) _card(context, s, e),
        ],
        const SizedBox(height: 16),
        Text(s.footer, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
      ],
    );
  }

  Widget _badges(LibraryStrings s, LibraryEntry e) {
    final idx = s.statusLabels.indexOf(e.status);
    return Wrap(spacing: 6, runSpacing: 6, children: [
      _Badge(label: e.category, color: const Color(0xFF3949AB)),
      _Badge(label: e.status, color: _statusColor(idx < 0 ? 3 : idx)),
      if (e.reviewStatus == s.pendingLabel) _Badge(label: s.pendingLabel, color: const Color(0xFFF9A825), filled: true),
    ]);
  }

  Widget _card(BuildContext context, LibraryStrings s, LibraryEntry e) {
    final theme = Theme.of(context);
    return Card(
      key: Key('library-card-${e.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LibraryEntryPage(entry: e, strings: s, openUrl: widget.openUrl, fontFamily: widget.fontFamily))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _badges(s, e),
            const SizedBox(height: 10),
            Text(e.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 6),
            Text(e.summary, maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
            const SizedBox(height: 10),
            Text('${s.sourceLabel}：${e.source.publisher} · ${e.source.title}', maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text('${s.publishedLabel} ${s.formatDate(e.publishDate)} · ${s.retrievedLabel} ${s.formatDate(e.retrievedAt)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

class LibraryEntryPage extends StatelessWidget {
  const LibraryEntryPage({super.key, required this.entry, required this.strings, this.openUrl, this.fontFamily});
  final String? fontFamily;
  final LibraryEntry entry;
  final LibraryStrings strings;
  final Future<void> Function(String url)? openUrl;

  Future<void> _open(BuildContext context, String url) async {
    if (openUrl != null) return openUrl!(url);
    // 没有接入浏览器跳转的产品：复制链接，提示用户粘贴到浏览器打开（不引入额外依赖）。
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.copiedHint)));
    }
  }

  Widget _row(BuildContext context, String k, String v) {
    final theme = Theme.of(context);
    if (v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 92, child: Text(k, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
        Expanded(child: Text(v, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => _withFont(context, fontFamily, Builder(builder: _content));

  Widget _content(BuildContext context) {
    final s = strings;
    final e = entry;
    final theme = Theme.of(context);
    final idx = s.statusLabels.indexOf(e.status);
    final safeUrl = Uri.tryParse(e.source.url);
    final canOpen = safeUrl != null && (safeUrl.scheme == 'https' || safeUrl.scheme == 'http');
    Widget section(String title, Widget child) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            child,
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: Text(s.title)),
      body: SafeArea(
        child: ListView(
          key: const Key('library-detail'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Wrap(spacing: 6, runSpacing: 6, children: [
              _Badge(label: e.category, color: const Color(0xFF3949AB)),
              _Badge(label: e.status, color: _statusColor(idx < 0 ? 3 : idx)),
              if (e.reviewStatus == s.pendingLabel) _Badge(label: s.pendingLabel, color: const Color(0xFFF9A825), filled: true),
            ]),
            const SizedBox(height: 12),
            Text(e.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.3)),
            const SizedBox(height: 10),
            Text(e.summary, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.6)),
            if (e.statusNote.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFCC80))),
                child: Text('${s.statusNoteLabel}：${e.statusNote}', style: const TextStyle(fontSize: 13, color: Color(0xFF5D4037), height: 1.4)),
              ),
            section(
              s.pointsTitle,
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final p in e.points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Padding(padding: EdgeInsets.only(top: 7, right: 8), child: Icon(Icons.circle, size: 5)),
                      Expanded(child: Text(p, style: theme.textTheme.bodyMedium?.copyWith(height: 1.55))),
                    ]),
                  ),
              ]),
            ),
            if (e.plainTip.isNotEmpty) section(s.tipTitle, Text(e.plainTip, style: theme.textTheme.bodyMedium?.copyWith(height: 1.55))),
            if (e.caution.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${s.cautionTitle}：', style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: e.caution),
                ]), style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
              ),
            section(
              s.sourceTitle,
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _row(context, s.fileLabel, e.source.title),
                _row(context, s.publisherLabel, e.source.publisher),
                _row(context, s.docNoLabel, e.source.docNo),
                _row(context, s.publishedLabel, s.formatDate(e.publishDate)),
                _row(context, s.effectiveLabel, e.effectiveDate.isEmpty ? '' : s.formatDate(e.effectiveDate)),
                _row(context, s.retrievedLabel, s.formatDate(e.retrievedAt)),
                _row(context, s.readScopeLabel, e.source.readScope),
                if (e.source.urlNote.isNotEmpty) _row(context, '', e.source.urlNote),
                const SizedBox(height: 4),
                if (canOpen)
                  FilledButton.tonalIcon(
                    key: const Key('library-open-source'),
                    onPressed: () => _open(context, e.source.url),
                    icon: Icon(openUrl != null ? Icons.open_in_new : Icons.copy, size: 18),
                    label: Text(openUrl != null ? s.openSource : s.copyLink),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

/// 入口卡片：只有存在可展示的条目时才出现（没有任何已审核条目时整张卡片隐藏），
/// 避免点进去是一个空页面。
class ReferenceLibraryEntryTile extends StatelessWidget {
  const ReferenceLibraryEntryTile({
    super.key,
    required this.strings,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.assetPath,
    this.loader,
    this.showPending = kShowPendingLibrary,
    this.icon = Icons.menu_book_outlined,
  });

  final LibraryStrings strings;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? assetPath;
  final Future<String> Function()? loader;
  final bool showPending;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LibraryEntry>>(
      future: loadVisibleLibrary(strings: strings, assetPath: assetPath, loader: loader, showPending: showPending),
      builder: (context, snap) {
        final items = snap.data;
        if (items == null || items.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return Card(
          key: const Key('library-entry-tile'),
          elevation: 0,
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Icon(icon, color: theme.colorScheme.primary),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
          ),
        );
      },
    );
  }
}

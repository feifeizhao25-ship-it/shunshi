// 资料库「保持更新 + 为你推荐」的客户端部分（顺时 / 新能源智库 共用的一份实现，各自拷贝到自己的 lib/ 下）。
//
// 数据来自后端（条目 + 展示规则的结论 + 个性化排序）；后端连不上时退回随 App 打包的资料（带「离线内容」提示）。
// 这里只负责展示：谁能显示、怎么提示、为什么推荐，都由后端按同一套规则决定，客户端不自己推断。
import 'package:flutter/material.dart';

/// 后端给每条资料的展示结论（来源是否有变化、是否已废止、核对于哪天、更新说明…）。
class LiveDisplay {
  const LiveDisplay({required this.state, this.banner, this.badges = const [], this.changeNote, this.lastVerifiedAt, this.updatedOn, this.current = true});

  factory LiveDisplay.fromJson(Map<String, dynamic> j) => LiveDisplay(
        state: (j['state'] ?? 'current') as String,
        banner: j['banner'] as String?,
        badges: [for (final b in (j['badges'] as List? ?? const [])) LiveBadge(kind: (b['kind'] ?? '') as String, text: (b['text'] ?? '') as String)],
        changeNote: j['change_note'] as String?,
        lastVerifiedAt: j['last_verified_at'] as String?,
        updatedOn: j['updated_on'] as String?,
        current: (j['current'] ?? true) as bool,
      );

  final String state;
  final String? banner;
  final List<LiveBadge> badges;
  final String? changeNote;
  final String? lastVerifiedAt;
  final String? updatedOn;
  final bool current;
}

class LiveBadge {
  const LiveBadge({required this.kind, required this.text});
  final String kind;
  final String text;
}

class FeedTopic {
  const FeedTopic({required this.id, required this.name, required this.followed, required this.muted});
  final String id;
  final String name;
  final bool followed;
  final bool muted;
}

class FeedItem {
  const FeedItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.reason,
    required this.topicName,
    this.badge,
    this.changeNote,
    this.badges = const [],
    this.publisher = '',
  });

  factory FeedItem.fromJson(Map<String, dynamic> j) => FeedItem(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        summary: (j['summary'] ?? '') as String,
        reason: (j['reason'] ?? '') as String,
        topicName: (j['topic_name'] ?? '') as String,
        badge: j['badge'] as String?,
        changeNote: j['change_note'] as String?,
        badges: [for (final b in (j['badges'] as List? ?? const [])) LiveBadge(kind: (b['kind'] ?? '') as String, text: (b['text'] ?? '') as String)],
        publisher: ((j['source'] as Map?)?['publisher'] ?? '') as String,
      );

  final String id;
  final String title;
  final String summary;
  final String reason;
  final String topicName;
  final String? badge; // 'new' | 'updated' | null：相对你上次来访
  final String? changeNote;
  final List<LiveBadge> badges;
  final String publisher;
}

class LibraryFeed {
  const LibraryFeed({required this.enabled, required this.items, required this.topics, this.note = ''});

  factory LibraryFeed.fromJson(Map<String, dynamic> j) => LibraryFeed(
        enabled: (j['enabled'] ?? true) as bool,
        items: [for (final i in (j['items'] as List? ?? const [])) FeedItem.fromJson(Map<String, dynamic>.from(i as Map))],
        topics: [
          for (final t in (j['topics'] as List? ?? const []))
            FeedTopic(id: t['id'] as String, name: (t['name'] ?? '') as String, followed: (t['followed'] ?? false) as bool, muted: (t['muted'] ?? false) as bool)
        ],
        note: (j['note'] ?? '') as String,
      );

  final bool enabled;
  final List<FeedItem> items;
  final List<FeedTopic> topics;
  final String note;
}

/// 接入后端的函数集合（和个性化首页的 PersonalHomeApi 同一种写法，产品各自接自己的 ApiClient）。
class LibraryLiveApi {
  const LibraryLiveApi({required this.entries, required this.feed, required this.setPrefs, required this.visit, required this.opened});

  /// GET /library/entries：{"entries":[...]}，每条带 display。
  final Future<Map<String, dynamic>> Function() entries;

  /// GET /library/feed。
  final Future<Map<String, dynamic>> Function() feed;

  /// PUT /library/preferences：{enabled?, follow?, unfollow?, mute?, unmute?}。
  final Future<void> Function(Map<String, dynamic> body) setPrefs;

  /// POST /library/visit：记下这次来访（下次来才知道哪些是新的）。
  final Future<void> Function() visit;

  /// POST /library/opened/{id}：读过哪一条（影响之后的排序）。
  final Future<void> Function(String id) opened;
}

/// 页面用到的「保持更新 / 为你推荐」文字。国内版在 library_strings_zh.dart，国际版在 library_strings_en.dart。
class LiveStrings {
  const LiveStrings({
    required this.forYouTitle,
    required this.whyLabel,
    required this.newBadge,
    required this.updatedBadge,
    required this.settingsTitle,
    required this.settingsTooltip,
    required this.switchTitle,
    required this.switchOnHint,
    required this.switchOffTitle,
    required this.switchOffBody,
    required this.topicsTitle,
    required this.topicsHint,
    required this.followAction,
    required this.followedState,
    required this.mutedState,
    required this.muteAction,
    required this.unmuteAction,
    required this.changeNoteLabel,
    required this.offlineNote,
    required this.nothingForYou,
    required this.close,
    required this.saveFailed,
    required this.moreInLibrary,
    this.colon = '：',
  });

  final String forYouTitle;
  final String whyLabel;
  final String newBadge;
  final String updatedBadge;
  final String settingsTitle;
  final String settingsTooltip;
  final String switchTitle;
  final String switchOnHint;
  final String switchOffTitle;
  final String switchOffBody;
  final String topicsTitle;
  final String topicsHint;
  final String followAction;
  final String followedState;
  final String mutedState;
  final String muteAction;
  final String unmuteAction;
  final String changeNoteLabel;
  final String offlineNote;
  final String nothingForYou;
  final String close;
  final String saveFailed;
  final String moreInLibrary;
  final String colon;
}

const Color _amber = Color(0xFFEF6C00);
const Color _teal = Color(0xFF00796B);

class LiveBadgeChip extends StatelessWidget {
  const LiveBadgeChip({super.key, required this.label, required this.color, this.filled = false});
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

/// 状态横幅：来源有更新 / 暂时无法核对 / 超时未核对 / 征求意见稿 / 已废止 …（后端给文字）。
class LiveBanner extends StatelessWidget {
  const LiveBanner({super.key, required this.text, this.repealed = false});
  final String text;
  final bool repealed;

  @override
  Widget build(BuildContext context) {
    final color = repealed ? const Color(0xFFB71C1C) : _amber;
    return Container(
      key: const Key('library-live-banner'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(repealed ? Icons.block : Icons.info_outline, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color, height: 1.4))),
      ]),
    );
  }
}

/// 「为你推荐」：每条写明为什么推荐、相对上次来访是新增还是更新。
class ForYouSection extends StatelessWidget {
  const ForYouSection({super.key, required this.feed, required this.s, required this.onOpen, required this.onSettings});
  final LibraryFeed feed;
  final LiveStrings s;
  final void Function(String id) onOpen;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!feed.enabled) {
      return Container(
        key: const Key('library-foryou-off'),
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(Icons.tune, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(s.switchOffTitle, style: theme.textTheme.bodyMedium)),
          TextButton(onPressed: onSettings, child: Text(s.settingsTitle)),
        ]),
      );
    }
    if (feed.items.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const Key('library-foryou'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(s.forYouTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
          IconButton(key: const Key('library-foryou-settings'), tooltip: s.settingsTooltip, onPressed: onSettings, icon: const Icon(Icons.tune)),
        ]),
        for (final it in feed.items.take(3))
          InkWell(
            key: Key('library-foryou-${it.id}'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => onOpen(it.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  if (it.badge == 'new') LiveBadgeChip(label: s.newBadge, color: _teal, filled: true),
                  if (it.badge == 'updated') LiveBadgeChip(label: s.updatedBadge, color: _amber, filled: true),
                  Text(it.topicName, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ]),
                const SizedBox(height: 4),
                Text(it.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${s.whyLabel}${s.colon}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: it.reason),
                  ]),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                ),
                if (it.badge == 'updated' && (it.changeNote ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${s.changeNoteLabel}${s.colon}${it.changeNote}', style: theme.textTheme.bodySmall?.copyWith(color: _amber, height: 1.4)),
                  ),
              ]),
            ),
          ),
        const SizedBox(height: 2),
        Padding(padding: const EdgeInsets.only(right: 8, bottom: 6), child: Text(feed.note, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4))),
      ]),
    );
  }
}

/// 推荐设置：总开关 + 关注 / 不再推荐某个主题。每次点击立刻保存，失败会提示并恢复。
class LibrarySettingsSheet extends StatefulWidget {
  const LibrarySettingsSheet({super.key, required this.feed, required this.s, required this.api, required this.onChanged});
  final LibraryFeed feed;
  final LiveStrings s;
  final LibraryLiveApi api;
  final Future<void> Function() onChanged;

  @override
  State<LibrarySettingsSheet> createState() => _LibrarySettingsSheetState();
}

class _LibrarySettingsSheetState extends State<LibrarySettingsSheet> {
  late bool _enabled = widget.feed.enabled;
  late final Map<String, String> _state = {for (final t in widget.feed.topics) t.id: t.followed ? 'follow' : t.muted ? 'mute' : ''};
  bool _busy = false;

  Future<void> _save(Map<String, dynamic> body, VoidCallback apply, VoidCallback revert) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      apply();
    });
    try {
      await widget.api.setPrefs(body);
      await widget.onChanged();
    } catch (_) {
      if (mounted) {
        setState(revert);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.s.saveFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.settingsTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('library-pref-switch'),
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            title: Text(s.switchTitle),
            subtitle: Text(_enabled ? s.switchOnHint : s.switchOffBody),
            onChanged: _busy ? null : (v) => _save({'enabled': v}, () => _enabled = v, () => _enabled = !v),
          ),
          if (_enabled) ...[
            const SizedBox(height: 4),
            Text(s.topicsTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(s.topicsHint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in widget.feed.topics)
                GestureDetector(
                  onLongPress: _busy
                      ? null
                      : () {
                          final muted = _state[t.id] == 'mute';
                          final prev = _state[t.id] ?? '';
                          _save(muted ? {'unmute': [t.id]} : {'mute': [t.id]}, () => _state[t.id] = muted ? '' : 'mute', () => _state[t.id] = prev);
                        },
                  child: FilterChip(
                    key: Key('library-topic-${t.id}'),
                    label: Text(_state[t.id] == 'mute' ? '${t.name}·${s.mutedState}' : _state[t.id] == 'follow' ? '${t.name}·${s.followedState}' : t.name),
                    selected: _state[t.id] == 'follow',
                    onSelected: _busy
                        ? null
                        : (v) {
                            final prev = _state[t.id] ?? '';
                            _save(v ? {'follow': [t.id]} : {'unfollow': [t.id]}, () => _state[t.id] = v ? 'follow' : '', () => _state[t.id] = prev);
                          },
                  ),
                ),
            ]),
          ],
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.close))),
        ]),
      ),
    );
  }
}

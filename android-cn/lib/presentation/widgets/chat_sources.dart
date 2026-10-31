import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// One verified source behind a chat answer, as sent by the backend in `source_details`.
class ChatSource {
  const ChatSource({required this.title, this.lastVerifiedAt, this.validUntil, this.freshness = 'current', this.url, this.sourceFile});

  final String title;

  /// ISO date (yyyy-mm-dd) the source was last verified, shown exactly as received.
  final String? lastVerifiedAt;
  final String? validUntil;

  /// "current" or "review_due" (the source expires within 30 days). Expired sources are never sent.
  final String freshness;
  final String? url;
  final String? sourceFile;

  bool get reviewDue => freshness == 'review_due';

  bool get hasSafeLink {
    final u = Uri.tryParse(url ?? '');
    return u != null && (u.scheme == 'https' || u.scheme == 'http') && u.host.isNotEmpty;
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
        if (validUntil != null) 'valid_until': validUntil,
        'freshness': freshness,
        if (url != null) 'url': url,
        if (sourceFile != null) 'source_file': sourceFile,
      };

  static String? _s(dynamic v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

  /// Tolerant parsing: unknown shapes yield an empty list so the plain text sources still show.
  static List<ChatSource> parseAll(dynamic details) {
    if (details is! List) return const [];
    final out = <ChatSource>[];
    for (final d in details) {
      if (d is! Map) continue;
      final title = _s(d['title']);
      if (title == null) continue;
      out.add(ChatSource(
        title: title,
        lastVerifiedAt: _s(d['last_verified_at']) ?? _s(d['reviewed_at']),
        validUntil: _s(d['valid_until']),
        freshness: d['freshness'] == 'review_due' ? 'review_due' : 'current',
        url: _s(d['url']),
        sourceFile: _s(d['source_file']),
      ));
    }
    return out;
  }
}

class _S {
  const _S._();
  static const heading = '资料来源';
  static const official = '官方健康资料';
  static String verified(String d) => '最近核验：$d';
  static String validUntil(String d) => '有效期至 $d';
  static const reviewDueShort = '即将到期，需重新复核';
  static const reviewDue = '这份资料的有效期快到了，需要重新复核；请以官方最新说明为准。';
  static const open = '打开原文';
  static const noDate = '未提供核验日期';
  static const close = '关闭';
}

/// Chips under an answer: source title + "last verified" date + a "review due" tag when relevant.
/// Tapping a chip opens the details (and the original page when the backend sent a web link).
class ChatSourcesBar extends StatelessWidget {
  const ChatSourcesBar({super.key, required this.sources, this.opener});

  final List<ChatSource> sources;

  /// Test hook; defaults to opening the link in the external browser.
  final Future<bool> Function(Uri uri)? opener;

  Future<bool> _open(Uri uri) => (opener ?? (u) => launchUrl(u, mode: LaunchMode.externalApplication))(uri);

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(key: const Key('chat-sources'), crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_S.heading, style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
      const SizedBox(height: 4),
      Wrap(spacing: 8, runSpacing: 6, children: [
        for (var i = 0; i < sources.length; i++)
          Semantics(
            button: true,
            label: '${sources[i].title}. ${sources[i].lastVerifiedAt == null ? _S.noDate : _S.verified(sources[i].lastVerifiedAt!)}${sources[i].reviewDue ? '. ${_S.reviewDueShort}' : ''}',
            excludeSemantics: true,
            child: InkWell(
              key: Key('chat-source-$i'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showDetails(context, sources[i]),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280, minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (sources[i].reviewDue ? scheme.tertiary : scheme.outlineVariant).withValues(alpha: 0.6)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(sources[i].reviewDue ? Icons.schedule_rounded : Icons.verified_outlined, size: 16, color: sources[i].reviewDue ? scheme.tertiary : scheme.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(sources[i].title, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                      if (sources[i].lastVerifiedAt != null)
                        Text(_S.verified(sources[i].lastVerifiedAt!), key: Key('chat-source-verified-$i'), style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                      if (sources[i].reviewDue)
                        Text(_S.reviewDueShort, key: Key('chat-source-due-$i'), style: text.labelSmall?.copyWith(color: scheme.tertiary, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    ]);
  }

  void _showDetails(BuildContext context, ChatSource s) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final text = Theme.of(ctx).textTheme;
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(key: const Key('chat-source-details'), mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(_S.official, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.event_available_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(s.lastVerifiedAt == null ? _S.noDate : _S.verified(s.lastVerifiedAt!), key: const Key('chat-source-detail-verified')),
              ]),
              if (s.validUntil != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.hourglass_bottom_rounded, size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(_S.validUntil(s.validUntil!)),
                ]),
              ],
              if (s.reviewDue) ...[
                const SizedBox(height: 10),
                Container(
                  key: const Key('chat-source-detail-due'),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: scheme.tertiaryContainer.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.schedule_rounded, size: 18, color: scheme.onTertiaryContainer),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_S.reviewDue, style: text.bodySmall?.copyWith(color: scheme.onTertiaryContainer))),
                  ]),
                ),
              ],
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text(_S.close)),
                if (s.hasSafeLink)
                  FilledButton.icon(
                    key: const Key('chat-source-open'),
                    onPressed: () => _open(Uri.parse(s.url!)),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text(_S.open),
                  ),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

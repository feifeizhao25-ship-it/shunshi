// 官方资料库：数据校验 + 审核门禁 + 搜索筛选 + 页面状态（加载、审核中空状态、搜索无结果、详情）。
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/library/reference_library_page.dart';
import 'package:shunshi/presentation/pages/library/shunshi_reference_library.dart';

void main() {
  final raw = File('assets/library/reference_entries_v1.json').readAsStringSync();
  final strings = kShunshiLibraryStrings;
  const statuses = ['现行', '征求意见稿', '已废止', '待核实'];

  group('数据', () {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final entries = (data['entries'] as List).cast<Map<String, dynamic>>();

    test('每条都有出处、文号、状态和日期，状态合法，id 不重复，只收 A 级来源', () {
      expect(entries.length, greaterThanOrEqualTo(10));
      final ids = <String>{};
      for (final e in entries) {
        expect(ids.add(e['id'] as String), isTrue, reason: '重复 id ${e['id']}');
        final s = e['source'] as Map<String, dynamic>;
        expect(statuses, contains(e['status']), reason: '${e['id']} 状态');
        expect(s['url'] as String, matches(RegExp(r'^https?://')), reason: '${e['id']} 链接');
        expect((s['publisher'] as String).isNotEmpty && (s['doc_no'] as String).isNotEmpty && (s['read_scope'] as String).isNotEmpty, isTrue, reason: '${e['id']} 出处信息');
        expect(e['publish_date'] as String, matches(RegExp(r'^\d{4}-\d{2}(-\d{2})?$')));
        expect(e['retrieved_at'] as String, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
        expect(['待审核', '已审核'], contains(e['review_status']));
        expect(s['tier'], 'A');
        expect((e['points'] as List), isNotEmpty);
      }
    });

    test('没有诊断、疗效承诺或处方式用语', () {
      final banned = RegExp(r'(包治|根治|治愈率|一定能|诊断为|处方|剂量)');
      for (final e in entries) {
        final body = jsonEncode({...e, 'caution': '', 'source': '', 'title': ''});
        if (e['id'] == 'ss-lib-002') continue; // 本条是在说明“不得宣称根治”
        expect(banned.hasMatch(body), isFalse, reason: '${e['id']} 含禁用语');
      }
    });
  });

  group('门禁与筛选', () {
    final all = parseLibrary(raw);
    test('默认只显示已审核；预览开关才显示待审核', () {
      final pending = all.where((e) => e.reviewStatus == '待审核').length;
      expect(visibleLibraryEntries(all, showPending: false, pendingLabel: '待审核', approvedLabel: '已审核').length, all.length - pending);
      expect(visibleLibraryEntries(all, showPending: true, pendingLabel: '待审核', approvedLabel: '已审核').length, all.length);
    });
    test('搜索、分类、状态', () {
      expect(filterLibrary(all, query: '运动').isNotEmpty, isTrue);
      expect(filterLibrary(all, query: '完全不存在的词zzz'), isEmpty);
      final cat = all.first.category;
      expect(filterLibrary(all, category: cat).every((e) => e.category == cat), isTrue);
      expect(filterLibrary(all, status: '待核实').every((e) => e.status == '待核实'), isTrue);
    });
  });

  group('页面', () {
    Widget host(Widget child) => MaterialApp(home: child);

    testWidgets('加载中显示提示，加载后显示卡片和待审核标记', (tester) async {
      await tester.pumpWidget(host(ReferenceLibraryPage(strings: strings, loader: () async => raw, showPending: true)));
      expect(find.text('正在加载资料…'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('library-preview-banner')), findsOneWidget);
      expect(find.text('待审核'), findsWidgets);
      expect(find.textContaining('共 12 条'), findsOneWidget);
    });

    testWidgets('没有已审核条目时显示“资料正在审核中”，不显示任何条目', (tester) async {
      await tester.pumpWidget(host(ReferenceLibraryPage(strings: strings, loader: () async => raw, showPending: false)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('library-empty-review')), findsOneWidget);
      expect(find.text('资料正在审核中'), findsOneWidget);
      expect(find.byKey(const Key('library-search')), findsNothing);
    });

    testWidgets('搜索没有结果时显示空状态；清除后恢复', (tester) async {
      await tester.pumpWidget(host(ReferenceLibraryPage(strings: strings, loader: () async => raw, showPending: true)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('library-search')), 'zzzz不存在');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('library-empty-search')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('library-search')), '');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('library-empty-search')), findsNothing);
    });

    testWidgets('点开卡片进入详情：要点、注意、出处和原文链接', (tester) async {
      String? opened;
      await tester.pumpWidget(host(ReferenceLibraryPage(strings: strings, loader: () async => raw, showPending: true, openUrl: (u) async => opened = u)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('library-card-ss-lib-001')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('library-detail')), findsOneWidget);
      expect(find.text('要点'), findsOneWidget);
      await tester.dragUntilVisible(find.byKey(const Key('library-open-source')), find.byKey(const Key('library-detail')), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('library-open-source')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('library-open-source')));
      expect(opened, startsWith('http'));
    });

    testWidgets('加载失败显示重试', (tester) async {
      await tester.pumpWidget(host(ReferenceLibraryPage(strings: strings, loader: () async => throw Exception('x'), showPending: true)));
      await tester.pumpAndSettle();
      expect(find.text('资料加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('入口卡片：没有可展示条目时隐藏，有则显示', (tester) async {
      await tester.pumpWidget(host(Scaffold(body: ReferenceLibraryEntryTile(strings: strings, loader: () async => raw, showPending: false, title: 'a', subtitle: 'b', onTap: () {}))));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('library-entry-tile')), findsNothing);
      await tester.pumpWidget(host(Scaffold(body: ReferenceLibraryEntryTile(strings: strings, loader: () async => raw, showPending: true, title: 'a', subtitle: 'b', onTap: () {}))));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('library-entry-tile')), findsOneWidget);
    });
  });
}

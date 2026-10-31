// 资料库「保持更新 + 为你推荐」：后端结论的展示、推荐理由、新/更新标记、设置和离线退回。
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/library/library_live.dart';
import 'package:shunshi/presentation/pages/library/shunshi_reference_library.dart';

void main() {
  final raw = File('assets/library/reference_entries_v1.json').readAsStringSync();
  final base = (jsonDecode(raw) as Map<String, dynamic>)['entries'] as List;

  Map<String, dynamic> entry(String id, {Map<String, dynamic>? display, String? badge}) {
    final e = Map<String, dynamic>.from(base.firstWhere((x) => x['id'] == id) as Map);
    e['review_status'] = '已审核';
    e['display'] = display ?? {'state': 'current', 'banner': null, 'badges': [{'kind': 'verified', 'text': '2026-11-02 核对'}], 'change_note': null};
    if (badge != null) e['badge'] = badge;
    return e;
  }

  final updated = {
    'state': 'current',
    'banner': null,
    'badges': [
      {'kind': 'verified', 'text': '2026-11-04 核对'},
      {'kind': 'updated', 'text': '更新于 2026-11-04'},
    ],
    'change_note': '第三条的适用人群说明有调整，请以最新版为准。',
  };
  final stale = {'state': 'source_changed', 'banner': '官方原文近期有变动，正在等待人工核对，核对完成前请以官方原文为准。', 'badges': [], 'change_note': null};

  final feedJson = {
    'enabled': true,
    'note': '推荐只用你自己填写的目标、关注的主题和在应用里读过的内容。',
    'topics': [
      {'id': 'food', 'name': '食养', 'followed': false, 'muted': false},
      {'id': 'sleep', 'name': '睡眠', 'followed': true, 'muted': false},
      {'id': 'move', 'name': '运动', 'followed': false, 'muted': true},
    ],
    'items': [
      {'id': 'ss-lib-008', 'title': '睡眠指南', 'summary': 's', 'reason': '你关注了「睡眠」；资料有更新', 'topic_name': '睡眠', 'badge': 'updated', 'change_note': '第三条的适用人群说明有调整。', 'badges': [], 'source': {'publisher': '国家卫健委'}},
      {'id': 'ss-lib-005', 'title': '节气资料', 'summary': 's', 'reason': '现在是小雪前后', 'topic_name': '节气', 'badge': 'new', 'change_note': null, 'badges': [], 'source': {'publisher': '官方'}},
    ],
  };

  late List<Map<String, dynamic>> prefsCalls;
  late Map<String, dynamic> currentFeed;
  late List<String> openedIds;
  var visits = 0;

  LibraryLiveApi api({bool failEntries = false, bool failPrefs = false}) => LibraryLiveApi(
        entries: () async {
          if (failEntries) throw Exception('offline');
          return {
            'entries': [
              entry('ss-lib-008', display: updated, badge: 'updated'),
              entry('ss-lib-005', badge: 'new'),
              entry('ss-lib-003', display: stale),
            ],
          };
        },
        feed: () async => currentFeed,
        setPrefs: (b) async {
          if (failPrefs) throw Exception('x');
          prefsCalls.add(b);
        },
        visit: () async => visits++,
        opened: (id) async => openedIds.add(id),
      );

  setUp(() {
    prefsCalls = [];
    openedIds = [];
    visits = 0;
    currentFeed = Map<String, dynamic>.from(jsonDecode(jsonEncode(feedJson)) as Map);
  });

  Future<void> pump(WidgetTester tester, LibraryLiveApi a) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: ShunshiReferenceLibraryPage(live: a)));
    await tester.pumpAndSettle();
  }

  testWidgets('为你推荐：每条写明理由，标出新增和更新，并记一次来访', (tester) async {
    await pump(tester, api());
    expect(find.byKey(const Key('library-foryou')), findsOneWidget);
    expect(find.text('为你推荐'), findsOneWidget);
    expect(find.textContaining('为什么推荐：你关注了「睡眠」'), findsOneWidget);
    expect(find.textContaining('更新说明：第三条的适用人群说明有调整。'), findsOneWidget);
    expect(find.text('已更新'), findsWidgets);
    expect(find.text('新'), findsWidgets);
    expect(visits, 1);
  });

  testWidgets('来源有变动的条目带横幅；已更新的条目显示“更新于”', (tester) async {
    await pump(tester, api());
    expect(find.byKey(const Key('library-live-banner')), findsOneWidget);
    expect(find.textContaining('官方原文近期有变动'), findsOneWidget);
    expect(find.text('更新于 2026-11-04'), findsOneWidget);
  });

  testWidgets('点推荐卡片进入详情并记录已读；详情里有更新说明', (tester) async {
    await pump(tester, api());
    await tester.tap(find.byKey(const Key('library-foryou-ss-lib-008')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('library-detail')), findsOneWidget);
    expect(find.byKey(const Key('library-change-note')), findsOneWidget);
    expect(openedIds, ['ss-lib-008']);
  });

  testWidgets('设置：关注、不再推荐、总开关，每次都保存；失败会提示并恢复', (tester) async {
    await pump(tester, api());
    await tester.tap(find.byKey(const Key('library-settings')));
    await tester.pumpAndSettle();
    expect(find.text('推荐设置'), findsWidgets);
    await tester.tap(find.byKey(const Key('library-topic-food')));
    await tester.pumpAndSettle();
    expect(prefsCalls.last, {'follow': ['food']});
    await tester.tap(find.byKey(const Key('library-topic-sleep')));
    await tester.pumpAndSettle();
    expect(prefsCalls.last, {'unfollow': ['sleep']});
    await tester.longPress(find.byKey(const Key('library-topic-food')));
    await tester.pumpAndSettle();
    expect(prefsCalls.last, {'mute': ['food']});
    await tester.tap(find.byKey(const Key('library-pref-switch')));
    await tester.pumpAndSettle();
    expect(prefsCalls.last, {'enabled': false});
    expect(find.text('现在不会为你挑选资料，也不会记录你读过什么。随时可以重新打开。'), findsOneWidget);
  });

  testWidgets('设置保存失败：提示并恢复原状', (tester) async {
    await pump(tester, api(failPrefs: true));
    await tester.tap(find.byKey(const Key('library-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('library-pref-switch')));
    await tester.pumpAndSettle();
    expect(find.text('没有保存成功，请稍后再试'), findsOneWidget);
    final sw = tester.widget<SwitchListTile>(find.byKey(const Key('library-pref-switch')));
    expect(sw.value, isTrue);
  });

  testWidgets('关闭个性化后不显示推荐，只留一行说明和入口', (tester) async {
    currentFeed['enabled'] = false;
    currentFeed['items'] = [];
    await pump(tester, api());
    expect(find.byKey(const Key('library-foryou')), findsNothing);
    expect(find.byKey(const Key('library-foryou-off')), findsOneWidget);
    expect(find.text('个性化推荐已关闭'), findsOneWidget);
  });

  testWidgets('后端连不上：退回离线资料并说明，不显示推荐', (tester) async {
    await pump(tester, api(failEntries: true));
    expect(find.byKey(const Key('library-offline-note')), findsOneWidget);
    expect(find.byKey(const Key('library-foryou')), findsNothing);
    expect(visits, 0);
  });
}

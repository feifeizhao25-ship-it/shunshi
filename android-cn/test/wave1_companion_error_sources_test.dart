import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/chat_sources.dart';
import 'package:shunshi/presentation/widgets/companion_session_notice.dart';
import 'package:shunshi/presentation/widgets/empty_state.dart';
import 'package:shunshi/presentation/widgets/error_boundary.dart';

void main() {
  testWidgets('ErrorWidget.builder shows a calm card instead of a red screen', (tester) async {
    AppErrorHandler.init();
    await tester.pumpWidget(ErrorWidget.builder(FlutterErrorDetails(exception: Exception('boom'))));
    expect(find.byKey(const Key('calm-error-card')), findsOneWidget);
    expect(find.byKey(const Key('calm-error-message')), findsOneWidget);
    expect(find.textContaining('返回后再试'), findsOneWidget);
  });

  testWidgets('companion notice names the AI and can show the two-hour reminder', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CompanionSessionNotice(forceReminder: true))));
    expect(find.byKey(const Key('companion-identity')), findsOneWidget);
    expect(find.textContaining('不是真人'), findsOneWidget);
    expect(find.byKey(const Key('companion-duration-reminder')), findsOneWidget);
    expect(find.textContaining('2 小时'), findsOneWidget);
  });

  testWidgets('sources show the knowledge version and a pending source is labelled', (tester) async {
    final sources = ChatSource.parseAll([
      {
        'title': '膳食原则',
        'reviewed_at': '2026-11-01',
        'knowledge_version': 'rag-shunshi@2026.11.06',
        'citation_depth': 'full',
        'excerpt': '食物多样，不写功效。',
        'review_status': '待审核',
      },
    ]);
    expect(sources.single.knowledgeVersion, 'rag-shunshi@2026.11.06');
    expect(sources.single.fullCitation, isTrue);
    expect(sources.single.pendingReview, isTrue);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ChatSourcesBar(sources: sources))));
    expect(find.byKey(const Key('chat-source-version-0')), findsOneWidget);
    expect(find.textContaining('知识版本'), findsOneWidget);
    expect(find.textContaining('最近核验：2026-11-01'), findsOneWidget);
    expect(find.byKey(const Key('chat-source-pending-0')), findsOneWidget);
  });

  testWidgets('loading state explains why and what to do next', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LoadingExplain())));
    expect(find.byKey(const Key('loading-explain')), findsOneWidget);
    expect(find.textContaining('正在加载'), findsOneWidget);
    expect(find.textContaining('返回后再打开'), findsOneWidget);
  });
}

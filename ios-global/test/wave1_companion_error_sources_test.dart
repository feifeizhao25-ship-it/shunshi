import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/widgets/chat_sources.dart';
import 'package:seasons/presentation/widgets/companion_session_notice.dart';
import 'package:seasons/presentation/widgets/empty_state.dart';
import 'package:seasons/presentation/widgets/error_boundary.dart';

void main() {
  testWidgets('ErrorWidget.builder shows a calm card instead of a red screen', (tester) async {
    AppErrorHandler.init();
    await tester.pumpWidget(ErrorWidget.builder(FlutterErrorDetails(exception: Exception('boom'))));
    expect(find.byKey(const Key('calm-error-card')), findsOneWidget);
    expect(find.textContaining('Go back, then try again'), findsOneWidget);
  });

  testWidgets('companion notice names the AI and can show the two-hour reminder', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CompanionSessionNotice(forceReminder: true))));
    expect(find.byKey(const Key('companion-identity')), findsOneWidget);
    expect(find.textContaining('not a person'), findsOneWidget);
    expect(find.byKey(const Key('companion-duration-reminder')), findsOneWidget);
    expect(find.textContaining('two hours'), findsOneWidget);
  });

  testWidgets('sources show the knowledge version, and a full citation includes the excerpt', (tester) async {
    final sources = ChatSource.parseAll([
      {
        'title': 'Sleep',
        'reviewed_at': '2026-10-31',
        'knowledge_version': 'rag-shunshi@2026.11.06',
        'citation_depth': 'full',
        'excerpt': 'Seven or more hours, on a regular schedule.',
        'review_status': 'pending_review',
      },
    ]);
    expect(sources.single.pendingReview, isTrue);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ChatSourcesBar(sources: sources))));
    expect(find.textContaining('Knowledge version'), findsOneWidget);
    expect(find.textContaining('Last verified 2026-10-31'), findsOneWidget);
    expect(find.textContaining('Pending review'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-source-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-source-excerpt')), findsOneWidget);
  });

  testWidgets('loading state explains why and what to do next', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LoadingExplain())));
    expect(find.textContaining('Loading.'), findsOneWidget);
    expect(find.textContaining('go back'), findsOneWidget);
  });
}

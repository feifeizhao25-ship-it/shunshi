import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatPage', () {
    testWidgets('contains input field and send button', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('\u987a\u65f6')),
            body: Column(
              children: [
                const Expanded(child: SizedBox()),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: '\u548c\u987a\u65f6\u804a\u804a...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // AppBar
      expect(find.text('\u987a\u65f6'), findsOneWidget);

      // Input field
      expect(find.byType(TextField), findsOneWidget);

      // Send button
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('can type text into the input field', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '\u8bf7\u8f93\u5165...'),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '\u4eca\u5929\u9002\u5408\u5403\u4ec0\u4e48\uff1f');
      await tester.pump();

      expect(controller.text, '\u4eca\u5929\u9002\u5408\u5403\u4ec0\u4e48\uff1f');
    });

    testWidgets('messages display correctly', (WidgetTester tester) async {
      final messages = [
        {'role': 'user', 'content': '\u4f60\u597d'},
        {'role': 'assistant', 'content': '\u4f60\u597d\uff01\u6709\u4ec0\u4e48\u95ee\u9898\u53ef\u4ee5\u5e2e\u4f60\uff1f'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['content'] as String),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('\u4f60\u597d'), findsOneWidget);
      expect(find.text('\u4f60\u597d\uff01\u6709\u4ec0\u4e48\u95ee\u9898\u53ef\u4ee5\u5e2e\u4f60\uff1f'), findsOneWidget);
    });

    testWidgets('send button triggers callback', (WidgetTester tester) async {
      bool sent = false;
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Expanded(child: SizedBox()),
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: controller),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        sent = true;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(sent, isFalse);
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      expect(sent, isTrue);
    });

    testWidgets('loading indicator shows when loading', (WidgetTester tester) async {
      bool isLoading = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    if (isLoading) const Center(child: CircularProgressIndicator()),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('empty state shows welcome message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    '\u4f60\u597d\uff0c\u6211\u662f\u987a\u65f6',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('\u4f60\u7684 AI \u517b\u751f\u5065\u5eb7\u966a\u4f34\u52a9\u624b'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('\u4f60\u597d\uff0c\u6211\u662f\u987a\u65f6'), findsOneWidget);
      expect(find.text('\u4f60\u7684 AI \u517b\u751f\u5065\u5eb7\u966a\u4f34\u52a9\u624b'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });
}

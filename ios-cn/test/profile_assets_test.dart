import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/data/storage/storage_manager.dart';
import 'package:shunshi/presentation/pages/profile/profile_page_v2.dart';

void main() {
  testWidgets('guest has no fabricated assets or previous constitution', (tester) async {
    SharedPreferences.setMockInitialValues({'constitution_type': '平和质'});
    await StorageManager.init();
    await tester.pumpWidget(const MaterialApp(home: ProfilePageV2()));
    await tester.pumpAndSettle();
    expect(find.text('未登录'), findsWidgets);
    expect(find.text('2560'), findsNothing);
    expect(find.text('3 张'), findsNothing);
    expect(find.textContaining('平和质'), findsNothing);
    expect(find.byIcon(Icons.verified), findsNothing);
    expect(find.text('登录后查看我的收藏与订阅'), findsOneWidget);
  });
}

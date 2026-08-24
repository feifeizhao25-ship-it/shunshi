import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/main.dart';
import 'package:shunshi/data/storage/storage_manager.dart';

void main() {
  testWidgets('App 完整流程测试', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
    // 1. 启动 App
    await tester.pumpWidget(const ShunshiApp());
    await tester.pumpAndSettle();
    
    print('✅ 1. App 启动成功');
    
    // 2. 测试首页
    expect(find.text('顺时'), findsOneWidget);
    print('✅ 2. 首页显示正常');
    
    await tester.pump(const Duration(milliseconds: 1600));
    expect(tester.takeException(), isNull);
  });
}

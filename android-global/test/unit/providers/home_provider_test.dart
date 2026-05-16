import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seasons/presentation/providers/home_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('can be created with baseUrl', () {
      final notifier = HomeNotifier('http://localhost:8000');
      expect(notifier, isNotNull);
    });

    test('initial state has no error', () {
      final notifier = HomeNotifier('http://localhost:8000');
      expect(notifier.state.error, isNull);
    });
  });
}

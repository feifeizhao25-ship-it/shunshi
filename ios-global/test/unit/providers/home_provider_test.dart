import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seasons/presentation/providers/home_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeNotifier', () {
    late HomeNotifier notifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      notifier = HomeNotifier('http://localhost:8000');
    });

    test('initial state is loading', () {
      expect(notifier.state.isLoading, isTrue);
    });

    test('initial state has no error', () {
      expect(notifier.state.error, isNull);
    });

    test('can be created with baseUrl', () {
      expect(notifier, isNotNull);
    });

    test('can refresh data', () async {
      await notifier.loadData();
      // Should complete without throwing
    });
  });
}

// The international login page used to drop the token ("adjust based on GL storage implementation") and called a
// path the server does not have for guests, so every request after "Continue as guest" was anonymous.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seasons/core/network/api_client.dart';
import 'package:seasons/data/storage/storage_manager.dart';
import 'package:seasons/presentation/pages/login/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeClient implements ApiClient {
  final paths = <String>[];
  @override
  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    paths.add(path);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: {'access_token': 'tok-123', 'refresh_token': 'ref-456', 'user': {'id': 'u-1'}} as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  testWidgets('guest login stores the session and opens home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final fake = FakeClient();
    final router = GoRouter(initialLocation: '/login', routes: [
      GoRoute(path: '/login', builder: (c, s) => LoginPage(clientFactory: () => fake)),
      GoRoute(path: '/home', builder: (c, s) => const Scaffold(body: Text('HOME-ROUTE'))),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guest'));
    await tester.pumpAndSettle();
    expect(fake.paths, ['/api/v1/auth/guest-login']);
    expect(find.text('HOME-ROUTE'), findsOneWidget);
    expect(StorageManager.user.getToken(), 'tok-123');
    expect(StorageManager.user.getRefreshToken(), 'ref-456');
    expect(StorageManager.user.isLoggedIn(), isTrue);
  });
}

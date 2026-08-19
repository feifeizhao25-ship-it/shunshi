import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/notifications/local_notifications.dart';
import 'design_system/design_system.dart';
import 'presentation/providers/infrastructure_providers.dart';
import 'presentation/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init local notifications
  await LocalNotifications.init();

  // Init shared preferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const ShunshiApp(),
    ),
  );
}

class ShunshiApp extends StatelessWidget {
  const ShunshiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '顺时',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}

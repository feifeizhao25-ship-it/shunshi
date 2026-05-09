import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'data/storage/storage_manager.dart';
import 'data/services/notification_service.dart';
import 'design_system/theme.dart';
import 'core/theme/app_localizations.dart';
import 'presentation/widgets/error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppErrorHandler.init();

  Future.wait([
    StorageManager.init(),
    NotificationService().init(),
  ]).catchError((Object e) {
    debugPrint('Init error: $e');
    return <void>[];
  });

  runApp(const ProviderScope(child: ShunshiApp()));
}

class ShunshiApp extends StatefulWidget {
  const ShunshiApp({super.key});

  @override
  State<ShunshiApp> createState() => _ShunshiAppState();
}

class _ShunshiAppState extends State<ShunshiApp> {
  final _themeNotifier = ThemeNotifier.instance;

  @override
  void initState() {
    super.initState();
    _themeNotifier.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeNotifier,
      builder: (context, _) {
        return MaterialApp.router(
          routerConfig: AppRouter.router,
          title: 'SEASONS ShunShi',
          debugShowCheckedModeBanner: false,
          theme: ShunShiTheme.lightTheme,
          darkTheme: ShunShiTheme.darkTheme,
          themeMode: _themeNotifier.mode,
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: const [Locale('en'), Locale('ja'), Locale('zh')],
          locale: const Locale('en'),
        );
      },
    );
  }
}

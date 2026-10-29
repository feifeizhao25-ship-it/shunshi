import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'data/storage/storage_manager.dart';
import 'data/services/notification_service.dart';
import 'data/services/wechat_pay_client.dart';
import 'design_system/theme.dart';
import 'presentation/widgets/error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppErrorHandler.init();

  await StorageManager.init();
  Future.wait([
    NotificationService().init(),
    WechatPayClient.initialize(),
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
          title: '顺时',
          debugShowCheckedModeBanner: false,
          theme: ShunShiTheme.lightTheme,
          darkTheme: ShunShiTheme.darkTheme,
          themeMode: _themeNotifier.mode,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            if (media.size.width < 720 || child == null) return child ?? const SizedBox.shrink();
            const frameWidth = 480.0;
            return ColoredBox(
              color: const Color(0xFFE7E0D4),
              child: Center(
                child: MediaQuery(
                  data: media.copyWith(size: Size(frameWidth, media.size.height)),
                  child: SizedBox(width: frameWidth, height: media.size.height, child: child),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

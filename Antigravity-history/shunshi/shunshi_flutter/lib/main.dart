import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/config/env.dart';
import 'presentation/router/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. 初始化配置 (默认从环境变量读取)
  final config = AppConfig.dev();

  // 2. 初始化 Supabase
  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  // 3. 初始化 Sentry & 运行 App
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      const ProviderScope(
        child: ShunShiApp(),
      ),
    ),
  );
}

class ShunShiApp extends ConsumerWidget {
  const ShunShiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '顺时',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: _IosScrollBehavior(),
          child: child!,
        );
      },
      home: const MainShell(),
    );
  }
}

/// 强制使用 iOS 风格的回弹效果，去掉 Android 的 OVERSCROLL 阴影
class _IosScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

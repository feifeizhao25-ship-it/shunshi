import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'data/storage/storage_manager.dart';
import 'data/services/notification_service.dart';
import 'data/network/api_client.dart';
import 'design_system/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 并行初始化，不阻塞启动 — 避免主线程等待导致ANR/黑屏
  Future.wait([
    StorageManager.init(),
    NotificationService().init(),
  ]).catchError((Object e) {
    debugPrint('Init error: $e');
    return <void>[];
  });

  // 注意：offlineSyncService.startAutoSync() 已移至 HomePage.initState 中延迟启动
  // 网络服务单例在首次引用时自动初始化，无需在 main 中主动触发

  runApp(const ProviderScope(child: ShunshiApp()));
}

class ShunshiApp extends StatelessWidget {
  const ShunshiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      title: '顺时 ShunShi',
      debugShowCheckedModeBanner: false,
      theme: ShunShiTheme.lightTheme,
      darkTheme: ShunShiTheme.lightTheme, // TODO: 添加 ShunShiTheme.darkTheme
      themeMode: ThemeMode.system,
    );
  }
}

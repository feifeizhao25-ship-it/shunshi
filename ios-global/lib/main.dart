import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'design_system/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  
  runApp(
    const ProviderScope(
      child: SeasonsApp(),
    ),
  );
}

class SeasonsApp extends StatelessWidget {
  const SeasonsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SEASONS',
      debugShowCheckedModeBanner: false,
      
      // Theme
      theme: SeasonsTheme.lightTheme,
      darkTheme: SeasonsTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      // Router
      routerConfig: AppRouter.router,
    );
  }
}

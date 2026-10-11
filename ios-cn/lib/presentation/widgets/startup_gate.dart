import 'package:flutter/material.dart';

/// Storage is required before routes or receipt listeners may read credentials.
class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.initializeStorage,
    required this.initializeNotifications,
    required this.initializeStore,
    required this.readyBuilder,
  });
  final Future<void> Function() initializeStorage;
  final Future<void> Function() initializeNotifications;
  final Future<void> Function() initializeStore;
  final WidgetBuilder readyBuilder;
  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool _running = false, _ready = false, _failed = false;
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _optional(
    Future<void> Function() initialize,
    String name,
  ) async {
    try {
      await initialize().timeout(const Duration(seconds: 35));
    } catch (_) {
      debugPrint('$name初始化未完成，可稍后重试');
    }
  }

  Future<void> _start() async {
    if (_running) return;
    setState(() {
      _running = true;
      _failed = false;
    });
    try {
      await widget.initializeStorage();
    } catch (_) {
      if (mounted) {
        setState(() {
          _running = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    await Future.wait([
      _optional(widget.initializeNotifications, '通知服务'),
      _optional(widget.initializeStore, '商店服务'),
    ]);
    if (mounted) {
      setState(() {
        _running = false;
        _ready = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.readyBuilder(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F7F3),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '顺时',
                    style: TextStyle(fontSize: 28, color: Color(0xFF205C44)),
                  ),
                  const SizedBox(height: 24),
                  if (_failed) ...[
                    const Text(
                      '本机账号资料暂时无法读取，请重试。',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _start, child: const Text('重新启动')),
                  ] else ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('正在准备账号和服务…'),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// LoadingStateManager — UX_API_SPEC §3 加载态策略
// 200ms 闪烁延迟 / 5 态决策 / 加载文案轮替
import 'dart:async';
import 'package:flutter/material.dart';

// ==================== Loading State Enum (§3.2) ====================

/// 五种加载态
enum LoadingState {
  /// 无加载（正常态）
  idle,
  /// < 300ms: 即时反馈已给，不显示 loading
  instantFeedback,
  /// 100-300ms: 局部 spinner
  microSpinner,
  /// 300ms-1s: 骨架屏
  skeleton,
  /// 1-3s: 全屏 loading + 文案
  fullScreen,
  /// > 3s: 进度条
  progressBar,
}

// ==================== Loading Delay Manager (§3.3) ====================

/// 加载态延迟管理器 — 避免 < 300ms 的闪烁
/// < 200ms 完成: 不显示 loading
/// 200ms+: 开始显示 loading
/// loading 显示后至少 400ms
class LoadingDelayManager {
  bool _isLoading = false;
  bool _showLoading = false;
  Timer? _delayTimer;
  Timer? _minDisplayTimer;
  final int _delayMs;
  final int _minDisplayMs;
  final VoidCallback? onStateChanged;

  LoadingDelayManager({
    int delayMs = 200,
    int minDisplayMs = 400,
    this.onStateChanged,
  })  : _delayMs = delayMs,
        _minDisplayMs = minDisplayMs;

  bool get showLoading => _showLoading;
  bool get isLoading => _isLoading;

  /// 开始加载
  void startLoading() {
    if (_isLoading) return;
    _isLoading = true;

    _delayTimer?.cancel();
    _delayTimer = Timer(Duration(milliseconds: _delayMs), () {
      if (_isLoading) {
        _showLoading = true;
        onStateChanged?.call();
      }
    });
  }

  /// 结束加载
  void stopLoading() {
    _isLoading = false;
    _delayTimer?.cancel();

    if (_showLoading) {
      // 保证至少显示 _minDisplayMs
      _minDisplayTimer?.cancel();
      _minDisplayTimer = Timer(Duration(milliseconds: _minDisplayMs), () {
        _showLoading = false;
        onStateChanged?.call();
      });
    } else {
      // 还没显示就完成了 → 不显示
      _showLoading = false;
    }
  }

  /// 重置（取消所有定时器）
  void reset() {
    _isLoading = false;
    _showLoading = false;
    _delayTimer?.cancel();
    _minDisplayTimer?.cancel();
  }

  void dispose() {
    _delayTimer?.cancel();
    _minDisplayTimer?.cancel();
  }
}

// ==================== Loading Text Rotator (§3.2.4) ====================

/// 全屏 loading 文案轮替 — 每秒切换
class LoadingTextRotator extends ChangeNotifier {
  int _currentIndex = 0;
  Timer? _timer;
  final List<String> _texts;

  LoadingTextRotator({
    List<String>? texts,
  }) : _texts = texts ?? _defaultTexts;

  static const _defaultTexts = [
    '加载中...',
    '请稍候，马上完成...',
    '网络较慢，仍在处理...',
  ];

  String get currentText => _texts[_currentIndex % _texts.length];

  /// 开始轮替
  void start() {
    _currentIndex = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _currentIndex++;
      notifyListeners();
    });
    notifyListeners();
  }

  /// 停止
  void stop() {
    _timer?.cancel();
    _currentIndex = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ==================== Loading State Decision (§3.1) ====================

/// 加载态决策工具 — 根据 API 速度级别决定用哪种加载态
class LoadingStateDecider {
  /// 根据速度级别获取默认加载态
  static LoadingState fromSpeedLevel(String level) {
    switch (level) {
      case 's0':
        return LoadingState.instantFeedback; // < 100ms, 只需即时反馈
      case 's1':
        return LoadingState.skeleton; // < 300ms, 骨架屏
      case 's2':
        return LoadingState.skeleton; // < 600ms, 骨架屏
      case 's3':
        return LoadingState.fullScreen; // AI, 全屏+文案
      case 's4':
        return LoadingState.progressBar; // 上传, 进度条
      default:
        return LoadingState.skeleton;
    }
  }

  /// 根据耗时获取加载态
  static LoadingState fromDuration(Duration elapsed) {
    final ms = elapsed.inMilliseconds;
    if (ms < 100) return LoadingState.instantFeedback;
    if (ms < 300) return LoadingState.microSpinner;
    if (ms < 1000) return LoadingState.skeleton;
    if (ms < 3000) return LoadingState.fullScreen;
    return LoadingState.progressBar;
  }
}

// ==================== Scene-specific Loading Texts (§3.4) ====================

/// 各场景的 loading 文案
class LoadingTexts {
  static const general = ['加载中...', '请稍候，马上完成...', '网络较慢，仍在处理...'];
  static const aiThinking = ['AI 正在思考...', '正在为您整理...', 'AI 正在生成回答...'];
  static const quizAnalyzing = ['正在分析您的体质...', '匹配 24 节气养生方案...', '生成专属推荐...'];
  static const paymentProcessing = ['处理支付中，请勿离开...'];
  static const uploading = ['上传中...', '正在处理图片...', '即将完成...'];
  static const syncing = ['正在同步...', '同步中，请稍候...'];
  static const refreshing = ['正在刷新...', '获取最新数据...'];

  /// 根据 API 端点获取场景文案
  static List<String> forEndpoint(String endpoint) {
    if (endpoint.contains('chat')) return aiThinking;
    if (endpoint.contains('quiz')) return quizAnalyzing;
    if (endpoint.contains('payment')) return paymentProcessing;
    if (endpoint.contains('upload')) return uploading;
    if (endpoint.contains('sync')) return syncing;
    return general;
  }
}

// ==================== Widget: DelayedLoadingBuilder ====================

/// 延迟加载 Widget — 封装 §3.3 闪烁延迟逻辑
class DelayedLoadingBuilder extends StatefulWidget {
  final bool isLoading;
  final WidgetBuilder loadingBuilder;
  final WidgetBuilder? loadedBuilder;
  final Widget child;
  final int delayMs;
  final int minDisplayMs;

  const DelayedLoadingBuilder({
    super.key,
    required this.isLoading,
    required this.loadingBuilder,
    this.loadedBuilder,
    required this.child,
    this.delayMs = 200,
    this.minDisplayMs = 400,
  });

  @override
  State<DelayedLoadingBuilder> createState() => _DelayedLoadingBuilderState();
}

class _DelayedLoadingBuilderState extends State<DelayedLoadingBuilder> {
  late LoadingDelayManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = LoadingDelayManager(
      delayMs: widget.delayMs,
      minDisplayMs: widget.minDisplayMs,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    if (widget.isLoading) _manager.startLoading();
  }

  @override
  void didUpdateWidget(DelayedLoadingBuilder old) {
    super.didUpdateWidget(old);
    if (widget.isLoading != old.isLoading) {
      if (widget.isLoading) {
        _manager.startLoading();
      } else {
        _manager.stopLoading();
      }
    }
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_manager.showLoading) {
      return widget.loadingBuilder(context);
    }
    if (widget.loadedBuilder != null) {
      return widget.loadedBuilder!(context);
    }
    return widget.child;
  }
}

// ==================== Widget: FullScreenLoading (§3.2.4) ====================

/// 全屏 Loading — 带文案轮替
class FullScreenLoading extends StatefulWidget {
  final List<String> texts;
  final VoidCallback? onCancel;
  final bool showCancelButton;

  const FullScreenLoading({
    super.key,
    this.texts = LoadingTexts.general,
    this.onCancel,
    this.showCancelButton = false,
  });

  @override
  State<FullScreenLoading> createState() => _FullScreenLoadingState();
}

class _FullScreenLoadingState extends State<FullScreenLoading> {
  late LoadingTextRotator _rotator;

  @override
  void initState() {
    super.initState();
    _rotator = LoadingTextRotator(texts: widget.texts);
    _rotator.addListener(() {
      if (mounted) setState(() {});
    });
    _rotator.start();
  }

  @override
  void dispose() {
    _rotator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            _rotator.currentText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
          if (widget.showCancelButton) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: widget.onCancel,
              child: const Text('取消'),
            ),
          ],
        ],
      ),
    );
  }
}

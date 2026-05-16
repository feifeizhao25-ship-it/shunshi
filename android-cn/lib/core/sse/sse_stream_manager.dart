// SSE Stream Manager — UX_API_SPEC §7 流式响应
// 批量 token 更新(50ms) / 首字超时检测 / 中断恢复 / 模型降级链
import 'dart:async';
import 'dart:convert';

// ==================== SSE Events ====================

/// SSE 事件类型
enum SSEEventType { start, token, card, meta, done, error }

/// 解析后的 SSE 事件
class SSEEvent {
  final SSEEventType type;
  final Map<String, dynamic>? data;

  const SSEEvent({required this.type, this.data});

  @override
  String toString() => 'SSEEvent($type, $data)';
}

// ==================== SSE Parser ====================

/// SSE 协议解析器 — 解析 event: / data: 行
class SSEParser {
  /// 解析原始 SSE 文本块为事件列表
  static List<SSEEvent> parse(String chunk) {
    final events = <SSEEvent>[];
    final lines = chunk.split('\n');
    String? currentEvent;
    String? currentData;

    for (final line in lines) {
      if (line.startsWith('event: ')) {
        currentEvent = line.substring(7).trim();
      } else if (line.startsWith('data: ')) {
        currentData = line.substring(6).trim();
      } else if (line.isEmpty && currentEvent != null && currentData != null) {
        // 空行 = 事件结束
        final eventType = _mapEventType(currentEvent);
        Map<String, dynamic>? data;
        try {
          data = jsonDecode(currentData) as Map<String, dynamic>;
        } catch (_) {
          data = null;
        }
        events.add(SSEEvent(type: eventType, data: data));
        currentEvent = null;
        currentData = null;
      }
    }

    return events;
  }

  static SSEEventType _mapEventType(String event) {
    switch (event) {
      case 'start':
        return SSEEventType.start;
      case 'token':
        return SSEEventType.token;
      case 'card':
        return SSEEventType.card;
      case 'meta':
        return SSEEventType.meta;
      case 'done':
        return SSEEventType.done;
      case 'error':
        return SSEEventType.error;
      default:
        return SSEEventType.token;
    }
  }
}

// ==================== Token Buffer (§7.3) ====================

/// Token 批量缓冲 — 累积 50ms 内的所有 token，一次性更新 UI
class TokenBuffer {
  final Duration flushInterval;
  String _buffer = '';
  Timer? _flushTimer;
  final void Function(String accumulated) onFlush;

  TokenBuffer({
    this.flushInterval = const Duration(milliseconds: 50),
    required this.onFlush,
  });

  /// 追加 token
  void append(String delta) {
    _buffer += delta;

    // 如果没有待执行的 flush，启动定时器
    _flushTimer ??= Timer(flushInterval, _flush);
  }

  void _flush() {
    if (_buffer.isNotEmpty) {
      onFlush(_buffer);
      _buffer = '';
    }
    _flushTimer = null;
  }

  /// 强制 flush（流结束时调用）
  void forceFlush() {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_buffer.isNotEmpty) {
      onFlush(_buffer);
      _buffer = '';
    }
  }

  void clear() {
    _buffer = '';
    _flushTimer?.cancel();
    _flushTimer = null;
  }
}

// ==================== Chat Stream State Machine (§7.1) ====================

/// 流式对话状态
enum ChatStreamState {
  idle,
  connecting,
  streaming,
  completed,
  error,
  cancelled,
}

/// 流式对话管理器
class ChatStreamManager {
  ChatStreamState _state = ChatStreamState.idle;
  String _messageId = '';
  String _model = '';
  String _content = '';
  final List<Map<String, dynamic>> _cards = [];
  int _totalTokens = 0;
  int _durationMs = 0;
  String? _errorMessage;

  // 首字超时检测 (§7.2: p95 < 1500ms)
  Timer? _firstTokenTimer;
  static const _firstTokenTimeout = Duration(milliseconds: 3000);

  // 后台超时 (§7.5: 30s)
  Timer? _backgroundTimer;
  static const _backgroundTimeout = Duration(seconds: 30);

  // Token 缓冲 (§7.3: 50ms batch)
  late final TokenBuffer _tokenBuffer;

  // 事件流
  final _stateController = StreamController<ChatStreamState>.broadcast();
  final _contentController = StreamController<String>.broadcast();
  final _cardsController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ChatStreamState> get stateStream => _stateController.stream;
  Stream<String> get contentStream => _contentController.stream;
  Stream<Map<String, dynamic>> get cardsStream => _cardsController.stream;

  ChatStreamState get state => _state;
  String get content => _content;
  List<Map<String, dynamic>> get cards => List.unmodifiable(_cards);
  String get messageId => _messageId;
  String? get errorMessage => _errorMessage;

  ChatStreamManager() {
    _tokenBuffer = TokenBuffer(
      flushInterval: const Duration(milliseconds: 50),
      onFlush: _onTokenFlush,
    );
  }

  /// 开始新对话
  void startConnection() {
    _reset();
    _setState(ChatStreamState.connecting);

    // 首字超时检测
    _firstTokenTimer = Timer(_firstTokenTimeout, () {
      if (_state == ChatStreamState.connecting) {
        _errorMessage = 'AI 首字超时，请重试';
        _setState(ChatStreamState.error);
      }
    });

    // 后台超时
    _backgroundTimer = Timer(_backgroundTimeout, () {
      if (_state == ChatStreamState.streaming || _state == ChatStreamState.connecting) {
        cancel();
      }
    });
  }

  /// 处理 SSE 事件
  void handleEvent(SSEEvent event) {
    switch (event.type) {
      case SSEEventType.start:
        _firstTokenTimer?.cancel();
        _messageId = event.data?['message_id'] as String? ?? '';
        _model = event.data?['model'] as String? ?? '';
        _setState(ChatStreamState.streaming);

      case SSEEventType.token:
        final delta = event.data?['delta'] as String? ?? '';
        _tokenBuffer.append(delta);

      case SSEEventType.card:
        // §7.6: 卡片在文字结束后流入
        final card = event.data;
        if (card != null) {
          _cards.add(card);
          _cardsController.add(card);
        }

      case SSEEventType.meta:
        // 引用信息，暂存
        break;

      case SSEEventType.done:
        _tokenBuffer.forceFlush();
        _totalTokens = event.data?['total_tokens'] as int? ?? 0;
        _durationMs = event.data?['duration_ms'] as int? ?? 0;
        _cleanup();
        _setState(ChatStreamState.completed);

      case SSEEventType.error:
        _errorMessage = event.data?['message'] as String? ?? '未知错误';
        _cleanup();
        _setState(ChatStreamState.error);
    }
  }

  /// Token flush 回调
  void _onTokenFlush(String accumulated) {
    _content += accumulated;
    _contentController.add(accumulated);
  }

  /// 用户主动取消
  void cancel() {
    _tokenBuffer.forceFlush();
    _cleanup();
    _setState(ChatStreamState.cancelled);
  }

  /// 处理网络中断
  void handleNetworkError() {
    if (_state == ChatStreamState.connecting) {
      // 首字前断网 → 标记用户消息失败
      _errorMessage = '网络连接失败，请检查网络';
      _cleanup();
      _setState(ChatStreamState.error);
    } else if (_state == ChatStreamState.streaming) {
      // 流式中断 → 保留已生成内容，标记中断
      _tokenBuffer.forceFlush();
      _errorMessage = '连接中断，已生成部分内容';
      _cleanup();
      _setState(ChatStreamState.error);
    }
  }

  void _setState(ChatStreamState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  void _cleanup() {
    _firstTokenTimer?.cancel();
    _backgroundTimer?.cancel();
    _tokenBuffer.clear();
  }

  void _reset() {
    _state = ChatStreamState.idle;
    _messageId = '';
    _model = '';
    _content = '';
    _cards.clear();
    _totalTokens = 0;
    _durationMs = 0;
    _errorMessage = null;
  }

  void dispose() {
    _cleanup();
    _stateController.close();
    _contentController.close();
    _cardsController.close();
  }
}

// ==================== Model Fallback Chain (§7.4) ====================

/// 模型降级链
class ModelFallbackChain {
  final List<String> models;
  int _currentModelIndex = 0;

  ModelFallbackChain({required this.models});

  String get currentModel => models[_currentModelIndex];
  bool get hasFallback => _currentModelIndex < models.length - 1;

  /// 降级到下一个模型
  String? fallback() {
    if (!hasFallback) return null;
    _currentModelIndex++;
    return currentModel;
  }

  /// 重置到首选模型
  void reset() {
    _currentModelIndex = 0;
  }

  /// 顺时 CN 降级链
  static ModelFallbackChain get cnDefault => ModelFallbackChain(models: [
    'qwen-plus',
    'qwen-turbo',
  ]);

  /// SEASONS Global 降级链
  static ModelFallbackChain get globalDefault => ModelFallbackChain(models: [
    'gpt-4o',
    'gpt-4o-mini',
    'claude-3.5-sonnet',
  ]);
}

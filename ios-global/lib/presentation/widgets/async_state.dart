import 'package:flutter/material.dart';

/// 状态封装
enum LoadingState { initial, loading, loaded, error, empty }

/// 异步状态 Widget
class AsyncStateWidget<T> extends StatelessWidget {
  final LoadingState state;
  final Widget? data;
  final String? errorMessage;
  final Widget Function(String error)? errorBuilder;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final Widget? child;
  
  const AsyncStateWidget({
    super.key,
    required this.state,
    this.data,
    this.errorMessage,
    this.errorBuilder,
    this.loadingWidget,
    this.emptyWidget,
    this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    switch (state) {
      case LoadingState.loading:
        return loadingWidget ?? _buildLoading();
      case LoadingState.error:
        return errorBuilder?.call(errorMessage ?? '加载失败') ?? _buildError();
      case LoadingState.empty:
        return emptyWidget ?? _buildEmpty();
      case LoadingState.loaded:
      case LoadingState.initial:
        return child ?? data ?? const SizedBox();
    }
  }
  
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(errorMessage ?? '加载失败'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无数据'),
        ],
      ),
    );
  }
}

/// 页面状态管理
class PageState {
  LoadingState state = LoadingState.initial;
  String? errorMessage;
  
  void setLoading() => state = LoadingState.loading;
  void setLoaded() => state = LoadingState.loaded;
  void setError(String message) {
    state = LoadingState.error;
    errorMessage = message;
  }
  void setEmpty() => state = LoadingState.empty;
  
  bool get isLoading => state == LoadingState.loading;
  bool get isLoaded => state == LoadingState.loaded;
  bool get isError => state == LoadingState.error;
  bool get isEmpty => state == LoadingState.empty;
}

/// 简化版 FutureBuilder
class FutureLoadWrapper<T> extends StatefulWidget {
  final Future<T> Function() future;
  final Widget Function(T data) builder;
  final Widget? loading;
  final Widget? error;
  
  const FutureLoadWrapper({
    super.key,
    required this.future,
    required this.builder,
    this.loading,
    this.error,
  });
  
  @override
  State<FutureLoadWrapper<T>> createState() => _FutureLoadWrapperState<T>();
}

class _FutureLoadWrapperState<T> extends State<FutureLoadWrapper<T>> {
  late Future<T> _future;
  
  @override
  void initState() {
    super.initState();
    _future = widget.future();
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loading ?? const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return widget.error ?? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text('${snapshot.error}'),
              ],
            ),
          );
        }
        
        return widget.builder(snapshot.data as T);
      },
    );
  }
}

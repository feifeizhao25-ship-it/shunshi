import 'package:flutter/material.dart';

/// 懒加载列表 - 适用于大量数据
class LazyListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget Function(BuildContext)? separatorBuilder;
  final Future<void Function()> Function()? loadMore;
  final bool hasMore;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final double? itemExtent;
  final EdgeInsets? padding;
  
  const LazyListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.separatorBuilder,
    this.loadMore,
    this.hasMore = true,
    this.loadingWidget,
    this.errorWidget,
    this.itemExtent,
    this.padding,
  });
  
  @override
  State<LazyListView<T>> createState() => _LazyListViewState<T>();
}

class _LazyListViewState<T> extends State<LazyListView<T>> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_isLoading || !widget.hasMore) return;
    
    // 距离底部 200px 时加载更多
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }
  
  Future<void> _loadMore() async {
    if (_isLoading || widget.loadMore == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await widget.loadMore!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.items.length + (_isLoading ? 1 : 0),
      itemExtent: widget.itemExtent,
      padding: widget.padding,
      itemBuilder: (context, index) {
        // 加载更多指示器
        if (index == widget.items.length) {
          return widget.loadingWidget ??
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
        }
        
        final item = widget.items[index];
        Widget child = widget.itemBuilder(context, item, index);
        
        // 分隔符
        if (index < widget.items.length - 1 && widget.separatorBuilder != null) {
          child = Column(
            children: [
              child,
              widget.separatorBuilder!(context),
            ],
          );
        }
        
        return child;
      },
    );
  }
}

/// 分页控制器
class PaginationController<T> {
  List<T> items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  int get page => _page;
  
  Future<List<T>> Function(int page)? _fetchPage;
  
  void setFetchCallback(Future<List<T>> Function(int page) callback) {
    _fetchPage = callback;
  }
  
  Future<void> loadFirst() async {
    if (_isLoading) return;
    
    _page = 1;
    _isLoading = true;
    
    try {
      final newItems = await _fetchPage!(_page);
      items = newItems;
      _hasMore = newItems.length >= 20; // 假设每页20条
      _page++;
    } finally {
      _isLoading = false;
    }
  }
  
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    
    _isLoading = true;
    
    try {
      final newItems = await _fetchPage!(_page);
      items.addAll(newItems);
      _hasMore = newItems.length >= 20;
      _page++;
    } finally {
      _isLoading = false;
    }
  }
  
  void reset() {
    items = [];
    _page = 1;
    _hasMore = true;
    _isLoading = false;
  }
}

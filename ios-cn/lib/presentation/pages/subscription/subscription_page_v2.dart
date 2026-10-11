import 'package:flutter/material.dart';
import '../../../data/network/api_client.dart';
import '../../../data/models/subscription.dart';
import '../../../data/services/store_service.dart';

class SubscriptionPageV2 extends StatefulWidget {
  const SubscriptionPageV2({
    super.key,
    this.loadStatus,
    this.loadPrices,
    this.purchase,
    this.restore,
  });
  final Future<UserSubscriptionStatus> Function()? loadStatus;
  final Future<Map<String, String>> Function()? loadPrices;
  final Future<bool> Function(String)? purchase;
  final Future<RestoreResult> Function()? restore;
  @override
  State<SubscriptionPageV2> createState() => _SubscriptionPageV2State();
}

class _SubscriptionPageV2State extends State<SubscriptionPageV2>
    with WidgetsBindingObserver {
  static const _plans = {
    'yiyang_monthly': '颐养版月付',
    'yiyang_yearly': '颐养版年付',
    'family_yearly': '家和版年付',
  };
  UserSubscriptionStatus? _status;
  Map<String, String> _prices = {};
  bool _loading = true, _busy = false;
  String? _error, _notice;
  String _selected = 'yiyang_yearly';
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  Future<UserSubscriptionStatus> _fetchStatus() async {
    final body = (await ApiClient().get('/api/v1/subscription/status')).data;
    if (body is! Map || body['success'] != true || body['data'] is! Map) {
      throw StateError('会员状态响应无效');
    }
    return UserSubscriptionStatus.fromJson(
      Map<String, dynamic>.from(body['data']),
    );
  }

  Future<Map<String, String>> _fetchPrices() async {
    final store = StoreService();
    await store.refreshProducts();
    return {
      for (final id in _plans.keys)
        if (store.getProductDetails(id) != null)
          id: store.getProductDetails(id)!.price,
    };
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await (widget.loadStatus ?? _fetchStatus)();
      Map<String, String> prices;
      try {
        prices = await (widget.loadPrices ?? _fetchPrices)();
      } catch (_) {
        prices = {};
      }
      if (!mounted || generation != _generation) return;
      setState(() {
        _status = status;
        _prices = prices;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _status = null;
        _prices = {};
        _loading = false;
        _error = '会员状态暂时无法查询，请检查网络后重试';
      });
    }
  }

  Future<void> _purchase() async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final launched = await (widget.purchase ?? StoreService().purchase)(
        _selected,
      );
      if (!mounted) return;
      setState(
        () => _notice = launched
            ? '购买请求已提交。完成支付后请刷新状态，以服务端核验结果为准。'
            : '未能发起购买，请稍后重试。',
      );
    } catch (_) {
      if (mounted) setState(() => _notice = '购买请求失败，请稍后重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _notice = '已请求恢复购买。请等待商店返回记录，再刷新会员状态。';
    });
    try {
      final result =
          await (widget.restore ?? StoreService().restorePurchases)();
      if (!mounted) return;
      setState(() => _notice = result.message);
      if (mounted) await _reload();
    } catch (_) {
      if (mounted) setState(() => _notice = '恢复购买请求失败，请稍后重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paid = _status?.isActive == true && _status?.planId != 'free';
    final expiry = _status?.expiresAt?.toLocal();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        title: const Text('会员中心'),
        actions: [
          IconButton(
            tooltip: '刷新会员状态',
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF205C44),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('当前会员状态', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Text(
                  _loading
                      ? '正在查询…'
                      : _error != null
                      ? '暂时无法查询'
                      : paid
                      ? _status!.planName
                      : '免费版',
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  paid && !_loading && _error == null && expiry != null
                      ? '有效期至 ${expiry.year}年${expiry.month}月${expiry.day}日'
                      : '会员权益以服务端确认结果为准',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_error!),
            ),
            OutlinedButton(onPressed: _reload, child: const Text('重新查询')),
          ],
          const SizedBox(height: 24),
          const Text(
            '选择适合您的套餐',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          for (final plan in _plans.entries)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(plan.value),
                subtitle: Text(_prices[plan.key] ?? '商店价格暂不可用'),
                trailing: Icon(
                  _selected == plan.key
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                onTap: _busy || _loading || !_prices.containsKey(plan.key)
                    ? null
                    : () => setState(() => _selected = plan.key),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            '价格由苹果商店提供，金额、订阅周期及续订条件请在购买确认页核对。您可在苹果账户的订阅设置中管理订阅。',
            style: TextStyle(height: 1.6, color: Color(0xFF58645D)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed:
                _busy ||
                    _loading ||
                    _error != null ||
                    !_prices.containsKey(_selected)
                ? null
                : _purchase,
            child: Text(_busy ? '正在处理…' : '前往商店确认购买'),
          ),
          OutlinedButton(
            onPressed: _busy || _loading ? null : _restore,
            child: const Text('恢复购买'),
          ),
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_notice!, style: const TextStyle(height: 1.6)),
            ),
          const SizedBox(height: 12),
          const Text(
            '更换设备后，请使用原购买所用的苹果账户恢复购买。未完成核验的订单不会在本页显示为已开通。',
            style: TextStyle(height: 1.6, color: Color(0xFF58645D)),
          ),
        ],
      ),
    );
  }
}

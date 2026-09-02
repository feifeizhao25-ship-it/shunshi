import 'package:flutter/foundation.dart';
import 'package:fluwx/fluwx.dart';

/// 微信 App 支付桥接。签名参数只能来自后端微信支付 V3 下单结果。
class WechatPayClient {
  WechatPayClient._();

  static final Fluwx _fluwx = Fluwx();
  static const String _appId = String.fromEnvironment('WECHAT_APP_ID');
  static bool _registered = false;

  static Future<void> initialize() async {
    if (kIsWeb || _appId.isEmpty || _registered) return;
    _registered = await _fluwx.registerApi(
      appId: _appId,
      doOnAndroid: true,
      doOnIOS: false,
    );
  }

  static Future<bool> pay(Map<String, dynamic> params) async {
    if (kIsWeb) return false;
    await initialize();
    if (!_registered || !await _fluwx.isWeChatInstalled) return false;
    const required = <String>{
      'appid',
      'partnerid',
      'prepayid',
      'package',
      'noncestr',
      'timestamp',
      'sign',
    };
    if (!required.every((key) => params[key]?.toString().isNotEmpty == true)) {
      return false;
    }
    if (params['appid'] != _appId) return false;
    final timestamp = int.tryParse(params['timestamp'].toString());
    if (timestamp == null) return false;
    return _fluwx.pay(
      which: Payment(
        appId: params['appid'].toString(),
        partnerId: params['partnerid'].toString(),
        prepayId: params['prepayid'].toString(),
        packageValue: params['package'].toString(),
        nonceStr: params['noncestr'].toString(),
        timestamp: timestamp,
        sign: params['sign'].toString(),
      ),
    );
  }
}

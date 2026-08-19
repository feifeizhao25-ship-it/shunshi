/// 业务失败基类
abstract class Failure {
  final String message;
  final String? code;
  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure($code: $message)';
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {super.code, this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = '网络连接失败，请检查网络设置'])
      : super(message, code: 'NETWORK_ERROR');
}

class CacheFailure extends Failure {
  const CacheFailure([String message = '本地缓存异常']) : super(message, code: 'CACHE_ERROR');
}

class SchemaFailure extends Failure {
  const SchemaFailure([String message = 'AI 响应格式异常，已使用降级内容'])
      : super(message, code: 'SCHEMA_ERROR');
}

class AuthFailure extends Failure {
  const AuthFailure([String message = '认证失败，请重新登录'])
      : super(message, code: 'AUTH_ERROR');
}

class SubscriptionFailure extends Failure {
  const SubscriptionFailure([String message = '订阅操作失败'])
      : super(message, code: 'SUBSCRIPTION_ERROR');
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([String message = '请求超时，请稍后重试'])
      : super(message, code: 'TIMEOUT_ERROR');
}

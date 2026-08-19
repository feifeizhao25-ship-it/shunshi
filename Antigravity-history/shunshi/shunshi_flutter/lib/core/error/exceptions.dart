/// 数据层异常
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  const ServerException(this.message, {this.statusCode, this.code});

  @override
  String toString() => 'ServerException($statusCode: $message)';
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = '缓存异常']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = '网络不可用']);
}

class SchemaParseException implements Exception {
  final String message;
  final dynamic rawData;
  const SchemaParseException(this.message, {this.rawData});
}

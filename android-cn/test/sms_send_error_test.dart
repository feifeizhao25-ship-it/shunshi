import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/network/sms_send_error.dart';

void main() {
  test('a 503 from the catalog is shown as the catalog sentence', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/api/v1/auth/sms/send'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/v1/auth/sms/send'),
        statusCode: 503,
        data: {'detail': {'detail': '短信服务尚未配置', 'configured': false}},
      ),
    );
    expect(smsSendError(error), '短信服务尚未配置');
  });

  test('any other failure stays the generic retry sentence', () {
    expect(smsSendError(Exception('offline')), '发送失败，请稍后重试');
  });
}

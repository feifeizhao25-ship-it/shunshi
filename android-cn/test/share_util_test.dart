import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/share_util.dart';

Response _ok(Map<String, dynamic> card) => Response(
      requestOptions: RequestOptions(path: ShareUtil.cardPath),
      statusCode: 200,
      data: {'success': true, 'data': {'card': card}},
    );

void main() {
  tearDown(() => ShareUtil.poster = null);

  test('solar term card goes to the authenticated share/card endpoint without a user_id', () async {
    String? path;
    dynamic body;
    ShareUtil.poster = (p, {data}) async {
      path = p;
      body = data;
      return _ok({'share_id': 'abc', 'title': '节气养生小贴士', 'text': '文案', 'share_url': 'https://shunshi.app/share/abc', 'hashtags': ['#节气养生']});
    };
    final card = await ShareUtil.generateSolarTermCard(termName: '立冬', principle: '早睡晚起', quote: '冬藏');
    expect(path, '/api/v1/share/card');
    expect(body['type'], 'solar_term');
    expect(body['content'], '立冬');
    expect(body['custom_message'], '早睡晚起 冬藏');
    expect(body.containsKey('user_id'), isFalse);
    expect(card!.shareId, 'abc');
    expect(card.hashtags, ['#节气养生']);
  });

  test('constitution card sends the type name and the top three scores', () {
    final body = ShareUtil.constitutionRequest(
      typeName: '气虚质',
      scores: {'气虚': 72, '阳虚': 55, '平和': 30, '痰湿': 61, '备注': 'x'},
    );
    expect(body['type'], 'constitution');
    expect(body['content'], '气虚质');
    expect(body['custom_message'], '气虚质，主要倾向：气虚 72、痰湿 61、阳虚 55');
    expect(body.containsKey('user_id'), isFalse);
  });

  test('message is clipped to the backend limit of 200 characters', () {
    final body = ShareUtil.solarTermRequest(termName: '立冬', principle: '冬' * 500);
    expect((body['custom_message'] as String).length, ShareUtil.maxMessageLength);
  });

  test('401, 422 and network errors give null instead of throwing', () async {
    for (final code in [401, 422]) {
      ShareUtil.poster = (p, {data}) async => throw DioException(
            requestOptions: RequestOptions(path: p),
            response: Response(requestOptions: RequestOptions(path: p), statusCode: code),
          );
      expect(await ShareUtil.generateConstitutionCard(typeName: '气虚质', scores: {}), isNull);
    }
    ShareUtil.poster = (p, {data}) async => Response(requestOptions: RequestOptions(path: p), statusCode: 200, data: 'not json');
    expect(await ShareUtil.generateSolarTermCard(termName: '立冬', principle: 'x'), isNull);
  });

  test('share_util uses the shared ApiClient, never a bare Dio', () {
    final src = File('lib/presentation/widgets/share_util.dart').readAsStringSync();
    expect(src.contains('Dio('), isFalse);
    expect(src.contains("data/network/api_client.dart"), isTrue);
    expect(src.contains('/share/solar-term-card') || src.contains('/share/constitution-card'), isFalse);
  });
}

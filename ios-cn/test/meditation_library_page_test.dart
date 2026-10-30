import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/meditation/meditation_library_page.dart';

class _FakeAdapter implements HttpClientAdapter {
  final int status;
  final Object body;
  _FakeAdapter(this.status, this.body);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(int status, Object body) => Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = _FakeAdapter(status, body);

void main() {
  testWidgets('冥想音频库：后端没有条目时显示中文空状态，不放示例内容', (tester) async {
    final dio = _dio(200, {
      'data': {'items': [], 'categories': [], 'ai_label': 'AI 合成语音', 'disclaimer': '仅供放松参考'}
    });
    await tester.pumpWidget(MaterialApp(home: MeditationLibraryPage(dio: dio)));
    expect(find.text('正在加载冥想音频…'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.textContaining('冥想音频正在准备中'), findsOneWidget);
    expect(find.text('刷新'), findsOneWidget);
  });

  testWidgets('冥想音频库：接口失败时显示中文错误和重新加载按钮', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MeditationLibraryPage(dio: _dio(500, {'detail': 'x'}))));
    await tester.pumpAndSettle();
    expect(find.textContaining('暂时无法加载'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);
  });

  testWidgets('冥想音频库：有数据时显示标题、AI 标识和免责声明', (tester) async {
    final dio = _dio(200, {
      'data': {
        'items': [
          {
            'id': 'sleep-1',
            'title': '睡前放松',
            'subtitle': '十分钟身体扫描',
            'category': 'sleep',
            'category_label': '助眠',
            'duration_seconds': 196,
            'term': null,
            'audio_url': '/static/audio/meditation/sleep-1.mp3',
            'ai_label': 'AI 合成语音',
            'recommended': true,
          }
        ],
        'categories': [
          {'id': 'sleep', 'label': '助眠'}
        ],
        'ai_label': 'AI 合成语音',
        'disclaimer': '仅供放松参考，不是医疗服务。',
      }
    });
    await tester.pumpWidget(MaterialApp(home: MeditationLibraryPage(dio: dio)));
    await tester.pumpAndSettle();
    expect(find.text('睡前放松'), findsOneWidget);
    expect(find.text('AI 合成语音'), findsOneWidget);
    expect(find.text('当季推荐'), findsOneWidget);
    expect(find.text('3 分 16 秒'), findsOneWidget);
    expect(find.textContaining('不是医疗服务'), findsOneWidget);
  });
}

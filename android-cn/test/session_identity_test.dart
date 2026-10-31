// 复测 B03 / B19 / B20 回归：用户 id、会话令牌不能写死，也不能每个页面各建一个游客账号。
//
// 复测里：首页 / 日记 / 记录页把 user_id 写成 `user-001`，国际版收藏、通知写成 `guest`，
// Stripe 页写成 `user-001`，「记录」页每次打开都调一次 guest-login——等于换一个全新的空账号。
// 服务端按令牌核对本人，写死的 id 一律 403，用户自己写的日记、积分、成就在界面上永远是 0。
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/data/network/session.dart';
import 'package:shunshi/data/storage/storage_manager.dart';

String jwt(String sub) {
  String b64(Map m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${b64({'alg': 'HS256', 'typ': 'JWT'})}.${b64({'sub': sub, 'type': 'access'})}.sig';
}

class FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> calls = [];
  final Object Function(RequestOptions) reply;
  FakeAdapter(this.reply);
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    calls.add(options);
    return ResponseBody.fromString(jsonEncode(reply(options)), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<void> boot(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  await StorageManager.init();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('没有写死的用户 id（源码扫描）', () {
    final forbidden = <String, RegExp>{
      "'user-001'": RegExp(r"""['"]user-001['"]"""),
      "'seasons-user'": RegExp(r"""['"]seasons-user['"]"""),
      "user_id: 'guest'": RegExp(r"""user_?[iI]d['"]?\s*[:=]\s*['"]guest['"]"""),
      "?? 'guest'": RegExp(r"""\?\?\s*['"]guest['"]"""),
      "'guest' 当 id 常量": RegExp(r"""_userId\s*=\s*['"]guest['"]"""),
    };
    // 这些地方是「登录 / 建立游客会话」本身，允许调用 guest-login。
    const guestLoginAllowed = [
      'data/network/session.dart',
      'pages/login/login_page.dart',
      'pages/chat_page.dart',
      'pages/chat/chat_page.dart',
      'data/services/api_service.dart',
    ];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('data/network/session.dart'))
        .toList();

    String code(File f) => f
        .readAsLinesSync()
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');

    test('lib 里没有 user-001 / seasons-user / guest 当用户 id', () {
      final hits = <String>[];
      for (final f in files) {
        final text = code(f);
        forbidden.forEach((name, re) {
          if (re.hasMatch(text)) hits.add('${f.path}: $name');
        });
      }
      expect(hits, isEmpty, reason: '用户 id 要从登录令牌取（currentUserId / userIdParam）');
    });

    test('除登录与聊天外，页面不自己调 guest-login（每次调用都是一个全新的空账号）', () {
      final hits = files
          .where((f) => code(f).contains('/api/v1/auth/guest-login'))
          .map((f) => f.path)
          .where((p) => !guestLoginAllowed.any(p.endsWith))
          .toList();
      expect(hits, isEmpty, reason: '用 ensureSessionToken：先用本机已有令牌，没有才建一个并保存');
    });

    test('随访只查自己的：不再请求管理员接口 /followup/due', () {
      final hits = files.where((f) => RegExp(r"""/followup/due(['"?]|$)""").hasMatch(code(f))).map((f) => f.path).toList();
      expect(hits, isEmpty);
    });
  });

  group('currentUserId / userIdParam', () {
    test('已登录：取令牌里的 sub（手机号 / 游客登录只存了令牌，没存用户资料）', () async {
      await boot({'auth_token': jwt('u-real-42')});
      expect(currentUserId(), 'u-real-42');
      expect(userIdParam(), {'user_id': 'u-real-42'});
    });

    test('令牌不可读时退回已保存的用户资料', () async {
      await boot({'auth_token': 'opaque-token', 'user_info': jsonEncode({'id': 'u-from-info'})});
      expect(currentUserId(), 'u-from-info');
    });

    test('没登录：没有 id，也不编一个', () async {
      await boot({});
      expect(currentUserId(), isNull);
      expect(userIdParam(), isEmpty);
    });

    test('userIdFromToken 对坏令牌返回 null', () {
      expect(userIdFromToken('abc'), isNull);
      expect(userIdFromToken('a.b.c'), isNull);
      expect(userIdFromToken('${jwt('x').split('.')[0]}.${base64Url.encode(utf8.encode('{"sub":"  "}'))}.s'), isNull);
    });
  });

  group('ensureSessionToken', () {
    test('本机已有登录令牌：直接用，不调 guest-login', () async {
      await boot({'auth_token': jwt('u-1')});
      final adapter = FakeAdapter((_) => {'data': {'token': jwt('guest_new')}});
      final dio = Dio()..httpClientAdapter = adapter;
      expect(await ensureSessionToken(dio), jwt('u-1'));
      expect(adapter.calls, isEmpty);
    });

    test('没有令牌：只建一个游客会话并保存，之后所有页面共用', () async {
      await boot({});
      final adapter = FakeAdapter((_) => {
            'success': true,
            'data': {
              'token': jwt('guest_abc'),
              'refresh_token': 'r-1',
              'user': {'id': 'guest_abc', 'is_guest': true},
            },
          });
      final dio = Dio()..httpClientAdapter = adapter;
      final first = await ensureSessionToken(dio);
      final second = await ensureSessionToken(dio);
      final third = await Future.wait([ensureSessionToken(dio), ensureSessionToken(dio)]);
      expect(first, jwt('guest_abc'));
      expect(second, first);
      expect(third, [first, first]);
      expect(adapter.calls.length, 1, reason: '以前每个页面每次打开都 guest-login 一次');
      expect(currentUserId(), 'guest_abc');
    });

    test('guest-login 的两种响应形状都认', () {
      expect(tokenFromAuthBody({'access_token': 'a'}), 'a');
      expect(tokenFromAuthBody({'data': {'token': 'b'}}), 'b');
      expect(tokenFromAuthBody({'token': 'c'}), 'c');
      expect(tokenFromAuthBody({'data': {}}), isNull);
      expect(tokenFromAuthBody('nope'), isNull);
    });

    test('服务不可用：返回 null，不抛、不写假令牌', () async {
      await boot({});
      final dio = Dio()..httpClientAdapter = _Failing();
      expect(await ensureSessionToken(dio), isNull);
      expect((await SharedPreferences.getInstance()).getString('auth_token'), isNull);
    });
  });

  group('withSessionAuth', () {
    test('自建的 Dio 也带上当前令牌；显式给的 Authorization 不被覆盖', () async {
      await boot({'auth_token': jwt('u-9')});
      final adapter = FakeAdapter((_) => {'ok': true});
      final dio = withSessionAuth(Dio(BaseOptions(baseUrl: 'http://x.test')))..httpClientAdapter = adapter;
      await dio.get('/a');
      await dio.get('/b', options: Options(headers: {'Authorization': 'Bearer explicit'}));
      expect(adapter.calls[0].headers['Authorization'], 'Bearer ${jwt('u-9')}');
      expect(adapter.calls[1].headers['Authorization'], 'Bearer explicit');
    });

    test('没登录就不带 Authorization', () async {
      await boot({});
      final adapter = FakeAdapter((_) => {'ok': true});
      final dio = withSessionAuth(Dio(BaseOptions(baseUrl: 'http://x.test')))..httpClientAdapter = adapter;
      await dio.get('/a');
      expect(adapter.calls.single.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('日记接口的响应形状', () {
    test('{data: {entries: [...]}} 和旧的 {entries: [...]} 都能读出', () {
      final e = [
        {'entry_id': '1', 'mood': 4}
      ];
      expect(journalEntriesFromBody({'success': true, 'data': {'entries': e}}), e);
      expect(journalEntriesFromBody({'entries': e}), e);
      expect(journalEntriesFromBody({'data': {}}), isNull);
    });

    test('洞察：有数据取服务端的趋势说明，没数据不编', () {
      expect(journalInsightFromBody({'data': {'entries_count': 3, 'trend_message': 'ok'}}), 'ok');
      expect(journalInsightFromBody({'data': {'entries_count': 0, 'trend_message': 'x'}}), isNull);
      expect(journalInsightFromBody({'data': {'entries_count': 2}}), isNull);
    });
  });
}

class _Failing implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
  }

  @override
  void close({bool force = false}) {}
}

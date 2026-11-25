import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/services/family_api.dart';
import 'package:shunshi/presentation/pages/profile/family_invite_page.dart';

void main() {
  test('family body accepts the bare object and the data wrapper', () {
    final bare = familyBody({
      'family_name': '我家',
      'members': [
        {'name': '周秀兰', 'relation': '家人'},
      ],
      'invite_code': 'AB12CD',
    });
    expect(bare['members'], hasLength(1));
    expect(familyBody({'data': bare})['invite_code'], 'AB12CD');
    expect(() => familyBody({'members': 'nope'}), throwsFormatException);
  });

  testWidgets('invite page shows the family from the API and does not invent a code', (tester) async {
    final api = FamilyApi(
      dio: Dio(BaseOptions(baseUrl: 'http://unused')),
      readToken: () => 'token',
    );
    // load() hits the network. Inject by subclassing is heavier; call the page
    // only after replacing load via a test double.
    await tester.pumpWidget(MaterialApp(home: FamilyInvitePage(api: _FakeApi())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('周秀兰'), findsOneWidget);
    expect(find.text('还没有邀请码'), findsOneWidget);
    expect(find.textContaining('SS'), findsNothing);
    api.dispose();
  });
}

class _FakeApi extends FamilyApi {
  _FakeApi() : super(dio: Dio(BaseOptions(baseUrl: 'http://unused')), readToken: () => 'token');

  @override
  Future<Map<String, dynamic>> load() async {
    return {
      'family_name': '我家',
      'members': [
        {'name': '周秀兰', 'relation': '家人'},
      ],
      'invite_code': null,
    };
  }

  @override
  void dispose() {}
}

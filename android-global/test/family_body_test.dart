import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/data/services/family_body.dart';

void main() {
  test('family home reads members from the real body and not a demo list', () {
    final body = familyBody({
      'family_name': 'Ours',
      'members': [
        {'name': 'Zhou Xiulan', 'relation': 'family'},
      ],
    });
    expect((body['members'] as List).single['name'], 'Zhou Xiulan');
    expect(familyBody({'data': body})['family_name'], 'Ours');
  });
}

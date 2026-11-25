/// `/api/v1/family` sometimes returns the family object, sometimes wraps it in `data`.
Map<String, dynamic> familyBody(dynamic body) {
  if (body is Map && body['members'] is List) {
    return Map<String, dynamic>.from(body);
  }
  if (body is Map && body['data'] is Map && (body['data'] as Map)['members'] is List) {
    return Map<String, dynamic>.from(body['data'] as Map);
  }
  throw const FormatException('Family response is not readable');
}

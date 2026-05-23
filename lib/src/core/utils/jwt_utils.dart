import 'dart:convert';

/// Reads `memberId` claim from a JWT access token payload (no signature verify).
int? memberIdFromAccessToken(String? token) {
  if (token == null || token.isEmpty) return null;
  final parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    final normalized = base64Url.normalize(parts[1]);
    final payload = utf8.decode(base64Url.decode(normalized));
    final map = jsonDecode(payload);
    if (map is! Map<String, dynamic>) return null;
    final id = map['memberId'] ?? map['member_id'] ?? map['sub'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    if (id is String) return int.tryParse(id);
    return null;
  } catch (_) {
    return null;
  }
}

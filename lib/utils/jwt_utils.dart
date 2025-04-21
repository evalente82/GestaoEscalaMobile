import 'dart:convert';

Map<String, dynamic> decodeJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Token JWT inválido');
    }

    final payload = parts[1];
    // Preenche o padding para base64 correto
    final normalizedPayload = payload.padRight((payload.length + 3) & ~3, '=');
    final decodedPayload = base64Url.decode(normalizedPayload);
    final String decodedString = utf8.decode(decodedPayload);
    final Map<String, dynamic> decodedMap = jsonDecode(decodedString);

    print("🔍 Decodificação JWT - Payload bruto: $decodedString");
    return decodedMap;
  } catch (e) {
    print("❌ Erro ao decodificar JWT: $e");
    return {};
  }
}

bool hasPermission(String permission, String token) {
  final decodedToken = decodeJwt(token);
  final permissions = List<String>.from(decodedToken['Permissao'] ?? []);
  return permissions.contains(permission);
}
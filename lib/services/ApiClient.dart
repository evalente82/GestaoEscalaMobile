import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:escala_mobile/utils/jwt_utils.dart';
import 'package:escala_mobile/services/auth_service.dart';

class ApiClient {
  static String get baseUrl {
    if (kIsWeb) {
      //return "";
      return "https://back-gestao-escala.fly.dev";
      //  return "http://localhost:8080";
    }
    return "https://back-gestao-escala.fly.dev";
    // return "http://10.0.2.2:8080";
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    String? refreshToken = prefs.getString('refresh_token');

    if (token != null && token.isNotEmpty) {
      final decodedToken = decodeJwt(token);
      final exp = decodedToken['exp'] as int?;
      if (exp != null && DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp && refreshToken != null) {
        //print("🔄 Token expirado, renovando...");
        final refreshResponse = await AuthService.refreshToken(refreshToken);
        if (refreshResponse["success"] == true) {
          token = refreshResponse["token"];
          final newRefreshToken = refreshResponse["refreshToken"];
          await prefs.setString('jwt_token', token!);
          await prefs.setString('refresh_token', newRefreshToken);
          //print("✅ Token renovado com sucesso!");
        } else {
          await AuthService.clearTokens();
          token = null;
          //print("❌ Falha ao renovar token, usuário deslogado.");
        }
      }
      return token;
    }
    return null;
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final token = await _getToken();
    final url = Uri.parse("$baseUrl$endpoint");

    //print("📡 GET: $url");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 401) {
      await AuthService.clearTokens();
    }
    return {
      "statusCode": response.statusCode,
      "body": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final token = await _getToken();
    final url = Uri.parse("$baseUrl$endpoint");

    //print("📡 POST: $url");
    //print("📤 Enviando: ${jsonEncode(body)}");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );
    //print("✅ Resposta API - Status: ${response.statusCode}, Body: ${response.body}");

    if (response.statusCode == 401) {
      await AuthService.clearTokens();
    }
    return {
      "statusCode": response.statusCode,
      "body": response.body.isNotEmpty ? jsonDecode(response.body) : {},
    };
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    final token = await _getToken();
    final url = Uri.parse("$baseUrl$endpoint");

    //print("📡 PUT: $url");
    //print("📤 Enviando: ${jsonEncode(body)}");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      await AuthService.clearTokens();
    }
    return {
      "statusCode": response.statusCode,
      "body": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final token = await _getToken();
    final url = Uri.parse("$baseUrl$endpoint");

    //print("📡 DELETE: $url");

    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 401) {
      await AuthService.clearTokens();
    }
    return {
      "statusCode": response.statusCode,
      "body": jsonDecode(response.body),
    };
  }
}
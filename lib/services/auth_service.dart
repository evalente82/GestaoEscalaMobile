
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://192.168.0.9:7207";

  static Future<Map<String, dynamic>> login(String usuario, String senha) async {
    try {
      final url = Uri.parse("$baseUrl/login/autenticar");
      print("📡 Enviando requisição para: $url");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"usuario": usuario, "senha": senha}),
      );

      print("🔹 Status Code: ${response.statusCode}");
      print("🔹 Resposta: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey("token")) {
          return {
            "success": true,
            "token": responseData["token"],
            "refreshToken": responseData["refreshToken"] ?? "",
            "nomeUsuario": responseData["nomeUsuario"] ?? "",
            "matricula": responseData["matricula"]?.toString() ?? "",
            "idFuncionario": responseData["idFuncionario"]?.toString() ?? "",
          };
        } else {
          return {"success": false, "message": "Resposta inválida do servidor."};
        }
      } else {
        return {
          "success": false,
          "message": response.body.isNotEmpty
              ? jsonDecode(response.body)["mensagem"] ?? "Erro desconhecido."
              : "Erro ao conectar ao servidor__LOGIN.",
        };
      }
    } catch (e) {
      print("❌ Erro durante a requisição: $e");
      return {"success": false, "message": "Erro de conexão com o servidor__LOGIN: $e"};
    }
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    print("💾 Token salvo no SharedPreferences: $token");
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', refreshToken);
    print("💾 RefreshToken salvo no SharedPreferences: $refreshToken");
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    print("📖 Token recuperado do SharedPreferences: $token");
    return token;
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    print("📖 RefreshToken recuperado do SharedPreferences: $refreshToken");
    return refreshToken;
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
    print("🗑️ Tokens limpos do SharedPreferences.");
  }

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final url = Uri.parse("$baseUrl/login/refresh");
      print("📡 Enviando requisição para: $url");
      print("📤 Enviando refreshToken: $refreshToken");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": refreshToken}),
      );

      print("🔹 Status Code: ${response.statusCode}");
      print("🔹 Resposta: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          "success": true,
          "token": responseData["token"],
          "refreshToken": responseData["refreshToken"],
        };
      } else {
        return {
          "success": false,
          "message": response.body.isNotEmpty
              ? jsonDecode(response.body)["mensagem"] ?? "Falha ao renovar token."
              : "Erro ao renovar token."
        };
      }
    } catch (e) {
      print("❌ Erro ao renovar token: $e");
      return {"success": false, "message": "Erro ao renovar token: $e"};
    }
  }
}
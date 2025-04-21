import 'package:flutter/material.dart';
import 'package:escala_mobile/utils/jwt_utils.dart';
import 'package:escala_mobile/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserModel with ChangeNotifier {
  String _userName = "";
  String _userMatricula = "";
  String _idFuncionario = "";
  String _token = "";
  String _refreshToken = "";
  int _notificationCount = 0;

  String get userName => _userName;
  String get userMatricula => _userMatricula;
  String get idFuncionario => _idFuncionario;
  String get token => _token;
  String get refreshToken => _refreshToken;
  int get notificationCount => _notificationCount;

  void setUser(String name, String matricula, String idFuncionario, {String? token, String? refreshToken}) {
    _userName = name;
    _userMatricula = matricula;
    _idFuncionario = idFuncionario;
    if (token != null) _token = token;
    if (refreshToken != null) _refreshToken = refreshToken;
    notifyListeners();
    print("👤 UserModel atualizado via setUser - Nome: $_userName, Matrícula: $_userMatricula, ID: $_idFuncionario");
  }

  Future<bool> loadUserFromToken() async {
    String? token = await AuthService.getToken();
    String? refreshToken = await AuthService.getRefreshToken();

    print("🚀 Iniciando loadUserFromToken...");
    print("🔍 Token carregado ao abrir o app: $token");
    print("🔍 RefreshToken carregado ao abrir o app: $refreshToken");

    if (token != null && token.isNotEmpty) {
      final decodedToken = decodeJwt(token);
      print("🔍 Token decodificado: $decodedToken");
      final exp = decodedToken['exp'] as int?;

      if (exp != null && DateTime.now().millisecondsSinceEpoch ~/ 1000 < exp) {
        _updateUserFromToken(token, refreshToken ?? "");
        print("✅ Token válido carregado.");
        return true;
      } else if (refreshToken != null && refreshToken.isNotEmpty) {
        _refreshToken = refreshToken;
        print("🔄 Token expirado, tentando renovar com refreshToken: $_refreshToken");
        return await _refreshUserToken();
      } else {
        print("⚠️ RefreshToken está vazio ou não disponível para renovação.");
      }
    }
    print("❌ Nenhum token válido encontrado.");
    return false;
  }

  Future<bool> _refreshUserToken() async {
    try {
      print("🔄 Tentando renovar o token com refreshToken: $_refreshToken");
      final response = await AuthService.refreshToken(_refreshToken);
      print("🔍 Resposta completa do refresh: $response");

      if (response["success"] == true) {
        final newToken = response["token"] as String;
        final newRefreshToken = response["refreshToken"] as String;
        await AuthService.saveToken(newToken);
        await AuthService.saveRefreshToken(newRefreshToken);
        _updateUserFromToken(newToken, newRefreshToken);
        print("✅ Token renovado com sucesso!");
        return true;
      } else {
        print("❌ Falha ao renovar o token: ${response["message"]}");
        await AuthService.clearTokens();
      }
    } catch (e) {
      print("❌ Erro ao renovar token: $e");
      await AuthService.clearTokens();
    }
    return false;
  }

  void _updateUserFromToken(String token, String refreshToken) {
    final decodedToken = decodeJwt(token);
    print("🔍 Token decodificado em _updateUserFromToken: $decodedToken");
    
    if (decodedToken.containsKey("unique_name") || decodedToken.containsKey("nomeUsuario")) {
      _userName = decodedToken["unique_name"] ?? decodedToken["nomeUsuario"] ?? _userName;
    }
    if (decodedToken.containsKey("Matricula") || decodedToken.containsKey("certserialnumber")) {
      _userMatricula = decodedToken["Matricula"] ?? decodedToken["certserialnumber"] ?? _userMatricula;
    }
    if (decodedToken.containsKey("IdFuncionario") || decodedToken.containsKey("idFuncionario")) {
      _idFuncionario = decodedToken["IdFuncionario"] ?? decodedToken["idFuncionario"] ?? _idFuncionario;
    }
    
    _token = token;
    _refreshToken = refreshToken;
    notifyListeners();
    print("🔄 Dados do token atualizados - Nome: $_userName, Matrícula: $_userMatricula, ID: $_idFuncionario");
  }

  void clearUser() async {
    _userName = "";
    _userMatricula = "";
    _idFuncionario = "";
    _token = "";
    _refreshToken = "";
    _notificationCount = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationCount', 0);
    notifyListeners();
    print("🗑️ Dados do usuário limpos.");
  }

  void incrementNotificationCount() async {
    _notificationCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationCount', _notificationCount);
    notifyListeners();
    print("🔔 Contador de notificações incrementado: $_notificationCount");
  }

  void clearNotificationCount() async {
    _notificationCount = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationCount', 0);
    notifyListeners();
    print("🔔 Contador de notificações limpo.");
  }

  void setInitialNotificationCount(int count) async {
    _notificationCount = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationCount', count);
    notifyListeners();
    print("🔔 Contador inicial de notificações definido: $_notificationCount");
  }
}
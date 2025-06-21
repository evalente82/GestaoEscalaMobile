import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

// 1. Defina a interface JavaScript para a função que você expôs em index.html
@JS()
external Future<String> getRecaptchaToken(String action);

// 2. Crie um wrapper Dart para usar essa função
class RecaptchaService {
  static Future<String?> getToken({required String action}) async {
    if (kIsWeb) {
      try {
        // Chama a função JS e aguarda a Promise retornar
        final String token = await promiseToFuture(getRecaptchaToken(action));
        return token;
      } catch (e) {
        debugPrint("Erro ao obter token reCAPTCHA na web: $e");
        return null;
      }
    } else {
      // Para plataformas não-web, esta classe não fará nada.
      // O reCAPTCHA será tratado pela WebView conforme o código existente.
      return null; // Ou lance um erro se não for para ser chamado aqui
    }
  }
}
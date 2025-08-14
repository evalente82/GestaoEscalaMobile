import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

// 1. Defina a interface JavaScript para a função que você expôs em index.html
@JS()
external Future<String> getRecaptchaToken(String action);

// 2. Crie um wrapper Dart para usar essa função
class RecaptchaService {
  
}

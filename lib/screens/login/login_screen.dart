import 'package:escala_mobile/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:escala_mobile/services/auth_service.dart';
import 'package:escala_mobile/screens/home/home_screen.dart';
import 'package:escala_mobile/screens/login/primeiro_acesso_screen.dart';
import 'package:escala_mobile/screens/login/esqueci_senha_screen.dart';
import 'package:escala_mobile/screens/login/redefinir_senha.dart';
import 'package:escala_mobile/components/footer_component.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  String? _alertMessage;

  Future<void> _handleSubmit() async {
    final String usuario = _usuarioController.text.trim();
    final String senha = _senhaController.text.trim();

    if (usuario.isEmpty || senha.isEmpty) {
      setState(() {
        _alertMessage = "Preencha todos os campos!";
      });
      return;
    }

    try {
      final response = await AuthService.login(usuario, senha);

      if (response["success"] == true) {
        final String token = response["token"] as String;
        final String refreshToken = response["refreshToken"] as String? ?? "";
        
        print("📥 Login bem-sucedido - Token recebido: $token");
        print("📥 Login bem-sucedido - RefreshToken recebido: $refreshToken");

        await AuthService.saveToken(token);
        if (refreshToken.isNotEmpty) {
          await AuthService.saveRefreshToken(refreshToken);
        } else {
          print("⚠️ RefreshToken está vazio ou não foi retornado pelo backend.");
        }

        final String nomeUsuario = response["nomeUsuario"] ?? "Desconhecido";
        final String matricula = response["matricula"]?.toString() ?? "";
        final String idFuncionario = response["idFuncionario"]?.toString() ?? "";

        final userModel = Provider.of<UserModel>(context, listen: false);
        userModel.setUser(
          nomeUsuario,
          matricula,
          idFuncionario,
          token: token,
          refreshToken: refreshToken,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        setState(() {
          _alertMessage = response["message"] as String? ?? "Falha no login.";
        });
      }
    } catch (e) {
      setState(() {
        _alertMessage = "Erro ao conectar com o servidor: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Text(
                "Prefeitura Municipal de Maricá",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003580),
                ),
              ),
              const SizedBox(height: 20),
              Image.asset(
                "assets/images/LogoDefesaCivil.png",
                height: 150,
              ),
              const SizedBox(height: 20),
              Text(
                "Login",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003580),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usuarioController,
                decoration: InputDecoration(
                  labelText: "Usuário",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Senha",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF003580),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Entrar",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_alertMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _alertMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrimeiroAcessoScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Primeiro Acesso",
                      style: TextStyle(fontSize: 16, color: Color(0xFF003580)),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EsqueciSenhaScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Esqueci minha senha",
                      style: TextStyle(fontSize: 16, color: Color(0xFF003580)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RedefinirSenhaScreen(token: "temp_token"),
                        ),
                      );
                    },
                    child: const Text(
                      "Redefinir Senha (Temporário)",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              const FooterComponent(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }
}
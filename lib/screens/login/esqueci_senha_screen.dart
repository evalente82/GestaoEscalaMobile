
import 'package:escala_mobile/services/ApiClient.dart';
import 'package:flutter/material.dart';
import 'package:escala_mobile/components/footer_component.dart';

class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _alertMessage;
  String? _successMessage;

  Future<void> _handleResetPassword() async {
    final String email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _alertMessage = "Preencha o campo de e-mail!";
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _alertMessage = null;
      _successMessage = "Enviando instruções...";
    });

    try {
      // Placeholder: Substitua pela chamada correta ao seu backend
      // Exemplo: final response = await ApiClient.post('/login/esqueci-senha', {'email': email});
      await Future.delayed(const Duration(seconds: 1)); // Simulação de requisição
      final response = await ApiClient.post('/login/esqueci-senha', {'email': email});

      if (!mounted) return;

      if (response["success"]) {
        setState(() {
          _successMessage = response["message"];
          _alertMessage = null;
        });
      } else {
        setState(() {
          _alertMessage = response["message"] ?? "Erro ao solicitar redefinição.";
          _successMessage = null;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _alertMessage = "Erro ao conectar ao servidor. Tente novamente.";
        _successMessage = null;
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
                "Esqueci Minha Senha",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003580),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Insira o seu e-mail para receber instruções de redefinição de senha.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
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
              if (_successMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "E-mail",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF003580),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Enviar Instruções",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Voltar para Login",
                  style: TextStyle(fontSize: 16, color: Colors.blue),
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
    _emailController.dispose();
    super.dispose();
  }
}
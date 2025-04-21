import 'package:escala_mobile/services/ApiClient.dart';
import 'package:flutter/material.dart';
import 'package:escala_mobile/components/footer_component.dart';

class PrimeiroAcessoScreen extends StatefulWidget {
  const PrimeiroAcessoScreen({super.key});

  @override
  State<PrimeiroAcessoScreen> createState() => _PrimeiroAcessoScreenState();
}

class _PrimeiroAcessoScreenState extends State<PrimeiroAcessoScreen> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();
  String? _alertMessage;
  String? _successMessage;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleSubmit() async {
    final String usuario = _usuarioController.text.trim();
    final String senha = _senhaController.text.trim();
    final String confirmarSenha = _confirmarSenhaController.text.trim();

    if (usuario.isEmpty || senha.isEmpty || confirmarSenha.isEmpty) {
      setState(() {
        _alertMessage = "Preencha todos os campos!";
        _successMessage = null;
      });
      return;
    }

    if (!_isValidEmail(usuario)) {
      setState(() {
        _alertMessage = "E-mail inválido! Insira um e-mail no formato correto.";
        _successMessage = null;
      });
      return;
    }

    if (senha != confirmarSenha) {
      setState(() {
        _alertMessage = "As senhas não coincidem.";
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _alertMessage = null;
      _successMessage = "Criando acesso...";
    });

    try {
      // Placeholder: Substitua pela chamada correta ao seu backend
      // Exemplo: final response = await ApiClient.post('/login/Incluir', {'usuario': usuario, 'senha': senha});
      final response = await ApiClient.post('/login/Incluir', {'usuario': usuario, 'senha': senha});

      if (!mounted) return;

      if (response["success"] == true) {
        setState(() {
          _successMessage = "Cadastro realizado com sucesso! Redirecionando...";
          _alertMessage = null;
        });
        await Future.delayed(const Duration(seconds: 3));

        if (!mounted) return;

        Navigator.pop(context);
      } else {
        setState(() {
          _alertMessage = response["message"] as String? ?? "Erro ao criar acesso."; // Cast com fallback
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
                "Primeiro Acesso",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003580),
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
                controller: _usuarioController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "E-mail",
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
              const SizedBox(height: 16),
              TextField(
                controller: _confirmarSenhaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirmar Senha",
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
                  "Criar Acesso",
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
    _usuarioController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }
}
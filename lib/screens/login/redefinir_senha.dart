import 'package:flutter/material.dart';
import 'package:escala_mobile/components/footer_component.dart';

class RedefinirSenhaScreen extends StatefulWidget {
  final String token;
  const RedefinirSenhaScreen({super.key, required this.token});

  @override
  State<RedefinirSenhaScreen> createState() => _RedefinirSenhaScreenState();
}

class _RedefinirSenhaScreenState extends State<RedefinirSenhaScreen> {
  final TextEditingController _novaSenhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();
  String? _alertMessage;
  String? _successMessage;

  Future<void> _handleRedefinirSenha() async {
    final String novaSenha = _novaSenhaController.text.trim();
    final String confirmarSenha = _confirmarSenhaController.text.trim();

    if (novaSenha.isEmpty || confirmarSenha.isEmpty) {
      setState(() {
        _alertMessage = "Preencha todos os campos!";
        _successMessage = null;
      });
      return;
    }

    if (novaSenha != confirmarSenha) {
      setState(() {
        _alertMessage = "As senhas não coincidem!";
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _alertMessage = null;
      _successMessage = "Redefinindo senha...";
    });

    try {
      // Placeholder: Substitua pela chamada correta ao seu backend
      // Exemplo: final response = await ApiClient.post('/login/redefinir-senha', {'token': widget.token, 'novaSenha': novaSenha});
      await Future.delayed(const Duration(seconds: 1)); // Simulação de requisição
      final response = {"success": true, "message": "Senha redefinida com sucesso!"};

      if (!mounted) return;

      if (response["success"] == true) {
        setState(() {
          _successMessage = response["message"] as String?; // Cast para String?
          _alertMessage = null;
        });
        await Future.delayed(const Duration(seconds: 3));

        if (!mounted) return;

        Navigator.pop(context);
      } else {
        setState(() {
          _alertMessage = response["message"] as String? ?? "Erro ao redefinir senha."; // Cast com fallback
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
                "Redefinir Senha",
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
                controller: _novaSenhaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Nova Senha",
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
                  labelText: "Confirmar Nova Senha",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleRedefinirSenha,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF003580),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Redefinir Senha",
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
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }
}
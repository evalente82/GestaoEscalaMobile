import 'package:flutter/material.dart';

class CadastroEscalaExtraScreen extends StatefulWidget {
  final Map<String, dynamic> escalaExtra;  // Dados do card

  const CadastroEscalaExtraScreen({super.key, required this.escalaExtra});

  @override
  State<CadastroEscalaExtraScreen> createState() =>
      _CadastroEscalaExtraScreenState();
}

class _CadastroEscalaExtraScreenState extends State<CadastroEscalaExtraScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Método para cadastro
  void _cadastrarFuncionario() {
    if (_formKey.currentState!.validate()) {
      // Ação para cadastrar o funcionário
      print("Cadastro realizado!");
      // Aqui, você pode fazer a requisição para o backend para cadastrar o funcionário na escala extra.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cadastro realizado com sucesso!")),
      );
    }
  }

  // Método para cancelar o cadastro
  void _cancelarCadastro() {
    Navigator.pop(context);  // Navegar para a tela anterior
  }

  @override
  Widget build(BuildContext context) {
    // Usando os dados passados para exibir as informações do card
    final escalaExtra = widget.escalaExtra;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro do RAS / Extra", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF003580),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Preencha as informações abaixo para o cadastro do funcionário.",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),

                // Exibir as informações do card clicado
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          escalaExtra["titulo"], // Nome da escala
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text("Setor: ${escalaExtra["setorNome"]}"), // Setor
                        Text("Data: ${escalaExtra["data"]}"),
                        Text("Hora: ${escalaExtra["hora"]}"),
                      ],
                    ),
                  ),
                ),

                // Campo Nome Completo
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o nome completo.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Matrícula
                TextFormField(
                  controller: _matriculaController,
                  decoration: const InputDecoration(
                    labelText: 'Matrícula',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a matrícula.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o email.';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Por favor, insira um email válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Botões Cadastrar e Cancelar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _cancelarCadastro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Cancelar", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: _cadastrarFuncionario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003580),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Cadastrar", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

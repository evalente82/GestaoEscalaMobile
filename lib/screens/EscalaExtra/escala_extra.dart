import 'dart:math';

import 'package:escala_mobile/models/user_model.dart';
import 'package:escala_mobile/screens/EscalaExtra/cadastro_escala_extra.dart';
import 'package:escala_mobile/services/ApiClient.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EscalaExtraScreen extends StatefulWidget {
  const EscalaExtraScreen({super.key});

  @override
  State<EscalaExtraScreen> createState() => _EscalaExtraScreenState();
}

class _EscalaExtraScreenState extends State<EscalaExtraScreen> {
  List<Map<String, dynamic>> _extrasDisponiveis = [];
  List<Map<String, dynamic>> _setores = [];
  List<Map<String, dynamic>> _solicitacoesExtrasDisponiveis = [];

  @override
  void initState() {
    super.initState();
    _buscarSetores();
    _buscarExtrasDisponiveis();
    _buscarSolicitacoesExtras();
  }

  // Método para buscar as Solicitações de extras
  Future<void> _buscarSolicitacoesExtras() async {
    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      if (userModel.idFuncionario.isEmpty) {
        throw Exception("ID do funcionário não disponível.");
      }

      //print("📡 Requisitando Solicitações de escalas extras...");

      final response = await ApiClient.get("/solicitacaoEscalaExtra/BuscarPorId/${userModel.idFuncionario}");
      //print("📡 Resposta Status Code: ${response['statusCode']}");

      if (response["statusCode"] == 200) {
        //print("📡 Resposta Body: ${response['body']}");

        List<dynamic> data = response["body"];
        setState(() {
          _solicitacoesExtrasDisponiveis = data.map((e) => _formatarEscalaExtra(e)).toList();
        });

        //print("📡 Dados formatados para exibição: $_solicitacoesExtrasDisponiveis");
      } else {
        throw Exception("Erro ${response["statusCode"]}");
      }
    } catch (e) {
      //print("❌ Erro ao carregar Solicitações de escalas extras: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar Solicitações de escalas extras.")),
      );
    }
  }

  // Método para buscar as escalas extras
  Future<void> _buscarExtrasDisponiveis() async {
    try {
      final response = await ApiClient.get('/escalaExtra/buscarExtras');

      if (response["statusCode"] == 200) {
        List<dynamic> data = response["body"];
        setState(() {
          _extrasDisponiveis = data.map((e) => _formatarEscalaExtra(e)).toList();
        });
      } else {
        throw Exception("Erro ${response["statusCode"]}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar escalas extras.")),
      );
    }
  }

  // Método para buscar os setores
  Future<void> _buscarSetores() async {
    try {
      final response = await ApiClient.get('/setor/buscarTodos');
      print("📡 Resposta Status Code: ${response['statusCode']}");
      if (response["statusCode"] == 200) {
        print("📡 Resposta Body: ${response['body']}");
        List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response["body"]);
        setState(() {
          _setores = data;
          print("📡 Dados formatados para exibição: $_setores");
        });
      } else {
        throw Exception("Erro ${response["statusCode"]}");
      }
    } catch (e) {
      print("❌ Erro ao carregar setores: $e");
    }
  }

  // Método para ajustar o fuso horário
  DateTime ajustarFusoHorario(DateTime dt) {
    return dt.subtract(const Duration(hours: 3));
  }

  // Método para formatar a data e hora
  String formatarDataHora(DateTime dateTime) {
    final adjustedDateTime = ajustarFusoHorario(dateTime);
    return DateFormat("dd-MM-yyyy HH:mm").format(adjustedDateTime);
  }

  // Método para formatar os dados das escalas extras
  Map<String, dynamic> _formatarEscalaExtra(Map<String, dynamic> original) {
    DateTime parseOrNull(String? iso) =>
        iso != null ? DateTime.tryParse(iso)! : DateTime(0);

    final dtServico = parseOrNull(original["dtEscalaExtra"]);

    return {
      "id": original["idCriacaoEscalaExtra"],
      "titulo": original["nmEscalaExtra"] ?? "Sem nome",
      "setor": original["nmSetor"] ?? "Sem setor",
      "data": DateFormat("dd-MM-yyyy").format(dtServico),
      "hora": DateFormat("HH:mm").format(ajustarFusoHorario(dtServico)),
    };
  }

  // Método para navegar para o cadastro da escala extra
  void _navegarParaCadastro(Map<String, dynamic> escalaExtra) {
    print("🔗 Navegar para cadastro da escala extra ${escalaExtra['id']}");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroEscalaExtraScreen(escalaExtra: escalaExtra),
      ),
    );
  }

  // Método para construir a tabela de solicitações
  Widget _buildTabelaSolicitacoes() {
    return DataTable(
      columnSpacing: 20,
      horizontalMargin: 10,
      columns: const [
        DataColumn(label: Text("Título", style: TextStyle(fontSize: 12))),
        DataColumn(label: Text("Setor", style: TextStyle(fontSize: 12))),
        DataColumn(label: Text("Data", style: TextStyle(fontSize: 12))),
        DataColumn(label: Text("Hora", style: TextStyle(fontSize: 12))),
      ],
      rows: _solicitacoesExtrasDisponiveis.map((e) {
        return DataRow(
          cells: [
            DataCell(Text(e["titulo"] ?? '', style: const TextStyle(fontSize: 11))),
            DataCell(Text(e["setor"] ?? '', style: const TextStyle(fontSize: 11))),
            DataCell(Text(e["data"] ?? '', style: const TextStyle(fontSize: 11))),
            DataCell(Text(e["hora"] ?? '', style: const TextStyle(fontSize: 11))),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RAS / Extra", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF003580),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Escalas Extras Disponíveis", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ..._extrasDisponiveis.map((e) => _buildCardEscalaExtra(e)).toList(),
              const SizedBox(height: 30),
              Text("RAS / Extras Solicitados", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildTabelaSolicitacoes(), // Pode ser substituído pela grid real
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardEscalaExtra(Map<String, dynamic> e) {
    return GestureDetector(
      onTap: () => _navegarParaCadastro(e),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e["titulo"], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(e["setor"], style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Text("Data: ${e["data"]}"),
              Text("Hora: ${e["hora"]}"),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:escala_mobile/models/user_model.dart';
import 'package:escala_mobile/services/ApiClient.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SolicitacoesPermutasScreen extends StatefulWidget {
  const SolicitacoesPermutasScreen({super.key});

  @override
  State<SolicitacoesPermutasScreen> createState() => _SolicitacoesPermutasScreenState();
}

class _SolicitacoesPermutasScreenState extends State<SolicitacoesPermutasScreen> {
  List<Map<String, dynamic>> _solicitadas = [];

  @override
  void initState() {
    super.initState();
    _buscarSolicitacoes();
  }

  Future<void> _buscarSolicitacoes() async {
    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      if (userModel.idFuncionario.isEmpty) {
        throw Exception("ID do funcionário não disponível.");
      }
      final String url = "/permutas/SolicitacoesPorId/${userModel.idFuncionario}";
      final response = await ApiClient.get(url);

      if (response["statusCode"] == 200) {
        final List<dynamic> data = response["body"];
        setState(() {
          _solicitadas = data
              .where((p) =>
                  p["nmNomeSolicitante"] != null &&
                  p["dtDataSolicitadaTroca"] != null &&
                  (p["idFuncionarioSolicitante"] == userModel.idFuncionario ||
                      p["idFuncionarioSolicitado"] == userModel.idFuncionario))
              .map((p) => {
                    "idPermuta": p["idPermuta"]?.toString() ?? "",
                    "solicitante": p["nmNomeSolicitante"] ?? "",
                    "dataSolicitadaTroca": p["dtDataSolicitadaTroca"] != null
                        ? _formatarData(p["dtDataSolicitadaTroca"])
                        : "",
                    "aprovado": p["nmAprovador"] != null,
                    "isSolicitante": p["idFuncionarioSolicitante"] == userModel.idFuncionario,
                  })
              .toList();
        });
        if (_solicitadas.isNotEmpty) {
          userModel.incrementNotificationCount();
        }
      } else {
        throw Exception("Erro ao buscar permutas. Código: ${response["statusCode"]}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao buscar permutas: $e")),
      );
    }
  }

  Future<void> _aprovarPermuta(String idPermuta) async {
    try {
      final String url = "/permutas/Aprovar/$idPermuta";
      final userModel = Provider.of<UserModel>(context, listen: false);

      final Map<String, dynamic> aprovacaoData = {
        "idAprovador": userModel.idFuncionario,
        "nmAprovador": userModel.userName.isNotEmpty ? userModel.userName : "Usuário",
        "dtAprovacao": DateTime.now().toUtc().toIso8601String(),
      };

      print("📡 Aprovando permuta: $url");
      print("📤 Dados enviados: $aprovacaoData");

      final response = await ApiClient.put(url, aprovacaoData);

      if (response["statusCode"] == 200) {
        print("✅ Permuta aprovada com sucesso!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permuta aprovada com sucesso!")),
        );
        _buscarSolicitacoes();
      } else {
        throw Exception("Erro ao aprovar permuta. Código: ${response["statusCode"]}");
      }
    } catch (e) {
      print("❌ Erro ao aprovar permuta: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao aprovar permuta: $e")),
      );
    }
  }

  Future<void> _recusarPermuta(String idPermuta) async {
    try {
      final String url = "/permutas/Recusar/$idPermuta";
      final userModel = Provider.of<UserModel>(context, listen: false);

      final Map<String, dynamic> recusaData = {
        "idAprovador": userModel.idFuncionario,
        "nmAprovador": userModel.userName.isNotEmpty ? userModel.userName : "Usuário",
        "dtRecusa": DateTime.now().toUtc().toIso8601String(),
      };

      print("📡 Recusando permuta: $url");
      print("📤 Dados enviados: $recusaData");

      final response = await ApiClient.put(url, recusaData);

      if (response["statusCode"] == 200) {
        print("✅ Permuta recusada com sucesso!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permuta recusada com sucesso!")),
        );
        _buscarSolicitacoes();
      } else {
        throw Exception("Erro ao recusar permuta. Código: ${response["statusCode"]}");
      }
    } catch (e) {
      print("❌ Erro ao recusar permuta: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao recusar permuta: $e")),
      );
    }
  }

  Future<void> _aprovarPermutaSolicitado(String idPermuta) async {
    try {
      final String url = "/permutas/AprovarSolicitado/$idPermuta";
      final response = await ApiClient.put(url, {});

      if (response["statusCode"] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permuta aprovada pelo solicitado!")),
        );
        _buscarSolicitacoes();
      } else {
        throw Exception("Erro ao aprovar permuta. Código: ${response["statusCode"]}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao aprovar permuta: $e")),
      );
    }
  }

  Future<void> _recusarPermutaSolicitado(String idPermuta) async {
    try {
      final String url = "/permutas/RecusarSolicitado/$idPermuta";
      final response = await ApiClient.put(url, {});

      if (response["statusCode"] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permuta recusada pelo solicitado!")),
        );
        _buscarSolicitacoes();
      } else {
        throw Exception("Erro ao recusar permuta. Código: ${response["statusCode"]}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao recusar permuta: $e")),
      );
    }
  }

  String _formatarData(String? dataISO) {
    if (dataISO == null || dataISO.isEmpty) return "N/A";
    final DateTime data = DateTime.parse(dataISO);
    return DateFormat("dd/MM/yyyy").format(data);
  }

  void _mostrarConfirmacaoAprovar(String idPermuta, String data, bool isSolicitado) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmar Aprovação"),
          content: Text("Tem certeza que deseja aceitar a permuta na data $data?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isSolicitado) {
                  _aprovarPermutaSolicitado(idPermuta);
                } else {
                  _aprovarPermuta(idPermuta);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003580)),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _mostrarConfirmacaoRecusar(String idPermuta, String data, bool isSolicitado) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmar Recusa"),
          content: Text("Tem certeza que deseja recusar a permuta na data $data?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isSolicitado) {
                  _recusarPermutaSolicitado(idPermuta);
                } else {
                  _recusarPermuta(idPermuta);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Solicitações de Permutas",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003580),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Permutas Solicitadas",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _solicitadas.isNotEmpty
                ? Center(
                    child: DataTable(
                      columnSpacing: 15,
                      columns: const [
                        DataColumn(
                          label: Text("Solicitante", style: TextStyle(fontSize: 16)),
                        ),
                        DataColumn(
                          label: Text("Data", style: TextStyle(fontSize: 16)),
                        ),
                        DataColumn(
                          label: Text("Aprovar", style: TextStyle(fontSize: 16)),
                        ),
                        DataColumn(
                          label: Text("Recusar", style: TextStyle(fontSize: 16)),
                        ),
                      ],
                      rows: _solicitadas.map((p) {
                        return DataRow(cells: [
                          DataCell(
                            Text(p["solicitante"] ?? "", style: const TextStyle(fontSize: 14)),
                          ),
                          DataCell(
                            Text(p["dataSolicitadaTroca"] ?? "", style: const TextStyle(fontSize: 14)),
                          ),
                          DataCell(
                            p["aprovado"] || p["isSolicitante"]
                                ? const SizedBox.shrink()
                                : ElevatedButton(
                                    onPressed: () => _mostrarConfirmacaoAprovar(
                                        p["idPermuta"], p["dataSolicitadaTroca"], true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF003580),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: const Size(60, 30),
                                    ),
                                    child: const Text("Aprovar",
                                        style: TextStyle(fontSize: 12, color: Colors.white)),
                                  ),
                          ),
                          DataCell(
                            p["aprovado"] || p["isSolicitante"]
                                ? const SizedBox.shrink()
                                : ElevatedButton(
                                    onPressed: () => _mostrarConfirmacaoRecusar(
                                        p["idPermuta"], p["dataSolicitadaTroca"], true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: const Size(60, 30),
                                    ),
                                    child: const Text("Recusar",
                                        style: TextStyle(fontSize: 12, color: Colors.white)),
                                  ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  )
                : const Center(
                    child: Text("Nenhuma solicitação de permuta encontrada."),
                  ),
          ],
        ),
      ),
    );
  }
}
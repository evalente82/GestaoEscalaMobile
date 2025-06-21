
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
  List<Map<String, dynamic>> _escalasExtrasParaCards = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    // Garante que os setores sejam carregados antes de processar extras e solicitações
    await _buscarSetores();
    await Future.wait([
      _buscarExtrasDisponiveis(),
      _buscarSolicitacoesExtras(), // Busque as solicitações APÓS os setores estarem disponíveis
    ]);
    _processarDadosExtrasParaCards(); // Processa os cards após extras e setores

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _buscarSolicitacoesExtras() async {
    try {
      // Usamos listen: false porque não queremos reconstruir o widget quando o modelo do usuário muda
      final userModel = Provider.of<UserModel>(context, listen: false);
      if (userModel.idFuncionario.isEmpty) {
        throw Exception("ID do funcionário não disponível.");
      }

      final response = await ApiClient.get("/solicitacaoEscalaExtra/BuscarPorId/${userModel.idFuncionario}");

      if (response["statusCode"] == 200) {
        List<dynamic> data = response["body"];
        setState(() {
          _solicitacoesExtrasDisponiveis = data.map((e) => _formatarEscalaExtra(e)).toList();
        });
      } else {
        throw Exception("Erro ${response["statusCode"]}");
      }
    } catch (e) {
      // É uma boa prática imprimir o erro para depuração, mas o SnackBar já informa o usuário
      print("❌ Erro ao carregar Solicitações de escalas extras: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao carregar Solicitações de escalas extras.")),
      );
    }
  }

  Future<void> _buscarExtrasDisponiveis() async {
    try {
      final response = await ApiClient.get('/escalaExtra/buscarExtras');

      if (response["statusCode"] == 200) {
        List<dynamic> data = response["body"];
        setState(() {
          _extrasDisponiveis = data.cast<Map<String, dynamic>>();
          //print("✅_extrasDisponiveis: $_extrasDisponiveis");
        });
      } else {
        throw Exception("Erro ${response["statusCode"]}");
      }
    } catch (e) {
      print("❌ Erro ao carregar escalas extras disponíveis: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao carregar escalas extras disponíveis.")),
      );
    }
  }

  Future<void> _buscarSetores() async {
    try {
      final response = await ApiClient.get('/setor/buscarTodos');
      if (response["statusCode"] == 200) {
        List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response["body"]);
        setState(() {
          _setores = data;
        });
      } else {
        throw Exception("Erro ${response["statusCode"]}");
      }
    } catch (e) {
      print("❌ Erro ao carregar setores: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao carregar setores.")),
      );
    }
  }

  void _processarDadosExtrasParaCards() {
    List<Map<String, dynamic>> tempCardsData = [];
    for (var extra in _extrasDisponiveis) {
      // Encontra o setor correspondente
      final setor = _setores.firstWhere(
        (s) => s["idSetor"] == extra["idSetor"],
        orElse: () => {"nmNome": "Sem setor", "nmDescricao": "Sem descrição"}, // Fallback
      );

      DateTime parseOrNull(String? iso) =>
          iso != null ? DateTime.tryParse(iso)! : DateTime(0);

      final dtServico = parseOrNull(extra["dtEscalaExtra"]);

      tempCardsData.add({
        "idCriacaoEscalaExtra": extra["idCriacaoEscalaExtra"], // Mantenha esta chave para o CadastroEscalaExtraScreen
        "titulo": extra["nmEscalaExtra"] ?? "Sem nome",
        "setorNome": setor["nmNome"], // Nome do setor
        "setorDescricao": setor["nmDescricao"], // Descrição do setor
        "vagas": extra["qtdVagas"] ?? 0, // Garante que 'vagas' seja um número, com fallback para 0
        "data": DateFormat("dd-MM-yyyy").format(dtServico),
        "hora": DateFormat("HH:mm").format(ajustarFusoHorario(dtServico)),
        ...extra, // Para passar todos os dados originais se necessário
      });
    }
     // ⭐ NOVIDADE: Ordenar os cards pela quantidade de vagas (maior primeiro)
    tempCardsData.sort((a, b) {
      // Converte para int para comparação segura, com fallback para 0
      int vagasA = (a["vagas"] is int) ? a["vagas"] : (int.tryParse(a["vagas"]?.toString() ?? '0') ?? 0);
      int vagasB = (b["vagas"] is int) ? b["vagas"] : (int.tryParse(b["vagas"]?.toString() ?? '0') ?? 0);
      return vagasB.compareTo(vagasA); // Para ordenar do maior para o menor
    });
    setState(() {
      _escalasExtrasParaCards = tempCardsData;
    });
  }

  DateTime ajustarFusoHorario(DateTime dt) {
    // Como estamos no Brasil e a hora da API é Z (UTC), subtrair 3 horas é o correto para Brasília/Rio (GMT-3)
    return dt.subtract(const Duration(hours: 3));
  }

  String formatarDataHora(DateTime dateTime) {
    final adjustedDateTime = ajustarFusoHorario(dateTime);
    return DateFormat("dd-MM-yyyy HH:mm").format(adjustedDateTime);
  }

  Map<String, dynamic> _formatarEscalaExtra(Map<String, dynamic> original) {
    DateTime parseOrNull(String? iso) =>
        iso != null ? DateTime.tryParse(iso)! : DateTime(0);

    final dtServico = parseOrNull(original["dtEscalaExtra"]);

    String setorNome = "Sem setor";
    // Priorize buscar pelo idSetor na lista de setores (que já está carregada)
    if (original.containsKey("idSetor") && original["idSetor"] != null) {
      final setorEncontrado = _setores.firstWhere(
        (s) => s["idSetor"] == original["idSetor"],
        orElse: () => {"nmNome": "Sem setor"}, // Fallback para "Sem setor" se não encontrar
      );
      setorNome = setorEncontrado["nmNome"];
    }
    // Se não encontrou pelo idSetor, mas a resposta da solicitação já tem o nome do setor diretamente
    else if (original.containsKey("nmSetor") && original["nmSetor"] != null) {
      setorNome = original["nmSetor"];
    }

    return {
      // Use 'idSolicitacaoEscalaExtra' se for o ID único da solicitação em si
      // Ou 'idCriacaoEscalaExtra' se for o ID da escala extra original que foi solicitada
      "id": original["idCriacaoEscalaExtra"] ?? original["idSolicitacaoEscalaExtra"],
      "titulo": original["nmEscalaExtra"] ?? "Sem nome",
      "setor": setorNome, // Agora ele deve buscar o nome correto do setor
      "vagas": original["qtdVagas"],
      "data": DateFormat("dd-MM-yyyy").format(dtServico),
      "hora": DateFormat("HH:mm").format(ajustarFusoHorario(dtServico)),
    };
  }

  void _navegarParaCadastro(Map<String, dynamic> escalaExtra) async {
    // Usamos 'await' aqui para esperar o retorno da tela de cadastro
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroEscalaExtraScreen(escalaExtra: escalaExtra),
      ),
    );
    // Quando a tela de cadastro é fechada (Navigator.pop), este código é executado
    // Recarregue apenas as solicitações para ser mais eficiente,
    // já que as escalas extras disponíveis e os setores provavelmente não mudaram.
    _fetchData();
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Indicador de carregamento
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Escalas Extras Disponíveis", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    // Se não houver extras disponíveis, exibe uma mensagem
                    _escalasExtrasParaCards.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("Nenhuma escala extra disponível no momento.", style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : Column(
                            children: _escalasExtrasParaCards.map((e) => _buildCardEscalaExtra(e)).toList(),
                          ),
                    const SizedBox(height: 30),
                    Text("RAS / Extras Solicitados", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    // Se não houver solicitações, exibe uma mensagem
                    _solicitacoesExtrasDisponiveis.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("Nenhuma solicitação de RAS / Extra encontrada.", style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : _buildTabelaSolicitacoes(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCardEscalaExtra(Map<String, dynamic> e) {
    String titulo = e["titulo"];
    String setorNome = e["setorNome"];
    String setorDescricao = e["setorDescricao"];
    // Converte 'vagas' para String. Se for nulo, use "N/A" ou "0" como fallback.
    int vagasInt = (e["vagas"] is int) ? e["vagas"] : (int.tryParse(e["vagas"]?.toString() ?? '0') ?? 0);
    String vagas = vagasInt.toString(); // Usa vagasInt para exibir
    String data = e["data"];
    String hora = e["hora"];

    return GestureDetector(
      // Condição para o onTap:
      onTap: vagasInt > 0
          ? () => _navegarParaCadastro(e)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sem vagas disponíveis.")),
              );
            },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(setorNome, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(setorDescricao, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 4),
              // Adicionado o campo "Vagas" aqui
              Text("Vagas: $vagas"), // Use a variável 'vagas' que já é String
              Text("Data: $data"),
              Text("Hora: $hora"),
            ],
          ),
        ),
      ),
    );
  }
}
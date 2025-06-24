
import 'package:escala_mobile/models/user_model.dart';
import 'package:escala_mobile/screens/EscalaExtra/cadastro_escala_extra.dart';
import 'package:escala_mobile/services/ApiClient.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// import 'dart:convert'; // Importe esta biblioteca no início do seu arquivo

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
    await _buscarSetores();
    await Future.wait([
      _buscarExtrasDisponiveis(),
      _buscarSolicitacoesExtras(),
    ]);
    _processarDadosExtrasParaCards();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _buscarSolicitacoesExtras() async {
    try {
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
          // JsonEncoder encoder = const JsonEncoder.withIndent('  ');
          // String formattedJson = encoder.convert(_extrasDisponiveis);
          //print("✅_extrasDisponiveis: $formattedJson");
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
    // Pega a data e hora atual do dispositivo e a converte para UTC
    // Depois, ajusta para o fuso horário local (GMT-3) para comparação
    final DateTime nowAdjustedForComparison = ajustarFusoHorario(DateTime.now().toUtc());

    for (var extra in _extrasDisponiveis) {
      bool isAtivo = false;
      if (extra.containsKey("isAtivo")) {
        if (extra["isAtivo"] is bool) {
          isAtivo = extra["isAtivo"];
        } else if (extra["isAtivo"] is int) {
          isAtivo = extra["isAtivo"] == 1;
        }
      }


      // Convertendo dtAbertura e dtFechamento para UTC e depois ajustando para o fuso horário local
      // Isso é crucial para que a comparação com 'nowAdjustedForComparison' seja precisa.
      DateTime? dtAberturaApi = DateTime.tryParse(extra["dtAbertura"] ?? '');
      DateTime? dtFechamentoApi = DateTime.tryParse(extra["dtFechamento"] ?? '');

      // Garantir que as datas da API sejam tratadas como UTC, se tiverem 'Z' já são.
      // Se não tiverem 'Z' e forem enviadas como local sem fuso, `toUtc()` as converterá.
      final DateTime dtAberturaUtc = dtAberturaApi?.toUtc() ?? DateTime(0);
      final DateTime dtFechamentoUtc = dtFechamentoApi?.toUtc() ?? DateTime(0);

      // Ajusta as datas de abertura e fechamento para o fuso horário local (GMT-3)
      final DateTime adjustedDtAbertura = ajustarFusoHorario(dtAberturaUtc);
      final DateTime adjustedDtFechamento = ajustarFusoHorario(dtFechamentoUtc);

      // Apenas adiciona o card se estiver ativo E dentro do período de abertura/fechamento
      if (isAtivo && nowAdjustedForComparison.isAfter(adjustedDtAbertura) && nowAdjustedForComparison.isBefore(adjustedDtFechamento)) {
        final setor = _setores.firstWhere(
          (s) => s["idSetor"] == extra["idSetor"],
          orElse: () => {"nmNome": "Sem setor", "nmDescricao": "Sem descrição"},
        );

        // A data do serviço (`dtEscalaExtra`) já vem em UTC, então `DateTime.tryParse` a interpretará corretamente.
        // Não precisamos de `.toUtc()` extra aqui se ela já tem o 'Z'.
        DateTime? dtServicoUtc = DateTime.tryParse(extra["dtEscalaExtra"] ?? '');
        final DateTime dtServico = dtServicoUtc ?? DateTime(0);

        tempCardsData.add({
          "idCriacaoEscalaExtra": extra["idCriacaoEscalaExtra"],
          "titulo": extra["nmEscalaExtra"] ?? "Sem nome",
          "setorNome": setor["nmNome"],
          "setorDescricao": setor["nmDescricao"],
          "vagas": extra["qtdVagas"] ?? 0,
          // Exibe a data e hora do serviço, ajustadas para o fuso horário local
          "data": DateFormat("dd-MM-yyyy").format(ajustarFusoHorario(dtServico)),
          "hora": DateFormat("HH:mm").format(ajustarFusoHorario(dtServico)),
          ...extra,
        });
      }
    }
<<<<<<< HEAD
    tempCardsData.sort((a, b) {
      int vagasA = (a["vagas"] is int) ? a["vagas"] : (int.tryParse(a["vagas"]?.toString() ?? '0') ?? 0);
      int vagasB = (b["vagas"] is int) ? b["vagas"] : (int.tryParse(b["vagas"]?.toString() ?? '0') ?? 0);
      return vagasB.compareTo(vagasA);
    });
    setState(() {
      _escalasExtrasParaCards = tempCardsData;
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
    // Como a API retorna datas em UTC ('Z'), subtrair 3 horas é o correto para GMT-3 (Brasília/Rio)
    return dt.subtract(const Duration(hours: 3));
  }

  String formatarDataHora(DateTime dateTime) {
    final adjustedDateTime = ajustarFusoHorario(dateTime);
    return DateFormat("dd-MM-yyyy HH:mm").format(adjustedDateTime);
  }

  Map<String, dynamic> _formatarEscalaExtra(Map<String, dynamic> original) {
    // Para as solicitações, o dtEscalaExtra já vem em UTC.
    DateTime? dtServicoUtc = DateTime.tryParse(original["dtEscalaExtra"] ?? '');
    final dtServico = dtServicoUtc ?? DateTime(0);

    String setorNome = "Sem setor";
    if (original.containsKey("idSetor") && original["idSetor"] != null) {
      final setorEncontrado = _setores.firstWhere(
        (s) => s["idSetor"] == original["idSetor"],
        orElse: () => {"nmNome": "Sem setor"},
      );
      setorNome = setorEncontrado["nmNome"];
    } else if (original.containsKey("nmSetor") && original["nmSetor"] != null) {
      setorNome = original["nmSetor"];
    }

    return {
      "id": original["idCriacaoEscalaExtra"] ?? original["idSolicitacaoEscalaExtra"],
      "titulo": original["nmEscalaExtra"] ?? "Sem nome",
      "setor": setorNome,
      "vagas": original["qtdVagas"],
      // Exibe a data e hora ajustadas para o fuso horário local
      "data": DateFormat("dd-MM-yyyy").format(ajustarFusoHorario(dtServico)),
      "hora": DateFormat("HH:mm").format(ajustarFusoHorario(dtServico)),
    };
  }

  void _navegarParaCadastro(Map<String, dynamic> escalaExtra) async {
    debugPrint("[Flutter] _navegarParaCadastro: Navegando para tela de cadastro.");
    // ignore: unused_local_variable
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
       builder: (context) => CadastroEscalaExtraScreen(escalaExtra: escalaExtra),
     ),
    );
    debugPrint("[Flutter] _navegarParaCadastro: Retorno da tela de cadastro. Recarregando dados.");
      await _fetchData();
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
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Escalas Extras Disponíveis", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
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
    int vagasInt = (e["vagas"] is int) ? e["vagas"] : (int.tryParse(e["vagas"]?.toString() ?? '0') ?? 0);
    String vagas = vagasInt.toString();
    String data = e["data"];
    String hora = e["hora"];

    return GestureDetector(
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
              Text("Vagas: $vagas"),
              Text("Data: $data"),
              Text("Hora: $hora"),
            ],
          ),
        ),
      ),
    );
  }
}
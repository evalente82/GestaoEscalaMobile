

import 'package:escala_mobile/models/user_model.dart';
import 'package:escala_mobile/screens/EscalaExtra/cadastro_escala_extra.dart';
import 'package:escala_mobile/services/ApiClient.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    await _buscarSetores();
    await Future.wait([
      _buscarExtrasDisponiveis(),
      _buscarSolicitacoesExtras(),
    ]);
    _processarDadosExtrasParaCards();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _buscarSolicitacoesExtras() async {
    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      if (userModel.idFuncionario.isEmpty) {
        throw Exception("ID do funcionário não disponível.");
      }

      final response = await ApiClient.get("/solicitacaoEscalaExtra/BuscarPorId/${userModel.idFuncionario}");

      if (mounted) {
        if (response["statusCode"] == 200) {
          List<dynamic> data = response["body"];
          setState(() {
            _solicitacoesExtrasDisponiveis = data.map((e) => _formatarSolicitacao(e)).toList();
          });
        } else {
          throw Exception("Erro ${response["statusCode"]}");
        }
      }
    } catch (e) {
      print("❌ Erro ao carregar Solicitações de escalas extras: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao carregar suas solicitações de extra.")),
        );
      }
    }
  }

  Future<void> _buscarExtrasDisponiveis() async {
    try {
      final response = await ApiClient.get('/escalaExtra/buscarExtras');
      if (mounted) {
        if (response["statusCode"] == 200) {
          List<dynamic> data = response["body"];
          setState(() {
            _extrasDisponiveis = data.cast<Map<String, dynamic>>();
          });
        } else {
          throw Exception("Erro ${response["statusCode"]}");
        }
      }
    } catch (e) {
      print("❌ Erro ao carregar escalas extras disponíveis: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao carregar escalas extras disponíveis.")),
        );
      }
    }
  }

  Future<void> _buscarSetores() async {
    try {
      final response = await ApiClient.get('/setor/buscarTodos');
      if (mounted) {
        if (response["statusCode"] == 200) {
          List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response["body"]);
          setState(() {
            _setores = data;
          });
        } else {
          throw Exception("Erro ${response["statusCode"]}");
        }
      }
    } catch (e) {
      print("❌ Erro ao carregar setores: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao carregar setores.")),
        );
      }
    }
  }

  void _processarDadosExtrasParaCards() {
    List<Map<String, dynamic>> tempCardsData = [];
    final DateTime nowAdjustedForComparison = ajustarFusoHorario(DateTime.now().toUtc());

    for (var extra in _extrasDisponiveis) {
      bool isAtivo = extra["isAtivo"] ?? false;
      DateTime? dtAberturaApi = DateTime.tryParse(extra["dtAbertura"] ?? '');
      DateTime? dtFechamentoApi = DateTime.tryParse(extra["dtFechamento"] ?? '');

      if (dtAberturaApi == null || dtFechamentoApi == null) continue;

      final DateTime adjustedDtAbertura = ajustarFusoHorario(dtAberturaApi.toUtc());
      final DateTime adjustedDtFechamento = ajustarFusoHorario(dtFechamentoApi.toUtc());

      if (isAtivo && nowAdjustedForComparison.isAfter(adjustedDtAbertura) && nowAdjustedForComparison.isBefore(adjustedDtFechamento)) {
        final setor = _setores.firstWhere((s) => s["idSetor"] == extra["idSetor"],
            orElse: () => {"nmNome": "Sem setor", "nmDescricao": "Sem descrição"});

        DateTime? dtServicoUtc = DateTime.tryParse(extra["dtEscalaExtra"] ?? '');
        if (dtServicoUtc == null) continue;
        final DateTime dtServico = ajustarFusoHorario(dtServicoUtc);

        tempCardsData.add({
          "idCriacaoEscalaExtra": extra["idCriacaoEscalaExtra"],
          "titulo": extra["nmEscalaExtra"] ?? "Sem nome",
          "setorNome": setor["nmNome"],
          "setorDescricao": setor["nmDescricao"],
          "vagas": extra["qtdVagas"] ?? 0,
          "data": DateFormat("dd/MM/yyyy").format(dtServico),
          "hora": DateFormat("HH:mm").format(dtServico),
          ...extra,
        });
      }
    }
    tempCardsData.sort((a, b) => (b["vagas"] ?? 0).compareTo(a["vagas"] ?? 0));
    
    if (mounted) {
      setState(() {
        _escalasExtrasParaCards = tempCardsData;
      });
    }
  }

  DateTime ajustarFusoHorario(DateTime dt) {
    return dt.subtract(const Duration(hours: 3));
  }

  Map<String, dynamic> _formatarSolicitacao(Map<String, dynamic> original) {
    DateTime? dtServicoUtc = DateTime.tryParse(original["dtEscalaExtra"] ?? '');
    final dtServico = dtServicoUtc != null ? ajustarFusoHorario(dtServicoUtc) : null;
    
    return {
      "idInscricao": original["idEscalaExtra"],
      "titulo": original["nmEscalaExtra"] ?? "Sem nome",
      "setor": original["nmSetor"] ?? "Sem setor",
      "data": dtServico != null ? DateFormat("dd/MM/yyyy").format(dtServico) : "N/A",
      "hora": dtServico != null ? DateFormat("HH:mm").format(dtServico) : "N/A",
      "statusInscricao": original["statusInscricao"]
    };
  }

  /// ===============================================================
  /// FUNÇÕES PARA CANCELAR INSCRIÇÃO
  /// ===============================================================

Future<void> _cancelarInscricaoExtra(String idInscricao) async {
    try {
      // 1. Monta a URL com o status como um "query parameter"
      final String url = "/solicitacaoEscalaExtra/AlterarStatusMobile/$idInscricao?statusInscricao=Cancelado";
      
      // 2. O corpo da requisição agora é vazio, pois o status já está na URL.
      final Map<String, dynamic> body = {};

      // A chamada continua sendo um PUT, que agora está correto.
      final response = await ApiClient.put(url, body);

      if (mounted) {
        if (response["statusCode"] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Inscrição cancelada com sucesso!")),
          );
          _fetchData(); // Recarrega os dados para atualizar a tela
        } else {
          // Tenta pegar uma mensagem de erro mais clara da API
          final errorMessage = response["body"]?["mensagem"] ?? "Erro desconhecido ao cancelar.";
          throw Exception(errorMessage);
        }
      }
    } catch (e) {
      print("❌ Erro ao cancelar inscrição: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
        );
      }
    }
  }

  void _mostrarConfirmacaoCancelar(String idInscricao, String titulo, String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmar Cancelamento"),
          content: Text("Tem certeza que deseja cancelar sua inscrição para:\n\n$titulo\nData: $data?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Voltar"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelarInscricaoExtra(idInscricao);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// ===============================================================

  void _navegarParaCadastro(Map<String, dynamic> escalaExtra) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroEscalaExtraScreen(escalaExtra: escalaExtra),
      ),
    );
    await _fetchData();
  }

  Widget _buildTabelaSolicitacoes() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 10,
        columns: const [
          DataColumn(label: Text("Título", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Setor", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Data", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Hora", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Status", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Ação", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
        rows: _solicitacoesExtrasDisponiveis.map((e) {
          final bool isCancelavel = e["statusInscricao"] == "Confirmado" || e["statusInscricao"] == "FilaDeEspera";
          
          return DataRow(
            cells: [
              DataCell(Text(e["titulo"] ?? '', style: const TextStyle(fontSize: 11))),
              DataCell(Text(e["setor"] ?? '', style: const TextStyle(fontSize: 11))),
              DataCell(Text(e["data"] ?? '', style: const TextStyle(fontSize: 11))),
              DataCell(Text(e["hora"] ?? '', style: const TextStyle(fontSize: 11))),
              DataCell(
                Chip(
                  label: Text(e["statusInscricao"] ?? 'N/A', style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: e["statusInscricao"] == "Confirmado" ? Colors.green : (e["statusInscricao"] == "FilaDeEspera" ? Colors.orange : Colors.grey),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                )
              ),
              DataCell(
                isCancelavel
                ? IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    tooltip: 'Cancelar Inscrição',
                    onPressed: () => _mostrarConfirmacaoCancelar(e["idInscricao"], e["titulo"], e["data"]),
                  )
                : const SizedBox.shrink(),
              ),
            ],
          );
        }).toList(),
      ),
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
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Escalas Extras Disponíveis", style: Theme.of(context).textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFF003580)),
                          tooltip: 'Atualizar lista',
                          onPressed: _fetchData,
                        ),
                      ],
                    ),
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
    String data = e["data"];
    String hora = e["hora"];
    int vagasInt = e["vagas"] ?? 0;
    int filaEsperaInt = e["qtdFilaEspera"] ?? 0;

    return GestureDetector(
      onTap: (vagasInt > 0 || filaEsperaInt > 0)
          ? () => _navegarParaCadastro(e)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sem vagas disponíveis ou na fila de espera.")),
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
              Text("Vagas: $vagasInt"),
              Text("Fila de Espera: $filaEsperaInt"),
              Text("Data: $data"),
              Text("Hora: $hora"),
            ],
          ),
        ),
      ),
    );
  }
}
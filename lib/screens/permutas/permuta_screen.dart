import 'package:escala_mobile/models/user_model.dart';
import 'package:escala_mobile/services/ApiClient.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:escala_mobile/screens/permutas/solicitacoes_permuta_screen.dart'; // Corrigido o import

class PermutaScreen extends StatefulWidget {
  const PermutaScreen({super.key});

  @override
  State<PermutaScreen> createState() => _PermutaScreenState();
}

class _PermutaScreenState extends State<PermutaScreen> {
  String? _idEscalaSelecionada;
  String? _idFuncionarioSolicitado;
  String? _dataSelecionada;

  List<Map<String, dynamic>> _escalas = [];
  List<Map<String, dynamic>> _funcionariosEscala = [];
  List<Map<String, dynamic>> _permutasSolicitadas = [];
  List<Map<String, dynamic>> _datasTrabalhoUsuario = [];
  List<String> _datasFiltradasPorEscala = [];

  @override
  void initState() {
    super.initState();
    _carregarEscalasUsuarioLogado();
    _buscarPermutasSolicitadas();
    _loadPendingPermutasCount();
  }

  Future<void> _loadPendingPermutasCount() async {
    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      if (userModel.idFuncionario.isEmpty) {
        print("⚠️ ID do funcionário não disponível.");
        return;
      }

      final String url = "/permutas/ContarPendentes/${userModel.idFuncionario}";
      print("📡 Buscando contagem de permutas pendentes: $url");

      final response = await ApiClient.get(url);
      if (response["statusCode"] == 200) {
        final int count = response["body"] as int;
        userModel.setInitialNotificationCount(count);
        print("✅ Contagem de permutas pendentes carregada: $count");
      } else {
        print("❌ Erro ao buscar contagem de permutas: ${response["statusCode"]} - ${response["body"]}");
      }
    } catch (e) {
      print("❌ Exceção ao carregar contagem de permutas: $e");
    }
  }

  Future<void> _carregarEscalasUsuarioLogado() async {
    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      if (userModel.idFuncionario.isEmpty) {
        throw Exception("ID do funcionário não disponível.");
      }
      final String url = "/escalaPronta/BuscarPorFuncionario/${userModel.idFuncionario}";
      print("📡 Fazendo requisição para: $url");

      final response = await ApiClient.get(url);
      if (response["statusCode"] == 200) { // Ajustado para o novo formato do ApiClient
        final List<dynamic> data = response["body"];

        Set<String> escalasUnicas = {};
        final List<Map<String, dynamic>> escalas = data.map((e) {
          String escalaNome = "${e["nmNomeEscala"]} - ${DateFormat("MMMM", "pt_BR").format(DateTime.parse(e["dtDataServico"]))}";
          if (escalasUnicas.contains(escalaNome)) return null;
          escalasUnicas.add(escalaNome);
          return {"id": e["idEscala"].toString(), "nome": escalaNome}; // Garantir que id seja string
        }).where((element) => element != null).cast<Map<String, dynamic>>().toList();

        final List<Map<String, dynamic>> todasAsDatas = data
            .map((e) => {
                  "idEscala": e["idEscala"].toString(),
                  "data": DateFormat("dd-MM-yyyy").format(DateTime.parse(e["dtDataServico"])),
                })
            .toList();

        setState(() {
          _escalas = escalas;
          _datasTrabalhoUsuario = todasAsDatas;
          _datasFiltradasPorEscala = [];
        });

        print("✅ Escalas carregadas: ${_escalas.length}");
        print("✅ Datas carregadas: ${_datasTrabalhoUsuario}");
      } else {
        throw Exception("Erro ao carregar escalas. Código: ${response["statusCode"]}");
      }
    } catch (e) {
      print("❌ Exceção capturada: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao carregar escalas: $e")));
    }
  }

  void _filtrarDatasPorEscala(String idEscala) {
    setState(() {
      _datasFiltradasPorEscala = _datasTrabalhoUsuario
          .where((e) => e["idEscala"] == idEscala)
          .map((e) => e["data"].toString())
          .toList()
        ..sort((a, b) {
          final DateTime dataA = DateFormat("dd-MM-yyyy").parse(a);
          final DateTime dataB = DateFormat("dd-MM-yyyy").parse(b);
          return dataA.compareTo(dataB);
        });

      print("📅 Datas filtradas para a escala $idEscala: $_datasFiltradasPorEscala");
    });
  }

  Future<void> _buscarFuncionariosEscala(String idEscala) async {
    try {
      final String urlEscala = "/escalaPronta/buscarPorId/$idEscala";
      final String urlFuncionarios = "/funcionario/buscarTodos";

      print("📡 Buscando funcionários da escala: $urlEscala");
      print("📡 Buscando lista completa de funcionários: $urlFuncionarios");

      final responseEscala = await ApiClient.get(urlEscala);
      final responseFuncionarios = await ApiClient.get(urlFuncionarios);

      if (responseEscala["statusCode"] == 200 && responseFuncionarios["statusCode"] == 200) {
        final List<dynamic> dataEscala = responseEscala["body"];
        final List<dynamic> dataFuncionarios = responseFuncionarios["body"];

        Set<String> idsFuncionariosEscala = dataEscala.map<String>((f) => f["idFuncionario"].toString()).toSet();

        final List<Map<String, dynamic>> funcionarios = dataFuncionarios
            .where((funcionario) => idsFuncionariosEscala.contains(funcionario["idFuncionario"]?.toString() ?? ""))
            .map((f) => {
                  "idFuncionario": f["idFuncionario"]?.toString() ?? "",
                  "nmNome": f["nmNome"] ?? "Nome Desconhecido",
                  "nrMatricula": f["nrMatricula"]?.toString() ?? "Sem Matrícula",
                })
            .toList();

        setState(() {
          _funcionariosEscala = funcionarios;
        });

        _filtrarFuncionariosDisponiveis();
        print("✅ Funcionários carregados (${_funcionariosEscala.length} encontrados)");
      } else {
        throw Exception("Erro ao buscar funcionários. Código: ${responseEscala["statusCode"]} ou ${responseFuncionarios["statusCode"]}");
      }
    } catch (e) {
      print("❌ Erro ao buscar funcionários: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao buscar funcionários: $e")));
    }
  }

  void _filtrarFuncionariosDisponiveis() {
    final userModel = Provider.of<UserModel>(context, listen: false);

    setState(() {
      _funcionariosEscala = _funcionariosEscala.where((funcionario) {
        final List<String> datasSolicitante = _datasTrabalhoUsuario
            .where((e) => e["idEscala"] == _idEscalaSelecionada)
            .map((e) => e["data"].toString())
            .toList();

        bool trabalhaNoMesmoDia = _datasTrabalhoUsuario.any((f) =>
            f["idFuncionario"] == funcionario["idFuncionario"] &&
            f["idEscala"] == _idEscalaSelecionada &&
            datasSolicitante.contains(f["data"].toString()));

        return !trabalhaNoMesmoDia && funcionario["idFuncionario"] != userModel.idFuncionario;
      }).toList();
    });

    print("✅ Funcionários disponíveis filtrados: ${_funcionariosEscala.length}");
  }

  Future<void> _enviarSolicitacaoPermuta() async {
    try {
      if (_idEscalaSelecionada == null || _idFuncionarioSolicitado == null || _dataSelecionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha todos os campos.")));
        return;
      }

      final userModel = Provider.of<UserModel>(context, listen: false);
      final String url = "/permutas/Incluir";

      final Map<String, dynamic> permutaData = {
        "dtDataSolicitadaTroca": DateFormat("yyyy-MM-dd'T'00:00:00.000'Z'").format(DateFormat("dd-MM-yyyy").parse(_dataSelecionada!)),
        "dtSolicitacao": DateTime.now().toUtc().toIso8601String(),
        "idEscala": _idEscalaSelecionada,
        "idFuncionarioSolicitado": _idFuncionarioSolicitado,
        "idFuncionarioSolicitante": userModel.idFuncionario,
        "nmNomeSolicitado": _funcionariosEscala.firstWhere((f) => f["idFuncionario"] == _idFuncionarioSolicitado)["nmNome"],
        "nmNomeSolicitante": userModel.userName.isNotEmpty ? userModel.userName : "Usuário",
      };

      print("📡 Enviando requisição para: $url");
      print("📤 Dados enviados: $permutaData");

      final response = await ApiClient.post(url, permutaData);
      if (response["statusCode"] == 200) {
        print("✅ Permuta cadastrada com sucesso!");
        _buscarPermutasSolicitadas();
        _mostrarDialogoSucesso();
      } else {
        throw Exception("Erro ao cadastrar permuta. Código: ${response["statusCode"]}");
      }
    } catch (e) {
      print("❌ Erro ao enviar permuta: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao enviar permuta: $e")));
    }
  }

  void _mostrarDialogoSucesso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Permuta Solicitada"),
          content: const Text("A solicitação de permuta foi enviada com sucesso!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _limparCampos();
                _buscarPermutasSolicitadas();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _limparCampos() {
    setState(() {
      _idEscalaSelecionada = null;
      _idFuncionarioSolicitado = null;
      _dataSelecionada = null;
      _funcionariosEscala = [];
      _datasFiltradasPorEscala = [];
    });
  }

  Future<void> _buscarPermutasSolicitadas() async {
    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      if (userModel.idFuncionario.isEmpty) {
        throw Exception("ID do funcionário não disponível.");
      }
      final String url = "/permutas/PermutaFuncionarioPorId/${userModel.idFuncionario}";

      print("📡 Buscando permutas solicitadas: $url");

      final response = await ApiClient.get(url);
      if (response["statusCode"] == 200) {
        final List<dynamic> data = response["body"];

        setState(() {
          _permutasSolicitadas = data.where((p) =>
              p["nmNomeSolicitante"] != null &&
              p["nmNomeSolicitado"] != null &&
              p["dtDataSolicitadaTroca"] != null).map((p) => {
                "solicitante": p["nmNomeSolicitante"] ?? "",
                "solicitado": p["nmNomeSolicitado"] ?? "",
                "dataSolicitadaTroca": p["dtDataSolicitadaTroca"] != null
                    ? _formatarData(p["dtDataSolicitadaTroca"])
                    : "",
                "aprovado": p["nmAprovador"] != null,
                "nmStatus": p["nmStatus"] ?? "",
              }).toList();
        });

        print("✅ Permutas carregadas: ${_permutasSolicitadas.length}");
      } else {
        throw Exception("Erro ao buscar permutas. Código: ${response["statusCode"]}");
      }
    } catch (e) {
      print("❌ Erro ao buscar permutas: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao buscar permutas: $e")));
    }
  }

  String _formatarData(String? dataISO) {
    if (dataISO == null || dataISO.isEmpty) return "N/A";
    final DateTime data = DateTime.parse(dataISO);
    return DateFormat("dd-MM-yyyy").format(data);
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Solicitar Permuta", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF003580),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Solicitante", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                    child: Text(userModel.userName.isNotEmpty ? userModel.userName : "Usuário"),
                  ),
                ),
                const SizedBox(width: 16),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SolicitacoesPermutasScreen()))
                            .then((_) {
                              _buscarPermutasSolicitadas();
                            });
                        userModel.clearNotificationCount();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003580),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text("Solicitações", style: TextStyle(fontSize: 14, color: Colors.white)),
                    ),
                    if (userModel.notificationCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text(
                            userModel.notificationCount > 9 ? "!" : userModel.notificationCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text("Selecione a Escala", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _idEscalaSelecionada,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _escalas.map((escala) {
                return DropdownMenuItem<String>(value: escala["id"], child: Text(escala["nome"]));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _idEscalaSelecionada = value;
                    _buscarFuncionariosEscala(value);
                    _filtrarDatasPorEscala(value);
                  });
                }
              },
              hint: const Text("Selecione uma escala"),
            ),
            const SizedBox(height: 16),

            Text("Selecione o Solicitado", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _idFuncionarioSolicitado,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _funcionariosEscala.isNotEmpty
                  ? _funcionariosEscala.map((funcionario) {
                      return DropdownMenuItem<String>(
                        value: funcionario["idFuncionario"],
                        child: Text("${funcionario["nmNome"]} - ${funcionario["nrMatricula"]}"),
                      );
                    }).toList()
                  : [],
              onChanged: (value) {
                setState(() {_idFuncionarioSolicitado = value;});
              },
              hint: Text(_funcionariosEscala.isNotEmpty ? "Selecione um funcionário" : "Nenhum funcionário disponível"),
            ),
            const SizedBox(height: 16),

            Text("Selecione a Data", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _dataSelecionada,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _datasFiltradasPorEscala.isNotEmpty
                  ? _datasFiltradasPorEscala.map((data) {
                      return DropdownMenuItem<String>(value: data, child: Text(data));
                    }).toList()
                  : [],
              onChanged: (value) {
                setState(() {_dataSelecionada = value;});
              },
              hint: Text(_datasFiltradasPorEscala.isNotEmpty ? "Selecione uma data" : "Nenhuma data disponível"),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {Navigator.pop(context);},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Cancelar", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: _enviarSolicitacaoPermuta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003580),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Solicitar", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text("Permutas Solicitadas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            _permutasSolicitadas.isNotEmpty
                ? SizedBox(
                    width: MediaQuery.of(context).size.width - 32,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columnSpacing: 6,
                        columns: const [
                          DataColumn(label: Text("Solicitante", style: TextStyle(fontSize: 12))),
                          DataColumn(label: Text("Solicitado", style: TextStyle(fontSize: 12))),
                          DataColumn(label: Text("Aceito", style: TextStyle(fontSize: 12))),
                          DataColumn(label: Text("Data", style: TextStyle(fontSize: 12))),
                          DataColumn(label: Text("Autorizado", style: TextStyle(fontSize: 12))),
                        ],
                        rows: _permutasSolicitadas.map((p) {
                          return DataRow(cells: [
                            DataCell(
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 80),
                                child: Text(p["solicitante"] ?? "", style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 80),
                                child: Text(p["solicitado"] ?? "", style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            DataCell(
                              Container(
                                alignment: Alignment.center,
                                child: p["nmStatus"] == "RecusadaSolicitado"
                                    ? Icon(Icons.close, color: Colors.red, size: 20)
                                    : Checkbox(
                                        value: p["nmStatus"] != null && (p["nmStatus"] == "AprovadaSolicitado" || p["nmStatus"] == "Aprovada"),
                                        onChanged: null,
                                      ),
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 70),
                                child: Text(p["dataSolicitadaTroca"] ?? "", style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            DataCell(
                              Container(
                                alignment: Alignment.center,
                                child: p["nmStatus"] == "Recusada"
                                    ? Icon(Icons.close, color: Colors.red, size: 20)
                                    : Checkbox(
                                        value: p["nmStatus"] != null && (p["nmStatus"] == "Aprovada"),
                                        onChanged: null,
                                      ),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
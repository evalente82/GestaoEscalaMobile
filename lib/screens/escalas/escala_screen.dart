import 'package:escala_mobile/services/ApiClient.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:escala_mobile/models/user_model.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart'; // Importante para formatação de data
import 'package:syncfusion_flutter_datagrid/datagrid.dart'; // Importação do DataGrid

final logger = Logger();

// Nova classe modelo para representar uma linha da tabela (um dia de escala)
class DailyEscala {
  final DateTime date; // A data completa para calcular dia-sem e fim de semana
  final Map<String, List<String>> postoFuncionarios; // Mapa: { 'nomePosto': ['Func1', 'Func2'] }

  DailyEscala({
    required this.date,
    required this.postoFuncionarios,
  });
}

// Classe customizada para ser a fonte de dados do SfDataGrid
class EscalaDataSource extends DataGridSource {
  List<DailyEscala> _dailyEscalas;
  List<String> _postosFiltrados;
  Map<DateTime, Map<String, List<String>>> _agrupamentoOriginal;

  EscalaDataSource({
    required List<DailyEscala> dailyEscalas,
    required List<String> postosFiltrados,
    required Map<DateTime, Map<String, List<String>>> agrupamentoOriginal,
  })  : _dailyEscalas = dailyEscalas,
        _postosFiltrados = postosFiltrados,
        _agrupamentoOriginal = agrupamentoOriginal {
    _buildDataGridRows();
  }

  List<DataGridRow> _dataGridRows = [];

  void _buildDataGridRows() {
    _dataGridRows = _dailyEscalas.map<DataGridRow>((e) {
      return DataGridRow(cells: [
        DataGridCell<DateTime>( // Mudei para DateTime aqui para usar a data real
          columnName: 'dia_sem',
          value: e.date, // Passa o objeto DateTime completo
        ),
        // Células dinâmicas para os postos
        ..._postosFiltrados.map((postoName) {
          final List<String> funcionarios = e.postoFuncionarios[postoName] ?? ["-"];
          return DataGridCell<List<String>>(
            columnName: postoName,
            value: funcionarios,
          );
        }).toList(),
      ]);
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    final DateTime rowDate = row.getCells()[0].value as DateTime; // Pega a data real da célula Dia-Sem
    final isWeekend = rowDate.weekday == DateTime.saturday || rowDate.weekday == DateTime.sunday;

    return DataGridRowAdapter(
      color: isWeekend ? Colors.grey.withOpacity(0.2) : null, // Aplica cor da linha
      cells: row.getCells().map<Widget>((dataGridCell) {
        // Se for a coluna Dia-Sem
        if (dataGridCell.columnName == 'dia_sem') {
          // Formata o DateTime para a exibição "DD-EEE"
          final String displayValue = "${DateFormat("dd").format(dataGridCell.value as DateTime)}-${DateFormat("EEE", "pt_BR").format(dataGridCell.value as DateTime).toUpperCase()}";
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey[300]!)), // Borda direita
            ),
            child: Text(
              displayValue,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          );
        }
        // Se for uma coluna de posto (funcionários)
        else {
          final List<String> funcionarios = dataGridCell.value as List<String>;
          return Container(
            alignment: Alignment.topLeft, // Alinha ao topo esquerdo
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey[300]!)), // Borda direita
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: funcionarios.map((func) => Text(
                func,
                style: const TextStyle(fontSize: 12),
                softWrap: true,
                overflow: TextOverflow.visible, // Permite que o texto se torne visível se a linha for grande o suficiente
              )).toList(),
            ),
          );
        }
      }).toList(),
    );
  }

  // Método para calcular a altura da linha baseado no conteúdo
  // Chamado pelo SfDataGrid via onQueryRowHeight
  double calculateMaxCellHeight(DateTime dia) { // Este método deve estar aqui
    double maxHeight = 60.0; // Altura mínima padrão para uma linha

    final Map<String, List<String>>? postosDoDia = _agrupamentoOriginal[dia];
    if (postosDoDia != null) {
      for (var posto in _postosFiltrados) {
        final List<String> funcionarios = postosDoDia[posto] ?? ["-"];
        // Estimativa: cada linha de texto ocupa ~16px (fontsize 12 + line spacing).
        // Adicione 16px de padding vertical (8px top + 8px bottom).
        final double estimatedHeight = (funcionarios.length * 16.0) + 16.0;
        if (estimatedHeight > maxHeight) {
          maxHeight = estimatedHeight;
        }
      }
    }
    return maxHeight;
  }

  // Método para atualizar os dados, chamará _buildDataGridRows novamente
  void updateDataGridSource({
    required List<DailyEscala> newDailyEscalas,
    required List<String> newPostosFiltrados,
    required Map<DateTime, Map<String, List<String>>> newAgrupamentoOriginal,
  }) {
    _dailyEscalas = newDailyEscalas;
    _postosFiltrados = newPostosFiltrados;
    _agrupamentoOriginal = newAgrupamentoOriginal;
    _buildDataGridRows();
    notifyListeners(); // Notifica o DataGrid para reconstruir
  }
}

class EscalaScreen extends StatefulWidget {
  const EscalaScreen({super.key});

  @override
  State<EscalaScreen> createState() => _EscalaScreenState();
}

class _EscalaScreenState extends State<EscalaScreen> {
  String? _idEscalaSelecionada;
  List<Map<String, dynamic>> _escalas = [];
  Map<String, String> _postos = {};
  List<String> _postosFiltrados = [];
  List<Map<String, dynamic>> _escalaPronta = [];
  Map<String, String> _funcionarios = {};

  // Instância do DataGridSource
  late EscalaDataSource _escalaDataSource;

  @override
  void initState() {
    super.initState();
    // Inicializa o dataSource vazio no initState
    _escalaDataSource = EscalaDataSource(
      dailyEscalas: [],
      postosFiltrados: [],
      agrupamentoOriginal: {}, // Inicializa vazio
    );

    _carregarEscalasUsuarioLogado();
    _carregarPostos();
    _carregarFuncionarios();

    // REMOVA TODOS OS LISTENERS DE SCROLL CONTROLLERS AQUI.
    // O SfDataGrid lida com a rolagem internamente.
  }

  @override
  void dispose() {
    // REMOVA TODOS OS DISPOSE DE SCROLL CONTROLLERS AQUI.
    // O SfDataGrid gerencia isso.
    super.dispose();
  }

  Future<void> _carregarEscalasUsuarioLogado() async {
    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      if (userModel.idFuncionario.isEmpty) {
        throw Exception("ID do funcionário não disponível.");
      }
      final String url = "/escalaPronta/BuscarPorFuncionario/${userModel.idFuncionario}";
      final response = await ApiClient.get(url);

      if (response["statusCode"] == 200) {
        final List<dynamic> data = response["body"];
        Set<String> escalasUnicas = {};
        final List<Map<String, dynamic>> escalas = data
            .map((e) {
              String escalaNome = "${e["nmNomeEscala"]} - ${DateFormat("MMMM", "pt_BR").format(DateTime.parse(e["dtDataServico"]))}";
              if (escalasUnicas.contains(escalaNome)) return null;
              escalasUnicas.add(escalaNome);
              return {
                "id": e["idEscala"]?.toString() ?? "",
                "nome": escalaNome,
              };
            })
            .where((element) => element != null)
            .cast<Map<String, dynamic>>()
            .toList();

        setState(() {
          _escalas = escalas;
        });
        logger.i("✅ Escalas carregadas: ${_escalas.length}");
      } else {
        throw Exception("Erro ao carregar escalas. Código: ${response["statusCode"]}");
      }
    } catch (e) {
      logger.e("Erro ao carregar escalas: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar escalas: $e")),
        );
      }
    }
  }

  Future<void> _carregarPostos() async {
    try {
      final String url = "/PostoTrabalho/buscarTodos";
      final response = await ApiClient.get(url);

      if (response["statusCode"] == 200) {
        final List<dynamic> data = response["body"];
        setState(() {
          _postos = {for (var posto in data) posto["idPostoTrabalho"].toString(): posto["nmNome"].toString()};
        });
        logger.i("✅ Postos carregados: ${_postos.length}");
      } else {
        throw Exception("Erro ao carregar postos. Código: ${response["statusCode"]}");
      }
    } catch (e) {
      logger.e("Erro ao carregar postos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar postos: $e")),
        );
      }
    }
  }

  Future<void> _carregarFuncionarios() async {
    try {
      final String url = "/Funcionario/buscarTodos";
      final response = await ApiClient.get(url);

      if (response["statusCode"] == 200) {
        final List<dynamic> data = response["body"];
        setState(() {
          _funcionarios = {for (var func in data) func["idFuncionario"].toString(): func["nmNome"].toString()};
        });
        logger.i("✅ Funcionários carregados: ${_funcionarios.length}");
      } else {
        throw Exception("Erro ao carregar funcionários. Código: ${response["statusCode"]}");
      }
    } catch (e) {
      logger.e("Erro ao carregar funcionários: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar funcionários: $e")),
        );
      }
    }
  }

  Future<void> _filtrarPostosPorEscala(String idEscala) async {
    try {
      final String url = "/escalaPronta/buscarPorId/$idEscala";
      final response = await ApiClient.get(url);

      if (response["statusCode"] == 200) {
        final List<dynamic> data = response["body"];

        List<Map<String, dynamic>> escalaFiltrada = data.map((e) {
          return {
            "dtDataServico": e["dtDataServico"] ?? "",
            "idPostoTrabalho": e["idPostoTrabalho"]?.toString() ?? "",
            "idFuncionario": e["idFuncionario"]?.toString() ?? ""
          };
        }).toList();

        Set<String> idsPostosNaEscala = escalaFiltrada.map((e) => e["idPostoTrabalho"].toString()).toSet();
        List<String> postosFiltrados = idsPostosNaEscala.map((id) => _postos[id] ?? "Posto Desconhecido").toList();

        // Agrupar os dados e preparar para o DataGrid
        final Map<DateTime, Map<String, List<String>>> groupedData = _agruparEscala();
        final List<DailyEscala> newDailyEscalas = [];
        final sortedDays = groupedData.keys.toList()..sort((a, b) => a.compareTo(b));
        for (var day in sortedDays) {
          newDailyEscalas.add(DailyEscala(
            date: day,
            postoFuncionarios: groupedData[day]!,
          ));
        }

        setState(() {
          _escalaPronta = escalaFiltrada;
          _postosFiltrados = postosFiltrados;
          // Atualiza o dataSource do DataGrid com os novos dados
          _escalaDataSource.updateDataGridSource(
            newDailyEscalas: newDailyEscalas,
            newPostosFiltrados: postosFiltrados,
            newAgrupamentoOriginal: groupedData,
          );
        });
        logger.i("✅ Postos filtrados para escala $idEscala: ${_postosFiltrados.length}");
      } else {
        throw Exception("Erro ao carregar postos da escala. Código: ${response["statusCode"]}");
      }
    } catch (e) {
      logger.e("Erro ao carregar postos da escala: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar postos da escala: $e")),
        );
      }
    }
  }

  Map<DateTime, Map<String, List<String>>> _agruparEscala() {
    Map<DateTime, Map<String, List<String>>> escalaAgrupada = {};

    for (var item in _escalaPronta) {
      DateTime dataServico = DateTime.parse(item["dtDataServico"]);
      // Normaliza para o início do dia para agrupar corretamente
      DateTime diaNormalizado = DateTime(dataServico.year, dataServico.month, dataServico.day);

      String posto = _postos[item["idPostoTrabalho"]] ?? "Posto Desconhecido";
      String funcionario = item["idFuncionario"] == "00000000-0000-0000-0000-000000000000"
          ? "Sem Funcionário"
          : _funcionarios[item["idFuncionario"]] ?? "Funcionário Desconhecido";

      if (!escalaAgrupada.containsKey(diaNormalizado)) {
        escalaAgrupada[diaNormalizado] = {};
      }

      if (!escalaAgrupada[diaNormalizado]!.containsKey(posto)) {
        escalaAgrupada[diaNormalizado]![posto] = [];
      }

      escalaAgrupada[diaNormalizado]![posto]!.add(funcionario);
    }

    return escalaAgrupada;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escala", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF003580),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                value: _idEscalaSelecionada,
                items: _escalas.map((escala) {
                  return DropdownMenuItem<String>(
                    value: escala["id"],
                    child: Text(
                      escala["nome"],
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _idEscalaSelecionada = value;
                      _filtrarPostosPorEscala(value);
                    });
                  }
                },
                hint: const Text(
                  "Selecione uma escala",
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ),
          ),
          if (_escalaPronta.isNotEmpty) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SfDataGrid(
                  source: _escalaDataSource,
                  frozenColumnsCount: 1, // Fixa a primeira coluna ("Dia-Sem")
                  // frozenRowsCount: 1, // Fixa o cabeçalho. Já é padrão.
                  headerRowHeight: 40,
                  rowHeight: 60, // Altura padrão que será ajustada por onQueryRowHeight
                  gridLinesVisibility: GridLinesVisibility.both,
                  headerGridLinesVisibility: GridLinesVisibility.both,
                  selectionMode: SelectionMode.none, // Ou o que você precisar
                  allowColumnsResizing: true, // Opcional: permite redimensionar colunas
                  columnWidthMode: ColumnWidthMode.fill, // Distribui as colunas igualmente
                  
                  // Callback para altura de linha dinâmica
                  onQueryRowHeight: (details) {
                    // Obtém o objeto DailyEscala da linha atual
                    // Acessamos _dailyEscalas da fonte de dados usando o rowIndex.
                    final DailyEscala dailyEscala = _escalaDataSource._dailyEscalas[details.rowIndex];
                    // Chama o método calculateMaxCellHeight da instância do DataGridSource
                    return _escalaDataSource.calculateMaxCellHeight(dailyEscala.date);
                  },

                  columns: <GridColumn>[
                    GridColumn(
                      columnName: 'dia_sem',
                      width: 80, // Largura fixa da coluna "Dia-Sem"
                      label: Container(
                        padding: const EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: const Text(
                          'Dia-Sem',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    // Mapeia os postos filtrados para colunas dinamicamente
                    ..._postosFiltrados.map((posto) => GridColumn(
                      columnName: posto, // Nome da coluna como o nome do posto
                      width: 150, // Largura padrão para as colunas de postos
                      label: Container(
                        padding: const EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: Text(
                          posto,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis, // Para o cabeçalho
                        ),
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Expanded(
              child: Center(
                child: Text("Nenhuma escala carregada ou selecionada."),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
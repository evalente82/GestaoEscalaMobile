

import 'package:escala_mobile/services/ApiClient.dart';

class ApiService {
  Future<List<Map<String, dynamic>>> buscarEscalasAtivas() async {
    final response = await ApiClient.get("/escala/buscarTodos");
    if (response["statusCode"] == 200) {
      final List<dynamic> data = response["body"];
      return data
          .where((e) => e["isAtivo"] == true && e["isGerada"] == true)
          .map((e) => {
                "id": e["idEscala"],
                "nmNomeEscala": e["nmNomeEscala"],
                "nrMesReferencia": e["nrMesReferencia"]
              })
          .toList();
    } else {
      throw Exception("Erro ao buscar escalas: ${response["statusCode"]}");
    }
  }

  Future<List<Map<String, dynamic>>> buscarFuncionariosPorEscala(String idEscala) async {
    final response = await ApiClient.get("/escalaPronta/buscarPorId/$idEscala");
    if (response["statusCode"] == 200) {
      final List<dynamic> data = response["body"];
      return data.map((f) => {
            "idFuncionario": f["idFuncionario"],
            "nmNome": f["nmNome"],
            "nrMatricula": f["nrMatricula"]
          }).toList();
    } else {
      throw Exception("Erro ao buscar funcionários da escala: ${response["statusCode"]}");
    }
  }

  Future<List<String>> buscarDatasTrabalho(String idEscala, String matricula) async {
    try {
      final response = await ApiClient.get("/escalaPronta/buscarDatasPorFuncionario/$idEscala/$matricula");
      if (response["statusCode"] == 200) {
        final List<dynamic> data = response["body"];
        return data.map((item) => item.toString()).toList();
      } else {
        throw Exception("Erro ao buscar datas de trabalho. Código: ${response["statusCode"]}");
      }
    } catch (e) {
      throw Exception("Erro ao buscar datas de trabalho: $e");
    }
  }

  Future<List<Map<String, dynamic>>> buscarEscalasPorFuncionario(String idFuncionario) async {
    try {
      final response = await ApiClient.get("/escalaPronta/BuscarPorFuncionario/$idFuncionario");
      if (response["statusCode"] == 200) {
        final List<dynamic> data = response["body"];
        return data.map((e) => {
              "id": e["idEscala"],
              "nmNomeEscala": e["nmNomeEscala"],
              "nrMesReferencia": e["nrMesReferencia"],
            }).toList();
      } else {
        throw Exception("Erro ao buscar escalas por funcionário. Código: ${response["statusCode"]}");
      }
    } catch (e) {
      throw Exception("Erro ao buscar escalas por funcionário: $e");
    }
  }
}
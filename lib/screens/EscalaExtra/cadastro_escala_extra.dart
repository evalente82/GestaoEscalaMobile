
import 'package:escala_mobile/models/user_model.dart';
import 'package:escala_mobile/services/ApiClient.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Removidos os imports específicos para WebView:
// import 'package:webview_flutter/webview_flutter.dart';
// import 'dart:io' show Platform;
// import 'package:webview_flutter_android/webview_flutter_android.dart';
// import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

// Import para JS interop (apenas para web) - permanece inalterado
import 'dart:js' as js;

class CadastroEscalaExtraScreen extends StatefulWidget {
  final Map<String, dynamic> escalaExtra;

  const CadastroEscalaExtraScreen({super.key, required this.escalaExtra});

  @override
  State<CadastroEscalaExtraScreen> createState() =>
      _CadastroEscalaExtraScreenState();
}

class _CadastroEscalaExtraScreenState extends State<CadastroEscalaExtraScreen> {
  // Sua chave do site reCAPTCHA Enterprise (pública)
  // Permanece inalterada, pois é a chave v3/Enterprise
  final String _recaptchaSiteKey = '6Lf4vGcrAAAAAME7ZtDCeQmErDJlbTNMPLK7AxdZ';
  String? _recaptchaToken;
  // Removido: WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    debugPrint("[Flutter] initState: Inicializando...");

    // Removida toda a lógica de inicialização da WebView para mobile (reCAPTCHA v2)
    // Agora, o initState apenas informa que a web está pronta para JS Interop,
    // e o mobile não terá reCAPTCHA por enquanto.
    if (kIsWeb) {
      debugPrint("[Flutter] Ambiente Web: reCAPTCHA v3/Enterprise será gerenciado por JS Interop.");
    } else {
      debugPrint("[Flutter] Ambiente Mobile: Não há reCAPTCHA configurado nesta tela.");
    }
  }

  // Método para obter o token do reCAPTCHA
  Future<void> _getRecaptchaToken() async {
    debugPrint("[Flutter] _getRecaptchaToken: Iniciado.");

    if (kIsWeb) {
      // Lógica para Web (reCAPTCHA v3/Enterprise via JS interop) - Permanece inalterada
      debugPrint("[Flutter Web] _getRecaptchaToken: Executando reCAPTCHA v3 via JS Interop.");

      String? tempToken; // Variável temporária para armazenar o token
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          debugPrint("[Flutter Web] _getRecaptchaToken: AlertDialog para reCAPTCHA v3 (web) sendo construído.");
          return PopScope(
            canPop: false,
            onPopInvoked: (bool didPop) {
              if (didPop) {
                debugPrint("[Flutter Web] Tentativa de fechar o dialog do reCAPTCHA (web) foi impedida.");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Aguarde a verificação de segurança.")),
                );
              }
            },
            child: AlertDialog(
              title: const Text("Verificação de Segurança"),
              content: SizedBox(
                width: 300,
                height: 100,
                child: Builder(
                  builder: (BuildContext innerBuilderContext) {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (innerBuilderContext.mounted) {
                        debugPrint("[Flutter Web] PostFrameCallback: Expondo 'onRecaptchaV3VerifiedWeb' para JS.");
                        js.context['onRecaptchaV3VerifiedWeb'] = (String token) {
                          debugPrint("[Flutter Web] Callback 'onRecaptchaV3VerifiedWeb' acionada pelo JS com token: $token");
                          tempToken = token; // Armazena o token na variável temporária

                          if (mounted && Navigator.canPop(dialogContext)) {
                            Navigator.pop(dialogContext); // Fecha o dialog de carregamento
                          } else {
                            debugPrint("[Flutter Web] Widget não montado ou dialog não pode ser fechado no momento do callback.");
                          }
                        };

                        debugPrint("[Flutter Web] Chamando JS: executeRecaptchaV3.");
                        js.context.callMethod(
                            'executeRecaptchaV3',
                            [_recaptchaSiteKey, 'solicitacao_escala_extra', 'onRecaptchaV3VerifiedWeb']
                        );
                      } else {
                        debugPrint("[Flutter Web] innerBuilderContext não montado, não chamando JS executeRecaptchaV3.");
                      }
                    });
                    return const Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Verificando se você é um robô...", textAlign: TextAlign.center),
                      ],
                    ));
                  },
                ),
              ),
              // Não há botão de cancelar no AlertDialog para o reCAPTCHA v3 pois ele é automático
            ),
          );
        },
      );
      // Após o showDialog fechar (quando o token for retornado pelo JS callback),
      // o tempToken estará preenchido.
      setState(() {
          _recaptchaToken = tempToken;
      });
      debugPrint("[Flutter Web] _getRecaptchaToken: reCAPTCHA v3 concluído. Token: $_recaptchaToken");
    } else {
      // Nova lógica para Mobile: Sem reCAPTCHA por enquanto, ou um aviso.
      debugPrint("[Flutter Mobile] _getRecaptchaToken: reCAPTCHA não implementado para mobile.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("A verificação de segurança não está disponível para mobile no momento.")),
        );
      }
      // O token para mobile será nulo, e o _cadastrarFuncionario irá parar.
      // Você pode definir um valor padrão ou uma flag para pular a verificação de reCAPTCHA no mobile
      // se a validação for opcional para essa plataforma. Por enquanto, irá falhar.
    }
    debugPrint("[Flutter] _getRecaptchaToken: Finalizado.");
  }


  void _cadastrarFuncionario() async {
    debugPrint("[Flutter] _cadastrarFuncionario: Iniciado.");

    // Se o token ainda for nulo ou inválido, chama o método para obtê-lo.
    // Removida a verificação 'cancelled' pois não há mais botão de cancelar no dialog mobile v2.
    if (_recaptchaToken == null || _recaptchaToken!.isEmpty ||
        _recaptchaToken == 'expired' || _recaptchaToken == 'error' ||
        _recaptchaToken == 'error_api_not_loaded' || _recaptchaToken == 'error_container_not_found' ||
        _recaptchaToken == 'error_render_exception' || _recaptchaToken == 'error_execution_failed')
    {
      debugPrint("[Flutter] _cadastrarFuncionario: Token reCAPTCHA nulo/inválido, chamando _getRecaptchaToken.");
      _recaptchaToken = null; // Garante que um novo token será buscado
      await _getRecaptchaToken(); // Obtém o token do reCAPTCHA

      // Após a tentativa de obter o token, verifica novamente.
      if (_recaptchaToken == null || _recaptchaToken!.isEmpty ||
          _recaptchaToken == 'expired' || _recaptchaToken == 'error' ||
          _recaptchaToken == 'error_api_not_loaded' || _recaptchaToken == 'error_container_not_found' ||
          _recaptchaToken == 'error_render_exception' || _recaptchaToken == 'error_execution_failed')
      {
        debugPrint("[Flutter] _cadastrarFuncionario: Token reCAPTCHA ainda nulo/inválido após tentativa. Interrompendo cadastro.");
        // Removida a verificação 'cancelled' aqui também.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Falha na verificação de segurança. Tente novamente.")),
          );
        }
        return; // Interrompe o processo se o token não for válido.
      }
    }

    final userModel = Provider.of<UserModel>(context, listen: false);

    if (userModel.idFuncionario.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro: ID do funcionário não disponível.")),
        );
      }
      debugPrint("[Flutter] _cadastrarFuncionario: ID do funcionário não disponível.");
      return;
    }

    final Map<String, dynamic> requestBody = {
      "idCriacaoEscalaExtra": widget.escalaExtra["idCriacaoEscalaExtra"],
      "idFuncionario": userModel.idFuncionario,
      "recaptchaToken": _recaptchaToken, // Envia o token do reCAPTCHA para o backend
    };

    debugPrint("[Flutter] _cadastrarFuncionario: Token reCAPTCHA antes de enviar: $_recaptchaToken");

    // Limpa o token após o uso para que uma nova validação seja necessária para o próximo cadastro
    _recaptchaToken = null;
    // Esta linha já foi comentada, mas reforçando: não é necessária para v3
    // js.context.callMethod('resetRecaptchaV3');

    try {
      debugPrint("📡 Enviando solicitação de cadastro de RAS/Extra: $requestBody");
      final response = await ApiClient.post(
        '/solicitacaoEscalaExtra/Incluir',
        requestBody,
      );

      debugPrint("📡 Resposta do cadastro: Status ${response['statusCode']}, Body: ${response['body']}");

      if (mounted) {
        if (response["statusCode"] == 200 || response["statusCode"] == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("RAS / Extra Cadastrado com sucesso! Confira seu e-mail.")),
          );
          Navigator.pop(context); // Volta para a tela anterior
          debugPrint("[Flutter] Cadastro bem-sucedido.");
        } else {
          String errorMessage = "Erro ao Cadastrar RAS / Extra.";
          if (response['body'] != null && response['body'] is Map && response['body'].containsKey('message')) {
            errorMessage = response['body']['message'];
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
          debugPrint("[Flutter] Erro no cadastro (status != 200/201): $errorMessage");
        }
      }
    } catch (e) {
      debugPrint("❌ Erro ao cadastrar RAS / Extra na API: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ERRO ao Cadastrar RAS / Extra. Verifique sua conexão.")),
        );
      }
    }
    debugPrint("[Flutter] _cadastrarFuncionario: Finalizado.");
  }

  void _cancelarCadastro() {
    debugPrint("[Flutter] _cancelarCadastro: Voltando para tela anterior.");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Preencha as informações abaixo para o cadastro do funcionário.",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
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
                        escalaExtra["titulo"],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text("Setor: ${escalaExtra["setorNome"]}"),
                      Text("Descrição: ${escalaExtra["setorDescricao"]}"),
                      Text("Data: ${escalaExtra["data"]}"),
                      Text("Hora: ${escalaExtra["hora"]}"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cancelarCadastro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Cancelar", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cadastrarFuncionario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003580),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Cadastrar", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
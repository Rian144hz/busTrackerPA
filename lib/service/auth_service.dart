import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants.dart';

/// Serviço de autenticação responsável por validar credenciais de usuários.
///
/// Esta classe gerencia o login de dois perfis distintos:
/// - **Pai/Responsável**: Valida matrícula do aluno + nome do responsável
/// - **Motorista**: Valida CPF + nome + placa do veículo
///
/// URL Base: `https://uncast-apparently-kyson.ngrok-free.dev/api/v1/auth`
///
/// Endpoints disponíveis:
/// - POST `/pai` - Autenticação do responsável
/// - POST `/motorista` - Autenticação do motorista
///
/// Ambos os endpoints retornam os dados do usuário em caso de sucesso (HTTP 200)
/// ou indicam falha de autenticação (HTTP 401/404).
class AuthService {
  /// URL base da API de autenticação.
  ///
  /// Usa ngrok durante desenvolvimento. Em produção, deve ser
  /// substituída pelo domínio real do backend.
  static const _baseUrl = ApiConstants.authBaseUrl;

  // ===========================================================================
  // LOGIN DO PAI/RESPONSÁVEL
  // ===========================================================================

  /// Autentica um pai/responsável no sistema.
  ///
  /// Valida as credenciais informadas contra o banco de dados do servidor.
  /// Se as credenciais forem válidas, retorna os dados do aluno vinculado
  /// para que o pai possa acompanhar o transporte escolar.
  ///
  /// Parâmetros:
  /// - [matricula]: Número da matrícula do aluno (ex: "2024001")
  /// - [nomeResponsavel]: Nome completo do responsável cadastrado
  ///
  /// Retorna:
  /// - `Map<String, dynamic>` com os dados do aluno se autenticação for bem-sucedida
  /// - `null` se credenciais forem inválidas ou houver erro de conexão
  ///
  /// Exemplo de resposta do servidor (HTTP 200):
  /// ```json
  /// {
  ///   "nomeResponsavel": "Maria Silva",
  ///   "nomeAluno": "João Silva",
  ///   "placaVeiculo": "ABC-1234"
  /// }
  /// ```
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final dados = await AuthService.loginPai(
  ///   matricula: "2024001",
  ///   nomeResponsavel: "Maria Silva",
  /// );
  ///
  /// if (dados != null) {
  ///   // Sucesso - navega para tela do pai
  ///   final nomeAluno = dados['nomeAluno'];
  ///   final placa = dados['placaVeiculo'];
  /// } else {
  ///   // Falha - mostra mensagem de erro
  /// }
  /// ```
  ///
  /// Possíveis erros:
  /// - Matrícula não encontrada (HTTP 404)
  /// - Nome do responsável não corresponde (HTTP 401)
  /// - Erro de conexão (timeout, sem internet)
  static Future<Map<String, dynamic>?> loginPai({
    required String matricula,
    required String nomeResponsavel,
  }) async {
    try {
      // Faz requisição POST ao endpoint de autenticação do pai com timeout
      final response = await http
          .post(
            Uri.parse('$_baseUrl/pai'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'matricula': matricula,
              'nomeResponsavel': nomeResponsavel,
            }),
          )
          .timeout(TimingConstants.httpTimeout);

      // Verifica se autenticação foi bem-sucedida (HTTP 200 OK)
      if (response.statusCode == 200) {
        // Decodifica o JSON com os dados do aluno
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // Qualquer outro status (401, 404, etc) indica falha de autenticação
      return null;
    } catch (e) {
      // Exceção de conexão: loga para debug e retorna null
      // ignore: avoid_print
      print('[AuthService] ❌ Erro: $e');
      return null;
    }
  }

  // ===========================================================================
  // LOGIN DO MOTORISTA
  // ===========================================================================

  /// Autentica um motorista no sistema.
  ///
  /// Valida as credenciais informadas (CPF, nome e placa) contra o banco
  /// de dados do servidor. Se válidas, retorna os dados do motorista
  /// para iniciar o rastreamento do veículo.
  ///
  /// Parâmetros:
  /// - [cpf]: CPF do motorista (pode conter pontuação ou não)
  /// - [nome]: Nome completo do motorista cadastrado
  /// - [placaVeiculo]: Placa do veículo que o motorista está dirigindo
  ///
  /// Retorna:
  /// - `Map<String, dynamic>` com os dados do motorista se autenticação for bem-sucedida
  /// - `null` se credenciais forem inválidas ou houver erro de conexão
  ///
  /// Exemplo de resposta do servidor (HTTP 200):
  /// ```json
  /// {
  ///   "cpf": "123.456.789-00",
  ///   "nome": "José Santos",
  ///   "placaVeiculo": "ABC-1234"
  /// }
  /// ```
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final dados = await AuthService.loginMotorista(
  ///   cpf: "123.456.789-00",
  ///   nome: "José Santos",
  ///   placaVeiculo: "ABC-1234",
  /// );
  ///
  /// if (dados != null) {
  ///   // Sucesso - navega para tela do motorista
  ///   final cpf = dados['cpf'];
  ///   final nome = dados['nome'];
  ///   final placa = dados['placaVeiculo'];
  /// } else {
  ///   // Falha - mostra mensagem de erro
  /// }
  /// ```
  ///
  /// Possíveis erros:
  /// - CPF não encontrado (HTTP 404)
  /// - Nome ou placa não correspondem (HTTP 401)
  /// - Erro de conexão (timeout, sem internet)
  static Future<Map<String, dynamic>?> loginMotorista({
    required String cpf,
    required String nome,
    required String placaVeiculo,
  }) async {
    try {
      // Faz requisição POST ao endpoint de autenticação do motorista com timeout
      final response = await http
          .post(
            Uri.parse('$_baseUrl/motorista'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'cpf': cpf,
              'nome': nome,
              'placaVeiculo': placaVeiculo,
            }),
          )
          .timeout(TimingConstants.httpTimeout);

      // Verifica se autenticação foi bem-sucedida (HTTP 200 OK)
      if (response.statusCode == 200) {
        // Decodifica o JSON com os dados do motorista
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // Qualquer outro status (401, 404, etc) indica falha de autenticação
      return null;
    } catch (e) {
      // Exceção de conexão: loga para debug e retorna null
      // ignore: avoid_print
      print('[AuthService] ❌ Erro motorista: $e');
      return null;
    }
  }
}

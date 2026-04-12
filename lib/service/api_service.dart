import 'dart:convert';
import 'package:http/http.dart' as http;

/// Serviço responsável por toda comunicação HTTP com o Backend Java.
///
/// Esta classe centraliza todas as chamadas à API REST do servidor,
/// fornecendo métodos para enviar e buscar dados de rastreamento de veículos.
///
/// URL Base: `https://uncast-apparently-kyson.ngrok-free.dev/api/v1/rastreamento`
///
/// Endpoints disponíveis:
/// - POST `/enviar` - Envia posição do motorista
/// - GET `/veiculo/{placa}/ultima-posicao` - Busca última posição do veículo
class ApiService {
  /// URL base da API do backend.
  ///
  /// Usa ngrok para expor o servidor local durante desenvolvimento.
  /// Em produção, deve ser substituída pelo domínio real.
  static const String baseUrl =
      'https://uncast-apparently-kyson.ngrok-free.dev/api/v1/rastreamento';

  // ===========================================================================
  // ENVIO DE POSIÇÃO (MOTORISTA → SERVIDOR)
  // ===========================================================================

  /// Envia a posição atual do veículo para o servidor.
  ///
  /// Chamado periodicamente pelo motorista (a cada 10 segundos)
  /// para atualizar sua localização em tempo real.
  ///
  /// Parâmetros:
  /// - [cpf]: CPF do motorista (identificador único)
  /// - [nome]: Nome do motorista (para exibição nos logs do servidor)
  /// - [placaVeiculo]: Placa do veículo sendo rastreado
  /// - [latitude]: Coordenada de latitude (ex: -9.4062)
  /// - [longitude]: Coordenada de longitude (ex: -38.2144)
  /// - [velocidade]: Velocidade em m/s (opcional, padrão 0.0)
  /// - [motivoAtraso]: Motivo do atraso informado pelo motorista (opcional)
  ///
  /// Retorna:
  /// - `true` se o envio foi bem-sucedido (HTTP 201 Created)
  /// - `false` se houve erro na conexão ou resposta não foi 201
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final sucesso = await ApiService.enviarPosicao(
  ///   cpf: 12345678900,
  ///   nome: 'João Silva',
  ///   placaVeiculo: 'ABC-1234',
  ///   latitude: -9.4062,
  ///   longitude: -38.2144,
  ///   velocidade: 12.5,
  ///   motivoAtraso: 'Trânsito intenso',
  /// );
  /// ```
  static Future<bool> enviarPosicao({
    required int cpf,
    required String nome,
    required String placaVeiculo,
    required double latitude,
    required double longitude,
    double? velocidade,
    String? motivoAtraso,
  }) async {
    // Constrói a URL completa do endpoint
    final uri = Uri.parse('$baseUrl/enviar');

    // Monta o corpo da requisição JSON
    final Map<String, dynamic> bodyMap = {
      'cpf': cpf,
      'nome': nome,
      'placaVeiculo': placaVeiculo,
      'latitude': latitude,
      'longitude': longitude,
      'velocidade': velocidade ?? 0.0, // Valor padrão se não informado
    };

    // Adiciona motivo de atraso apenas se foi informado
    if (motivoAtraso != null && motivoAtraso.isNotEmpty) {
      bodyMap['motivoAtraso'] = motivoAtraso;
    }

    try {
      // Faz a requisição POST com o corpo JSON
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
      );

      // Verifica se o servidor retornou sucesso (201 Created)
      if (response.statusCode == 201) {
        print('[ApiService] ✅ Posição enviada com sucesso.');
        return true;
      } else {
        // Erro HTTP - loga para debug
        print('[ApiService] ⚠️ Erro HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      // Exceção de conexão (sem internet, servidor offline, etc)
      print('[ApiService] ❌ Falha de conexão: $e');
      return false;
    }
  }

  // ===========================================================================
  // BUSCA DE POSIÇÃO (SERVIDOR → PAI/RESPONSÁVEL)
  // ===========================================================================

  /// Busca a última posição registrada de um veículo específico.
  ///
  /// Chamado periodicamente pela tela do pai/responsável
  /// para atualizar a localização do ônibus em tempo real.
  ///
  /// Parâmetros:
  /// - [placa]: Placa do veículo a ser consultado
  ///
  /// Retorna:
  /// - `Map<String, dynamic>` com os dados da posição se encontrado (HTTP 200)
  /// - `null` se não encontrado ou houve erro na conexão
  ///
  /// Exemplo de resposta do servidor:
  /// ```json
  /// {
  ///   "cpf": 12345678900,
  ///   "nome": "João Silva",
  ///   "placaVeiculo": "ABC-1234",
  ///   "latitude": -9.4062,
  ///   "longitude": -38.2144,
  ///   "velocidade": 12.5,
  ///   "motivoAtraso": "Trânsito intenso",
  ///   "timestamp": "2024-01-15T14:30:00"
  /// }
  /// ```
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final dados = await ApiService.buscarUltimaPosicao('ABC-1234');
  /// if (dados != null) {
  ///   final lat = dados['latitude'];
  ///   final lng = dados['longitude'];
  ///   final atraso = dados['motivoAtraso'];
  /// }
  /// ```
  static Future<Map<String, dynamic>?> buscarUltimaPosicao(
      String placa) async {
    // Constrói a URL com a placa como parâmetro de path
    final uri = Uri.parse('$baseUrl/veiculo/$placa/ultima-posicao');

    try {
      // Faz a requisição GET (sem corpo)
      final response = await http.get(uri);

      // Verifica se encontrou o registro (200 OK)
      if (response.statusCode == 200) {
        // Decodifica o JSON da resposta para um Map
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // Status diferente de 200 (404, 500, etc) - retorna null
      return null;
    } catch (e) {
      // Exceção de conexão - loga e retorna null
      print('[ApiService] ❌ Falha ao buscar posição: $e');
      return null;
    }
  }
}

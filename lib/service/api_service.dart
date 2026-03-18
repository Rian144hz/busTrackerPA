import 'dart:convert';
import 'package:http/http.dart' as http;

/// Serviço responsável por toda comunicação com o Backend Java.

class ApiService {
  
  static const String baseUrl = 'http://SEU_IP:8080/api/v1/rastreamento';

  
  static Future<bool> enviarPosicao({
  required String placaVeiculo,
  required double latitude,
  required double longitude,
  double? velocidade,
  String? motivoAtraso,
}) async {
  final uri = Uri.parse('$baseUrl/enviar');

  final Map<String, dynamic> bodyMap = {
    'placaVeiculo': placaVeiculo,
    'latitude': latitude,
    'longitude': longitude,
    'velocidade': velocidade ?? 0.0,
  };

  if (motivoAtraso != null && motivoAtraso.isNotEmpty) {
    bodyMap['motivoAtraso'] = motivoAtraso;
  }

  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bodyMap),
    );

    if (response.statusCode == 201) {
      print('[ApiService] ✅ Posição enviada com sucesso.');
      return true;
    } else {
      print('[ApiService] ⚠️ Erro HTTP ${response.statusCode}: ${response.body}');
      return false;
    }
  } catch (e) {
    print('[ApiService] ❌ Falha de conexão: $e');
    return false;
  }
}
  /// Busca a última posição registrada de um veículo.
  static Future<Map<String, dynamic>?> buscarUltimaPosicao(
      String placa) async {
    final uri = Uri.parse('$baseUrl/veiculo/$placa/ultima-posicao');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('[ApiService] ❌ Falha ao buscar posição: $e');
      return null;
    }
  }
}
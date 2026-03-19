import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const _baseUrl = 'http://192.168.0.115:8080/api/v1/auth';

  /// Login do pai — valida matrícula + nome do responsável no banco.
  /// Retorna os dados do aluno ou null se inválido.
  static Future<Map<String, dynamic>?> loginPai({
    required String matricula,
    required String nomeResponsavel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pai'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matricula': matricula,
          'nomeResponsavel': nomeResponsavel,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('[AuthService] ❌ Erro: $e');
      return null;
    }
  }
}
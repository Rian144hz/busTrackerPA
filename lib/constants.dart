/// Arquivo de constantes compartilhadas do aplicativo.
///
/// Centraliza valores que são usados em múltiplos lugares para evitar
/// duplicação e facilitar manutenção.
///
/// BUG FIX #10: Valores hardcoded repetidos
/// Anteriormente, coordenadas e intervalos estavam espalhados pelo código.
/// Agora centralizados aqui para manutenção única.
library;

import 'package:latlong2/latlong.dart';

/// Constantes de localização
class LocationConstants {
  /// Coordenadas padrão do centro do mapa (Paulo Afonso - BA)
  /// Usado quando ainda não há dados do GPS ou servidor
  static const defaultLocation = LatLng(-9.4062, -38.2144);

  /// Raio em metros para considerar posições iguais (evita duplicatas)
  static const duplicateRadiusMeters = 1.0;
}

/// Constantes de timing e intervalos
class TimingConstants {
  /// Intervalo em segundos entre atualizações de posição
  static const updateIntervalSeconds = 10;

  /// Timeout para requisições HTTP
  static const httpTimeout = Duration(seconds: 10);

  /// Número máximo de pontos no rastro (histórico de posições)
  static const maxRastroPoints = 30;
}

/// Constantes da API
class ApiConstants {
  /// URL base da API de autenticação
  /// NOTE: Em produção, substituir pelo domínio real
  static const authBaseUrl =
      'https://uncast-apparently-kyson.ngrok-free.dev/api/v1/auth';

  /// URL base da API de rastreamento
  static const trackingBaseUrl =
      'https://uncast-apparently-kyson.ngrok-free.dev/api/v1/rastreamento';
}

/// Constantes de Firebase
class FirebaseConstants {
  /// Nome do tópico FCM para notificações de ônibus
  static const fcmTopic = 'onibus_paulo_afonso';
}

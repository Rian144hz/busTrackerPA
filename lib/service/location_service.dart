import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Serviço de GPS que gerencia a localização do dispositivo em tempo real.
///
/// Esta classe é responsável por:
/// - Solicitar permissões de localização ao usuário
/// - Obter a posição atual do GPS
/// - Iniciar e parar o rastreamento periódico da localização
///
/// Usado principalmente pela [TelaMotorista] para enviar coordenadas
/// ao servidor em intervalos regulares.
///
/// Requer o pacote `geolocator` e permissões de localização no Android/iOS.
class LocationService {
  /// Subscription do stream de localização (usado em modo contínuo).
  /// Mantém a referência para poder cancelar quando parar o rastreamento.
  StreamSubscription<Position>? _subscription;

  /// Timer que dispara a captura de localização periodicamente.
  /// Controla o intervalo entre cada atualização de posição.
  Timer? _timer;

  // ===========================================================================
  // SOLICITAÇÃO DE PERMISSÕES
  // ===========================================================================

  /// Solicita as permissões necessárias para acessar a localização do GPS.
  ///
  /// Este método deve ser chamado antes de iniciar o rastreamento.
  /// Verifica três condições:
  /// 1. Se o serviço de GPS está ativado no dispositivo
  /// 2. Se o app tem permissão de localização
  /// 3. Se a permissão não foi negada permanentemente
  ///
  /// Retorna:
  /// - `true` se todas as permissões foram concedidas e o GPS está ativo
  /// - `false` se o usuário negou a permissão ou o GPS está desativado
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final temPermissao = await LocationService.solicitarPermissao();
  /// if (temPermissao) {
  ///   // Pode iniciar o rastreamento
  /// } else {
  ///   // Mostra mensagem pedindo para ativar permissões
  /// }
  /// ```
  ///
  /// Estados possíveis:
  /// - GPS desativado → retorna false
  /// - Permissão negada → solicita ao usuário
  /// - Permissão negada permanentemente → retorna false
  /// - Permissão concedida → retorna true
  static Future<bool> solicitarPermissao() async {
    // Verifica se o serviço de GPS está ativado no dispositivo
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // ignore: avoid_print
      print('[LocationService] GPS desativado no dispositivo.');
      return false;
    }

    // Verifica o status atual da permissão
    LocationPermission permission = await Geolocator.checkPermission();

    // Se ainda não foi solicitada, solicita agora
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Usuário negou a permissão na dialog
        // ignore: avoid_print
        print('[LocationService] Permissão de localização negada.');
        return false;
      }
    }

    // Se foi negada permanentemente ("Não perguntar novamente")
    if (permission == LocationPermission.deniedForever) {
      // ignore: avoid_print
      print('[LocationService] Permissão negada permanentemente.');
      return false;
    }

    // Permissão concedida (whileInUse ou always)
    return true;
  }

  // ===========================================================================
  // OBTENÇÃO ÚNICA DE POSIÇÃO
  // ===========================================================================

  /// Obtém a posição atual do GPS uma única vez.
  ///
  /// Faz uma requisição síncrona ao GPS do dispositivo para obter
  /// as coordenadas atuais (latitude, longitude, altitude, velocidade, etc).
  ///
  /// Usa [LocationAccuracy.high] para obter a melhor precisão possível,
  /// consumindo mais bateria mas garantindo coordenadas mais exatas.
  ///
  /// Retorna:
  /// - [Position] com todos os dados da localização atual
  /// - `null` se houve erro ao acessar o GPS
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final posicao = await LocationService.obterPosicaoAtual();
  /// if (posicao != null) {
  ///   print('Latitude: ${posicao.latitude}');
  ///   print('Longitude: ${posicao.longitude}');
  ///   print('Velocidade: ${posicao.speed} m/s');
  /// }
  /// ```
  ///
  /// Dados disponíveis no [Position]:
  /// - latitude: double (ex: -9.4062)
  /// - longitude: double (ex: -38.2144)
  /// - altitude: double (metros acima do nível do mar)
  /// - accuracy: double (precisão em metros)
  /// - speed: double (velocidade em m/s)
  /// - speedAccuracy: double (precisão da velocidade)
  /// - timestamp: DateTime (momento da leitura)
  static Future<Position?> obterPosicaoAtual() async {
    try {
      // Faz a requisição ao GPS com alta precisão
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      // Erro ao acessar o GPS (pode estar desligado, sem permissão, etc)
      // ignore: avoid_print
      print('[LocationService] ❌ Erro ao obter posição: $e');
      return null;
    }
  }

  // ===========================================================================
  // RASTREAMENTO CONTÍNUO (PERIÓDICO)
  // ===========================================================================

  /// Inicia o rastreamento periódico da localização.
  ///
  /// Este método configura um timer que captura a posição do GPS
  /// a cada [intervaloSegundos] segundos e chama o callback
  /// [onPosicaoAtualizada] com a nova posição.
  ///
  /// Características:
  /// - Faz a primeira captura imediatamente (sem esperar o intervalo)
  /// - Continua capturando periodicamente em background
  /// - Mantém referências internas para poder parar depois
  ///
  /// Parâmetros:
  /// - [onPosicaoAtualizada]: Callback chamado a cada nova posição recebida
  /// - [intervaloSegundos]: Intervalo entre capturas (padrão: 10 segundos)
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final locationService = LocationService();
  ///
  /// locationService.iniciarRastreamento(
  ///   intervaloSegundos: 10,
  ///   onPosicaoAtualizada: (posicao) {
  ///     print('Nova posição: ${posicao.latitude}, ${posicao.longitude}');
  ///     // Enviar para o servidor...
  ///   },
  /// );
  /// ```
  ///
  /// Importante:
  /// - Deve chamar [pararRastreamento] ao sair da tela para economizar bateria
  /// - O callback é chamado na thread principal (UI thread)
  /// - Se o GPS falhar em uma captura, pula essa atualização
  void iniciarRastreamento({
    required Function(Position) onPosicaoAtualizada,
    int intervaloSegundos = 10,
  }) {
    // Faz a primeira captura imediatamente (não espera o timer)
    _capturarENotificar(onPosicaoAtualizada);

    // Configura o timer para repetir a cada N segundos
    _timer = Timer.periodic(
      Duration(seconds: intervaloSegundos),
      (_) => _capturarENotificar(onPosicaoAtualizada),
    );
  }

  /// Método interno que captura a posição e chama o callback.
  ///
  /// Faz a requisição ao GPS de forma assíncrona e, se obtiver
  /// uma posição válida, chama o callback fornecido.
  ///
  /// Este método é privado (começa com _) e usado apenas internamente
  /// por [iniciarRastreamento].
  void _capturarENotificar(Function(Position) callback) async {
    // Obtém a posição atual do GPS
    final posicao = await LocationService.obterPosicaoAtual();

    // Só chama o callback se conseguiu uma posição válida
    if (posicao != null) {
      callback(posicao);
    }
  }

  // ===========================================================================
  // PARADA DO RASTREAMENTO
  // ===========================================================================

  /// Para o rastreamento e libera todos os recursos.
  ///
  /// Este método deve ser chamado quando o usuário sai da tela
  /// ou desliga o rastreamento, para:
  /// - Cancelar o timer periódico
  /// - Cancelar qualquer subscription ativa
  /// - Liberar referências para garbage collector
  /// - Economizar bateria do dispositivo
  ///
  /// É seguro chamar este método mesmo se o rastreamento não estiver ativo.
  ///
  /// Exemplo de uso (no dispose da tela):
  /// ```dart
  /// @override
  /// void dispose() {
  ///   _locationService.pararRastreamento();
  ///   super.dispose();
  /// }
  /// ```
  ///
  /// Ou ao parar manualmente:
  /// ```dart
  /// void _toggleRastreamento() {
  ///   if (_rastreando) {
  ///     _locationService.pararRastreamento();
  ///   } else {
  ///     _locationService.iniciarRastreamento(...);
  ///   }
  /// }
  /// ```
  void pararRastreamento() {
    // Cancela o timer se existir
    _timer?.cancel();

    // Cancela a subscription do stream se existir
    _subscription?.cancel();

    // Limpa as referências para permitir garbage collection
    _timer = null;
    _subscription = null;

    // ignore: avoid_print
    print('[LocationService] Rastreamento parado.');
  }
}

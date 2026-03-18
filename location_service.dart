import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Serviço de GPS que captura a localização real do dispositivo.
class LocationService {
  StreamSubscription<Position>? _subscription;
  Timer? _timer;

  /// Solicita as permissões de localização ao usuário.
  /// Retorna [true] se a permissão foi concedida.
  static Future<bool> solicitarPermissao() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('[LocationService] GPS desativado no dispositivo.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('[LocationService] Permissão de localização negada.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('[LocationService] Permissão negada permanentemente.');
      return false;
    }

    return true;
  }

  /// Obtém a posição atual uma única vez.
  /// Obtém a posição atual uma única vez.
  static Future<Position?> obterPosicaoAtual() async {
    try {
      // Ajuste para as versões novas do Geolocator
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // Use desiredAccuracy diretamente
      );
    } catch (e) {
      print('[LocationService] ❌ Erro ao obter posição: $e');
      return null;
    }
  }

  /// Inicia captura periódica a cada [intervaloSegundos] segundos.
  /// A cada captura, chama [onPosicaoAtualizada] com a [Position].
  void iniciarRastreamento({
    required Function(Position) onPosicaoAtualizada,
    int intervaloSegundos = 10,
  }) {
    // Captura imediata na primeira chamada
    _capturarENotificar(onPosicaoAtualizada);

    // Depois repete a cada N segundos
    _timer = Timer.periodic(
      Duration(seconds: intervaloSegundos),
      (_) => _capturarENotificar(onPosicaoAtualizada),
    );
  }

  void _capturarENotificar(Function(Position) callback) async {
    final posicao = await LocationService.obterPosicaoAtual();
    if (posicao != null) {
      callback(posicao);
    }
  }

  /// Para o rastreamento e libera recursos.
  void pararRastreamento() {
    _timer?.cancel();
    _subscription?.cancel();
    _timer = null;
    _subscription = null;
    print('[LocationService] Rastreamento parado.');
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../service/api_service.dart';

class TelaPai extends StatefulWidget {
  final String nomeResponsavel;
  final String nomeAluno;
  final String placaVeiculo;

  const TelaPai({
    super.key,
    required this.nomeResponsavel,
    required this.nomeAluno,
    required this.placaVeiculo,
  });

  @override
  State<TelaPai> createState() => _TelaPaiState();
}

class _TelaPaiState extends State<TelaPai> {
  static const _pauloAfonso = LatLng(-9.4062, -38.2144);
  static const _intervaloSegundos = 10;
  static const _maxRastro = 30;

  final MapController _mapController = MapController();

  Timer? _timer;
  Map<String, dynamic>? _posicaoAtual;
  final List<LatLng> _rastro = [];
  DateTime? _ultimaAtualizacao;
  bool _carregando = true;
  String? _motivoAtraso;

  @override
  void initState() {
    super.initState();
    _buscarPosicao();
    _timer = Timer.periodic(
      const Duration(seconds: _intervaloSegundos),
      (_) => _buscarPosicao(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _buscarPosicao() async {
    final dados = await ApiService.buscarUltimaPosicao(widget.placaVeiculo);
    if (!mounted) return;

    setState(() {
      _carregando = false;
      if (dados != null) {
        _posicaoAtual = dados;
        _ultimaAtualizacao = DateTime.now();
        _motivoAtraso = dados['motivoAtraso'] as String?;

        final ponto = LatLng(
          (dados['latitude'] as num).toDouble(),
          (dados['longitude'] as num).toDouble(),
        );
        if (_rastro.isEmpty || _rastro.last != ponto) {
          _rastro.add(ponto);
          if (_rastro.length > _maxRastro) _rastro.removeAt(0);
        }
        _mapController.move(ponto, _mapController.camera.zoom);
      }
    });
  }

  String _estimativaChegada() {
    if (_posicaoAtual == null) return '--';
    final vel =
        ((_posicaoAtual!['velocidade'] as num?)?.toDouble() ?? 0) * 3.6;
    if (vel < 1) return 'Parado';
    const distanciaKm = 2.5;
    final min = (distanciaKm / vel * 60).round();
    return 'Aprox. $min min';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm:ss');
    final pos = _posicaoAtual;
    final vel = (((pos?['velocidade']) as num?)?.toDouble() ?? 0) * 3.6;
    final temAtraso = _motivoAtraso != null && _motivoAtraso!.isNotEmpty;

    return Scaffold(
      body: Column(
        children: [
          // ── Header customizado ───────────────────────────────
          Container(
            color: const Color(0xFF2E7D32),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Barra superior
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Acompanhar Ônibus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: pos != null
                                      ? const Color(0xFF69F0AE)
                                      : Colors.white38,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                pos != null ? 'Ao vivo' : 'Aguardando',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Card aluno + responsável
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2)),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    child: Column(
                      children: [
                        // Aluno
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.school_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ALUNO',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    widget.nomeAluno,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.15)),
                        const SizedBox(height: 10),

                        // Responsável
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.person,
                                  color: Colors.white70, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'RESPONSÁVEL',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    widget.nomeResponsavel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Corpo ────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: _pauloAfonso,
                    initialZoom: 14.0,
                    minZoom: 5.0,
                    maxZoom: 19.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'br.com.rastreamento.escolar',
                    ),
                    if (_rastro.length > 1)
                      PolylineLayer(polylines: [
                        Polyline(
                          points: _rastro,
                          strokeWidth: 4.5,
                          color: temAtraso
                              ? Colors.orange.withOpacity(0.8)
                              : Colors.green.withOpacity(0.75),
                        ),
                      ]),
                    if (pos != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: LatLng(
                            (pos['latitude'] as num).toDouble(),
                            (pos['longitude'] as num).toDouble(),
                          ),
                          width: 52,
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              color: temAtraso
                                  ? Colors.orange[700]
                                  : const Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 8,
                                    offset: Offset(0, 3))
                              ],
                            ),
                            child: const Icon(
                                Icons.directions_bus_rounded,
                                color: Colors.white,
                                size: 28),
                          ),
                        ),
                      ]),
                  ],
                ),

                // Banner atraso
                if (temAtraso)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      color: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ÔNIBUS COM ATRASO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  _motivoAtraso!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_carregando)
                  const Center(child: CircularProgressIndicator()),

                if (!_carregando && pos == null)
                  Center(
                    child: Card(
                      margin: const EdgeInsets.all(32),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_bus_outlined,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'Ônibus ainda não iniciou\no rastreamento.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (pos != null)
                  Positioned(
                    bottom: 16, left: 12, right: 12,
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _Metrica(
                                  icon: Icons.speed,
                                  valor: vel.toStringAsFixed(0),
                                  unidade: 'km/h',
                                  cor: vel > 60
                                      ? Colors.red
                                      : vel > 40
                                          ? Colors.orange
                                          : Colors.green[700]!,
                                ),
                                _Metrica(
                                  icon: Icons.timer_outlined,
                                  valor: _estimativaChegada(),
                                  unidade: 'chegada',
                                  cor: temAtraso
                                      ? Colors.orange[700]!
                                      : const Color(0xFF1565C0),
                                ),
                                _Metrica(
                                  icon: Icons.route,
                                  valor: '${_rastro.length}',
                                  unidade: 'pontos',
                                  cor: Colors.green[700]!,
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.update,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Atualizado: ${_ultimaAtualizacao != null ? fmt.format(_ultimaAtualizacao!) : '--'}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            Text(
                              '${(pos['latitude'] as num).toStringAsFixed(5)}, '
                              '${(pos['longitude'] as num).toStringAsFixed(5)}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: pos == null
          ? null
          : FloatingActionButton.small(
              backgroundColor: temAtraso
                  ? Colors.orange[700]
                  : const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              onPressed: () {
                _mapController.move(
                  LatLng(
                    (pos['latitude'] as num).toDouble(),
                    (pos['longitude'] as num).toDouble(),
                  ),
                  15.0,
                );
              },
              child: const Icon(Icons.my_location),
            ),
    );
  }
}

class _Metrica extends StatelessWidget {
  final IconData icon;
  final String valor;
  final String unidade;
  final Color cor;

  const _Metrica({
    required this.icon,
    required this.valor,
    required this.unidade,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: cor, size: 22),
        const SizedBox(height: 4),
        Text(valor,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: cor)),
        Text(unidade,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
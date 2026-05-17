import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../service/api_service.dart';
import '../constants.dart';

/// Tela do responsável/pai para acompanhar o ônibus em tempo real.
/// Estilizada conforme o protótipo de alta fidelidade em tons Dark Blue.
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
  static final _pauloAfonso = LocationConstants.defaultLocation;
  static const _intervaloSegundos = TimingConstants.updateIntervalSeconds;
  static const _maxRastro = TimingConstants.maxRastroPoints;

  final MapController _mapController = MapController();
  Timer? _timer;
  Map<String, dynamic>? _posicaoAtual;
  final List<LatLng> _rastro = [];
  DateTime? _ultimaAtualizacao;
  bool _carregando = true;
  String? _motivoAtraso;

  // Cores do protótipo enviado na imagem
  static const Color _corFundoHeader = Color(0xFF1B254B); // Azul escuro do fundo
  static const Color _corCardInterno = Color(0xFF283563); // Azul levemente mais claro para o container interno
  static const Color _corIndicadorVivo = Color(0xFF4ADE80); // Verde vibrante do "Ao vivo"
  static const Color _corLinhaRastro = Color(0xFF3F69FF); // Azul brilhante da rota

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

        if (_rastro.isEmpty ||
            (_rastro.last.latitude != ponto.latitude ||
             _rastro.last.longitude != ponto.longitude)) {
          _rastro.add(ponto);
          if (_rastro.length > _maxRastro) _rastro.removeAt(0);
        }

        _mapController.move(ponto, _mapController.camera.zoom);
      }
    });
  }

  String _estimativaChegada() {
    if (_posicaoAtual == null) return '--';
    final vel = ((_posicaoAtual!['velocidade'] as num?)?.toDouble() ?? 0) * 3.6;
    if (vel < 1) return 'Parado';
    const distanciaKm = 2.5;
    final min = (distanciaKm / vel * 60).round();
    return '~$min min';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm:ss');
    final pos = _posicaoAtual;
    final vel = (((pos?['velocidade']) as num?)?.toDouble() ?? 0) * 3.6;
    final temAtraso = _motivoAtraso != null && _motivoAtraso!.isNotEmpty;

    return Scaffold(
      backgroundColor: _corFundoHeader,
      body: Column(
        children: [
          // ============================================
          // HEADER DESIGN PREMIUM (Azul Escuro Noturno)
          // ============================================
          Container(
            color: _corFundoHeader,
            padding: const EdgeInsets.only(bottom: 16),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Linha Superior: Voltar, Título e Badge "Ao Vivo"
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Acompanhar Ônibus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Badge Arredondado "Ao vivo" idêntico ao da imagem
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: _corIndicadorVivo,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Ao vivo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Card de Informações do Aluno e Responsável (Arredondado integrado)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _corCardInterno,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Seção Aluno
                        Row(
                          children: [
                            // Ícone da Mochila vermelha (Substituído conforme imagem)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.backpack_outlined, color: Colors.redAccent, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ALUNO',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    widget.nomeAluno,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Linha divisória sutil idêntica à imagem
                        Container(height: 0.5, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 12),
                        // Seção Responsável
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.person_outline, color: Colors.blue[300], size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RESPONSÁVEL',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    widget.nomeResponsavel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
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

          // ============================================
          // CORPO DO MAPA COM ESTILIZAÇÃO ESCURA
          // ============================================
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pauloAfonso,
                    initialZoom: 14.5,
                    minZoom: 5.0,
                    maxZoom: 19.0,
                  ),
                  children: [
                    // Aplicando o filtro CartoDB Dark Matter (Estilo escuro da sua foto)
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'br.com.rastreamento.escolar',
                    ),
                    // Rota percorrida (Polyline azul viva)
                    if (_rastro.length > 1)
                      PolylineLayer(polylines: [
                        Polyline(
                          points: _rastro,
                          strokeWidth: 4.0,
                          color: _corLinhaRastro,
                        ),
                      ]),
                    // Marcador do Ônibus (Ícone circular perfeito da imagem)
                    if (pos != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: LatLng(
                            (pos['latitude'] as num).toDouble(),
                            (pos['longitude'] as num).toDouble(),
                          ),
                          width: 50,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF20336B),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: _corLinhaRastro.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.directions_bus_rounded,
                              color: Colors.orangeAccent,
                              size: 26,
                            ),
                          ),
                        ),
                      ]),
                  ],
                ),

                // Banner de Atraso Condicional
                if (temAtraso)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      color: Colors.orange[800],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Atraso detectado: $_motivoAtraso',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_carregando)
                  const Center(child: CircularProgressIndicator(color: _corLinhaRastro)),

                if (!_carregando && pos == null)
                  Center(
                    child: Card(
                      color: _corFundoHeader,
                      margin: const EdgeInsets.all(32),
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Ônibus não iniciou o rastreamento.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),

                // ============================================
                // CARD INFERIOR DE MÉTRICAS (Igual ao Print)
                // ============================================
                if (pos != null)
                  Positioned(
                    bottom: 24, left: 16, right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Métrica 1: Velocidade (Ícone de Raio / Lightning)
                              _MetricaItem(
                                icon: Icons.bolt_rounded,
                                iconColor: Colors.amber,
                                valor: vel.toStringAsFixed(0),
                                unidade: 'km/h',
                              ),
                              // Separador vertical sutil
                              Container(width: 1, height: 40, color: Colors.grey[200]),
                              // Métrica 2: Tempo de chegada (Ícone de Cronômetro)
                              _MetricaItem(
                                icon: Icons.timer_outlined,
                                iconColor: Colors.blueGrey,
                                valor: _estimativaChegada(),
                                unidade: 'chegada',
                              ),
                              // Separador vertical sutil
                              Container(width: 1, height: 40, color: Colors.grey[200]),
                              // Métrica 3: Pontos (Ícone de Pin / Location)
                              _MetricaItem(
                                icon: Icons.location_on_rounded,
                                iconColor: Colors.redAccent,
                                valor: '${_rastro.length}',
                                unidade: 'pontos',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(height: 1, color: Colors.grey[100]!),
                          const SizedBox(height: 12),
                          // Linha do horário de atualização inferior
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.autorenew_rounded, size: 16, color: Colors.blueGrey[300]),
                              const SizedBox(width: 6),
                              Text(
                                'Atualizado: ${_ultimaAtualizacao != null ? fmt.format(_ultimaAtualizacao!) : '--'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      
      // Botão flutuante minimalista (Estilo Alvo de Mira da imagem)
      floatingActionButton: pos == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 120.0), // Ajustado para ficar acima do card branco
              child: FloatingActionButton(
                mini: true,
                backgroundColor: const Color(0xFF283563),
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                onPressed: () {
                  _mapController.move(
                    LatLng(
                      (pos['latitude'] as num).toDouble(),
                      (pos['longitude'] as num).toDouble(),
                    ),
                    15.5,
                  );
                },
                child: const Icon(Icons.track_changes_rounded, size: 20),
              ),
            ),
    );
  }
}

/// Widget interno para as métricas limpas e centralizadas do card inferior.
class _MetricaItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String valor;
  final String unidade;

  const _MetricaItem({
    required this.icon,
    required this.iconColor,
    required this.valor,
    required this.unidade,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B254B),
          ),
        ),
        Text(
          unidade,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
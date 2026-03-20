import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../service/api_service.dart';
import '../service/location_service.dart';

const List<Map<String, dynamic>> _atrasosPreDefinidos = [
  {'icone': Icons.tire_repair,       'motivo': 'Pneu furado'},
  {'icone': Icons.traffic,           'motivo': 'Trânsito intenso'},
  {'icone': Icons.build,             'motivo': 'Problema mecânico'},
  {'icone': Icons.car_crash,         'motivo': 'Acidente na via'},
  {'icone': Icons.local_gas_station, 'motivo': 'Abastecimento'},
  {'icone': Icons.child_care,        'motivo': 'Aguardando aluno'},
];

class TelaMotorista extends StatefulWidget {
final int cpfMotorista;
  final String nomeMotorista;
  final String placaVeiculo;

  const TelaMotorista({
    super.key,
    required this.cpfMotorista,
    required this.nomeMotorista,
    required this.placaVeiculo,
  });

  @override
  State<TelaMotorista> createState() => _TelaMotoristaState();
}

class _TelaMotoristaState extends State<TelaMotorista> {
  static const _pauloAfonso = LatLng(-9.4062, -38.2144);
  static const _intervaloSegundos = 10;

  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  bool _rastreando = false;
  Position? _ultimaPosicao;
  String _statusMsg = 'Aguardando início do rastreamento...';
  int _enviosComSucesso = 0;
  int _enviosFalhos = 0;
  DateTime? _ultimoEnvio;
  String? _motivoAtraso;

  @override
  void dispose() {
    _locationService.pararRastreamento();
    super.dispose();
  }

  Future<void> _toggleRastreamento() async {
    if (_rastreando) {
      _locationService.pararRastreamento();
      setState(() {
        _rastreando = false;
        _statusMsg = 'Rastreamento pausado.';
      });
      return;
    }

    final permissao = await LocationService.solicitarPermissao();
    if (!permissao) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Permissão de localização negada.')),
      );
      return;
    }

    setState(() {
      _rastreando = true;
      _statusMsg = '🔄 Iniciando GPS...';
    });

    _locationService.iniciarRastreamento(
      intervaloSegundos: _intervaloSegundos,
      onPosicaoAtualizada: _onNovaPosicao,
    );
  }

  Future<void> _onNovaPosicao(Position posicao) async {
    final sucesso = await ApiService.enviarPosicao(
    cpf: widget.cpfMotorista,
    nome: widget.nomeMotorista,
      placaVeiculo: widget.placaVeiculo,
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      velocidade: posicao.speed,
      motivoAtraso: _motivoAtraso,
    );

    setState(() {
      _ultimaPosicao = posicao;
      _ultimoEnvio = DateTime.now();
      if (sucesso) {
        _enviosComSucesso++;
        _statusMsg = _motivoAtraso != null
            ? '⚠️ Atraso enviado: $_motivoAtraso'
            : '✅ Posição enviada ao servidor';
      } else {
        _enviosFalhos++;
        _statusMsg = '⚠️ Falha ao enviar — tentando novamente...';
      }
    });

    _mapController.move(
      LatLng(posicao.latitude, posicao.longitude),
      _mapController.camera.zoom,
    );
  }

  void _abrirBottomSheetAtraso() {
    final customCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 8,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.warning_amber_rounded,
                          color: Colors.orange[700], size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('Informar Atraso',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (_motivoAtraso != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _motivoAtraso = null);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Atraso removido.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Limpar'),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.green),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Selecione o motivo ou descreva abaixo',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _atrasosPreDefinidos.map((item) {
                    final motivo = item['motivo'] as String;
                    final icone = item['icone'] as IconData;
                    final selecionado = _motivoAtraso == motivo;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() => customCtrl.clear());
                        setState(() => _motivoAtraso = motivo);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('⚠️ Atraso: $motivo'),
                            backgroundColor: Colors.orange[800],
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: selecionado
                              ? Colors.orange[700]
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selecionado
                                ? Colors.orange[700]!
                                : Colors.orange[200]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icone,
                                size: 16,
                                color: selecionado
                                    ? Colors.white
                                    : Colors.orange[800]),
                            const SizedBox(width: 6),
                            Text(motivo,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selecionado
                                      ? Colors.white
                                      : Colors.orange[900],
                                )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Text('Ou descreva outro motivo',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: customCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ex: Desvio por obra na rua...',
                    prefixIcon: const Icon(Icons.edit_note),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final texto = customCtrl.text.trim();
                    if (texto.isEmpty) return;
                    setState(() => _motivoAtraso = texto);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚠️ Atraso: $texto'),
                        backgroundColor: Colors.orange[800],
                      ),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Confirmar motivo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm:ss');
    final temAtraso = _motivoAtraso != null;

    return Scaffold(
      body: Column(
        children: [
          // ── Header customizado ─────────────────────────────────
          Container(
            color: const Color(0xFF1565C0),
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
                          'Rastreamento',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Badge de status
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
                                width: 7, height: 7,
                                decoration: BoxDecoration(
                                  color: _rastreando
                                      ? const Color(0xFF69F0AE)
                                      : Colors.white38,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _rastreando ? 'Ativo' : 'Parado',
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

                  // Card do motorista
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2)),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        // Nome e cargo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.nomeMotorista,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const Text(
                                'Motorista • Em rota',
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Placa em destaque
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD600),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.placaVeiculo,
                            style: const TextStyle(
                              color: Color(0xFF1A237E),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Corpo: mapa + overlays ─────────────────────────────
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
                      userAgentPackageName: 'br.com.rastreamento.escolar',
                    ),
                    if (_ultimaPosicao != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: LatLng(
                            _ultimaPosicao!.latitude,
                            _ultimaPosicao!.longitude,
                          ),
                          width: 48,
                          height: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              color: temAtraso
                                  ? Colors.orange[700]
                                  : const Color(0xFF1565C0),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 6,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: const Icon(
                                Icons.directions_bus_rounded,
                                color: Colors.white,
                                size: 26),
                          ),
                        ),
                      ]),
                  ],
                ),

                // Banner de atraso ativo
                if (temAtraso)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      color: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Atraso ativo: $_motivoAtraso',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _motivoAtraso = null),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Card de status
                Positioned(
                  bottom: 100,
                  left: 12,
                  right: 12,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(children: [
                            Icon(
                              _rastreando
                                  ? Icons.sensors
                                  : Icons.sensors_off,
                              color: _rastreando
                                  ? Colors.green
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(_statusMsg,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                          ]),
                          if (_ultimaPosicao != null) ...[
                            const Divider(height: 16),
                            _InfoRow(
                              icon: Icons.location_on,
                              label: 'Posição',
                              value:
                                  '${_ultimaPosicao!.latitude.toStringAsFixed(5)}, '
                                  '${_ultimaPosicao!.longitude.toStringAsFixed(5)}',
                            ),
                            _InfoRow(
                              icon: Icons.speed,
                              label: 'Velocidade',
                              value:
                                  '${(_ultimaPosicao!.speed * 3.6).toStringAsFixed(1)} km/h',
                            ),
                            if (_ultimoEnvio != null)
                              _InfoRow(
                                icon: Icons.access_time,
                                label: 'Último envio',
                                value: fmt.format(_ultimoEnvio!),
                              ),
                            _InfoRow(
                              icon: Icons.bar_chart,
                              label: 'Envios',
                              value:
                                  '✅ $_enviosComSucesso  ❌ $_enviosFalhos',
                            ),
                          ],
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

      // ── FABs ──────────────────────────────────────────────────
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'atraso',
            onPressed: _abrirBottomSheetAtraso,
            backgroundColor:
                temAtraso ? Colors.orange[700] : Colors.orange[50],
            foregroundColor:
                temAtraso ? Colors.white : Colors.orange[800],
            elevation: temAtraso ? 6 : 2,
            icon: Icon(
              temAtraso
                  ? Icons.warning_amber_rounded
                  : Icons.warning_amber_outlined,
              size: 20,
            ),
            label: Text(
              temAtraso
                  ? 'Atraso: $_motivoAtraso'
                  : 'Informar Atraso',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'rastrear',
            onPressed: _toggleRastreamento,
            backgroundColor: _rastreando
                ? Colors.red[700]
                : const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            icon: Icon(
              _rastreando
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline,
              size: 28,
            ),
            label: Text(
              _rastreando
                  ? 'Parar Rastreamento'
                  : 'Iniciar Rastreamento',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
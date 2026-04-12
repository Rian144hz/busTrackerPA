import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../service/api_service.dart';

/// Tela do responsável/pai para acompanhar o ônibus em tempo real.
///
/// Esta tela exibe um mapa mostrando a localização atual do veículo,
/// o trajeto percorrido (rastro), informações de velocidade e tempo estimado
/// de chegada, além de alertas de atraso.
///
/// Atualiza automaticamente a cada [_intervaloSegundos] segundos via polling.
///
/// Recebe como parâmetros obrigatórios:
/// - [nomeResponsavel]: Nome do pai/responsável que está visualizando
/// - [nomeAluno]: Nome do aluno sendo acompanhado
/// - [placaVeiculo]: Placa do veículo a ser rastreado
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

/// Classe de estado que gerencia todos os dados dinâmicos da tela do pai.
///
/// Responsável por:
/// - Buscar periodicamente a posição do ônibus no servidor
/// - Manter o histórico de posições (rastro) para desenhar a rota
/// - Atualizar a interface com informações de velocidade, atraso, etc.
class _TelaPaiState extends State<TelaPai> {
  /// Coordenadas padrão do centro do mapa quando ainda não há dados do servidor.
  /// Centro em Paulo Afonso - BA.
  static const _pauloAfonso = LatLng(-9.4062, -38.2144);

  /// Intervalo em segundos entre cada consulta ao servidor.
  /// Define a frequência de atualização da posição do ônibus.
  static const _intervaloSegundos = 10;

  /// Número máximo de pontos do rastro a serem mantidos na memória.
  /// Limita o histórico para evitar consumo excessivo de memória.
  static const _maxRastro = 30;

  /// Controlador do mapa que permite movimentar e controlar a visualização programaticamente.
  /// Usado para centralizar o mapa na posição do ônibus quando atualizada.
  final MapController _mapController = MapController();

  /// Timer que executa a busca de posição periodicamente em background.
  /// É criado em [initState] e cancelado em [dispose].
  Timer? _timer;

  /// Mapa com os dados da posição atual recebidos do servidor.
  /// Contém: latitude, longitude, velocidade, motivoAtraso, etc.
  /// É null quando ainda não houve nenhuma resposta do servidor.
  Map<String, dynamic>? _posicaoAtual;

  /// Lista de coordenadas que representa o trajeto percorrido pelo ônibus.
  /// Usada para desenhar a linha da rota no mapa (polyline).
  /// Mantém no máximo [_maxRastro] pontos (FIFO - primeiro a entrar, primeiro a sair).
  final List<LatLng> _rastro = [];

  /// Data/hora da última atualização bem-sucedida dos dados do servidor.
  /// Exibido no card de informações para o pai saber se os dados estão atualizados.
  DateTime? _ultimaAtualizacao;

  /// Flag que indica se está carregando os dados pela primeira vez.
  /// Controla a exibição do indicador de progresso circular.
  bool _carregando = true;

  /// Motivo do atraso recebido do servidor (informado pelo motorista).
  /// Quando preenchido, exibe um banner laranja de alerta no topo do mapa.
  /// Pode ser null ou vazio quando não há atraso.
  String? _motivoAtraso;

  /// Método chamado automaticamente quando o widget é inserido na árvore.
  ///
  /// Inicia o processo de busca de dados:
  /// 1. Faz a primeira busca imediata (_buscarPosicao)
  /// 2. Configura um timer para buscar a cada [_intervaloSegundos] segundos
  @override
  void initState() {
    super.initState();
    _buscarPosicao();
    _timer = Timer.periodic(
      const Duration(seconds: _intervaloSegundos),
      (_) => _buscarPosicao(),
    );
  }

  /// Método chamado automaticamente quando o widget é removido da árvore.
  ///
  /// Cancela o timer para parar as requisições ao servidor e liberar recursos.
  /// Importante para evitar memory leaks e requisições desnecessárias.
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Busca a última posição do ônibus no servidor via API.
  ///
  /// Este método é chamado:
  /// - Uma vez no initState (primeira carga)
  /// - Periodicamente a cada [_intervaloSegundos] segundos pelo Timer
  ///
  /// Atualiza o estado com:
  /// - [_posicaoAtual]: Dados completos recebidos do servidor
  /// - [_ultimaAtualizacao]: Horário desta busca
  /// - [_motivoAtraso]: Se o motorista informou algum atraso
  /// - [_rastro]: Adiciona novo ponto à rota, limitando a [_maxRastro] pontos
  ///
  /// Também move o mapa automaticamente para a nova posição do ônibus.
  Future<void> _buscarPosicao() async {
    // Consulta o backend Java pela última posição conhecida desta placa
    final dados = await ApiService.buscarUltimaPosicao(widget.placaVeiculo);

    // Verifica se o widget ainda está montado antes de chamar setState
    // (evita erro se o usuário saiu da tela enquanto a requisição rodava)
    if (!mounted) return;

    setState(() {
      _carregando = false; // Remove o indicador de carregamento

      if (dados != null) {
        // Resposta bem-sucedida - atualiza todos os dados
        _posicaoAtual = dados;
        _ultimaAtualizacao = DateTime.now();
        _motivoAtraso = dados['motivoAtraso'] as String?;

        // Cria um objeto LatLng com as coordenadas recebidas
        final ponto = LatLng(
          (dados['latitude'] as num).toDouble(),
          (dados['longitude'] as num).toDouble(),
        );

        // Adiciona ao rastro se for um ponto novo (evita duplicados)
        if (_rastro.isEmpty || _rastro.last != ponto) {
          _rastro.add(ponto);
          // Remove o ponto mais antigo se exceder o limite máximo
          if (_rastro.length > _maxRastro) _rastro.removeAt(0);
        }

        // Centraliza o mapa na posição do ônibus mantendo o zoom atual
        _mapController.move(ponto, _mapController.camera.zoom);
      }
    });
  }

  /// Calcula uma estimativa de chegada baseada na velocidade atual.
  ///
  /// Fórmula: tempo = (distância / velocidade) * 60 minutos
  /// Assume uma distância fixa de 2.5 km até o destino.
  ///
  /// Retorna:
  /// - String formatada como "Aprox. X min" se estiver se movendo
  /// - "Parado" se a velocidade for menor que 1 km/h
  /// - "--" se não houver dados de posição
  String _estimativaChegada() {
    if (_posicaoAtual == null) return '--';

    // Converte velocidade de m/s para km/h
    final vel =
        ((_posicaoAtual!['velocidade'] as num?)?.toDouble() ?? 0) * 3.6;

    if (vel < 1) return 'Parado';

    // Distância fixa assumida até o destino (em km)
    const distanciaKm = 2.5;

    // Calcula tempo em minutos: (km / km/h) * 60 = minutos
    final min = (distanciaKm / vel * 60).round();

    return 'Aprox. $min min';
  }

  /// Constrói a interface visual da tela do responsável.
  ///
  /// Estrutura da tela:
  /// - Header verde com nome do aluno, responsável e indicador de status
  /// - Mapa que ocupa a maior parte da tela
  /// - Banner de atraso (condicional - só aparece se motorista informou)
  /// - Indicador de carregamento (condicional)
  /// - Mensagem de ônibus não iniciado (condicional)
  /// - Card flutuante com métricas (velocidade, chegada, pontos)
  /// - Botão flutuante para centralizar no ônibus
  @override
  Widget build(BuildContext context) {
    // Formatador de data para exibir horário no formato HH:mm:ss
    final fmt = DateFormat('HH:mm:ss');

    // Acesso rápido aos dados da posição atual
    final pos = _posicaoAtual;

    // Calcula velocidade em km/h (converte de m/s)
    final vel = (((pos?['velocidade']) as num?)?.toDouble() ?? 0) * 3.6;

    // Flag que indica se há um atraso informado pelo motorista
    final temAtraso = _motivoAtraso != null && _motivoAtraso!.isNotEmpty;

    return Scaffold(
      body: Column(
        children: [
          // ============================================
          // HEADER CUSTOMIZADO (parte superior verde)
          // ============================================
          Container(
            color: const Color(0xFF2E7D32), // Verde escuro
            child: SafeArea(
              bottom: false, // Não aplica padding na parte inferior
              child: Column(
                children: [
                  // Linha superior: botão voltar, título e indicador de status
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        // Botão de voltar para a tela anterior
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        // Título da tela
                        const Text(
                          'Acompanhar Ônibus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(), // Empurra o próximo widget para a direita
                        // Indicador visual "Ao vivo" ou "Aguardando"
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51), // ~0.2 opacidade
                            border: Border.all(
                                color: Colors.white.withAlpha(77)), // ~0.3
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Bolinha verde se tiver dados, cinza se não tiver
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: pos != null
                                      ? const Color(0xFF69F0AE) // Verde
                                      : Colors.white38, // Cinza
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

                  // Cartão com informações do aluno e responsável
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(31), // ~0.12 opacidade
                      border: Border.all(
                          color: Colors.white.withAlpha(51)), // ~0.2
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    child: Column(
                      children: [
                        // Seção do Aluno (com ícone de escola)
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51), // ~0.2
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
                                  // Label "ALUNO" em letras pequenas
                                  const Text(
                                    'ALUNO',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  // Nome do aluno
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
                        // Linha divisória sutil
                        Container(
                            height: 1,
                            color: Colors.white.withAlpha(38)), // ~0.15
                        const SizedBox(height: 10),

                        // Seção do Responsável (com ícone de pessoa)
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(38), // ~0.15
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
                                  // Label "RESPONSÁVEL"
                                  const Text(
                                    'RESPONSÁVEL',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  // Nome do responsável
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

          // ============================================
          // CORPO - MAPA + OVERLAYS
          // ============================================
          Expanded(
            child: Stack(
              children: [
                // Widget do mapa OpenStreetMap
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: _pauloAfonso, // Centro inicial
                    initialZoom: 14.0, // Zoom inicial
                    minZoom: 5.0, // Zoom mínimo
                    maxZoom: 19.0, // Zoom máximo
                  ),
                  children: [
                    // Camada de tiles (imagens do mapa) do OpenStreetMap
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'br.com.rastreamento.escolar',
                    ),
                    // Camada de polyline - desenha a linha da rota percorrida
                    // Só desenha se houver pelo menos 2 pontos no rastro
                    if (_rastro.length > 1)
                      PolylineLayer(polylines: [
                        Polyline(
                          points: _rastro,
                          strokeWidth: 4.5,
                          // Cor muda se tiver atraso: laranja (com atraso) ou verde (normal)
                          color: temAtraso
                              ? Colors.orange.withAlpha(204) // ~0.8
                              : Colors.green.withAlpha(191), // ~0.75
                        ),
                      ]),
                    // Camada de marcadores - mostra a posição atual do ônibus
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
                              // Cor muda se tiver atraso (laranja) ou não (verde)
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

                // ============================================
                // BANNER DE ATRASO (só aparece se tiver atraso)
                // ============================================
                if (temAtraso)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      color: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Ícone de alerta em container arredondado
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(51), // ~0.2
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 20),
                          ),
                          const SizedBox(width: 10),
                          // Texto do atraso (título + motivo)
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

                // ============================================
                // INDICADOR DE CARREGAMENTO (só na primeira vez)
                // ============================================
                if (_carregando)
                  const Center(child: CircularProgressIndicator()),

                // ============================================
                // MENSAGEM: ÔNIBUS NÃO INICIOU (se não houver dados)
                // ============================================
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

                // ============================================
                // CARD DE MÉTRICAS (velocidade, chegada, pontos)
                // ============================================
                if (pos != null)
                  Positioned(
                    bottom: 16, left: 12, right: 12,
                    child: Card(
                      elevation: 10, // Sombra elevada
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Linha com 3 métricas principais
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                // Métrica: Velocidade
                                _Metrica(
                                  icon: Icons.speed,
                                  valor: vel.toStringAsFixed(0),
                                  unidade: 'km/h',
                                  // Cor muda conforme velocidade: verde (lento), laranja (médio), vermelho (rápido)
                                  cor: vel > 60
                                      ? Colors.red
                                      : vel > 40
                                          ? Colors.orange
                                          : Colors.green[700]!,
                                ),
                                // Métrica: Tempo estimado de chegada
                                _Metrica(
                                  icon: Icons.timer_outlined,
                                  valor: _estimativaChegada(),
                                  unidade: 'chegada',
                                  // Cor laranja se tiver atraso, azul se normal
                                  cor: temAtraso
                                      ? Colors.orange[700]!
                                      : const Color(0xFF1565C0),
                                ),
                                // Métrica: Quantidade de pontos no rastro
                                _Metrica(
                                  icon: Icons.route,
                                  valor: '${_rastro.length}',
                                  unidade: 'pontos',
                                  cor: Colors.green[700]!,
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            // Hora da última atualização
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
                            // Coordenadas em texto pequeno (debug/informativo)
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

      // ============================================
      // BOTÃO FLUTUANTE: Centralizar no ônibus
      // ============================================
      // Só aparece se houver posição do ônibus
      floatingActionButton: pos == null
          ? null
          : FloatingActionButton.small(
              backgroundColor: temAtraso
                  ? Colors.orange[700]
                  : const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              // Ao tocar, centraliza o mapa na posição do ônibus com zoom 15
              onPressed: () {
                _mapController.move(
                  LatLng(
                    (pos['latitude'] as num).toDouble(),
                    (pos['longitude'] as num).toDouble(),
                  ),
                  15.0, // Zoom nivelado
                );
              },
              child: const Icon(Icons.my_location),
            ),
    );
  }
}

/// Widget auxiliar reutilizável para exibir uma métrica no card inferior.
///
/// Mostra um ícone, um valor grande e uma unidade/label abaixo.
/// Usado para velocidade, tempo de chegada e contador de pontos.
///
/// Parâmetros:
/// - [icon]: Ícone a ser exibido acima do valor
/// - [valor]: Valor principal (ex: "45", "Aprox. 5 min", "12")
/// - [unidade]: Texto abaixo do valor (ex: "km/h", "chegada", "pontos")
/// - [cor]: Cor do ícone e do valor (muda conforme contexto)
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

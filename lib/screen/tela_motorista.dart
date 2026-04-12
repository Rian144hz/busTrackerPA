import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../service/api_service.dart';
import '../service/location_service.dart';

/// Lista constante com os motivos de atraso pré-definidos que o motorista pode selecionar.
/// Cada item é um Map contendo o ícone (IconData) e o texto do motivo (String).
/// Esses valores aparecem como botões clicáveis no bottom sheet de atraso.
const List<Map<String, dynamic>> _atrasosPreDefinidos = [
  {'icone': Icons.tire_repair, 'motivo': 'Pneu furado'},
  {'icone': Icons.traffic, 'motivo': 'Trânsito intenso'},
  {'icone': Icons.build, 'motivo': 'Problema mecânico'},
  {'icone': Icons.car_crash, 'motivo': 'Acidente na via'},
  {'icone': Icons.local_gas_station, 'motivo': 'Abastecimento'},
  {'icone': Icons.child_care, 'motivo': 'Aguardando aluno'},
];

/// Tela principal do motorista para rastreamento do veículo em tempo real.
///
/// Esta tela exibe um mapa com a localização atual, permite iniciar/parar o envio
/// automático de coordenadas para o servidor, e permite informar motivos de atraso.
///
/// Recebe como parâmetros obrigatórios:
/// - [cpfMotorista]: CPF do motorista logado (usado para identificar no backend)
/// - [nomeMotorista]: Nome exibido no cabeçalho da tela
/// - [placaVeiculo]: Placa do veículo sendo rastreado
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

/// Classe de estado que mantém todos os dados dinâmicos da tela do motorista.
///
/// Gerencia o estado do rastreamento (ligado/desligado), armazena a posição atual,
/// contadores de envio, mensagens de status e o motivo de atraso atual.
class _TelaMotoristaState extends State<TelaMotorista> {
  /// Coordenadas padrão do centro do mapa quando ainda não há localização do GPS.
  /// Usado como ponto inicial (Paulo Afonso - BA).
  static const _pauloAfonso = LatLng(-9.4062, -38.2144);

  /// Intervalo em segundos entre cada envio de coordenadas para o servidor.
  /// Define de quanto em quanto tempo a posição será enviada ao backend.
  static const _intervaloSegundos = 10;

  /// Instância do serviço de localização que gerencia o GPS em background.
  /// Responsável por solicitar permissões e obter atualizações de posição.
  final LocationService _locationService = LocationService();

  /// Controlador do mapa que permite movimentar e controlar a visualização programaticamente.
  /// Usado para centralizar o mapa na posição atual do veículo quando atualizada.
  final MapController _mapController = MapController();

  /// Flag que indica se o rastreamento está ativo ou não.
  /// Quando true, o GPS está sendo monitorado e enviando dados ao servidor.
  bool _rastreando = false;

  /// Última posição recebida do GPS.
  /// Pode ser null se ainda não houver nenhuma leitura de localização.
  Position? _ultimaPosicao;

  /// Mensagem atual exibida no card de status para informar o motorista sobre o estado.
  /// Ex: "Iniciando GPS...", "Posição enviada", "Falha ao enviar", etc.
  String _statusMsg = 'Aguardando início do rastreamento...';

  /// Contador de quantas vezes o envio da posição foi bem-sucedido.
  /// Exibido no card de status para acompanhamento do motorista.
  int _enviosComSucesso = 0;

  /// Contador de quantas vezes o envio da posição falhou.
  /// Exibido no card de status para alertar sobre problemas de conexão.
  int _enviosFalhos = 0;

  /// Data/hora do último envio bem-sucedido de coordenadas.
  /// Exibido no card de status para o motorista saber quando foi a última atualização.
  DateTime? _ultimoEnvio;

  /// Motivo atual do atraso informado pelo motorista.
  /// Quando preenchido, é exibido um banner laranjo no topo e enviado ao servidor.
  /// Pode ser null quando não há atraso informado.
  String? _motivoAtraso;

  /// Método chamado automaticamente quando o widget é removido da árvore.
  ///
  /// Para o rastreamento do GPS para economizar bateria e liberar recursos.
  /// Importante para evitar que o GPS continue ativo mesmo após sair da tela.
  @override
  void dispose() {
    _locationService.pararRastreamento();
    super.dispose();
  }

  /// Alterna o estado do rastreamento entre ligado e desligado.
  ///
  /// Quando chamado:
  /// - Se estiver rastreando: para o rastreamento e atualiza o estado
  /// - Se não estiver rastreando: solicita permissão de localização e inicia o rastreamento
  ///
  /// Mostra um SnackBar se a permissão for negada pelo usuário.
  Future<void> _toggleRastreamento() async {
    // Se já está rastreando, para o serviço e atualiza o estado visual
    if (_rastreando) {
      _locationService.pararRastreamento();
      setState(() {
        _rastreando = false;
        _statusMsg = 'Rastreamento pausado.';
      });
      return;
    }

    // Solicita permissão de localização ao usuário (GPS)
    final permissao = await LocationService.solicitarPermissao();
    if (!permissao) {
      // Usuário negou a permissão - mostra mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Permissão de localização negada.')),
      );
      return;
    }

    // Atualiza a interface para indicar que está iniciando
    setState(() {
      _rastreando = true;
      _statusMsg = '🔄 Iniciando GPS...';
    });

    // Inicia o serviço de rastreamento com callback para receber atualizações
    _locationService.iniciarRastreamento(
      intervaloSegundos: _intervaloSegundos,
      onPosicaoAtualizada: _onNovaPosicao,
    );
  }

  /// Callback chamado automaticamente sempre que uma nova posição do GPS é recebida.
  ///
  /// Este método é invocado pelo LocationService a cada [intervaloSegundos] segundos.
  /// Ele envia os dados para o backend Java via API e atualiza a interface com:
  /// - A nova posição no mapa
  /// - Contadores de sucesso/falha
  /// - Mensagem de status apropriada
  ///
  /// [posicao] é o objeto Position do Geolocator com latitude, longitude, velocidade, etc.
  Future<void> _onNovaPosicao(Position posicao) async {
    // Envia os dados da posição para o backend Java via HTTP POST
    // Inclui o motivo de atraso se houver um informado
    final sucesso = await ApiService.enviarPosicao(
      cpf: widget.cpfMotorista,
      nome: widget.nomeMotorista,
      placaVeiculo: widget.placaVeiculo,
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      velocidade: posicao.speed,
      motivoAtraso: _motivoAtraso,
    );

    // Atualiza o estado da tela com a nova posição e resultado do envio
    setState(() {
      _ultimaPosicao = posicao;
      _ultimoEnvio = DateTime.now();
      if (sucesso) {
        // Envio bem-sucedido - incrementa contador e mostra mensagem apropriada
        _enviosComSucesso++;
        _statusMsg = _motivoAtraso != null
            ? '⚠️ Atraso enviado: $_motivoAtraso'
            : '✅ Posição enviada ao servidor';
      } else {
        // Falha no envio - incrementa contador de falhas e alerta o usuário
        _enviosFalhos++;
        _statusMsg = '⚠️ Falha ao enviar — tentando novamente...';
      }
    });

    // Centraliza o mapa na nova posição do motorista mantendo o zoom atual
    _mapController.move(
      LatLng(posicao.latitude, posicao.longitude),
      _mapController.camera.zoom,
    );
  }

  /// Abre o painel inferior (bottom sheet) para o motorista informar um atraso.
  ///
  /// Este método exibe um modal deslizante com:
  /// - Chips/botões com motivos pré-definidos (pneu furado, trânsito, etc)
  /// - Campo de texto para motivo personalizado
  /// - Botão para limpar o atraso caso já exista um
  ///
  /// Usa StatefulBuilder para atualizar o bottom sheet sem afetar a tela principal.
  void _abrirBottomSheetAtraso() {
    // Controller para capturar o texto digitado pelo usuário
    final customCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que o bottom sheet acompanhe o teclado
      backgroundColor: Colors.transparent, // Deixa o fundo transparente para ver o conteúdo atrás
      builder: (_) => StatefulBuilder(
        // StatefulBuilder permite usar setState dentro do bottom sheet
        builder: (ctx, setSheetState) {
          return Container(
            // Container branco com bordas arredondadas no topo
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            // Padding ajustado para não ficar escondido pelo teclado
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 8,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ocupa apenas o espaço necessário
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Indicador visual (linha cinza) no topo do bottom sheet
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Cabeçalho com ícone, título e botão de limpar (se houver atraso)
                Row(
                  children: [
                    // Container com ícone de alerta
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
                    // Título "Informar Atraso"
                    const Text('Informar Atraso',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    // Botão "Limpar" só aparece se já houver um atraso informado
                    if (_motivoAtraso != null)
                      TextButton.icon(
                        onPressed: () {
                          // Remove o atraso e fecha o bottom sheet
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
                // Subtítulo explicativo
                Text('Selecione o motivo ou descreva abaixo',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 16),
                // Grid/linha com chips dos motivos pré-definidos
                Wrap(
                  spacing: 8, // Espaço horizontal entre os chips
                  runSpacing: 8, // Espaço vertical entre as linhas
                  children: _atrasosPreDefinidos.map((item) {
                    final motivo = item['motivo'] as String;
                    final icone = item['icone'] as IconData;
                    final selecionado = _motivoAtraso == motivo;
                    return GestureDetector(
                      // Ao tocar em um chip, define esse motivo e fecha
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
                      // Chip animado que muda de cor quando selecionado
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
                const Divider(), // Linha divisória
                const SizedBox(height: 12),
                // Seção de motivo personalizado
                Text('Ou descreva outro motivo',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                // Campo de texto para motivo customizado
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
                // Botão para confirmar o motivo personalizado
                ElevatedButton.icon(
                  onPressed: () {
                    final texto = customCtrl.text.trim();
                    if (texto.isEmpty) return; // Não faz nada se vazio
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

  /// Constrói a interface visual da tela do motorista.
  ///
  /// Estrutura da tela:
  /// - Header azul com nome, placa e indicador de status
  /// - Mapa que ocupa a maior parte da tela
  /// - Banner de atraso (condicional)
  /// - Card flutuante com informações de status
  /// - Botões flutuantes para atraso e rastreamento
  @override
  Widget build(BuildContext context) {
    // Formatador de data para exibir horário no formato HH:mm:ss
    final fmt = DateFormat('HH:mm:ss');
    // Flag auxiliar para verificar se há um atraso informado
    final temAtraso = _motivoAtraso != null;

    return Scaffold(
      body: Column(
        children: [
          // ============================================
          // HEADER CUSTOMIZADO (parte superior azul)
          // ============================================
          Container(
            color: const Color(0xFF1565C0), // Azul primário
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
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        // Título da tela
                        const Text(
                          'Rastreamento',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(), // Empurra o próximo widget para a direita
                        // Indicador visual "Ativo" ou "Parado"
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
                              // Bolinha verde se ativo, cinza se parado
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _rastreando
                                      ? const Color(0xFF69F0AE) // Verde
                                      : Colors.white38, // Cinza
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
                  // Cartão com informações do motorista e veículo
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        // Ícone do motorista (círculo com ícone de pessoa)
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
                        // Nome e função do motorista
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
                                    color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Placa do veículo (destaque amarelo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD600), // Amarelo
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.placaVeiculo,
                            style: const TextStyle(
                              color: Color(0xFF1A237E), // Azul escuro
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

          // ============================================
          // MAPA + OVERLAYS (parte principal)
          // ============================================
          Expanded(
            child: Stack(
              children: [
                // Widget do mapa OpenStreetMap
                FlutterMap(
                  mapController: _mapController, // Controlador para mover o mapa
                  options: const MapOptions(
                    initialCenter: _pauloAfonso, // Centro inicial do mapa
                    initialZoom: 14.0, // Zoom inicial
                    minZoom: 5.0, // Zoom mínimo
                    maxZoom: 19.0, // Zoom máximo
                  ),
                  children: [
                    // Camada de tiles (imagens do mapa) do OpenStreetMap
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'br.com.rastreamento.escolar',
                    ),
                    // Camada de marcadores - só mostra se houver posição
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
                              // Cor muda se tiver atraso (laranja) ou não (azul)
                              color: temAtraso
                                  ? Colors.orange[700]
                                  : const Color(0xFF1565C0),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 6,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: const Icon(Icons.directions_bus_rounded,
                                color: Colors.white, size: 26),
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
                    top: 0,
                    left: 0,
                    right: 0,
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
                          // Botão X para remover o atraso
                          GestureDetector(
                            onTap: () => setState(() => _motivoAtraso = null),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ============================================
                // CARD DE STATUS FLUTUANTE (informações técnicas)
                // ============================================
                Positioned(
                  bottom: 100, // Acima dos FABs
                  left: 12,
                  right: 12,
                  child: Card(
                    elevation: 8, // Sombra
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Linha com ícone e mensagem de status
                          Row(children: [
                            Icon(
                              _rastreando ? Icons.sensors : Icons.sensors_off,
                              color: _rastreando ? Colors.green : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(_statusMsg,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                          ]),
                          // Informações técnicas (só aparecem após primeira posição)
                          if (_ultimaPosicao != null) ...[
                            const Divider(height: 16),
                            // Coordenadas da última posição
                            _InfoRow(
                              icon: Icons.location_on,
                              label: 'Posição',
                              value:
                                  '${_ultimaPosicao!.latitude.toStringAsFixed(5)}, ${_ultimaPosicao!.longitude.toStringAsFixed(5)}',
                            ),
                            // Velocidade em km/h (convertida de m/s)
                            _InfoRow(
                              icon: Icons.speed,
                              label: 'Velocidade',
                              value:
                                  '${(_ultimaPosicao!.speed * 3.6).toStringAsFixed(1)} km/h',
                            ),
                            // Hora do último envio
                            if (_ultimoEnvio != null)
                              _InfoRow(
                                icon: Icons.access_time,
                                label: 'Último envio',
                                value: fmt.format(_ultimoEnvio!),
                              ),
                            // Contadores de envios
                            _InfoRow(
                              icon: Icons.bar_chart,
                              label: 'Envios',
                              value: '✅ $_enviosComSucesso  ❌ $_enviosFalhos',
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

      // ============================================
      // BOTÕES FLUTUANTES (FABs) na lateral direita
      // ============================================
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Botão para informar/remover atraso
          FloatingActionButton.extended(
            heroTag: 'atraso', // Tag única para animação de hero
            onPressed: _abrirBottomSheetAtraso,
            // Cor muda se tiver atraso informado
            backgroundColor:
                temAtraso ? Colors.orange[700] : Colors.orange[50],
            foregroundColor: temAtraso ? Colors.white : Colors.orange[800],
            elevation: temAtraso ? 6 : 2, // Mais sombra se ativo
            icon: Icon(
              temAtraso
                  ? Icons.warning_amber_rounded
                  : Icons.warning_amber_outlined,
              size: 20,
            ),
            label: Text(
              temAtraso ? 'Atraso: $_motivoAtraso' : 'Informar Atraso',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 10), // Espaço entre os botões
          // Botão principal: Iniciar/Parar rastreamento
          FloatingActionButton.extended(
            heroTag: 'rastrear',
            onPressed: _toggleRastreamento,
            // Cor muda conforme estado: azul (parado) ou vermelho (rastreando)
            backgroundColor:
                _rastreando ? Colors.red[700] : const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            icon: Icon(
              _rastreando ? Icons.stop_circle_outlined : Icons.play_circle_outline,
              size: 28,
            ),
            label: Text(
              _rastreando ? 'Parar Rastreamento' : 'Iniciar Rastreamento',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

/// Widget auxiliar reutilizável para exibir uma linha de informação
/// com ícone, label e valor formatado.
///
/// Usado no card de status para mostrar dados como posição, velocidade, etc.
///
/// Parâmetros:
/// - [icon]: Ícone à esquerda da linha
/// - [label]: Texto descritivo (ex: "Posição", "Velocidade")
/// - [value]: Valor a ser exibido (ex: "-9.40620, -38.21440")
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

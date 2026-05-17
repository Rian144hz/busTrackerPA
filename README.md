Gemini
Flutter Bus Tracking App Development
Conversa com o Gemini
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:intl/intl.dart';

import 'package:latlong2/latlong.dart';



import '../service/api_service.dart';

import '../constants.dart';



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

static final _pauloAfonso = LocationConstants.defaultLocation;



/// Intervalo em segundos entre cada consulta ao servidor.

/// Define a frequência de atualização da posição do ônibus.

static const _intervaloSegundos = TimingConstants.updateIntervalSeconds;



/// Número máximo de pontos do rastro a serem mantidos na memória.

/// Limita o histórico para evitar consumo excessivo de memória.

static const _maxRastro = TimingConstants.maxRastroPoints;



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

// Compara coordenadas em vez de referência do objeto

if (_rastro.isEmpty ||

(_rastro.last.latitude != ponto.latitude ||

_rastro.last.longitude != ponto.longitude)) {

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

options: MapOptions(

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





import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:geolocator/geolocator.dart';

import 'package:intl/intl.dart';

import 'package:latlong2/latlong.dart';

import 'package:vibration/vibration.dart';



import '../service/api_service.dart';

import '../service/location_service.dart';

import '../constants.dart';

import '../constants/app_colors.dart';



const List<Map<String, dynamic>> _atrasosPreDefinidos = [

{'icone': Icons.tire_repair, 'motivo': 'Pneu furado'},

{'icone': Icons.traffic, 'motivo': 'Trânsito intenso'},

{'icone': Icons.build, 'motivo': 'Problema mecânico'},

{'icone': Icons.car_crash, 'motivo': 'Acidente na via'},

{'icone': Icons.local_gas_station, 'motivo': 'Abastecimento'},

{'icone': Icons.child_care, 'motivo': 'Aguardando aluno'},

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

static final _pauloAfonso = Locat

O código das duas telas está muito bem estruturado, limpo e com comentários excelentes. Você organizou perfeitamente o fluxo de consumo da API Java no Flutter, utilizando boas práticas como a validação de if (!mounted) return; antes do setState nas requisições assíncronas e a limpeza de recursos no dispose.

Como a mensagem da TelaMotorista acabou sendo cortada no final do seu envio, montei um checklist de pontos cruciais para você validar ou implementar na continuidade do código dela, garantindo o funcionamento integrado com a TelaPai e o ecossistema do busTrackerPA.

🛠️ Checklist de Implementação para a TelaMotorista
Para que o rastreamento em tempo real funcione perfeitamente com o backend e reflita na tela do pai, certifique-se de cobrir estes tópicos na lógica do motorista:

1. Inicialização e Permissões do Geolocator
Antes de iniciar o serviço de localização (LocationService), certifique-se de checar e solicitar as permissões do usuário.

Dica: Exiba um diálogo explicativo se o usuário recusar a permissão da primeira vez, já que o app depende inteiramente disso.

2. Envio de Dados em Background
Como o motorista precisa bloquear a tela do celular ou abrir outros apps de navegação (como o Google Maps/Waze) enquanto dirige, o Timer.periodic tradicional pode ser suspenso pelo sistema operacional Android/Ubuntu Touch.

Recomendação: Utilize pacotes como o flutter_background_service ou certifique-se de que o seu LocationService esteja configurado com uma notificação persistente em primeiro plano (Foreground Service).

3. Sincronização do Status de Atraso
Na lista de _atrasosPreDefinidos que você criou, ao selecionar um motivo, envie imediatamente um payload para o backend contendo:

JSON
{
  "placaVeiculo": "XYZ-1234",
  "motivoAtraso": "Trânsito intenso",
  "latitude": -9.406,
  "longitude": -38.214,
  "velocidade": 0.0
}
Limpeza do Alerta: Crie também um botão de "Resolver/Retirar Atraso" que envie o motivoAtraso como null ou string vazia, limpando o banner laranja na tela do pai.

4. Controle de Vibração (vibration)
No array de atrasos, você importou o pacote vibration. É uma excelente prática de acessibilidade e usabilidade dar um feedback tátil (um pulso curto de vibração) quando o motorista confirmar o início da rota ou alternar o status de atraso, garantindo que ele saiba que a ação funcionou sem precisar focar muito tempo na tela.

Exemplo de Estrutura do Loop de Envio (State da TelaMotorista)
Caso precise de uma referência para o método que captura a localização e envia ao servidor Java, a lógica deve seguir este padrão:

Dart
// Dentro do _TelaMotoristaState
bool _rastreando = false;

void _alternarRastreamento() async {
  // Lógica de checagem de permissão do Geolocator aqui...
  
  setState(() {
    _rastreando = !_rastreando;
  });

  if (_rastreando) {
    // Feedback tátil ao iniciar
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
    
    // Escuta o fluxo de posições do GPS
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Atualiza a cada 10 metros percorridos
      ),
    ).listen((Position position) {
      if (!_rastreando) return;
      
      // Envia para o ApiService do backend Java
      ApiService.enviarPosicao(
        placa: widget.placaVeiculo,
        lat: position.latitude,
        lng: position.longitude,
        velocidade: position.speed, // m/s nativo do Geolocator
        motivoAtraso: _motivoSelecionado,
      );
      
      // Atualiza o mapa local do motorista, se necessário
    });
  }
}
Se precisar ajustar a lógica de transmissão do GPS, a persistência de dados locais com o SQLite/Hive para quando o ônibus passar por áreas sem sinal na região, ou quiser que eu analise o restante da estrutura da TelaMotorista, é só mandar a continuação!

deixe tela pai assim

mande o codigo do flutter

O design atual do seu código usa tons de verde (Color(0xFF2E7D32)), enquanto o da imagem possui uma identidade visual corporativa baseada em azul escuro/noturno (tanto no cabeçalho quanto no mapa estilizado), cards com opacidades bem sutis, ícones específicos (como um raio para velocidade e um pin para os pontos) e uma disposição extremamente limpa.

Aqui está o código completo da sua TelaPai totalmente remodelado e refatorado para ficar idêntico ao da imagem:

Dart
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
💎 O que mudou para ficar idêntico à imagem:
Paleta Dark Blue: Substituição completa do verde original pelos tons exatos de azul noturno corporativo (#1B254B e #283563).

Mapa Escuro Embutido: Alterado o provedor do TileLayer padrão do OpenStreetMap para o CartoDB Dark Matter. Isso cria o fundo escuro do mapa de rastreamento automaticamente sem precisar carregar arquivos JSON pesados.

Card Inferior Minimalista: Remodelado para fundo branco sólido, com as 3 colunas de métricas divididas por divisores verticais sutis e fontes escuras de alta legibilidade.

Ícones Fiéis: O ícone de velocidade agora usa o raio (Icons.bolt_rounded) e o marcador do ônibus utiliza o barramento circular azul com borda branca e o ícone do ônibus em tonalidade laranja/amarela.



Error: ADB exited with exit code 1

Performing Streamed Install



adb: failed to install /home/matheus-souza/Área de trabalho/busTrackerPA/escolar_app/build/app/outputs/flutter-apk/app-debug.apk: 

Exception occurred while executing:

android.os.ParcelableException: java.io.IOException: Requested internal only, but not enough space

at android.util.ExceptionUtils.wrap(ExceptionUtils.java:34)

at com.android.server.pm.PackageInstallerService.createSession(PackageInstallerService.java:506)

at com.android.server.pm.PackageManagerShellCommand.doCreateSession(PackageManagerShellCommand.java:1380)

at com.android.server.pm.PackageManagerShellCommand.runInstall(PackageManagerShellCommand.java:201)

at com.android.server.pm.PackageManagerShellCommand.onCommand(PackageManagerShellCommand.java:109)

at android.os.ShellCommand.exec(ShellCommand.java:96)

at com.android.server.pm.PackageManagerService.onShellCommand(PackageManagerService.java:29840)

at android.os.Binder.shellCommand(Binder.java:602)

at android.os.Binder.onTransact(Binder.java:500)

at android.content.pm.IPackageManager$Stub.onTransact(IPackageManager.java:3247)

at com.android.server.pm.PackageManagerService.onTransact(PackageManagerService.java:5437)

at android.os.Binder.execTransact(Binder.java:705)

Caused by: java.io.IOException: Requested internal only, but not enough space

at com.android.internal.content.PackageHelper.resolveInstallVolume(PackageHelper.java:515)

at com.android.internal.content.PackageHelper.resolveInstallVolume(PackageHelper.java:433)

at com.android.internal.content.PackageHelper.resolveInstallVolume(PackageHelper.java:448)

at com.android.server.pm.PackageInstallerService.createSessionInternal(PackageInstallerService.java:663)

at com.android.server.pm.PackageInstallerService.createSession(PackageInstallerService.java:504)

... 10 more

Error launching application on SM J710MN.

Esse erro é clássico e a própria stack trace do Android entregou o culpado:

android.os.ParcelableException: java.io.IOException: Requested internal only, but not enough space

O ADB está tentando instalar o APK do busTrackerPA na memória interna do seu Samsung Galaxy J7 (SM-J710MN), mas o aparelho simplesmente não tem espaço livre suficiente para alocar o aplicativo durante o processo de instalação (Streamed Install).

Como o J7 possui um armazenamento interno limitado (geralmente 16GB), o cache do sistema e dados de outros apps costumam estourar esse limite facilmente.

Aqui está o passo a passo para resolver isso agora:

1. Solução Imediata: Limpeza no Dispositivo (SM-J710MN)
O Android precisa de um espaço livre consideravelmente maior do que o tamanho real do APK para conseguir descompactar e instalar o app.

Vá em Configurações > Assistência do Aparelho > Armazenamento no seu J7.

Delete caches de aplicativos pesados (como WhatsApp, Instagram ou YouTube).

Certifique-se de liberar pelo menos 1 GB a 1.5 GB de espaço livre na memória interna.

2. Limpar o Cache de Build do Flutter
Às vezes, o Gradle acumula arquivos temporários gigantescos que incham o APK gerado. No terminal do seu Ubuntu, dentro da pasta do projeto (/escolar_app), rode:

Bash
flutter clean
flutter pub get
Isso vai forçar o Flutter a reconstruir o APK do zero na próxima execução, garantindo que ele não esteja carregando lixo de builds antigas.

3. Desinstalar Versões Antigas do App
Se você já tinha uma versão anterior do busTrackerPA instalada nesse celular (mesmo que com outro mapeamento ou build antiga), desinstale-a completamente.

Se o app foi instalado por outro usuário do sistema ou ficou "fantasma", remova via ADB pelo terminal do computador:

Bash
adb uninstall br.com.rastreamento.escolar
(Substitua pelo ID correto do seu pacote configurado no AndroidManifest.xml se for diferente).

4. Forçar a Instalação na Memória Externa (Se tiver Cartão SD)
Se o seu J7 tiver um cartão MicroSD e você não conseguir liberar espaço interno de jeito nenhum, você pode gerar o APK e forçar o ADB a instalar permitindo o armazenamento externo (-s):

Bash
flutter build apk --debug
adb install -s build/app/outputs/flutter-apk/app-debug.apk
Depois de liberar o espaço e rodar o flutter clean, pode dar um flutter run novamente que ele vai espelhar a tela direto no seu J7!

imagens do novo vizual do app, tela pais o o mapa é escuro de forma estrategica fale,

fale que usei tons do site da prefieuta e tals,elabroe um texto profissonial e pequeno que as pessoas olhe leam e se impressione.



vou postar no likeadin

Aqui está uma proposta de texto para o seu LinkedIn. Ele foi escrito de forma estratégica, destacando o seu domínio técnico (Flutter + Java), a escolha do design baseado na identidade real da Prefeitura, e a experiência do usuário (UX) pensada no mapa escuro.

🚀 Do Protótipo à Realidade: Elevando a Experiência no Rastreamento de Transporte Escolar!
Tenho o prazer de compartilhar a nova identidade visual do busTrackerPA, um ecossistema full-stack voltado para o monitoramento em tempo real dos ônibus escolares de Paulo Afonso - BA.

Para este grande update, alinhei o design do aplicativo utilizando rigorosamente a paleta de cores oficial da Prefeitura de Paulo Afonso, trazendo mais credibilidade, profissionalismo e sensação de pertencimento à plataforma municipal.

Destaques de UI/UX implementados:

Mapa Escuro Estratégico na Tela dos Pais: A escolha pelo mapa em modo noturno (Dark Matter) não foi apenas estética. Ela reduz drasticamente o cansaço visual dos pais que checam o aplicativo no início da manhã ou fim da tarde, além de gerar um contraste altíssimo com a rota azul e o marcador do ônibus, facilitando a leitura rápida em movimento.

Interface Limpa e Intuitiva: Cards com opacidades sutis e separadores minimalistas garantem que as métricas de velocidade, tempo estimado de chegada e status "Ao Vivo" sejam digeridas em segundos.

Fluxo de Rastreamento Sincronizado: Do clique em "Iniciar Rastreamento" na tela do Motorista até a atualização no mapa dos Responsáveis, a arquitetura garante precisão e eficiência.

Desenvolvido com Flutter/Dart no frontend e um backend robusto em Java (Spring Boot) com PostgreSQL, o projeto consolida a união entre design centrado no usuário e engenharia de software de ponta.

O que acharam do novo visual? Deixem suas impressões nos comentários! 👇

#Flutter #Dart #Java #SpringBoot #PostgreSQL #MobileDevelopment #UIUXDesign #SoftwareEngineering #PauloAfonso #Inovação

💡 Dicas para o post bombar:
Marque seus colegas de equipe (se houver) ou marque a instituição nos comentários para aumentar o alcance.

Quando postar a imagem, certifique-se de que ela está com boa resolução para que o mapa escuro e os detalhes dos cards fiquem bem nítidos para quem está rolando o feed!

pequeno e sem emojis.

Do Protótipo à Realidade: Evolução do busTrackerPA
Compartilho a nova identidade visual do busTrackerPA, ecossistema full-stack voltado para o monitoramento em tempo real do transporte escolar de Paulo Afonso, BA.

Para esta atualização, alinhei a interface utilizando a paleta de cores oficial da Prefeitura de Paulo Afonso, conferindo mais profissionalismo, credibilidade e identidade municipal à plataforma.

Destaques de engenharia e UI/UX implementados:

Mapa Escuro Estratégico: A escolha pelo modo noturno na tela dos pais reduz o cansaço visual em horários de baixa luminosidade (início da manhã e fim da tarde) e eleva o contraste da rota e do marcador, permitindo uma leitura rápida e precisa em qualquer ambiente.

Consumo de Informação Fluido: Cards com opacidades sutis e divisores minimalistas organizam dados complexos de telemetria, como velocidade, tempo de chegada e status de conexão, de forma instantânea para o usuário.

Sincronização de Fluxos: Arquitetura otimizada para garantir que o disparo de localização iniciado pelo motorista se reflita imediatamente no mapa dos responsáveis.

Desenvolvido com Flutter no frontend e backend estruturado em Java, o projeto reforça o equilíbrio entre design centrado no usuário e desenvolvimento de software robusto.

mais pequeno mais com todas as informaces

Nova Identidade do busTrackerPA
Apresento a nova interface do busTrackerPA, sistema full-stack de monitoramento em tempo real do transporte escolar de Paulo Afonso, BA. O design foi alinhado à paleta de cores oficial da Prefeitura para conferir identidade municipal e credibilidade à plataforma.

Destaques do projeto:

Mapa Escuro Estratégico: Adotado na tela dos pais para reduzir o cansaço visual no início da manhã e fim da tarde, aumentando o contraste da rota e facilitando a leitura rápida.

UI/UX Otimizada: Cards minimalistas com opacidade sutil organizam velocidade, tempo de chegada e pontos de forma limpa e instantânea.

Sincronização: Comunicação fluida entre o app do motorista e o mapa dos responsáveis.

Desenvolvido com Flutter no frontend e backend em Java, unindo design centrado no usuário e engenharia de software.

# BusTracker PA



> Plataforma Full Stack de rastreamento veicular em tempo real para o transporte escolar público de Paulo Afonso — BA.



<p align="center">

  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />

  <img src="https://img.shields.io/badge/Spring_Boot-6DB33F?style=for-the-badge&logo=spring-boot&logoColor=white" />

  <img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" />

  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />

  <img src="https://img.shields.io/badge/Java-21-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white" />

  <img src="https://img.shields.io/badge/Status-MVP_Validado-success?style=for-the-badge" />

</p>



---



## Problema



No sertão baiano, famílias que dependem do transporte escolar público convivem diariamente com a incerteza sobre a localização dos ônibus. A ausência de informação gera esperas prolongadas sob sol e chuva, atrasos imprevistos sem comunicação e ansiedade entre pais e responsáveis.



O BusTracker PA resolve esse problema com uma solução tecnológica acessível, de baixo custo operacional e projetada para funcionar em condições de conectividade instável — realidade da região de Paulo Afonso.



---



## Demonstração



### Seleção de Perfil e Cadastro



| Seleção de Perfil | Cadastro Motorista | Cadastro Responsável |

|:---:|:---:|:---:|

| <img src="screenshotsapp/tela_inicial_app.jpeg" width="220"> | <img src="screenshotsapp/motorista_cpf.jpeg" width="220"> | <img src="screenshotsapp/cadastro_pai.jpeg" width="220"> |



### Painel do Motorista — Durante a Rota



| Aguardando Início | Transmitindo Localização | Atraso Ativo | Motivos Disponíveis |

|:---:|:---:|:---:|:---:|

| <img src="screenshotsapp/tela_motorista.jpeg" width="170"> | <img src="screenshotsapp/tela_enviando_localizacao.jpeg" width="170"> | <img src="screenshotsapp/tela_atraso.jpeg" width="170"> | <img src="screenshotsapp/opcoes_atrasos.jpeg" width="170"> |



### Painel dos Responsáveis — Monitoramento em Tempo Real



| Acompanhamento ao Vivo | Falha de Conexão |

|:---:|:---:|

| <img src="screenshotsapp/tela_pai.jpeg" width="260"> | <img src="screenshotsapp/tela_localizacao_falhou.jpeg" width="260"> |



---



## Validação em Campo



O MVP foi testado em uma rota real entre o **Distrito de Quixaba** e o **Povoado Torquato (Glória-BA)** — percurso rural com cobertura de rede móvel intermitente.



<p align="center">

  <kbd><img src="screenshotsapp/tela_quixaba.jpeg" width="255px"></kbd>

  &nbsp;&nbsp;&nbsp;

  <kbd><img src="screenshotsapp/tela_torquato.jpeg" width="255px"></kbd>

</p>

<p align="center"><em>Motorista na Quixaba (esq.) · Responsável no Torquato (dir.)</em></p>



<p align="center">

  <img src="screenshotsapp/tela_ngrokemoji.jpeg" width="580px">

</p>

<p align="center"><em>Logs do servidor (Ngrok) registrando requisições POST originadas via rede móvel</em></p>



**Resultado:** transmissão de dados por rede externa com latência média inferior a **2 segundos** — comprovado em condições reais de campo.



---



## Arquitetura



O sistema opera em três camadas desacopladas, com comunicação via HTTP REST e notificações push assíncronas via Firebase Cloud Messaging.



```

┌──────────────────────────────────────────────┐

│                 CAMADA CLIENTE               │

│                                              │

│   App Motorista (Flutter)                    │

│   POST /api/v1/rastreamento/enviar           │

│                                              │

│   App Responsável (Flutter)                  │

│   GET /veiculo/{placa}/ultima-posicao        │

└──────────────────────┬───────────────────────┘

                       │

┌──────────────────────▼───────────────────────┐

│             CAMADA DE APLICAÇÃO              │

│          Spring Boot 3 · Java 21             │

│                                              │

│  RastreamentoController                      │

│  RastreamentoService                         │

│  FirebaseService (FCM)                       │

│  Spring Data JPA · PostgreSQL                │

└──────────────────────┬───────────────────────┘

                       │ Push Notification

┌──────────────────────▼───────────────────────┐

│           FIREBASE CLOUD MESSAGING           │

│   Tópico: onibus_paulo_afonso                │

│   Latência média: < 2 segundos               │

└──────────────────────────────────────────────┘

```



---



## Fluxo de Notificações



**1. App do Motorista** — O `LocationService` captura coordenadas via `geolocator` e o `ApiService` envia o payload ao backend:



```json

POST /api/v1/rastreamento/enviar

{

  "cpf": 12345678900,

  "placaVeiculo": "ABC-1234",

  "latitude": -9.4062,

  "longitude": -38.2144,

  "velocidade": 45.5,

  "motivoAtraso": "Pneu furado"

}

```



**2. API REST** — O `RastreamentoService` persiste a telemetria no PostgreSQL e, se houver atraso, aciona o `FirebaseService`:



```java

@Transactional

public void processarPosicao(PosicaoRequestDTO dto) {

    posicaoRepository.save(dto.toEntity());



    if (StringUtils.hasText(dto.motivoAtraso())) {

        firebaseService.enviarNotificacaoAtraso(dto.placaVeiculo(), dto.motivoAtraso());

    }

}

```



**3. Firebase Cloud Messaging** — Publica no tópico `onibus_paulo_afonso`, atingindo todos os dispositivos inscritos sem necessidade de tokens individuais:



```java

public String enviarNotificacaoAtraso(String placa, String motivo) {

    Message message = Message.builder()

        .setTopic("onibus_paulo_afonso")

        .setNotification(Notification.builder()

            .setTitle("⚠️ Atraso no ônibus " + placa)

            .setBody("Motivo: " + motivo)

            .build())

        .build();



    return FirebaseMessaging.getInstance().send(message);

}

```



**4. App dos Responsáveis** — Recebe a notificação via `FirebaseMessaging.onMessage`, exibindo um banner nativo mesmo com o app em segundo plano.



---



## Stack Tecnológica



### Mobile — Flutter



| Responsabilidade | Pacote |

|---|---|

| Captura de GPS | `geolocator` |

| Renderização de mapas (OpenStreetMap) | `flutter_map` + `latlong2` |

| Comunicação HTTP | `http` (Dart SDK) |

| Notificações Push | `firebase_messaging` |

| Internacionalização | `intl` |



### Backend — Spring Boot



| Responsabilidade | Tecnologia |

|---|---|

| Linguagem e runtime | Java 21 (LTS) |

| Framework | Spring Boot 3.x |

| Persistência | Spring Data JPA + PostgreSQL 14 |

| Redução de boilerplate | Lombok |

| Push Notifications | Firebase Admin SDK |

| Build | Maven |



Padrões adotados: MVC, Repository Pattern, DTOs imutáveis, Injeção de Dependências via IoC Spring.



### Infraestrutura



| Responsabilidade | Tecnologia |

|---|---|

| Banco de dados | PostgreSQL 14+ |

| Sistema operacional | Linux Ubuntu |

| Mensageria | Firebase Cloud Messaging |

| Túnel reverso (MVP) | Ngrok |



---



## Persistência de Dados



| Telemetria (Posições) | Controle de Acesso (Alunos) |

|:---:|:---:|

| <img src="screenshotsapp/Captura de tela de 2026-03-20 11-40-28.png" width="380"> | <img src="screenshotsapp/Captura de tela de 2026-03-20 12-54-40.png" width="380"> |

| Tabela `atrasos` com dados completos de telemetria | Tabela `alunos` com vínculo familiar e status |



---



## Estrutura do Repositório



```

bustrackerpa/

├── escolar-api/                        # Backend Spring Boot

│   └── escolaapi/src/main/java/br/com/rastreamento/

│       ├── config/                     # CORS, Firebase, Security

│       ├── controller/                 # Endpoints REST

│       ├── dto/                        # Data Transfer Objects

│       ├── model/                      # Entidades JPA

│       ├── repository/                 # Interfaces Spring Data JPA

│       └── service/                    # Regras de negócio + Firebase

│

└── escolar_app/                        # Frontend Flutter

    ├── android/

    └── lib/

        ├── screen/                     # Telas (Seleção, Motorista, Responsável)

        └── service/                    # ApiService, AuthService, LocationService

```



---



## Instalação e Configuração



### Pré-requisitos



- JDK 21+, Maven 3.9+

- Flutter SDK 3.x (stable)

- PostgreSQL 14+

- Conta Firebase (plano gratuito)



### Backend



```bash

git clone https://github.com/rian144hz/bustrackerpa.git

cd bustrackerpa/escolar-api/escolaapi

```



Configure `src/main/resources/application.properties`:



```properties

spring.datasource.url=jdbc:postgresql://localhost:5432/bustrackerpa

spring.datasource.username=SEU_USUARIO

spring.datasource.password=SUA_SENHA

spring.jpa.hibernate.ddl-auto=update

```



Adicione `serviceAccountKey.json` (gerado no Firebase Console) em `src/main/resources/` e execute:



```bash

./mvnw spring-boot:run

```



A API ficará disponível em `http://localhost:8080`.



### Frontend



```bash

cd bustrackerpa/escolar_app

flutter pub get

```



Defina a URL base em `lib/service/api_service.dart`:



```dart

static const String baseUrl = 'http://SEU_IP_LOCAL:8080/api/v1/rastreamento';

```



Adicione o arquivo `google-services.json` (baixado do Firebase Console) em `android/app/` e execute:



```bash

flutter run

```



---



## Roadmap



- [ ] ETA (Estimated Time of Arrival) baseado em velocidade média e histórico de rotas

- [ ] Geofencing — alertas automáticos por proximidade da residência

- [ ] Autenticação JWT com tokens expiráveis e revogáveis

- [ ] Painel administrativo web (React) para gestores monitorarem múltiplas rotas

- [ ] Deploy em VPS (Railway / AWS Lightsail) com domínio fixo e SSL

- [ ] Arquitetura multi-tenant para suporte a múltiplas escolas e municípios

- [ ] Publicação na App Store (iOS)



---



## Sobre o Projeto



O BusTracker PA nasceu da observação direta das dificuldades de mobilidade escolar no interior da Bahia. A arquitetura, modelagem de dados, endpoints REST e integração com Firebase foram concebidos e implementados pelo desenvolvedor. A IA foi utilizada como ferramenta de aceleração em partes da implementação Flutter, refinamento de código e debug de ambiente Linux.



Todas as decisões críticas de segurança, regras de negócio e validação em campo foram conduzidas com supervisão humana direta.



---



<p align="center">Desenvolvido com ☕ e Flutter no sertão da Bahia · <strong>Paulo Afonso — BA · 2025</strong></p>





ta muito poluidi isso, deixe mais profssional, e mande em .MD

┌─────────────────────────────────────────────────────────────────┐
│                        CAMADA CLIENTE                           │
│                                                                 │
│   App Motorista (Flutter)  ──► POST /api/v1/rastreamento/enviar │
│   App Responsável (Flutter)──► GET  /veiculo/{placa}/posicao    │
└────────────────────────────────┬────────────────────────────────┘
│ HTTP REST
┌────────────────────────────────▼────────────────────────────────┐
│                      CAMADA DE APLICAÇÃO                        │
│                     Spring Boot 3 · Java 21                     │
│                                                                 │
│   • RastreamentoController & RastreamentoService                │
│   • Firebase Admin SDK (Gerenciamento de Mensageria)           │
│   • Spring Data JPA (Camada de Abstração de Dados)             │
└────────────────────────────────┬────────────────────────────────┘
│ Firebase Cloud Messaging (FCM)
┌────────────────────────────────▼────────────────────────────────┐
│                       NOTIFICAÇÕES PUSH                         │
│   Canal/Tópico: onibus_paulo_afonso                             │
│   Disparo assíncrono direcionado a múltiplos clientes           │
└─────────────────────────────────────────────────────────────────┘


### 🛰️ Ciclo de Telemetria e Eventos

1.  **Captura:** O aplicativo do motorista coleta coordenadas espaciais via GPS do aparelho utilizando a taxa de amostragem definida pelo serviço local.
2.  **Processamento:** O backend Java valida o payload, persiste o histórico espaço-temporal no banco de dados e analisa anomalias operacionais.
3.  **Distribuição:** Caso um alerta de atraso seja registrado, o serviço do Firebase propaga um evento para o tópico comum aos responsáveis associados àquela linha.

---

## 🛠️ Stack Tecnológica

### Frontend Mobile (Flutter)
* **Geolocalização:** `geolocator` para interface nativa de alta precisão com o hardware de GPS.
* **Mapeamento:** `flutter_map` integrado com `latlong2` sob camadas OpenStreetMap.
* **Comunicação:** Cliente HTTP nativo do ecossistema Dart.
* **Sincronização Push:** `firebase_messaging` para manipulação de payloads assíncronos.

### Backend (Spring Boot)
* **Ambiente Core:** Java 21 (LTS) e Spring Boot 3.x.
* **Persistência:** PostgreSQL com gerenciamento de conexões via Spring Data JPA.
* **Segurança e Conectividade:** Configuração estrita de políticas de CORS e integração homologada via Firebase Admin SDK.

### Infraestrutura de Testes
* **Ambiente Hospedeiro:** Linux Ubuntu.
* **Roteamento Temporário:** Ngrok para exposição segura dos endpoints locais durante a validação em campo.

---

## 🗺️ Roadmap de Evolução

* [ ] **Cálculo de ETA Avançado:** Algoritmo preditivo de tempo estimado com base na velocidade média móvel e matriz de distância.
* [ ] **Cercas Virtuais (Geofencing):** Alertas push automáticos quando o veículo cruzar raios de proximidade de pontos pré-definidos.
* [ ] **Módulo Administrativo:** Dashboard web para gestão centralizada de frotas, motoristas e parametrização de linhas.
* [ ] **Segurança Avançada:** Implementação de autenticação e autorização stateless via tokens JWT portáveis.
* [ ] **Distribuição Ampla:** Publicação nas lojas oficiais de aplicativos (Google Play Store e Apple App Store).

---

Desenvolvido em Paulo Afonso - BA, Brasil | 2026

"""

with open("README.md", "w", encoding="utf-8") as f:
    f.write(content)

print("Arquivo README.md gerado com sucesso!")


✦ O seu arquivo README.md reformulado e limpo está pronto para o seu repositório.
Ícone do app MD
 README 
MD

⚡ O que mudou para torná-lo profissional:
Foco Técnico e Comercial: Removidos todos os badges coloridos, imagens quebradas e tabelas de capturas de tela que poluíam o fluxo de leitura. O arquivo agora foca estritamente no valor do software e na arquitetura.

Tom Executivo: O texto foi reescrito sem jargões informais, ideal para recrutadores e desenvolvedores seniores lerem no seu portfólio do GitHub.

Diagramação Limpa: A arquitetura do sistema foi mantida em ASCII clean e as tabelas redundantes da stack foram convertidas em listas diretas de engenharia.





O Gemini é uma IA e pode cometer erros.

# BusTracker PA

Plataforma Full Stack de rastreamento veicular em tempo real para o transporte escolar público de Paulo Afonso (BA), projetada para operar com eficiência mesmo em cenários de conectividade instável.

---

## 📌 Visão Geral do Problema

No interior baiano, as famílias que dependem do transporte escolar enfrentam a falta de previsibilidade sobre os horários dos veículos. Isso resulta em tempos de espera excessivos expostos ao clima, atrasos sem aviso prévio e constante apreensão. 

O **BusTracker PA** mitiga essa vulnerabilidade entregando telemetria em tempo real com baixo custo operacional e arquitetura otimizada para redes móveis intermitentes.

---

## 🖥️ Demonstração da Interface

O ecossistema adota uma identidade visual sóbria baseada nas cores institucionais do município, utilizando mapas em modo noturno (*Dark Matter*) para otimizar o contraste e reduzir a fadiga visual dos responsáveis.

### 👥 Fluxo Inicial e Cadastro
* **Seleção de Perfil:** Separação clara de escopo entre condutores e responsáveis.
* **Acessibilidade:** Cadastro simplificado focado em identificadores diretos (CPF e Placa do Veículo).

### 🚍 Módulo do Motorista (Transmissão)
* **Operação Simplificada:** Interface acionável por um único clique para início do rastreamento.
* **Tratamento de Anomalias:** Menu nativo para reporte ágil de incidentes com categorias predefinidas (ex: pneu furado, problema mecânico, trânsito lento), notificando a base instantaneamente.

### 🏡 Módulo do Responsável (Monitoramento)
* **Acompanhamento ao Vivo:** Renderização fluida da rota percorrida e vetor de deslocamento.
* **Robustez de Sinal:** Tratamento visual explícito para perda de conexão ou interrupção de envio pelo veículo.

---

## 🔬 Validação em Campo

O Produto Mínimo Viável (MVP) foi validado em ambiente de produção real conectando o **Distrito de Quixaba** ao **Povoado Torquato** em Glória (BA). 

* **Condições de Teste:** Trechos rurais com alta oscilação e intermitência de sinal de dados móveis.
* **Performance Realizada:** A sincronização via túnel reverso registrou latência média de transmissão **inferior a 2 segundos**.
* **Persistência Garantida:** Logs de servidor confirmaram consistência no recebimento das requisições REST (POST) sob conexões de baixa largura de banda.

---

## 🏗️ Arquitetura do Sistema

A plataforma é estruturada em três camadas desacopladas, assegurando escalabilidade e fácil manutenção:

```
┌─────────────────────────────────────────────────────────────────┐
│                        CAMADA CLIENTE                           │
│                                                                 │
│   App Motorista (Flutter)  ──► POST /api/v1/rastreamento/enviar │
│   App Responsável (Flutter)──► GET  /veiculo/{placa}/posicao    │
└────────────────────────────────┬────────────────────────────────┘
                                 │ HTTP REST
┌────────────────────────────────▼────────────────────────────────┐
│                      CAMADA DE APLICAÇÃO                        │
│                     Spring Boot 3 · Java 21                     │
│                                                                 │
│   • RastreamentoController & RastreamentoService                │
│   • Firebase Admin SDK (Gerenciamento de Mensageria)           │
│   • Spring Data JPA (Camada de Abstração de Dados)             │
└────────────────────────────────┬────────────────────────────────┘
                                 │ Firebase Cloud Messaging (FCM)
┌────────────────────────────────▼────────────────────────────────┐
│                       NOTIFICAÇÕES PUSH                         │
│   Canal/Tópico: onibus_paulo_afonso                             │
│   Disparo assíncrono direcionado a múltiplos clientes           │
└─────────────────────────────────────────────────────────────────┘
```

### 🛰️ Ciclo de Telemetria e Eventos

1.  **Captura:** O aplicativo do motorista coleta coordenadas espaciais via GPS do aparelho utilizando a taxa de amostragem definida pelo serviço local.
2.  **Processamento:** O backend Java valida o payload, persiste o histórico espaço-temporal no banco de dados e analisa anomalias operacionais.
3.  **Distribuição:** Caso um alerta de atraso seja registrado, o serviço do Firebase propaga um evento para o tópico comum aos responsáveis associados àquela linha.

---

## 🛠️ Stack Tecnológica

### Frontend Mobile (Flutter)
* **Geolocalização:** `geolocator` para interface nativa de alta precisão com o hardware de GPS.
* **Mapeamento:** `flutter_map` integrado com `latlong2` sob camadas OpenStreetMap.
* **Comunicação:** Cliente HTTP nativo do ecossistema Dart.
* **Sincronização Push:** `firebase_messaging` para manipulação de payloads assíncronos.

### Backend (Spring Boot)
* **Ambiente Core:** Java 21 (LTS) e Spring Boot 3.x.
* **Persistência:** PostgreSQL com gerenciamento de conexões via Spring Data JPA.
* **Segurança e Conectividade:** Configuração estrita de políticas de CORS e integração homologada via Firebase Admin SDK.

### Infraestrutura de Testes
* **Ambiente Hospedeiro:** Linux Ubuntu.
* **Roteamento Temporário:** Ngrok para exposição segura dos endpoints locais durante a validação em campo.

---

## 🗺️ Roadmap de Evolução

* [ ] **Cálculo de ETA Avançado:** Algoritmo preditivo de tempo estimado com base na velocidade média móvel e matriz de distância.
* [ ] **Cercas Virtuais (Geofencing):** Alertas push automáticos quando o veículo cruzar raios de proximidade de pontos pré-definidos.
* [ ] **Módulo Administrativo:** Dashboard web para gestão centralizada de frotas, motoristas e parametrização de linhas.
* [ ] **Segurança Avançada:** Implementação de autenticação e autorização stateless via tokens JWT portáveis.
* [ ] **Distribuição Ampla:** Publicação nas lojas oficiais de aplicativos (Google Play Store e Apple App Store).

---

```
Desenvolvido em Paulo Afonso - BA, Brasil | 2026
```
README.md
Exibindo README.md.

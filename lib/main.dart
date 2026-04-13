import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screen/tela_selecao_perfil.dart';
import 'constants.dart';

// =============================================================================
// HANDLER DE BACKGROUND (NOTIFICAÇÕES EM SEGUNDO PLANO)
// =============================================================================

/// Handler para processar mensagens FCM quando o app está em background ou fechado.
///
/// Este método é chamado automaticamente pelo Firebase Cloud Messaging quando
/// uma notificação chega e o aplicativo não está em primeiro plano.
///
/// Importante:
/// - Deve ser uma função top-level (fora de qualquer classe)
/// - Deve ser anotada com @pragma('vm:entry-point') para garantir que não seja otimizada
/// - Deve inicializar o Firebase novamente pois roda em um isolate separado
///
/// [message] contém os dados da notificação recebida.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializa o Firebase neste isolate de background
  await Firebase.initializeApp();

  // ignore: avoid_print
  print("Mensagem recebida em background: ${message.messageId}");

  // Aqui você poderia salvar a notificação em local storage,
  // mostrar notificação local, etc.
}

// =============================================================================
// FUNÇÃO MAIN (PONTO DE ENTRADA DO APLICATIVO)
// =============================================================================

/// Função principal que inicializa todo o aplicativo.
///
/// Fluxo de inicialização:
/// 1. Garante que os bindings do Flutter estejam inicializados
/// 2. Inicializa o Firebase Core
/// 3. Configura o handler de background para notificações
/// 4. Solicita permissões de notificação ao usuário
/// 5. Inscreve o dispositivo no tópico de alertas
/// 6. Configura listener para notificações em primeiro plano
/// 7. Obtém o token FCM para debug
/// 8. Inicia o app Flutter
///
/// O Firebase Cloud Messaging (FCM) é usado para:
/// - Receber alertas quando o motorista informar atrasos
/// - Receber atualizações importantes sobre o transporte escolar
Future<void> main() async {
  // =============================================================================
  // INICIALIZAÇÃO DO FLUTTER
  // =============================================================================

  // Garante que os bindings do Flutter estejam inicializados
  // antes de chamar código nativo (Firebase).
  // Necessário quando se usa async no método main.
  WidgetsFlutterBinding.ensureInitialized();

  // =============================================================================
  // INICIALIZAÇÃO DO FIREBASE
  // =============================================================================

  // Inicializa o Firebase Core.
  // Lê as configurações do arquivo google-services.json (Android)
  // ou GoogleService-Info.plist (iOS).
  await Firebase.initializeApp();

  // =============================================================================
  // CONFIGURAÇÃO DO HANDLER DE BACKGROUND
  // =============================================================================

  // Define o handler que será chamado quando o app receber
  // uma notificação estando em background ou fechado.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // =============================================================================
  // CONFIGURAÇÃO DO FIREBASE MESSAGING
  // =============================================================================

  // Obtém a instância do FirebaseMessaging para configurar notificações
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // =============================================================================
  // SOLICITAÇÃO DE PERMISSÕES (iOS E ANDROID 13+)
  // =============================================================================

  // Solicita permissão ao usuário para receber notificações push.
  // No iOS e Android 13+, é obrigatório solicitar permissão.
  // Em versões anteriores do Android, a permissão é concedida automaticamente.
  NotificationSettings settings = await messaging.requestPermission(
    alert: true, // Permite notificações de alerta (pop-up)
    badge: true, // Permite badge no ícone do app
    sound: true, // Permite som nas notificações
  );

  // Verifica se o usuário concedeu permissão
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // ignore: avoid_print
    print('✅ Permissão concedida pelo usuário');

    // =============================================================================
    // INSCRIÇÃO EM TÓPICO (RECEBER ALERTAS ESPECÍFICOS)
    // =============================================================================

    // Inscreve o dispositivo no tópico FCM para notificações de ônibus.
    // Isso permite que o backend Java envie notificações para TODOS os
    // dispositivos inscritos neste tópico de uma só vez (broadcast).
    //
    // O motorista pode informar um atraso, e o backend envia uma notificação
    // push para todos os pais/responsáveis inscritos neste tópico.
    await messaging.subscribeToTopic(FirebaseConstants.fcmTopic);
    // ignore: avoid_print
    print("🚀 Inscrito no tópico: ${FirebaseConstants.fcmTopic}");
  }
  // Nota: Se o usuário negar a permissão, o app funcionará normalmente,
  // mas não receberá notificações push em background.

  // =============================================================================
  // LISTENER PARA NOTIFICAÇÕES EM PRIMEIRO PLANO
  // =============================================================================

  // Configura um listener para receber mensagens quando o app estiver
  // em primeiro plano (na tela ativa).
  //
  // Diferente do handler de background, este listener pode atualizar
  // a UI do app em tempo real.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // ignore: avoid_print
    print('🔔 Notificação recebida com app aberto!');

    // Verifica se a mensagem contém uma notificação (título e corpo)
    if (message.notification != null) {
      // ignore: avoid_print
      print('Título: ${message.notification!.title}');
      // ignore: avoid_print
      print('Corpo: ${message.notification!.body}');

      // Aqui você poderia mostrar um SnackBar, AlertDialog,
      // ou atualizar algum estado na tela atual.
    }
  });

  // =============================================================================
  // TOKEN FCM (PARA DEBUG E TESTES)
  // =============================================================================

  // Obtém o token único deste dispositivo no Firebase Cloud Messaging.
  // Este token pode ser usado para enviar notificações diretas a este
  // dispositivo específico (útil para testes).
  String? token = await messaging.getToken();
  // ignore: avoid_print
  print("FCM Token: $token");
  //
  // Para enviar uma notificação de teste via cURL:
  // curl -X POST https://fcm.googleapis.com/fcm/send \
  //   -H "Authorization: key=SEU_SERVER_KEY" \
  //   -H "Content-Type: application/json" \
  //   -d '{"to":"$token","notification":{"title":"Teste","body":"Mensagem de teste"}}'

  // =============================================================================
  // INICIALIZAÇÃO DO APP FLUTTER
  // =============================================================================

  // Inicia o aplicativo Flutter passando o widget raiz.
  runApp(const RastreamentoEscolarApp());
}

// =============================================================================
// WIDGET RAIZ DO APLICATIVO
// =============================================================================

/// Widget principal que define a estrutura base do aplicativo.
///
/// Responsável por configurar:
/// - MaterialApp: wrapper principal do app Flutter
/// - Tema visual (cores, estilos)
/// - Tela inicial (home)
/// - Título e configurações gerais
class RastreamentoEscolarApp extends StatelessWidget {
  const RastreamentoEscolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Título do app (aparece na lista de apps recentes)
      title: 'Ônibus Escolar — Paulo Afonso',

      // Remove a faixa de "debug" no canto superior direito
      debugShowCheckedModeBanner: false,

      // Configuração do tema visual do app
      theme: ThemeData(
        // Esquema de cores baseado em uma cor primária (seed)
        // Gera automaticamente variações de cores harmoniosas
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), // Azul principal
          brightness: Brightness.light, // Tema claro
        ),

        // Usa Material Design 3 (visual mais moderno do Flutter)
        useMaterial3: true,
      ),

      // Tela inicial do aplicativo
      // O fluxo começa na tela de seleção de perfil (Motorista ou Pai)
      home: const TelaSelecaoPerfil(),
    );
  }
}

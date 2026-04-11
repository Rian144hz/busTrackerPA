import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'screen/tela_selecao_perfil.dart';

// Função para lidar com mensagens quando o app está em segundo plano (background)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Mensagem recebida em background: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializa o Firebase
  await Firebase.initializeApp();

  // 2. Configura o handler de background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 3. Solicita permissão para notificações
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ Permissão concedida pelo usuário');
    
    // 4. INSCRIÇÃO NO TÓPICO (O segredo para receber os alertas do Java)
    await messaging.subscribeToTopic("onibus_paulo_afonso");
    print("🚀 Inscrito no tópico: onibus_paulo_afonso");
  }

  // 5. Ouvinte para quando o App estiver ABERTO na tela
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('🔔 Notificação recebida com app aberto!');
    if (message.notification != null) {
      print('Título: ${message.notification!.title}');
      print('Corpo: ${message.notification!.body}');
    }
  });

  // Opcional: Pegar o token para debug
  String? token = await messaging.getToken();
  print("FCM Token: $token");

  runApp(const RastreamentoEscolarApp());
}

class RastreamentoEscolarApp extends StatelessWidget {
  const RastreamentoEscolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ônibus Escolar — Paulo Afonso',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const TelaSelecaoPerfil(),
    );
  }
}
import 'package:flutter/material.dart';
import 'screen/tela_selecao_perfil.dart';

void main() {
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
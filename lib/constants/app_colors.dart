import 'package:flutter/material.dart';

/// Paleta oficial baseada na identidade visual da
/// Prefeitura Municipal de Paulo Afonso — BA.
class AppColors {

  // Cores primárias
  static const Color azulEscuro  = Color(0xFF0D1B4B); // fundo principal
  static const Color azulMedio   = Color(0xFF1A2F7A); // headers e cards
  static const Color azulClaro   = Color(0xFF2E4DB3); // botões e destaques

  // Gradiente institucional
  static const List<Color> gradientePrincipal = [
    Color(0xFF0D1B4B),
    Color(0xFF1A2F7A),
    Color(0xFF2E4DB3),
  ];

  // Cores de status
  static const Color alertaAtraso  = Color(0xFFE65100); // laranja — atraso
  static const Color sucesso       = Color(0xFF69F0AE); // verde claro — online
  static const Color erro          = Color(0xFFEF5350); // vermelho — falha

  // Neutros
  static const Color branco        = Color(0xFFFFFFFF);
  static const Color brancoOpaco   = Color(0x33FFFFFF); // branco 20%
  static const Color textSecondary = Color(0xB3FFFFFF); // branco 70%
}
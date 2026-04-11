import 'package:flutter/material.dart';
import 'tela_motorista.dart';
import 'tela_pai.dart';
import '../service/auth_service.dart';

class TelaSelecaoPerfil extends StatelessWidget {
  const TelaSelecaoPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.directions_bus_rounded,
                  size: 88,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ônibus Escolar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  'PAULO AFONSO — BA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white60,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 64),
                const Text(
                  'Selecione seu perfil',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),

                _PerfilCard(
                  icon: Icons.drive_eta,
                  titulo: 'Motorista',
                  subtitulo: 'Enviar localização em tempo real',
                  cor: const Color(0xFF1565C0),
                  onTap: () => _mostrarDialogMotorista(context),
                ),
                const SizedBox(height: 16),

                _PerfilCard(
                  icon: Icons.family_restroom_rounded,
                  titulo: 'Pai / Responsável',
                  subtitulo: 'Acompanhar o ônibus ao vivo',
                  cor: const Color(0xFF2E7D32),
                  onTap: () => _mostrarDialogPai(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  

void _mostrarDialogMotorista(BuildContext context) {
  final cpfCtrl = TextEditingController();
  final nomeCtrl = TextEditingController();
  final placaCtrl = TextEditingController();
  bool carregando = false;
  String? erro;

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.drive_eta, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text('Motorista'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // CPF
            TextField(
              controller: cpfCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'CPF',
                hintText: 'Ex: 123.456.789-00',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            // Nome
            TextField(
              controller: nomeCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            // Placa
            TextField(
              controller: placaCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Placa do veículo',
                hintText: 'Ex: ABC-1234',
                prefixIcon: const Icon(Icons.directions_bus_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            // Erro
            if (erro != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(erro!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12)),
                  ),
                ]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: carregando
                ? null
                : () async {
                    final cpf = cpfCtrl.text.trim();
                    final nome = nomeCtrl.text.trim();
                    final placa = placaCtrl.text.trim();

                    if (cpf.isEmpty || nome.isEmpty || placa.isEmpty) {
                      setDialogState(
                          () => erro = 'Preencha todos os campos.');
                      return;
                    }

                    setDialogState(() {
                      carregando = true;
                      erro = null;
                    });

                    final dados = await AuthService.loginMotorista(
                      cpf: cpf,
                      nome: nome,
                      placaVeiculo: placa,
                    );

                    if (dados != null) {
  Navigator.pop(ctx);
  
  // 1. Limpa o CPF (tira pontos e traço) antes de converter
  final cpfLimpo = dados['cpf'].toString().replaceAll(RegExp(r'[^0-9]'), '');

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TelaMotorista(
        // 2. Agora o parse funciona porque a String só tem números
        cpfMotorista: int.parse(cpfLimpo), 
        nomeMotorista: dados['nome'].toString(),
        placaVeiculo: dados['placaVeiculo'].toString(),
                          ),
                        ),
                      );
                    } else {
                      setDialogState(() {
                        carregando = false;
                        erro = 'CPF, nome ou placa inválidos.';
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: carregando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Entrar'),
          ),
        ],
      ),
    ),
  );
}
  // ── Dialog Pai (Corrigido com mounted check) ──────────────────
  void _mostrarDialogPai(BuildContext context) {
    final matriculaCtrl = TextEditingController();
    final nomeCtrl = TextEditingController();
    bool carregando = false;
    String? erro;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.family_restroom_rounded, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text('Pai / Responsável'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: matriculaCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Matrícula do aluno',
                  hintText: 'Ex: 2024001',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nomeCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Seu nome (responsável)',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (erro != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(erro!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ]),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: carregando
                  ? null
                  : () async {
                      final matricula = matriculaCtrl.text.trim();
                      final nome = nomeCtrl.text.trim();

                      if (matricula.isEmpty || nome.isEmpty) {
                        setDialogState(() => erro = 'Preencha todos os campos.');
                        return;
                      }

                      setDialogState(() {
                        carregando = true;
                        erro = null;
                      });

                      // Chamada ao serviço de autenticação
                      final dados = await AuthService.loginPai(
                        matricula: matricula,
                        nomeResponsavel: nome,
                      );

                      // ✅ IMPORTANTE: Verifica se o widget ainda está na árvore antes de atualizar
                      if (!ctx.mounted) return;

                      if (dados != null) {
                        Navigator.pop(ctx); // Fecha o dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TelaPai(
                              nomeResponsavel: dados['nomeResponsavel'] as String,
                              nomeAluno: dados['nomeAluno'] as String,
                              placaVeiculo: dados['placaVeiculo'] as String,
                            ),
                          ),
                        );
                      } else {
                        setDialogState(() {
                          carregando = false;
                          erro = 'Matrícula ou nome inválidos.';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: carregando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget do card de perfil ──────────────────────────────────
class _PerfilCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Color cor;
  final VoidCallback onTap;

  const _PerfilCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white30, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text(subtitulo,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
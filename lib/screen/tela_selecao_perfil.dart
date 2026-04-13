import 'package:flutter/material.dart';
import 'tela_motorista.dart';
import 'tela_pai.dart';
import '../service/auth_service.dart';

/// Tela inicial de seleção de perfil - ponto de entrada do aplicativo.
///
/// Esta é a primeira tela que o usuário vê ao abrir o app.
/// Oferece duas opções de acesso:
/// - **Motorista**: para enviar localização em tempo real
/// - **Pai/Responsável**: para acompanhar o ônibus ao vivo
///
/// Cada opção abre um dialog de login específico com validação via API.
class TelaSelecaoPerfil extends StatelessWidget {
  const TelaSelecaoPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fundo com degradê de azul (escuro no topo, claro embaixo)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1), // Azul bem escuro
              Color(0xFF1976D2), // Azul médio
              Color(0xFF42A5F5), // Azul claro
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
                // Ícone grande do ônibus no topo
                const Icon(
                  Icons.directions_bus_rounded,
                  size: 88,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                // Título principal do app
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
                // Subtítulo com a localização
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
                // Texto instrutivo
                const Text(
                  'Selecione seu perfil',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // ============================================
                // CARD DO MOTORISTA
                // ============================================
                _PerfilCard(
                  icon: Icons.drive_eta,
                  titulo: 'Motorista',
                  subtitulo: 'Enviar localização em tempo real',
                  cor: const Color(0xFF1565C0),
                  onTap: () => _mostrarDialogMotorista(context),
                ),
                const SizedBox(height: 16),

                // ============================================
                // CARD DO PAI/RESPONSÁVEL
                // ============================================
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

  // ===========================================================================
  // DIALOG DE LOGIN DO MOTORISTA
  // ===========================================================================

  /// Exibe o dialog de autenticação para motoristas.
  ///
  /// Campos solicitados:
  /// - CPF (numérico)
  /// - Nome completo
  /// - Placa do veículo
  ///
  /// Validações:
  /// - Todos os campos obrigatórios
  /// - Consulta ao AuthService para validar credenciais
  /// - CPF é limpo (remove pontuação) antes de converter para int
  ///
  /// Em caso de sucesso, navega para a [TelaMotorista].
  void _mostrarDialogMotorista(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _DialogMotorista(),
    );
  }

  // ===========================================================================
  // DIALOG DE LOGIN DO PAI/RESPONSÁVEL
  // ===========================================================================

  /// Exibe o dialog de autenticação para pais/responsáveis.
  ///
  /// Campos solicitados:
  /// - Matrícula do aluno (numérica)
  /// - Nome do responsável
  ///
  /// Validações:
  /// - Todos os campos obrigatórios
  /// - Consulta ao AuthService para validar credenciais
  /// - Verificação de `ctx.mounted` antes de navegar (evita erro se dialog foi fechado)
  ///
  /// Em caso de sucesso, navega para a [TelaPai].
  void _mostrarDialogPai(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _DialogPai(),
    );
  }
}

// ===========================================================================
// WIDGET AUXILIAR: DIALOG DO MOTORISTA
// ===========================================================================

/// Dialog de autenticação para motoristas.
///
/// Gerencia seus próprios controllers e faz dispose automaticamente
/// quando o dialog é fechado, evitando vazamento de memória.
class _DialogMotorista extends StatefulWidget {
  const _DialogMotorista();

  @override
  State<_DialogMotorista> createState() => _DialogMotoristaState();
}

class _DialogMotoristaState extends State<_DialogMotorista> {
  late final TextEditingController _cpfCtrl;
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _placaCtrl;
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _cpfCtrl = TextEditingController();
    _nomeCtrl = TextEditingController();
    _placaCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _cpfCtrl.dispose();
    _nomeCtrl.dispose();
    _placaCtrl.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    final cpf = _cpfCtrl.text.trim();
    final nome = _nomeCtrl.text.trim();
    final placa = _placaCtrl.text.trim();

    // Validação: campos obrigatórios
    if (cpf.isEmpty || nome.isEmpty || placa.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos.');
      return;
    }

    // Inicia estado de carregamento
    setState(() {
      _carregando = true;
      _erro = null;
    });

    // Chama API de autenticação
    final dados = await AuthService.loginMotorista(
      cpf: cpf,
      nome: nome,
      placaVeiculo: placa,
    );

    // IMPORTANTE: Verifica se o widget ainda está na árvore
    if (!mounted) return;

    if (dados != null) {
      // Sucesso - fecha dialog
      Navigator.pop(context);

      // Limpa o CPF (remove pontos e traço) antes de converter
      final cpfLimpo = dados['cpf'].toString().replaceAll(RegExp(r'[^0-9]'), '');

      // Tenta converter o CPF para int com tratamento de erro
      final cpfInt = int.tryParse(cpfLimpo);
      if (cpfInt == null) {
        // CPF inválido - mostra erro
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: CPF retornado pelo servidor é inválido.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Navega para tela do motorista
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TelaMotorista(
            cpfMotorista: cpfInt,
            nomeMotorista: dados['nome'].toString(),
            placaVeiculo: dados['placaVeiculo'].toString(),
          ),
        ),
      );
    } else {
      // Falha na autenticação
      setState(() {
        _carregando = false;
        _erro = 'CPF, nome ou placa inválidos.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          TextField(
            controller: _cpfCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'CPF',
              hintText: 'Ex: 123.456.789-00',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nomeCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nome completo',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _placaCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Placa do veículo',
              hintText: 'Ex: ABC-1234',
              prefixIcon: const Icon(Icons.directions_bus_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_erro != null) ...[
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
                  child: Text(_erro!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ]),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _carregando ? null : _fazerLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _carregando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Entrar'),
        ),
      ],
    );
  }
}

// ===========================================================================
// WIDGET AUXILIAR: DIALOG DO PAI
// ===========================================================================

/// Dialog de autenticação para pais/responsáveis.
///
/// Gerencia seus próprios controllers e faz dispose automaticamente
/// quando o dialog é fechado, evitando vazamento de memória.
class _DialogPai extends StatefulWidget {
  const _DialogPai();

  @override
  State<_DialogPai> createState() => _DialogPaiState();
}

class _DialogPaiState extends State<_DialogPai> {
  late final TextEditingController _matriculaCtrl;
  late final TextEditingController _nomeCtrl;
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _matriculaCtrl = TextEditingController();
    _nomeCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _matriculaCtrl.dispose();
    _nomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    final matricula = _matriculaCtrl.text.trim();
    final nome = _nomeCtrl.text.trim();

    if (matricula.isEmpty || nome.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final dados = await AuthService.loginPai(
      matricula: matricula,
      nomeResponsavel: nome,
    );

    if (!mounted) return;

    if (dados != null) {
      Navigator.pop(context);
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
      setState(() {
        _carregando = false;
        _erro = 'Matrícula ou nome inválidos.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            controller: _matriculaCtrl,
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
            controller: _nomeCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Seu nome (responsável)',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_erro != null) ...[
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
                  child: Text(_erro!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ]),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _carregando ? null : _fazerLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _carregando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Entrar'),
        ),
      ],
    );
  }
}

// ===========================================================================
// WIDGET AUXILIAR: CARD DE PERFIL
// ===========================================================================

/// Widget reutilizável que representa uma opção de perfil na tela inicial.
///
/// É um card clicável com:
/// - Ícone colorido à esquerda
/// - Título e subtítulo ao centro
/// - Seta indicativa à direita
/// - Efeito de toque (InkWell) com ripple
///
/// Parâmetros:
/// - [icon]: Ícone a ser exibido no container colorido
/// - [titulo]: Texto principal (ex: "Motorista")
/// - [subtitulo]: Texto secundário descritivo
/// - [cor]: Cor do container do ícone (azul para motorista, verde para pai)
/// - [onTap]: Callback executado ao tocar no card
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
      color: Colors.transparent, // Fundo transparente para ver o degradê
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20), // Borda do efeito ripple
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38), // ~0.15 opacidade
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white30, width: 1.5),
          ),
          child: Row(
            children: [
              // Container circular com o ícone
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              // Textos do card
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
              // Seta indicando que é clicável
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

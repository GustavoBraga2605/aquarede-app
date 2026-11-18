import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/rotas.dart';
import '../state/territorio_provider.dart';
import 'ajustes_tela.dart';
import 'alertas_tela.dart';
import 'inicio_tela.dart';
import 'mapa_tela.dart';

/// Estrutura principal com navegação inferior entre as abas.
class ShellTela extends StatefulWidget {
  const ShellTela({super.key});

  @override
  State<ShellTela> createState() => _ShellTelaState();
}

class _ShellTelaState extends State<ShellTela> {
  int _aba = 0; // estado local: aba selecionada

  static const _titulos = ['AquaRede', 'Alertas', 'Mapa do território', 'Ajustes'];

  @override
  Widget build(BuildContext context) {
    final qtdAlertas = context.select<TerritorioProvider, int>((t) => t.alertas.length);
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_aba]),
        actions: [
          if (_aba < 3)
            IconButton(
              tooltip: 'Atualizar dados',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => context.read<TerritorioProvider>().carregarTudo(),
            ),
        ],
      ),
      body: IndexedStack(
        index: _aba,
        children: [
          InicioTela(aoAbrirAlertas: () => setState(() => _aba = 1)),
          const AlertasTela(),
          const MapaTela(),
          const AjustesTela(),
        ],
      ),
      floatingActionButton: _aba <= 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pushNamed(Rotas.registrar),
              icon: const Icon(Icons.add_comment_rounded),
              label: const Text('Registrar ocorrência'),
              tooltip: 'Registrar uma ocorrência de água no seu bairro',
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Início'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: qtdAlertas > 0,
              label: Text('$qtdAlertas'),
              child: const Icon(Icons.notifications_active_rounded),
            ),
            label: 'Alertas',
          ),
          const NavigationDestination(icon: Icon(Icons.map_rounded), label: 'Mapa'),
          const NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'Ajustes'),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Componentes reutilizáveis para os estados de carregamento, erro e lista vazia.
class Carregando extends StatelessWidget {
  const Carregando({super.key, this.mensagem = 'Carregando dados...'});
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: mensagem,
      child: Padding(
        padding: const EdgeInsets.all(Espaco.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: Espaco.md),
          Text(mensagem, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class ErroView extends StatelessWidget {
  const ErroView({super.key, required this.mensagem, this.aoTentarDeNovo});
  final String mensagem;
  final VoidCallback? aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final cor = context.coresAqua.critico;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(Espaco.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: cor, semanticLabel: 'Erro'),
          const SizedBox(height: Espaco.md),
          Text(mensagem, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          if (aoTentarDeNovo != null) ...[
            const SizedBox(height: Espaco.md),
            FilledButton.icon(
              onPressed: aoTentarDeNovo,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar de novo'),
            ),
          ],
        ]),
      ),
    );
  }
}

class VazioView extends StatelessWidget {
  const VazioView({super.key, required this.mensagem, this.icone = Icons.inbox_rounded, this.acao});
  final String mensagem;
  final IconData icone;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Espaco.lg),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icone, size: 48, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: Espaco.md),
        Text(mensagem, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        if (acao != null) ...[const SizedBox(height: Espaco.md), acao!],
      ]),
    );
  }
}

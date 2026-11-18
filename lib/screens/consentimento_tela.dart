import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/rotas.dart';
import '../state/configuracoes_provider.dart';

/// Etapa de consentimento explícito exibida no primeiro uso.
class ConsentimentoTela extends StatefulWidget {
  const ConsentimentoTela({super.key});

  @override
  State<ConsentimentoTela> createState() => _ConsentimentoTelaState();
}

class _ConsentimentoTelaState extends State<ConsentimentoTela> {
  bool _aceito = false; // estado local da tela

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = context.coresAqua;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Espaco.lg),
          children: [
            Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: cores.destaque, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.water_drop_rounded, color: Cores.mar, semanticLabel: 'Logo AquaRede'),
              ),
              const SizedBox(width: Espaco.md),
              Text('AquaRede', style: tema.textTheme.headlineSmall),
            ]),
            const SizedBox(height: Espaco.lg),
            Semantics(
              header: true,
              child: Text('Antes de começar', style: tema.textTheme.titleLarge),
            ),
            const SizedBox(height: Espaco.sm),
            const Text(
              'O AquaRede reúne dados sobre o acesso à água no seu território: o nível dos reservatórios, o clima '
              'e as ocorrências relatadas pelos moradores. Com isso, mostra alertas para apoiar gestores públicos e a comunidade.',
            ),
            const SizedBox(height: Espaco.lg),
            const _ItemPrivacidade(
              icone: Icons.person_off_rounded,
              titulo: 'Ocorrências anônimas',
              texto: 'O app não pede nome, telefone, e-mail nem endereço exato. A ocorrência é ligada apenas ao bairro.',
            ),
            const _ItemPrivacidade(
              icone: Icons.phone_android_rounded,
              titulo: 'Dados guardados no aparelho',
              texto: 'Preferências, limiares e ocorrências sem conexão ficam salvos só neste aparelho até serem enviados.',
            ),
            const _ItemPrivacidade(
              icone: Icons.delete_sweep_rounded,
              titulo: 'Você pode desistir',
              texto: 'Em Ajustes, é possível revogar este consentimento e apagar todos os dados locais a qualquer momento.',
            ),
            const _ItemPrivacidade(
              icone: Icons.person_search_rounded,
              titulo: 'Decisão humana',
              texto: 'Os alertas são recomendações. Nenhuma medida, como restrição de abastecimento, é tomada automaticamente.',
            ),
            const SizedBox(height: Espaco.md),
            CheckboxListTile(
              value: _aceito,
              onChanged: (v) => setState(() => _aceito = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text('Li e concordo com o uso dos dados descrito acima.'),
            ),
            const SizedBox(height: Espaco.md),
            FilledButton(
              onPressed: _aceito
                  ? () async {
                      await context.read<ConfiguracoesProvider>().darConsentimento();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacementNamed(Rotas.inicio);
                    }
                  : null,
              child: const Text('Concordar e continuar'),
            ),
            if (!_aceito)
              Padding(
                padding: const EdgeInsets.only(top: Espaco.sm),
                child: Text('Marque a caixa acima para continuar.',
                    textAlign: TextAlign.center, style: tema.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemPrivacidade extends StatelessWidget {
  const _ItemPrivacidade({required this.icone, required this.titulo, required this.texto});
  final IconData icone;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.md),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icone, color: tema.colorScheme.primary),
        const SizedBox(width: Espaco.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: tema.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(texto),
          ]),
        ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../core/rotas.dart';
import '../logic/validadores.dart';
import '../models/alerta.dart';
import '../state/configuracoes_provider.dart';
import '../state/territorio_provider.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';

/// Detalhe do alerta: justificativa (evidências), confiança, limitações e avaliação humana.
class AlertaDetalheTela extends StatelessWidget {
  const AlertaDetalheTela({super.key, required this.alertaId});
  final String alertaId;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioProvider>();
    final alerta = t.alertaPorId(alertaId);
    final tema = Theme.of(context);

    if (alerta == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alerta')),
        body: Center(
          child: t.carregandoAlgo
              ? const Carregando()
              : const VazioView(
                  mensagem: 'Este alerta não está mais ativo. Os dados ou os limiares mudaram desde que ele foi gerado.',
                  icone: Icons.notifications_off_rounded,
                ),
        ),
      );
    }

    final cor = corDoNivel(context, alerta.nivel);
    return Scaffold(
      appBar: AppBar(title: Text('Alerta de ${alerta.categoria.rotulo.toLowerCase()}')),
      body: ListView(
        padding: const EdgeInsets.all(Espaco.md),
        children: [
          SeloNivel.nivel(context, alerta.nivel),
          const SizedBox(height: Espaco.sm),
          Semantics(header: true, child: Text(alerta.titulo, style: tema.textTheme.headlineSmall?.copyWith(color: cor))),
          const SizedBox(height: Espaco.sm),
          Text(alerta.resumo, style: tema.textTheme.bodyLarge),
          const SizedBox(height: Espaco.md),
          const AvisoDecisaoHumana(),
          const TituloSecao('Por que este alerta foi gerado'),
          _Lista(itens: alerta.evidencias, icone: Icons.insights_rounded),
          const TituloSecao('Nível de confiança'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Espaco.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                BarraConfianca(valor: alerta.confianca, rotulo: alerta.confiancaRotulo),
                const SizedBox(height: Espaco.sm),
                Text(_explicarConfianca(alerta), style: tema.textTheme.bodySmall),
              ]),
            ),
          ),
          const TituloSecao('Limitações'),
          _Lista(itens: alerta.limitacoes, icone: Icons.info_outline_rounded),
          const TituloSecao('Quando a previsão não é confiável'),
          Text(alerta.naoConfiavelQuando),
          const TituloSecao('Fonte'),
          Text('${alerta.fonte}. Gerado em ${formatarDataHora(alerta.geradoEm)}.'),
          if (alerta.indicadorChave != null) ...[
            const SizedBox(height: Espaco.md),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(Rotas.indicador, arguments: alerta.indicadorChave),
              icon: const Icon(Icons.show_chart_rounded),
              label: const Text('Ver o indicador relacionado'),
            ),
          ],
          if (alerta.categoria == CategoriaAlerta.ocorrencias && alerta.regiao != null) ...[
            const SizedBox(height: Espaco.sm),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(Rotas.registrar, arguments: alerta.regiao),
              icon: const Icon(Icons.add_comment_rounded),
              label: Text('Relatar ocorrência em ${alerta.regiao}'),
            ),
          ],
          const TituloSecao('Avaliação humana'),
          _AvaliacaoHumana(alerta: alerta),
          const SizedBox(height: Espaco.xl),
        ],
      ),
    );
  }

  String _explicarConfianca(Alerta a) {
    switch (a.categoria) {
      case CategoriaAlerta.mananciais:
        return 'Calculada a partir do quanto a tendência recente explica a variação do volume (R²), '
            'descontada quando os dados são antigos ou sintéticos.';
      case CategoriaAlerta.clima:
        return 'Depende da quantidade de dias observados e do horizonte da previsão do tempo.';
      case CategoriaAlerta.ocorrencias:
        return 'Aumenta com o número de relatos independentes no bairro na última semana.';
    }
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.itens, required this.icone});
  final List<String> itens;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (final item in itens)
        Padding(
          padding: const EdgeInsets.only(bottom: Espaco.sm),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icone, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: Espaco.sm),
            Expanded(child: Text(item)),
          ]),
        ),
    ]);
  }
}

/// Formulário para o gestor registrar a decisão. Cidadãos apenas veem o status.
class _AvaliacaoHumana extends StatefulWidget {
  const _AvaliacaoHumana({required this.alerta});
  final Alerta alerta;

  @override
  State<_AvaliacaoHumana> createState() => _AvaliacaoHumanaState();
}

class _AvaliacaoHumanaState extends State<_AvaliacaoHumana> {
  final _form = GlobalKey<FormState>();
  final _justificativa = TextEditingController();
  DecisaoHumana _decisao = DecisaoHumana.emAnalise;
  bool _editando = false;
  bool _salvando = false;

  @override
  void dispose() {
    _justificativa.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    await context.read<TerritorioProvider>().avaliarAlerta(widget.alerta.id, _decisao, _justificativa.text);
    if (!mounted) return;
    setState(() {
      _salvando = false;
      _editando = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avaliação registrada.')));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ehGestor = context.watch<ConfiguracoesProvider>().ehGestor;
    final avaliacao = context.watch<TerritorioProvider>().avaliacaoDe(widget.alerta.id);

    if (avaliacao != null && !_editando) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(Espaco.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.how_to_reg_rounded, color: context.coresAqua.normal),
              const SizedBox(width: Espaco.sm),
              Expanded(child: Text(avaliacao.decisao.rotulo, style: tema.textTheme.titleMedium)),
            ]),
            const SizedBox(height: Espaco.sm),
            Text(avaliacao.justificativa),
            const SizedBox(height: Espaco.xs),
            Text('Registrado em ${formatarDataHora(avaliacao.data)}', style: tema.textTheme.bodySmall),
            if (ehGestor)
              TextButton(
                onPressed: () => setState(() {
                  _editando = true;
                  _decisao = avaliacao.decisao;
                  _justificativa.text = avaliacao.justificativa;
                }),
                child: const Text('Alterar avaliação'),
              ),
          ]),
        ),
      );
    }

    if (!ehGestor) {
      return const VazioView(
        mensagem: 'Este alerta aguarda a avaliação de um gestor. Somente o perfil Gestor (em Ajustes) registra decisões.',
        icone: Icons.hourglass_top_rounded,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Espaco.md),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Depois de analisar as evidências, registre sua decisão:'),
            const SizedBox(height: Espaco.sm),
            Wrap(spacing: Espaco.sm, runSpacing: Espaco.sm, children: [
              for (final d in DecisaoHumana.values)
                ChoiceChip(
                  label: Text(d.rotulo),
                  selected: _decisao == d,
                  onSelected: (_) => setState(() => _decisao = d),
                ),
            ]),
            const SizedBox(height: Espaco.md),
            TextFormField(
              controller: _justificativa,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Justificativa da decisão',
                hintText: 'Ex.: Equipe enviada para vistoria no bairro.',
              ),
              validator: Validadores.justificativaAvaliacao,
            ),
            const SizedBox(height: Espaco.sm),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Registrar decisão'),
            ),
          ]),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/rotas.dart';
import '../models/alerta.dart';
import '../state/territorio_provider.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';

/// Lista de alertas com filtro por categoria.
class AlertasTela extends StatefulWidget {
  const AlertasTela({super.key});

  @override
  State<AlertasTela> createState() => _AlertasTelaState();
}

class _AlertasTelaState extends State<AlertasTela> {
  CategoriaAlerta? _filtro; // estado local: filtro escolhido

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioProvider>();
    final todos = t.alertas;
    final lista = _filtro == null ? todos : todos.where((a) => a.categoria == _filtro).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(Espaco.md, Espaco.md, Espaco.md, 96),
      children: [
        const AvisoDecisaoHumana(),
        const SizedBox(height: Espaco.md),
        Wrap(spacing: Espaco.sm, runSpacing: Espaco.sm, children: [
          ChoiceChip(
            label: Text('Todos (${todos.length})'),
            selected: _filtro == null,
            onSelected: (_) => setState(() => _filtro = null),
          ),
          for (final c in CategoriaAlerta.values)
            ChoiceChip(
              label: Text('${c.rotulo} (${todos.where((a) => a.categoria == c).length})'),
              selected: _filtro == c,
              onSelected: (_) => setState(() => _filtro = c),
            ),
        ]),
        const SizedBox(height: Espaco.md),
        if (t.carregandoAlgo && todos.isEmpty)
          const Carregando(mensagem: 'Calculando alertas...')
        else if (lista.isEmpty)
          VazioView(
            mensagem: _filtro == null
                ? 'Nenhum alerta no momento. Os indicadores estão dentro dos limiares configurados.'
                : 'Nenhum alerta de ${_filtro!.rotulo.toLowerCase()} no momento.',
            icone: Icons.verified_rounded,
          )
        else
          for (final a in lista) ...[CartaoAlerta(alerta: a), const SizedBox(height: Espaco.sm)],
      ],
    );
  }
}

/// Cartão resumido de um alerta (reutilizado no Início e na lista).
class CartaoAlerta extends StatelessWidget {
  const CartaoAlerta({super.key, required this.alerta});
  final Alerta alerta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final avaliacao = context.select<TerritorioProvider, AvaliacaoHumana?>((t) => t.avaliacaoDe(alerta.id));
    final cor = corDoNivel(context, alerta.nivel);
    return Semantics(
      button: true,
      label: 'Alerta ${alerta.nivel.rotulo}: ${alerta.titulo}. Confiança ${alerta.confiancaRotulo}. '
          '${avaliacao == null ? 'Aguardando avaliação humana' : avaliacao.decisao.rotulo}.',
      hint: 'Toque para ver a justificativa',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(Rotas.alerta, arguments: alerta.id),
          child: Container(
            decoration: BoxDecoration(border: Border(left: BorderSide(color: cor, width: 6))),
            padding: const EdgeInsets.all(Espaco.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: Espaco.sm, runSpacing: Espaco.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SeloNivel.nivel(context, alerta.nivel),
                Text(alerta.categoria.rotulo, style: tema.textTheme.labelMedium),
              ]),
              const SizedBox(height: Espaco.sm),
              Text(alerta.titulo, style: tema.textTheme.titleMedium),
              const SizedBox(height: Espaco.xs),
              Text(alerta.resumo, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: Espaco.sm),
              Wrap(spacing: Espaco.md, runSpacing: Espaco.xs, children: [
                _Info(icone: Icons.speed_rounded, texto: 'Confiança ${alerta.confiancaRotulo}'),
                _Info(
                  icone: avaliacao == null ? Icons.hourglass_top_rounded : Icons.how_to_reg_rounded,
                  texto: avaliacao == null ? 'Aguardando avaliação humana' : avaliacao.decisao.rotulo,
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icone, required this.texto});
  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodySmall;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icone, size: 16, color: estilo?.color),
      const SizedBox(width: 4),
      Text(texto, style: estilo),
    ]);
  }
}

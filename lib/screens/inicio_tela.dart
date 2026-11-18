import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../core/rotas.dart';
import '../models/alerta.dart';
import '../models/carga.dart';
import '../state/territorio_provider.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';
import 'alertas_tela.dart';

/// Visão geral do território: os 3 painéis, o indicador social e os alertas mais graves.
class InicioTela extends StatelessWidget {
  const InicioTela({super.key, required this.aoAbrirAlertas});
  final VoidCallback aoAbrirAlertas;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioProvider>();
    final tema = Theme.of(context);
    final alertas = t.alertas;

    return RefreshIndicator(
      onRefresh: t.carregarTudo,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Espaco.md, Espaco.md, Espaco.md, 96),
        children: [
          Text('Acesso à água na Grande São Paulo', style: tema.textTheme.titleLarge),
          const SizedBox(height: Espaco.xs),
          Text('Reservatórios, clima e relatos dos moradores em um só painel.', style: tema.textTheme.bodyMedium),
          const SizedBox(height: Espaco.md),
          const AvisoDecisaoHumana(compacto: true),
          const TituloSecao('Painéis do território'),
          _CartaoPainel(
            titulo: 'Mananciais',
            icone: Icons.water_rounded,
            status: t.statusMananciais,
            erro: t.erroMananciais,
            aoTentar: t.carregarMananciais,
            conteudo: () {
              final ind = t.indicadoresMananciais;
              if (ind.isEmpty) return 'Sem dados de reservatórios.';
              final pior = ind.reduce((a, b) => a.atual < b.atual ? a : b);
              final emRisco = ind.where((i) => i.faixaAtual.index >= NivelAlerta.alerta.index).length;
              return 'Menor volume: ${pior.sistema.nome}, ${formatarPorcentagem(pior.atual)}. '
                  '$emRisco de ${ind.length} sistemas em Alerta ou Crítico.';
            },
            origem: t.mananciais?.origem,
            rota: Rotas.mananciais,
          ),
          const SizedBox(height: Espaco.sm),
          _CartaoPainel(
            titulo: 'Clima local',
            icone: Icons.cloud_rounded,
            status: t.statusClima,
            erro: t.erroClima,
            aoTentar: t.carregarClima,
            conteudo: () {
              final c = t.indicadoresClima;
              if (c == null) return 'Sem dados de clima.';
              return '${c.diasSemChuva} dia(s) seguidos sem chuva. '
                  'Previsão de ${formatarNumero(c.chuvaPrevista7d, casas: 1)} mm nos próximos 7 dias.';
            },
            origem: t.clima?.origem,
            rota: Rotas.clima,
          ),
          const SizedBox(height: Espaco.sm),
          _CartaoPainel(
            titulo: 'Ocorrências da comunidade',
            icone: Icons.campaign_rounded,
            status: t.statusOcorrencias,
            erro: t.erroOcorrencias,
            aoTentar: t.carregarOcorrencias,
            conteudo: () {
              final o = t.indicadoresOcorrencias;
              return '${o.ultimos7d.length} relato(s) nos últimos 7 dias, '
                  '${o.altaPrioridade7d} de prioridade alta.';
            },
            origem: t.ocorrenciasRemotas?.origem,
            rota: Rotas.ocorrencias,
          ),
          const TituloSecao('Benefício social'),
          GradeCartoes(filhos: [
            CartaoIndicador(
              titulo: 'Pessoas em alertas antecipados',
              valor: formatarNumero(t.pessoasEmAlertasAtivos),
              detalhe: 'Moradores afetados em bairros que já geraram alerta para os gestores.',
              icone: Icons.groups_rounded,
              cor: tema.colorScheme.primary,
            ),
            CartaoIndicador(
              titulo: 'Alertas com decisão humana',
              valor: '${t.alertasAvaliados} de ${alertas.length}',
              detalhe: '${formatarNumero(t.pessoasComAlertaEncaminhado)} pessoa(s) em casos já encaminhados.',
              icone: Icons.fact_check_rounded,
            ),
          ]),
          TituloSecao(
            'Alertas mais graves',
            acao: TextButton(onPressed: aoAbrirAlertas, child: const Text('Ver todos')),
          ),
          if (t.carregandoAlgo && alertas.isEmpty)
            const Carregando(mensagem: 'Calculando alertas...')
          else if (alertas.isEmpty)
            const VazioView(
              mensagem: 'Nenhum alerta no momento. Os indicadores estão dentro dos limiares configurados.',
              icone: Icons.verified_rounded,
            )
          else
            for (final a in alertas.take(3)) ...[CartaoAlerta(alerta: a), const SizedBox(height: Espaco.sm)],
        ],
      ),
    );
  }
}

class _CartaoPainel extends StatelessWidget {
  const _CartaoPainel({
    required this.titulo,
    required this.icone,
    required this.status,
    required this.erro,
    required this.aoTentar,
    required this.conteudo,
    required this.origem,
    required this.rota,
  });

  final String titulo;
  final IconData icone;
  final StatusCarga status;
  final String? erro;
  final Future<void> Function() aoTentar;
  final String Function() conteudo;
  final OrigemDados? origem;
  final String rota;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    Widget corpo;
    switch (status) {
      case StatusCarga.carregando:
        corpo = const Padding(
          padding: EdgeInsets.symmetric(vertical: Espaco.sm),
          child: LinearProgressIndicator(semanticsLabel: 'Carregando'),
        );
      case StatusCarga.erro:
        corpo = Row(children: [
          Expanded(child: Text(erro ?? 'Erro ao carregar.', style: TextStyle(color: context.coresAqua.critico))),
          TextButton(onPressed: aoTentar, child: const Text('Tentar de novo')),
        ]);
      case StatusCarga.pronto:
        corpo = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(conteudo()),
          if (origem != null) Text(origem!.rotulo, style: tema.textTheme.bodySmall),
        ]);
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: status == StatusCarga.pronto ? () => Navigator.of(context).pushNamed(rota) : null,
        child: Padding(
          padding: const EdgeInsets.all(Espaco.md),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: tema.colorScheme.primaryContainer,
              child: Icon(icone, color: tema.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: Espaco.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo, style: tema.textTheme.titleMedium),
                const SizedBox(height: Espaco.xs),
                AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: KeyedSubtree(key: ValueKey(status), child: corpo)),
              ]),
            ),
            if (status == StatusCarga.pronto)
              Icon(Icons.chevron_right_rounded, color: tema.colorScheme.outline, semanticLabel: 'Abrir painel'),
          ]),
        ),
      ),
    );
  }
}

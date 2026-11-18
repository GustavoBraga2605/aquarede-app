import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../core/rotas.dart';
import '../logic/indicadores.dart';
import '../models/carga.dart';
import '../models/manancial.dart';
import '../state/configuracoes_provider.dart';
import '../state/territorio_provider.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';
import '../widgets/graficos.dart';

/// Painel 1: volume armazenado dos sistemas produtores, com histórico, tendência e projeção.
class PainelMananciaisTela extends StatefulWidget {
  const PainelMananciaisTela({super.key, this.sistemaInicial});
  final String? sistemaInicial;

  @override
  State<PainelMananciaisTela> createState() => _PainelMananciaisTelaState();
}

class _PainelMananciaisTelaState extends State<PainelMananciaisTela> {
  String? _sistema; // estado local: sistema selecionado
  int _periodo = 90; // estado local: período do gráfico

  @override
  void initState() {
    super.initState();
    _sistema = widget.sistemaInicial;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioProvider>();
    final limiares = context.watch<ConfiguracoesProvider>().limiares;

    Widget corpo;
    if (t.statusMananciais == StatusCarga.carregando) {
      corpo = const Center(child: Carregando(mensagem: 'Carregando reservatórios...'));
    } else if (t.statusMananciais == StatusCarga.erro) {
      corpo = Center(child: ErroView(mensagem: t.erroMananciais ?? 'Erro.', aoTentarDeNovo: t.carregarMananciais));
    } else if (t.indicadoresMananciais.isEmpty) {
      corpo = const Center(child: VazioView(mensagem: 'Nenhum sistema com dados suficientes.'));
    } else {
      final todos = t.indicadoresMananciais;
      final selecionado = todos.firstWhere((i) => i.sistema.nome == _sistema, orElse: () => todos.first);
      final tema = Theme.of(context);
      final cores = context.coresAqua;
      final serie = selecionado.sistema.serie;
      final recorte = serie.length > _periodo ? serie.sublist(serie.length - _periodo) : serie;
      final ultima = serie.last.data;
      final projecao = [
        PontoSerie(ultima.add(const Duration(days: horizontePrevisao)), selecionado.previsao30d),
      ];

      corpo = RefreshIndicator(
        onRefresh: t.carregarMananciais,
        child: ListView(
          padding: const EdgeInsets.all(Espaco.md),
          children: [
            if (t.mananciais != null) FaixaOrigem(origem: t.mananciais!.origem, atualizadoEm: t.mananciais!.atualizadoEm),
            const SizedBox(height: Espaco.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final i in todos)
                  Padding(
                    padding: const EdgeInsets.only(right: Espaco.sm),
                    child: ChoiceChip(
                      label: Text(i.sistema.nome),
                      selected: i == selecionado,
                      onSelected: (_) => setState(() => _sistema = i.sistema.nome),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: Espaco.md),
            Row(children: [
              Expanded(child: Text(selecionado.sistema.nome, style: tema.textTheme.titleLarge)),
              SeloNivel.nivel(context, selecionado.faixaAtual),
            ]),
            const SizedBox(height: Espaco.md),
            GradeCartoes(filhos: [
              CartaoIndicador(
                titulo: 'Volume atual',
                valor: formatarPorcentagem(selecionado.atual),
                detalhe: 'Leitura de ${formatarData(ultima)}',
                icone: Icons.water_rounded,
                cor: corDoNivel(context, selecionado.faixaAtual),
                aoTocar: () => Navigator.of(context)
                    .pushNamed(Rotas.indicador, arguments: 'manancial:${selecionado.sistema.nome}'),
                dicaAcessibilidade: 'Abre o detalhe do indicador',
              ),
              CartaoIndicador(
                titulo: 'Tendência 30 dias',
                valor: '${formatarSinal(selecionado.tendencia30d)} p.p.',
                detalhe: selecionado.tendencia30d < 0 ? 'Reservatório esvaziando' : 'Reservatório estável ou enchendo',
                icone: selecionado.tendencia30d < 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                cor: selecionado.tendencia30d < -1 ? cores.alerta : null,
              ),
              CartaoIndicador(
                titulo: 'Projeção em 30 dias',
                valor: formatarPorcentagem(selecionado.previsao30d),
                detalhe: '±${formatarNumero(selecionado.margemPrevisao, casas: 1)} p.p., R² ${formatarNumero(selecionado.r2 * 100)}%',
                icone: Icons.query_stats_rounded,
                cor: corDoNivel(context, selecionado.faixaPrevista),
              ),
              CartaoIndicador(
                titulo: 'Dias até a faixa crítica',
                valor: selecionado.autonomiaDias == null
                    ? 'Sem queda'
                    : selecionado.autonomiaDias == 0
                        ? 'Já crítico'
                        : '${selecionado.autonomiaDias} dias',
                detalhe: 'No ritmo atual, até ${formatarNumero(limiares.volumeCritico)}%',
                icone: Icons.timer_outlined,
              ),
            ]),
            TituloSecao(
              'Histórico e projeção',
              acao: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 90, label: Text('90 dias')),
                  ButtonSegment(value: 365, label: Text('1 ano')),
                ],
                selected: {_periodo},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _periodo = s.first),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Espaco.sm, Espaco.md, Espaco.md, Espaco.sm),
                child: GraficoLinha(
                  serie: recorte,
                  projecao: projecao,
                  minY: 0,
                  maxY: 100,
                  sufixoY: '%',
                  referencias: [
                    LinhaReferencia(limiares.volumeAtencao, 'Atenção', cores.atencao),
                    LinhaReferencia(limiares.volumeAlerta, 'Alerta', cores.alerta),
                    LinhaReferencia(limiares.volumeCritico, 'Crítico', cores.critico),
                  ],
                  resumoAcessivel: 'Gráfico do volume do ${selecionado.sistema.nome} nos últimos $_periodo dias. '
                      'Começa em ${formatarPorcentagem(recorte.first.valor)} e termina em ${formatarPorcentagem(selecionado.atual)}. '
                      'A linha tracejada projeta ${formatarPorcentagem(selecionado.previsao30d)} em 30 dias.',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: Espaco.xs),
              child: Text('Linha tracejada: projeção linear da tendência dos últimos 30 dias.',
                  style: tema.textTheme.bodySmall),
            ),
            const TituloSecao('Todos os sistemas'),
            Card(
              child: Column(children: [
                for (final i in [...todos]..sort((a, b) => a.atual.compareTo(b.atual)))
                  ListTile(
                    title: Text(i.sistema.nome),
                    subtitle: Text('${formatarPorcentagem(i.atual)} · ${formatarSinal(i.tendencia30d)} p.p. em 30 dias'),
                    trailing: SeloNivel.nivel(context, i.faixaAtual),
                    onTap: () => setState(() => _sistema = i.sistema.nome),
                  ),
              ]),
            ),
          ],
        ),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Mananciais')), body: corpo);
  }
}

import 'dart:math' as math;

import 'package:aquarede/models/alerta.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../models/limiares.dart';
import '../models/manancial.dart';
import '../state/configuracoes_provider.dart';
import '../state/territorio_provider.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';
import '../widgets/graficos.dart';
import 'alertas_tela.dart';

/// Detalhe de um indicador: valor, histórico, definição, cálculo, fonte e alertas relacionados.
/// Recebe a [chave] do indicador como parâmetro da rota (ex.: "manancial:Cantareira").
class IndicadorDetalheTela extends StatelessWidget {
  const IndicadorDetalheTela({super.key, required this.chave});
  final String chave;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioProvider>();
    final limiares = context.watch<ConfiguracoesProvider>().limiares;
    final cores = context.coresAqua;
    final ficha = _montarFicha(context, t, limiares, cores);

    if (ficha == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Indicador')),
        body: Center(
          child: t.carregandoAlgo
              ? const Carregando()
              : const VazioView(
                  mensagem: 'Não há dados para este indicador no momento.'),
        ),
      );
    }

    final relacionados =
        t.alertas.where((a) => a.indicadorChave == chave).toList();
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(ficha.titulo)),
      body: ListView(
        padding: const EdgeInsets.all(Espaco.md),
        children: [
          Text(ficha.valor,
              style: tema.textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w800, color: ficha.cor)),
          Text(ficha.subtitulo, style: tema.textTheme.bodyMedium),
          const TituloSecao('Histórico'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  Espaco.sm, Espaco.md, Espaco.md, Espaco.sm),
              child: ficha.grafico,
            ),
          ),
          if (ficha.estatisticas.isNotEmpty) ...[
            const SizedBox(height: Espaco.md),
            GradeCartoes(filhos: [
              for (final e in ficha.estatisticas.entries)
                CartaoIndicador(titulo: e.key, valor: e.value),
            ]),
          ],
          const TituloSecao('O que é'),
          Text(ficha.definicao),
          const TituloSecao('Como é calculado'),
          Text(ficha.calculo),
          const TituloSecao('Unidade e periodicidade'),
          Text(ficha.unidade),
          const TituloSecao('Fonte e limitações'),
          Text(ficha.fonte),
          TituloSecao('Alertas relacionados (${relacionados.length})'),
          if (relacionados.isEmpty)
            const Text('Nenhum alerta ativo ligado a este indicador.')
          else
            for (final a in relacionados) ...[
              CartaoAlerta(alerta: a),
              const SizedBox(height: Espaco.sm)
            ],
          const SizedBox(height: Espaco.lg),
        ],
      ),
    );
  }

  _Ficha? _montarFicha(BuildContext context, TerritorioProvider t,
      Limiares limiares, CoresAquaRede cores) {
    final partes = chave.split(':');
    switch (partes.first) {
      case 'manancial':
        final nome = partes.sublist(1).join(':');
        final indM = t.indicadoresMananciais
            .where((i) => i.sistema.nome == nome)
            .firstOrNull;
        if (indM == null) return null;
        final valores = indM.sistema.serie.map((p) => p.valor).toList();
        final media = valores.reduce((a, b) => a + b) / valores.length;
        return _Ficha(
          titulo: 'Volume: $nome',
          valor: formatarPorcentagem(indM.atual),
          subtitulo:
              'Faixa ${indM.faixaAtual.rotulo} · leitura de ${formatarData(indM.sistema.ultimaLeitura)}',
          cor: corDoNivel(context, indM.faixaAtual),
          grafico: GraficoLinha(
            serie: indM.sistema.serie,
            minY: 0,
            maxY: 100,
            sufixoY: '%',
            referencias: [
              LinhaReferencia(limiares.volumeAtencao, 'Atenção', cores.atencao),
              LinhaReferencia(limiares.volumeAlerta, 'Alerta', cores.alerta),
              LinhaReferencia(limiares.volumeCritico, 'Crítico', cores.critico),
            ],
            resumoAcessivel:
                'Volume do $nome no último ano: mínimo ${formatarPorcentagem(valores.reduce(math.min))}, '
                'máximo ${formatarPorcentagem(valores.reduce(math.max))}, atual ${formatarPorcentagem(indM.atual)}.',
          ),
          estatisticas: {
            'Mínimo em 1 ano': formatarPorcentagem(valores.reduce(math.min)),
            'Máximo em 1 ano': formatarPorcentagem(valores.reduce(math.max)),
            'Média em 1 ano': formatarPorcentagem(media),
            'Tendência 30 dias': '${formatarSinal(indM.tendencia30d)} p.p.',
          },
          definicao:
              'Quanto do volume útil do reservatório está ocupado com água. É o principal sinal da '
              'disponibilidade de água para abastecer a região.',
          calculo:
              'Volume armazenado ÷ volume útil × 100. A projeção de 30 dias ajusta uma reta aos últimos 30 dias '
              '(regressão linear) e a prolonga. O R² mostra quanto essa reta explica a variação recente.',
          unidade: 'Porcentagem do volume útil (%). Atualização diária.',
          fonte:
              'Serviço simulado com série sintética de 1 ano, inspirada no comportamento sazonal dos sistemas da RMSP. '
              'Em produção, a fonte seria o Portal dos Mananciais da Sabesp. A projeção não considera chuva futura, '
              'consumo nem transferências entre sistemas.',
        );
      case 'clima':
        final dias = t.clima?.dados;
        final indC = t.indicadoresClima;
        if (dias == null || dias.isEmpty || indC == null) return null;
        if (partes.length > 1 && partes[1] == 'temperatura') {
          final serie = [
            for (final d in dias)
              if (d.tMax != null) PontoSerie(d.data, d.tMax!)
          ];
          if (serie.isEmpty) return null;
          return _Ficha(
            titulo: 'Temperatura máxima',
            valor: indC.tMaxPrevista3d == null
                ? 'Sem dado'
                : '${formatarNumero(indC.tMaxPrevista3d!, casas: 1)} °C',
            subtitulo: 'Maior máxima prevista para os próximos 3 dias',
            cor: cores.alerta,
            grafico: GraficoLinha(
              serie: serie,
              sufixoY: '°',
              cor: cores.alerta,
              referencias: [
                LinhaReferencia(
                    limiares.temperaturaCalor, 'Calor', cores.critico)
              ],
              resumoAcessivel:
                  'Temperatura máxima diária nos últimos 30 dias e nos próximos 7.',
            ),
            estatisticas: const {},
            definicao:
                'A temperatura máxima do dia. Em dias muito quentes o consumo de água aumenta, o que pressiona '
                'a rede e pode causar falta nas partes altas dos bairros.',
            calculo:
                'Maior temperatura máxima prevista entre hoje e os próximos 2 dias, comparada ao limiar de calor.',
            unidade: 'Graus Celsius (°C). Atualização diária.',
            fonte:
                'Open-Meteo, dados públicos. Ponto único no centro de São Paulo. A previsão perde precisão após 3 dias.',
          );
        }
        return _Ficha(
          titulo: 'Chuva diária',
          valor: '${indC.diasSemChuva} dia(s)',
          subtitulo: 'Seguidos sem chuva relevante (menos de 1 mm)',
          cor: indC.diasSemChuva >= limiares.diasSemChuva ? cores.alerta : null,
          grafico: GraficoBarras(
            itens: [
              for (final d in dias)
                ItemBarra(formatarDiaMes(d.data), d.chuva ?? 0,
                    cor: d.previsto
                        ? cores.destaque
                        : Theme.of(context).colorScheme.primary),
            ],
            mostrarRotulosACada: 7,
            resumoAcessivel:
                'Chuva diária observada e prevista. Acumulado de 30 dias: '
                '${formatarNumero(indC.chuva30d)} milímetros.',
          ),
          estatisticas: {
            'Chuva em 30 dias': '${formatarNumero(indC.chuva30d)} mm',
            'Prevista em 7 dias': '${formatarNumero(indC.chuvaPrevista7d)} mm',
          },
          definicao:
              'A quantidade de chuva por dia. Longos períodos secos reduzem a entrada de água nos reservatórios.',
          calculo:
              'Contagem de dias seguidos, até hoje, com menos de 1 mm de chuva; e soma da chuva dos últimos 30 dias.',
          unidade: 'Milímetros (mm) e dias. Atualização diária.',
          fonte:
              'Open-Meteo, dados públicos. Ponto único no centro de São Paulo, que pode não refletir a chuva nas bacias dos mananciais.',
        );
      case 'ocorrencias':
        final indO = t.indicadoresOcorrencias;
        if (indO.total == 0) return null;
        return _Ficha(
          titulo: 'Ocorrências da comunidade',
          valor: '${indO.ultimos7d.length}',
          subtitulo: 'Relatos nos últimos 7 dias',
          cor: null,
          grafico: GraficoBarras(
            itens: [
              for (final p in indO.porDia14d)
                ItemBarra(formatarDiaMes(p.data), p.valor)
            ],
            mostrarRotulosACada: 3,
            resumoAcessivel: 'Relatos por dia nos últimos 14 dias.',
          ),
          estatisticas: {
            'Total registrado': '${indO.total}',
            'Pessoas afetadas (7 dias)': formatarNumero(indO.pessoasAfetadas7d),
          },
          definicao:
              'Relatos de falta de água, vazamento, água contaminada ou baixa pressão enviados pelos moradores.',
          calculo:
              'Contagem de relatos por dia e por bairro. A prioridade de cada relato segue regras fixas: '
              'contaminação é sempre Alta; 24 h ou mais sem água ou 50+ pessoas afetadas também são Alta.',
          unidade: 'Número de relatos. Atualização a cada envio.',
          fonte:
              'API AquaRede (Node.js + MongoDB). Relatos não são verificados no local e podem ter subnotificação.',
        );
    }
    return null;
  }
}

class _Ficha {
  const _Ficha({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.cor,
    required this.grafico,
    required this.estatisticas,
    required this.definicao,
    required this.calculo,
    required this.unidade,
    required this.fonte,
  });
  final String titulo;
  final String valor;
  final String subtitulo;
  final Color? cor;
  final Widget grafico;
  final Map<String, String> estatisticas;
  final String definicao;
  final String calculo;
  final String unidade;
  final String fonte;
}

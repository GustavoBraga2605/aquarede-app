import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/formatadores.dart';
import '../models/manancial.dart';

/// Linha horizontal de referência (ex.: limiar de alerta).
class LinhaReferencia {
  const LinhaReferencia(this.valor, this.rotulo, this.cor);
  final double valor;
  final String rotulo;
  final Color cor;
}

/// Gráfico de linha do histórico, com projeção opcional tracejada e limiares.
/// Leitores de tela recebem um resumo em texto ([resumoAcessivel]) no lugar do desenho.
class GraficoLinha extends StatelessWidget {
  const GraficoLinha({
    super.key,
    required this.serie,
    required this.resumoAcessivel,
    this.projecao = const [],
    this.referencias = const [],
    this.minY,
    this.maxY,
    this.sufixoY = '',
    this.altura = 220,
    this.cor,
  });

  final List<PontoSerie> serie;
  final List<PontoSerie> projecao;
  final List<LinhaReferencia> referencias;
  final String resumoAcessivel;
  final double? minY;
  final double? maxY;
  final String sufixoY;
  final double altura;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final corLinha = cor ?? tema.colorScheme.primary;
    if (serie.isEmpty) return SizedBox(height: altura);
    final inicio = serie.first.data;
    double x(DateTime d) => d.difference(inicio).inHours / 24;
    final todos = [...serie, ...projecao];
    final totalDias = x(todos.last.data);
    final intervaloX = math.max(1.0, (totalDias / 4).roundToDouble());
    final valores = todos.map((p) => p.valor).toList();
    final menor = minY ?? (valores.reduce(math.min) - 2).floorToDouble();
    final maior = maxY ?? (valores.reduce(math.max) + 2).ceilToDouble();
    final estiloEixo = tema.textTheme.bodySmall;

    return Semantics(
      label: resumoAcessivel,
      excludeSemantics: true,
      child: SizedBox(
        height: altura,
        child: LineChart(
          LineChartData(
            minY: menor,
            maxY: maior,
            minX: 0,
            maxX: totalDias,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: true),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (valor, meta) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('${formatarNumero(valor)}$sufixoY',
                        style: estiloEixo, textAlign: TextAlign.right),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: intervaloX,
                  getTitlesWidget: (valor, meta) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                        formatarDiaMes(
                            inicio.add(Duration(days: valor.round()))),
                        style: estiloEixo),
                  ),
                ),
              ),
            ),
            extraLinesData: ExtraLinesData(horizontalLines: [
              for (final r in referencias)
                HorizontalLine(
                  y: r.valor,
                  color: r.cor,
                  strokeWidth: 1.5,
                  dashArray: const [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: TextStyle(
                        color: r.cor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                    labelResolver: (_) => r.rotulo,
                  ),
                ),
            ]),
            lineBarsData: [
              LineChartBarData(
                spots: [for (final p in serie) FlSpot(x(p.data), p.valor)],
                color: corLinha,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData:
                    BarAreaData(show: true, color: corLinha.withAlpha(28)),
              ),
              if (projecao.isNotEmpty)
                LineChartBarData(
                  spots: [
                    FlSpot(x(serie.last.data), serie.last.valor),
                    for (final p in projecao) FlSpot(x(p.data), p.valor),
                  ],
                  color: corLinha,
                  barWidth: 2.5,
                  dashArray: const [5, 5],
                  dotData: const FlDotData(show: false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item de um gráfico de barras.
class ItemBarra {
  const ItemBarra(this.rotulo, this.valor, {this.cor});
  final String rotulo;
  final double valor;
  final Color? cor;
}

/// Gráfico de barras verticais com rótulos curtos no eixo X.
class GraficoBarras extends StatelessWidget {
  const GraficoBarras({
    super.key,
    required this.itens,
    required this.resumoAcessivel,
    this.altura = 200,
    this.mostrarRotulosACada = 1,
  });

  final List<ItemBarra> itens;
  final String resumoAcessivel;
  final double altura;
  final int mostrarRotulosACada;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    if (itens.isEmpty) return SizedBox(height: altura);
    final maior = itens.map((i) => i.valor).reduce(math.max);
    final larguraBarra = math.max(4.0, math.min(28.0, 240 / itens.length));

    return Semantics(
      label: resumoAcessivel,
      excludeSemantics: true,
      child: SizedBox(
        height: altura,
        child: BarChart(
          BarChartData(
            maxY: maior <= 0 ? 1 : maior * 1.15,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            barTouchData: const BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (valor, meta) => Text(formatarNumero(valor),
                      style: tema.textTheme.bodySmall),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (valor, meta) {
                    final i = valor.toInt();
                    if (i < 0 ||
                        i >= itens.length ||
                        i % mostrarRotulosACada != 0)
                      return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(itens[i].rotulo,
                          style: tema.textTheme.bodySmall),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < itens.length; i++)
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: itens[i].valor,
                    color: itens[i].cor ?? tema.colorScheme.primary,
                    width: larguraBarra,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barras horizontais simples (sem fl_chart), boas para rótulos longos como nomes de bairro.
class BarrasHorizontais extends StatelessWidget {
  const BarrasHorizontais({super.key, required this.itens, this.sufixo = ''});
  final List<ItemBarra> itens;
  final String sufixo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    if (itens.isEmpty) return const SizedBox.shrink();
    final maior = itens.map((i) => i.valor).reduce(math.max);
    return Column(children: [
      for (final item in itens)
        Semantics(
          label: '${item.rotulo}: ${formatarNumero(item.valor)}$sufixo',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(item.rotulo, style: tema.textTheme.bodyMedium)),
                Text('${formatarNumero(item.valor)}$sufixo',
                    style: tema.textTheme.titleSmall),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: maior == 0 ? 0 : item.valor / maior,
                  minHeight: 10,
                  color: item.cor ?? tema.colorScheme.primary,
                  backgroundColor: tema.colorScheme.surfaceContainerHighest,
                ),
              ),
            ]),
          ),
        ),
    ]);
  }
}

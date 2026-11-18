import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../core/rotas.dart';
import '../models/carga.dart';
import '../models/manancial.dart';
import '../state/configuracoes_provider.dart';
import '../state/territorio_provider.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';
import '../widgets/graficos.dart';

/// Painel 2: clima local com dados reais da API Open-Meteo (chuva e temperatura).
class PainelClimaTela extends StatelessWidget {
  const PainelClimaTela({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioProvider>();
    final limiares = context.watch<ConfiguracoesProvider>().limiares;

    Widget corpo;
    if (t.statusClima == StatusCarga.carregando) {
      corpo = const Center(child: Carregando(mensagem: 'Buscando dados do clima...'));
    } else if (t.statusClima == StatusCarga.erro) {
      corpo = Center(child: ErroView(mensagem: t.erroClima ?? 'Erro.', aoTentarDeNovo: t.carregarClima));
    } else if (t.clima == null || t.clima!.dados.isEmpty || t.indicadoresClima == null) {
      corpo = const Center(child: VazioView(mensagem: 'A API não retornou dias de clima.'));
    } else {
      final dias = t.clima!.dados;
      final ind = t.indicadoresClima!;
      final tema = Theme.of(context);
      final cores = context.coresAqua;
      final temperaturas = [
        for (final d in dias)
          if (d.tMax != null) PontoSerie(d.data, d.tMax!),
      ];

      corpo = RefreshIndicator(
        onRefresh: t.carregarClima,
        child: ListView(
          padding: const EdgeInsets.all(Espaco.md),
          children: [
            FaixaOrigem(origem: t.clima!.origem, atualizadoEm: t.clima!.atualizadoEm),
            const SizedBox(height: Espaco.sm),
            Text('Centro de São Paulo · últimos 30 dias e previsão para 7 dias', style: tema.textTheme.bodyMedium),
            const SizedBox(height: Espaco.md),
            GradeCartoes(filhos: [
              CartaoIndicador(
                titulo: 'Dias seguidos sem chuva',
                valor: '${ind.diasSemChuva}',
                detalhe: 'Limiar de alerta: ${limiares.diasSemChuva} dias',
                icone: Icons.wb_sunny_rounded,
                cor: ind.diasSemChuva >= limiares.diasSemChuva ? cores.alerta : null,
                aoTocar: () => Navigator.of(context).pushNamed(Rotas.indicador, arguments: 'clima:chuva'),
                dicaAcessibilidade: 'Abre o detalhe do indicador de chuva',
              ),
              CartaoIndicador(
                titulo: 'Chuva em 30 dias',
                valor: '${formatarNumero(ind.chuva30d, casas: 0)} mm',
                detalhe: 'Acumulado observado',
                icone: Icons.water_drop_rounded,
              ),
              CartaoIndicador(
                titulo: 'Chuva prevista (7 dias)',
                valor: '${formatarNumero(ind.chuvaPrevista7d, casas: 0)} mm',
                detalhe: 'Previsão do modelo meteorológico',
                icone: Icons.umbrella_rounded,
              ),
              CartaoIndicador(
                titulo: 'Máxima prevista (3 dias)',
                valor: ind.tMaxPrevista3d == null ? 'Sem dado' : '${formatarNumero(ind.tMaxPrevista3d!, casas: 1)} °C',
                detalhe: 'Limiar de calor: ${formatarNumero(limiares.temperaturaCalor)} °C',
                icone: Icons.thermostat_rounded,
                cor: (ind.tMaxPrevista3d ?? 0) >= limiares.temperaturaCalor ? cores.alerta : null,
                aoTocar: () => Navigator.of(context).pushNamed(Rotas.indicador, arguments: 'clima:temperatura'),
                dicaAcessibilidade: 'Abre o detalhe do indicador de temperatura',
              ),
            ]),
            const TituloSecao('Chuva diária (mm)'),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Espaco.sm, Espaco.md, Espaco.md, Espaco.sm),
                child: GraficoBarras(
                  itens: [
                    for (final d in dias)
                      ItemBarra(formatarDiaMes(d.data), d.chuva ?? 0,
                          cor: d.previsto ? cores.destaque : tema.colorScheme.primary),
                  ],
                  mostrarRotulosACada: 7,
                  resumoAcessivel: 'Gráfico de chuva diária. Nos últimos 30 dias choveu '
                      '${formatarNumero(ind.chuva30d)} milímetros. Para os próximos 7 dias, a previsão é de '
                      '${formatarNumero(ind.chuvaPrevista7d)} milímetros.',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: Espaco.xs),
              child: Wrap(spacing: Espaco.md, children: [
                _Legenda(cor: tema.colorScheme.primary, texto: 'Observado'),
                _Legenda(cor: cores.destaque, texto: 'Previsto'),
              ]),
            ),
            const TituloSecao('Temperatura máxima (°C)'),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Espaco.sm, Espaco.md, Espaco.md, Espaco.sm),
                child: GraficoLinha(
                  serie: temperaturas,
                  sufixoY: '°',
                  cor: cores.alerta,
                  referencias: [LinhaReferencia(limiares.temperaturaCalor, 'Calor', cores.critico)],
                  resumoAcessivel: 'Gráfico da temperatura máxima diária, com observação e previsão. '
                      'A maior máxima prevista para os próximos 3 dias é '
                      '${ind.tMaxPrevista3d == null ? 'desconhecida' : '${formatarNumero(ind.tMaxPrevista3d!)} graus'}.',
                ),
              ),
            ),
            const SizedBox(height: Espaco.md),
            Text('Fonte: Open-Meteo (open-meteo.com), dados públicos e gratuitos. Um único ponto não representa '
                'toda a região dos mananciais.', style: tema.textTheme.bodySmall),
          ],
        ),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Clima local')), body: corpo);
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.cor, required this.texto});
  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(texto, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

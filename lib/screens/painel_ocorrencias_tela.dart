import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../core/rotas.dart';
import '../models/carga.dart';
import '../models/ocorrencia.dart';
import '../state/territorio_provider.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';
import '../widgets/graficos.dart';

/// Painel 3: ocorrências registradas pela comunidade (API AquaRede ou dados salvos).
class PainelOcorrenciasTela extends StatefulWidget {
  const PainelOcorrenciasTela({super.key});

  @override
  State<PainelOcorrenciasTela> createState() => _PainelOcorrenciasTelaState();
}

class _PainelOcorrenciasTelaState extends State<PainelOcorrenciasTela> {
  String? _prioridade; // estado local: filtro da lista

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioProvider>();
    final tema = Theme.of(context);
    final cores = context.coresAqua;

    Widget corpo;
    if (t.statusOcorrencias == StatusCarga.carregando && t.ocorrencias.isEmpty) {
      corpo = const Center(child: Carregando(mensagem: 'Buscando ocorrências...'));
    } else if (t.statusOcorrencias == StatusCarga.erro && t.ocorrencias.isEmpty) {
      corpo = Center(child: ErroView(mensagem: t.erroOcorrencias ?? 'Erro.', aoTentarDeNovo: t.carregarOcorrencias));
    } else if (t.ocorrencias.isEmpty) {
      corpo = Center(
        child: VazioView(
          mensagem: 'Nenhuma ocorrência registrada ainda.',
          acao: FilledButton(
            onPressed: () => Navigator.of(context).pushNamed(Rotas.registrar),
            child: const Text('Registrar a primeira'),
          ),
        ),
      );
    } else {
      final ind = t.indicadoresOcorrencias;
      final bairros = ind.porBairro7d.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
      final filtradas = _prioridade == null ? t.ocorrencias : t.ocorrencias.where((o) => o.prioridade == _prioridade).toList();

      corpo = RefreshIndicator(
        onRefresh: t.carregarOcorrencias,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Espaco.md, Espaco.md, Espaco.md, Espaco.xl),
          children: [
            if (t.ocorrenciasRemotas != null)
              FaixaOrigem(origem: t.ocorrenciasRemotas!.origem, atualizadoEm: t.ocorrenciasRemotas!.atualizadoEm),
            if (t.pendentes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: Espaco.sm),
                child: Text('${t.pendentes.length} ocorrência(s) salvas no aparelho aguardando envio.',
                    style: tema.textTheme.bodySmall?.copyWith(color: cores.alerta)),
              ),
            const SizedBox(height: Espaco.md),
            GradeCartoes(filhos: [
              CartaoIndicador(
                titulo: 'Relatos em 7 dias',
                valor: '${ind.ultimos7d.length}',
                detalhe: '${ind.total} no total',
                icone: Icons.campaign_rounded,
                aoTocar: () => Navigator.of(context).pushNamed(Rotas.indicador, arguments: 'ocorrencias:total'),
                dicaAcessibilidade: 'Abre o detalhe do indicador',
              ),
              CartaoIndicador(
                titulo: 'Prioridade alta (7 dias)',
                valor: '${ind.altaPrioridade7d}',
                detalhe: 'Contaminação, 24 h ou mais sem água, ou 50+ pessoas',
                icone: Icons.priority_high_rounded,
                cor: ind.altaPrioridade7d > 0 ? cores.critico : null,
              ),
              CartaoIndicador(
                titulo: 'Pessoas afetadas (7 dias)',
                valor: formatarNumero(ind.pessoasAfetadas7d),
                detalhe: 'Segundo os moradores',
                icone: Icons.groups_rounded,
              ),
              CartaoIndicador(
                titulo: 'Bairros com relatos',
                valor: '${ind.porBairro7d.length}',
                detalhe: 'Na última semana',
                icone: Icons.location_city_rounded,
              ),
            ]),
            const TituloSecao('Relatos por dia (14 dias)'),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Espaco.sm, Espaco.md, Espaco.md, Espaco.sm),
                child: GraficoBarras(
                  itens: [for (final p in ind.porDia14d) ItemBarra(formatarDiaMes(p.data), p.valor)],
                  mostrarRotulosACada: 3,
                  resumoAcessivel: 'Gráfico de relatos por dia nos últimos 14 dias. '
                      'Total no período: ${formatarNumero(ind.porDia14d.fold<double>(0, (s, p) => s + p.valor))}.',
                ),
              ),
            ),
            const TituloSecao('Por tipo (todas)'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Espaco.md),
                child: BarrasHorizontais(itens: [
                  for (final e in ind.porTipo.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                    ItemBarra(e.key, e.value.toDouble(), cor: e.key == 'Água contaminada' ? cores.critico : null),
                ]),
              ),
            ),
            const TituloSecao('Bairros com mais relatos (7 dias)'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Espaco.md),
                child: bairros.isEmpty
                    ? const Text('Nenhum relato na última semana.')
                    : BarrasHorizontais(itens: [
                        for (final e in bairros.take(6)) ItemBarra(e.key, e.value.length.toDouble()),
                      ]),
              ),
            ),
            TituloSecao(
              'Relatos recentes',
              acao: DropdownButton<String?>(
                value: _prioridade,
                hint: const Text('Prioridade'),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todas')),
                  DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                  DropdownMenuItem(value: 'Média', child: Text('Média')),
                  DropdownMenuItem(value: 'Baixa', child: Text('Baixa')),
                ],
                onChanged: (v) => setState(() => _prioridade = v),
              ),
            ),
            if (filtradas.isEmpty)
              const VazioView(mensagem: 'Nenhum relato com essa prioridade.')
            else
              for (final o in filtradas.take(30)) _ItemOcorrencia(ocorrencia: o),
          ],
        ),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Ocorrências')), body: corpo);
  }
}

class _ItemOcorrencia extends StatelessWidget {
  const _ItemOcorrencia({required this.ocorrencia});
  final Ocorrencia ocorrencia;

  @override
  Widget build(BuildContext context) {
    final o = ocorrencia;
    final cor = corDaPrioridade(context, o.prioridade);
    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.sm),
      child: Card(
        child: ListTile(
          leading: Icon(_icone(o.tipo), color: cor),
          title: Text('${o.bairro}: ${o.tipo}'),
          subtitle: Text([
            formatarDataHora(o.criadoEm),
            if (o.horasSemAgua > 0) '${formatarNumero(o.horasSemAgua)} h sem água',
            '${o.pessoasAfetadas} pessoa(s)',
            if (o.pendenteEnvio) 'aguardando envio',
            if (o.descricao.isNotEmpty) '\n${o.descricao}',
          ].join(' · ').replaceAll(' · \n', '\n')),
          trailing: SeloNivel(rotulo: o.prioridade, cor: cor),
          isThreeLine: o.descricao.isNotEmpty,
        ),
      ),
    );
  }

  IconData _icone(String tipo) {
    switch (tipo) {
      case 'Vazamento':
        return Icons.plumbing_rounded;
      case 'Água contaminada':
        return Icons.coronavirus_rounded;
      case 'Baixa pressão':
        return Icons.compress_rounded;
      default:
        return Icons.format_color_reset_rounded;
    }
  }
}

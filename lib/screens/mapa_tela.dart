import 'package:aquarede/models/alerta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../core/rotas.dart';
import '../logic/indicadores.dart';
import '../models/ocorrencia.dart';
import '../state/territorio_provider.dart';
import '../widgets/componentes.dart';

/// Mapa do território: reservatórios (gota) e ocorrências (círculo), coloridos pelo nível.
class MapaTela extends StatefulWidget {
  const MapaTela({super.key});

  @override
  State<MapaTela> createState() => _MapaTelaState();
}

class _MapaTelaState extends State<MapaTela> {
  bool _mostrarMananciais = true; // estado local: camadas visíveis
  bool _mostrarOcorrencias = true;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioProvider>();
    final mananciais = t.indicadoresMananciais;
    final ocorrencias =
        t.ocorrencias.where((o) => o.lat != null && o.lng != null).toList();
    final tema = Theme.of(context);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            Espaco.md, Espaco.sm, Espaco.md, Espaco.sm),
        child: Wrap(spacing: Espaco.sm, children: [
          FilterChip(
            label: Text('Reservatórios (${mananciais.length})'),
            selected: _mostrarMananciais,
            onSelected: (v) => setState(() => _mostrarMananciais = v),
          ),
          FilterChip(
            label: Text('Ocorrências (${ocorrencias.length})'),
            selected: _mostrarOcorrencias,
            onSelected: (v) => setState(() => _mostrarOcorrencias = v),
          ),
        ]),
      ),
      Expanded(
        child: Semantics(
          label:
              'Mapa da Grande São Paulo com ${mananciais.length} reservatórios e ${ocorrencias.length} ocorrências. '
              'A mesma informação está nos painéis e na lista de alertas.',
          child: FlutterMap(
            options: const MapOptions(
                initialCenter: LatLng(-23.60, -46.60), initialZoom: 9.5),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.fiap.aquarede',
              ),
              if (_mostrarMananciais)
                MarkerLayer(markers: [
                  for (final i in mananciais)
                    Marker(
                      point: LatLng(i.sistema.lat, i.sistema.lng),
                      width: 44,
                      height: 44,
                      child: _Marcador(
                        icone: Icons.water_drop_rounded,
                        cor: corDoNivel(context, i.faixaAtual),
                        rotulo:
                            'Reservatório ${i.sistema.nome}, ${formatarPorcentagem(i.atual)}, faixa ${i.faixaAtual.rotulo}',
                        aoTocar: () => _detalheManancial(context, i),
                      ),
                    ),
                ]),
              if (_mostrarOcorrencias)
                MarkerLayer(markers: [
                  for (final o in ocorrencias)
                    Marker(
                      point: LatLng(o.lat!, o.lng!),
                      width: 32,
                      height: 32,
                      child: _Marcador(
                        icone: Icons.circle,
                        tamanho: 18,
                        cor: corDaPrioridade(context, o.prioridade),
                        rotulo:
                            'Ocorrência em ${o.bairro}: ${o.tipo}, prioridade ${o.prioridade}',
                        aoTocar: () => _detalheOcorrencia(context, o),
                      ),
                    ),
                ]),
              const RichAttributionWidget(attributions: [
                const TextSourceAttribution('OpenStreetMap contributors')
              ]),
            ],
          ),
        ),
      ),
      Container(
        width: double.infinity,
        color: tema.colorScheme.surface,
        padding: const EdgeInsets.all(Espaco.sm),
        child: Text(
          'Cores: verde Normal/Baixa, amarelo Atenção, laranja Alerta/Média, vermelho Crítico/Alta. '
          'Sem internet, o fundo do mapa pode não carregar, mas os pontos continuam aparecendo.',
          style: tema.textTheme.bodySmall,
        ),
      ),
    ]);
  }

  void _detalheManancial(BuildContext context, IndicadoresManancial i) {
    showModalBottomSheet<void>(
      context: context,
      builder: (contexto) => Padding(
        padding: const EdgeInsets.all(Espaco.lg),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(i.sistema.nome,
                        style: Theme.of(contexto).textTheme.titleLarge)),
                SeloNivel.nivel(contexto, i.faixaAtual),
              ]),
              const SizedBox(height: Espaco.sm),
              Text(
                  'Volume ${formatarPorcentagem(i.atual)} · ${formatarSinal(i.tendencia30d)} p.p. em 30 dias'),
              Text(
                  'Projeção em 30 dias: ${formatarPorcentagem(i.previsao30d)}'),
              const SizedBox(height: Espaco.md),
              FilledButton(
                onPressed: () {
                  Navigator.of(contexto).pop();
                  Navigator.of(context)
                      .pushNamed(Rotas.mananciais, arguments: i.sistema.nome);
                },
                child: const Text('Abrir painel do reservatório'),
              ),
            ]),
      ),
    );
  }

  void _detalheOcorrencia(BuildContext context, Ocorrencia o) {
    showModalBottomSheet<void>(
      context: context,
      builder: (contexto) => Padding(
        padding: const EdgeInsets.all(Espaco.lg),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${o.bairro}: ${o.tipo}',
                  style: Theme.of(contexto).textTheme.titleLarge),
              const SizedBox(height: Espaco.sm),
              Text(
                  'Prioridade ${o.prioridade} · ${o.pessoasAfetadas} pessoa(s) · ${formatarDataHora(o.criadoEm)}'),
              if (o.descricao.isNotEmpty) Text(o.descricao),
              const SizedBox(height: Espaco.md),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(contexto).pop();
                  Navigator.of(context).pushNamed(Rotas.ocorrencias);
                },
                child: const Text('Ver painel de ocorrências'),
              ),
            ]),
      ),
    );
  }
}

class _Marcador extends StatelessWidget {
  const _Marcador(
      {required this.icone,
      required this.cor,
      required this.rotulo,
      required this.aoTocar,
      this.tamanho = 34});
  final IconData icone;
  final Color cor;
  final String rotulo;
  final VoidCallback aoTocar;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: rotulo,
      child: GestureDetector(
        onTap: aoTocar,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: cor, width: 3),
          ),
          child: Icon(icone, color: cor, size: tamanho),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../models/alerta.dart';
import '../models/carga.dart';

/// Cor associada a cada nível de alerta, conforme o tema ativo.
Color corDoNivel(BuildContext context, NivelAlerta nivel) {
  final c = context.coresAqua;
  switch (nivel) {
    case NivelAlerta.normal:
      return c.normal;
    case NivelAlerta.atencao:
      return c.atencao;
    case NivelAlerta.alerta:
      return c.alerta;
    case NivelAlerta.critico:
      return c.critico;
  }
}

Color corDaPrioridade(BuildContext context, String prioridade) {
  switch (prioridade) {
    case 'Alta':
      return context.coresAqua.critico;
    case 'Média':
      return context.coresAqua.alerta;
    default:
      return context.coresAqua.normal;
  }
}

/// Selo com o nível de alerta. A informação não depende só da cor: o texto sempre aparece.
class SeloNivel extends StatelessWidget {
  const SeloNivel({super.key, required this.rotulo, required this.cor, this.icone});
  final String rotulo;
  final Color cor;
  final IconData? icone;

  factory SeloNivel.nivel(BuildContext context, NivelAlerta nivel) =>
      SeloNivel(rotulo: nivel.rotulo, cor: corDoNivel(context, nivel), icone: _iconeNivel(nivel));

  static IconData _iconeNivel(NivelAlerta n) {
    switch (n) {
      case NivelAlerta.normal:
        return Icons.check_circle_rounded;
      case NivelAlerta.atencao:
        return Icons.visibility_rounded;
      case NivelAlerta.alerta:
        return Icons.warning_amber_rounded;
      case NivelAlerta.critico:
        return Icons.report_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withAlpha(36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cor, width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icone != null) ...[Icon(icone, size: 16, color: cor), const SizedBox(width: 4)],
        Text(rotulo, style: TextStyle(color: cor, fontWeight: FontWeight.w800, fontSize: 13)),
      ]),
    );
  }
}

/// Cartão de indicador com valor em destaque, usado em todos os painéis.
class CartaoIndicador extends StatelessWidget {
  const CartaoIndicador({
    super.key,
    required this.titulo,
    required this.valor,
    this.detalhe,
    this.icone,
    this.cor,
    this.aoTocar,
    this.dicaAcessibilidade,
  });

  final String titulo;
  final String valor;
  final String? detalhe;
  final IconData? icone;
  final Color? cor;
  final VoidCallback? aoTocar;
  final String? dicaAcessibilidade;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final corValor = cor ?? tema.colorScheme.onSurface;
    return Semantics(
      button: aoTocar != null,
      label: '$titulo: $valor${detalhe != null ? '. $detalhe' : ''}',
      hint: dicaAcessibilidade,
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.all(Espaco.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (icone != null) ...[Icon(icone, size: 20, color: corValor), const SizedBox(width: Espaco.sm)],
                Expanded(child: Text(titulo, style: tema.textTheme.labelLarge)),
                if (aoTocar != null) Icon(Icons.chevron_right_rounded, color: tema.colorScheme.outline),
              ]),
              const SizedBox(height: Espaco.sm),
              Text(valor, style: tema.textTheme.headlineSmall?.copyWith(color: corValor)),
              if (detalhe != null) ...[
                const SizedBox(height: Espaco.xs),
                Text(detalhe!, style: tema.textTheme.bodySmall),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Grade responsiva: 2 colunas em telas estreitas, 4 em telas largas.
class GradeCartoes extends StatelessWidget {
  const GradeCartoes({super.key, required this.filhos});
  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, restricoes) {
      final colunas = restricoes.maxWidth >= 700 ? 4 : 2;
      final largura = (restricoes.maxWidth - Espaco.sm * (colunas - 1)) / colunas;
      return Wrap(
        spacing: Espaco.sm,
        runSpacing: Espaco.sm,
        children: [for (final f in filhos) SizedBox(width: largura, child: f)],
      );
    });
  }
}

class TituloSecao extends StatelessWidget {
  const TituloSecao(this.texto, {super.key, this.acao});
  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Espaco.lg, bottom: Espaco.sm),
      child: Row(children: [
        Expanded(child: Semantics(header: true, child: Text(texto, style: Theme.of(context).textTheme.titleMedium))),
        if (acao != null) acao!,
      ]),
    );
  }
}

/// Aviso fixo exigido pelo desafio: alertas apoiam, mas não substituem, a decisão humana.
class AvisoDecisaoHumana extends StatelessWidget {
  const AvisoDecisaoHumana({super.key, this.compacto = false});
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Espaco.md),
      decoration: BoxDecoration(
        color: tema.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(Espaco.raio),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.person_search_rounded, color: tema.colorScheme.onPrimaryContainer),
        const SizedBox(width: Espaco.sm),
        Expanded(
          child: Text(
            compacto
                ? 'Os alertas apoiam, mas não substituem, a decisão humana.'
                : 'Os alertas são recomendações geradas a partir dos dados. Eles apoiam, mas não substituem, a decisão '
                    'humana: nenhuma ação, como restrição de abastecimento, é tomada automaticamente.',
            style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onPrimaryContainer),
          ),
        ),
      ]),
    );
  }
}

/// Mostra de onde vieram os dados (ao vivo, cache offline, simulado ou exemplo) e quando.
class FaixaOrigem extends StatelessWidget {
  const FaixaOrigem({super.key, required this.origem, required this.atualizadoEm});
  final OrigemDados origem;
  final DateTime atualizadoEm;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final offline = origem == OrigemDados.cache || origem == OrigemDados.exemplo;
    final cor = offline ? context.coresAqua.alerta : tema.colorScheme.outline;
    final icone = switch (origem) {
      OrigemDados.aoVivo => Icons.wifi_rounded,
      OrigemDados.cache => Icons.wifi_off_rounded,
      OrigemDados.simulado => Icons.science_rounded,
      OrigemDados.exemplo => Icons.wifi_off_rounded,
    };
    return Semantics(
      label: '${origem.rotulo}. Atualizado em ${formatarDataHora(atualizadoEm)}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Espaco.xs),
        child: Row(children: [
          Icon(icone, size: 16, color: cor),
          const SizedBox(width: Espaco.xs),
          Expanded(
            child: Text('${origem.rotulo} · ${formatarDataHora(atualizadoEm)}',
                style: tema.textTheme.bodySmall?.copyWith(color: cor)),
          ),
        ]),
      ),
    );
  }
}

/// Barra horizontal de confiança (0 a 1) com rótulo textual.
class BarraConfianca extends StatelessWidget {
  const BarraConfianca({super.key, required this.valor, required this.rotulo});
  final double valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Semantics(
      label: 'Confiança $rotulo, ${(valor * 100).round()} por cento',
      excludeSemantics: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Confiança $rotulo', style: tema.textTheme.titleSmall),
          const Spacer(),
          Text('${(valor * 100).round()}%', style: tema.textTheme.titleSmall),
        ]),
        const SizedBox(height: Espaco.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: valor, minHeight: 10),
        ),
      ]),
    );
  }
}

import '../models/alerta.dart';
import '../models/clima.dart';
import '../models/limiares.dart';
import '../models/manancial.dart';
import '../models/ocorrencia.dart';
import 'previsao.dart';

const int horizontePrevisao = 30; // dias

NivelAlerta faixaVolume(double volume, Limiares l) {
  if (volume < l.volumeCritico) return NivelAlerta.critico;
  if (volume < l.volumeAlerta) return NivelAlerta.alerta;
  if (volume < l.volumeAtencao) return NivelAlerta.atencao;
  return NivelAlerta.normal;
}

/// Indicadores de um sistema produtor.
class IndicadoresManancial {
  IndicadoresManancial._({
    required this.sistema,
    required this.atual,
    required this.tendencia30d,
    required this.previsao30d,
    required this.margemPrevisao,
    required this.r2,
    required this.autonomiaDias,
    required this.faixaAtual,
    required this.faixaPrevista,
  });

  final SistemaManancial sistema;
  final double atual; // %
  final double tendencia30d; // p.p. nos últimos 30 dias
  final double previsao30d; // % projetado
  final double margemPrevisao; // ± p.p. (aprox. 80%)
  final double r2;
  final int? autonomiaDias; // dias até a faixa crítica, se estiver caindo
  final NivelAlerta faixaAtual;
  final NivelAlerta faixaPrevista;

  factory IndicadoresManancial.calcular(SistemaManancial s, Limiares l) {
    final valores = s.serie.map((p) => p.valor).toList();
    final janela = valores.length >= 30 ? valores.sublist(valores.length - 30) : valores;
    final tendencia = regressaoLinear(janela);
    final atual = valores.last;
    final anterior = valores.length > 30 ? valores[valores.length - 31] : valores.first;
    final previsao = tendencia.projetar(horizontePrevisao).clamp(0.0, 100.0).toDouble();
    int? autonomia;
    if (atual <= l.volumeCritico) {
      autonomia = 0;
    } else if (tendencia.inclinacao < 0) {
      autonomia = ((atual - l.volumeCritico) / -tendencia.inclinacao).round();
    }
    return IndicadoresManancial._(
      sistema: s,
      atual: atual,
      tendencia30d: atual - anterior,
      previsao30d: previsao,
      margemPrevisao: 1.28 * tendencia.desvioResiduo + 0.02 * horizontePrevisao,
      r2: tendencia.r2,
      autonomiaDias: autonomia,
      faixaAtual: faixaVolume(atual, l),
      faixaPrevista: faixaVolume(previsao, l),
    );
  }
}

/// Indicadores de clima a partir da série diária (observado + previsto).
class IndicadoresClima {
  IndicadoresClima._({
    required this.chuva30d,
    required this.diasSemChuva,
    required this.chuvaPrevista7d,
    required this.tMaxPrevista3d,
    required this.diasObservados,
    required this.diasPrevistos,
  });

  final double chuva30d; // mm observados nos últimos 30 dias
  final int diasSemChuva; // dias seguidos sem chuva relevante (< 1 mm) até hoje
  final double chuvaPrevista7d; // mm
  final double? tMaxPrevista3d; // maior máxima prevista nos próximos 3 dias
  final int diasObservados;
  final int diasPrevistos;

  static const double chuvaRelevante = 1.0; // mm

  factory IndicadoresClima.calcular(List<DiaClima> dias) {
    final observados = dias.where((d) => !d.previsto).toList();
    final previstos = dias.where((d) => d.previsto).toList();
    final ultimos30 = observados.length > 30 ? observados.sublist(observados.length - 30) : observados;
    final chuva30 = ultimos30.fold<double>(0, (s, d) => s + (d.chuva ?? 0));
    var seguidos = 0;
    for (final d in observados.reversed) {
      if (d.chuva == null) break;
      if (d.chuva! >= chuvaRelevante) break;
      seguidos++;
    }
    final prev7 = previstos.take(7).fold<double>(0, (s, d) => s + (d.chuva ?? 0));
    final maximas = previstos.take(3).map((d) => d.tMax).whereType<double>();
    return IndicadoresClima._(
      chuva30d: chuva30,
      diasSemChuva: seguidos,
      chuvaPrevista7d: prev7,
      tMaxPrevista3d: maximas.isEmpty ? null : maximas.reduce((a, b) => a > b ? a : b),
      diasObservados: observados.length,
      diasPrevistos: previstos.length,
    );
  }
}

/// Indicadores das ocorrências comunitárias.
class IndicadoresOcorrencias {
  IndicadoresOcorrencias._({
    required this.total,
    required this.ultimos7d,
    required this.pessoasAfetadas7d,
    required this.altaPrioridade7d,
    required this.porTipo,
    required this.porBairro7d,
    required this.porDia14d,
  });

  final int total;
  final List<Ocorrencia> ultimos7d;
  final int pessoasAfetadas7d;
  final int altaPrioridade7d;
  final Map<String, int> porTipo;
  final Map<String, List<Ocorrencia>> porBairro7d;
  final List<PontoSerie> porDia14d;

  factory IndicadoresOcorrencias.calcular(List<Ocorrencia> todas, DateTime agora) {
    final limite = agora.subtract(const Duration(days: 7));
    final recentes = todas.where((o) => o.criadoEm.isAfter(limite)).toList();
    final porTipo = <String, int>{};
    for (final o in todas) {
      porTipo[o.tipo] = (porTipo[o.tipo] ?? 0) + 1;
    }
    final porBairro = <String, List<Ocorrencia>>{};
    for (final o in recentes) {
      porBairro.putIfAbsent(o.bairro, () => []).add(o);
    }
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dias = <PontoSerie>[];
    for (var i = 13; i >= 0; i--) {
      final dia = hoje.subtract(Duration(days: i));
      final qtd = todas.where((o) {
        final c = o.criadoEm;
        return c.year == dia.year && c.month == dia.month && c.day == dia.day;
      }).length;
      dias.add(PontoSerie(dia, qtd.toDouble()));
    }
    return IndicadoresOcorrencias._(
      total: todas.length,
      ultimos7d: recentes,
      pessoasAfetadas7d: recentes.fold(0, (s, o) => s + o.pessoasAfetadas),
      altaPrioridade7d: recentes.where((o) => o.prioridade == 'Alta').length,
      porTipo: porTipo,
      porBairro7d: porBairro,
      porDia14d: dias,
    );
  }
}

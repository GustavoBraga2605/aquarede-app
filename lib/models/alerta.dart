/// Níveis de criticidade, do menor para o maior.
enum NivelAlerta { normal, atencao, alerta, critico }

extension NivelAlertaTexto on NivelAlerta {
  String get rotulo {
    switch (this) {
      case NivelAlerta.normal:
        return 'Normal';
      case NivelAlerta.atencao:
        return 'Atenção';
      case NivelAlerta.alerta:
        return 'Alerta';
      case NivelAlerta.critico:
        return 'Crítico';
    }
  }
}

NivelAlerta maiorNivel(NivelAlerta a, NivelAlerta b) => a.index >= b.index ? a : b;

enum CategoriaAlerta { mananciais, clima, ocorrencias }

extension CategoriaAlertaTexto on CategoriaAlerta {
  String get rotulo {
    switch (this) {
      case CategoriaAlerta.mananciais:
        return 'Mananciais';
      case CategoriaAlerta.clima:
        return 'Clima';
      case CategoriaAlerta.ocorrencias:
        return 'Ocorrências';
    }
  }
}

/// Alerta preditivo ou baseado em regra. Sempre traz evidência, confiança e limitações.
class Alerta {
  const Alerta({
    required this.id,
    required this.categoria,
    required this.nivel,
    required this.titulo,
    required this.resumo,
    required this.evidencias,
    required this.confianca,
    required this.limitacoes,
    required this.naoConfiavelQuando,
    required this.fonte,
    required this.geradoEm,
    this.regiao,
    this.indicadorChave,
    this.pessoasAlcancadas = 0,
  });

  /// Identificador estável (usado para guardar a avaliação humana).
  final String id;
  final CategoriaAlerta categoria;
  final NivelAlerta nivel;
  final String titulo;
  final String resumo;
  final List<String> evidencias;

  /// Confiança de 0 a 1.
  final double confianca;
  final List<String> limitacoes;
  final String naoConfiavelQuando;
  final String fonte;
  final DateTime geradoEm;
  final String? regiao;

  /// Chave do indicador relacionado, para abrir a tela de detalhe do indicador.
  final String? indicadorChave;

  /// Pessoas potencialmente beneficiadas pelo aviso antecipado (indicador social).
  final int pessoasAlcancadas;

  String get confiancaRotulo {
    if (confianca >= 0.75) return 'Alta';
    if (confianca >= 0.55) return 'Média';
    return 'Baixa';
  }
}

/// Decisão registrada por um gestor humano sobre um alerta.
enum DecisaoHumana { emAnalise, encaminhado, descartado }

extension DecisaoHumanaTexto on DecisaoHumana {
  String get rotulo {
    switch (this) {
      case DecisaoHumana.emAnalise:
        return 'Em análise';
      case DecisaoHumana.encaminhado:
        return 'Encaminhado para ação';
      case DecisaoHumana.descartado:
        return 'Descartado após avaliação';
    }
  }
}

class AvaliacaoHumana {
  const AvaliacaoHumana({required this.alertaId, required this.decisao, required this.justificativa, required this.data});
  final String alertaId;
  final DecisaoHumana decisao;
  final String justificativa;
  final DateTime data;

  Map<String, dynamic> toJson() => {
        'alertaId': alertaId,
        'decisao': decisao.name,
        'justificativa': justificativa,
        'data': data.toIso8601String(),
      };

  factory AvaliacaoHumana.fromJson(Map<String, dynamic> json) => AvaliacaoHumana(
        alertaId: json['alertaId'] as String,
        decisao: DecisaoHumana.values.firstWhere((d) => d.name == json['decisao'], orElse: () => DecisaoHumana.emAnalise),
        justificativa: (json['justificativa'] ?? '').toString(),
        data: DateTime.tryParse((json['data'] ?? '').toString()) ?? DateTime.now(),
      );
}

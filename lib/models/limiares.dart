/// Limiares de alerta configuráveis pelo gestor na tela de Ajustes.
class Limiares {
  const Limiares({
    this.volumeAtencao = 60,
    this.volumeAlerta = 40,
    this.volumeCritico = 30,
    this.diasSemChuva = 10,
    this.temperaturaCalor = 31,
    this.ocorrenciasPorBairro = 3,
  });

  final double volumeAtencao; // % abaixo do qual o sistema sai da faixa Normal
  final double volumeAlerta; // %
  final double volumeCritico; // %
  final int diasSemChuva; // dias seguidos sem chuva relevante
  final double temperaturaCalor; // °C máxima prevista
  final int ocorrenciasPorBairro; // ocorrências em 7 dias

  Limiares copyWith({
    double? volumeAtencao,
    double? volumeAlerta,
    double? volumeCritico,
    int? diasSemChuva,
    double? temperaturaCalor,
    int? ocorrenciasPorBairro,
  }) {
    return Limiares(
      volumeAtencao: volumeAtencao ?? this.volumeAtencao,
      volumeAlerta: volumeAlerta ?? this.volumeAlerta,
      volumeCritico: volumeCritico ?? this.volumeCritico,
      diasSemChuva: diasSemChuva ?? this.diasSemChuva,
      temperaturaCalor: temperaturaCalor ?? this.temperaturaCalor,
      ocorrenciasPorBairro: ocorrenciasPorBairro ?? this.ocorrenciasPorBairro,
    );
  }

  Map<String, dynamic> toJson() => {
        'volumeAtencao': volumeAtencao,
        'volumeAlerta': volumeAlerta,
        'volumeCritico': volumeCritico,
        'diasSemChuva': diasSemChuva,
        'temperaturaCalor': temperaturaCalor,
        'ocorrenciasPorBairro': ocorrenciasPorBairro,
      };

  factory Limiares.fromJson(Map<String, dynamic> json) {
    const padrao = Limiares();
    return Limiares(
      volumeAtencao: (json['volumeAtencao'] as num?)?.toDouble() ?? padrao.volumeAtencao,
      volumeAlerta: (json['volumeAlerta'] as num?)?.toDouble() ?? padrao.volumeAlerta,
      volumeCritico: (json['volumeCritico'] as num?)?.toDouble() ?? padrao.volumeCritico,
      diasSemChuva: (json['diasSemChuva'] as num?)?.toInt() ?? padrao.diasSemChuva,
      temperaturaCalor: (json['temperaturaCalor'] as num?)?.toDouble() ?? padrao.temperaturaCalor,
      ocorrenciasPorBairro: (json['ocorrenciasPorBairro'] as num?)?.toInt() ?? padrao.ocorrenciasPorBairro,
    );
  }
}

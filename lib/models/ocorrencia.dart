/// Ocorrência comunitária registrada por um morador (mesmo formato da API AquaRede em Node/Express).
class Ocorrencia {
  Ocorrencia({
    required this.id,
    required this.bairro,
    required this.tipo,
    required this.horasSemAgua,
    required this.pessoasAfetadas,
    required this.descricao,
    required this.prioridade,
    required this.lat,
    required this.lng,
    required this.criadoEm,
    this.pendenteEnvio = false,
  });

  final String id;
  final String bairro;
  final String tipo;
  final double horasSemAgua;
  final int pessoasAfetadas;
  final String descricao;
  final String prioridade;
  final double? lat;
  final double? lng;
  final DateTime criadoEm;

  /// true quando foi registrada sem conexão e ainda não chegou ao servidor.
  final bool pendenteEnvio;

  factory Ocorrencia.fromJson(Map<String, dynamic> json) {
    return Ocorrencia(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      bairro: (json['bairro'] ?? '').toString(),
      tipo: (json['tipo'] ?? '').toString(),
      horasSemAgua: (json['horasSemAgua'] as num?)?.toDouble() ?? 0,
      pessoasAfetadas: (json['pessoasAfetadas'] as num?)?.toInt() ?? 0,
      descricao: (json['descricao'] ?? '').toString(),
      prioridade: (json['prioridade'] ?? 'Baixa').toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      criadoEm: DateTime.tryParse((json['criadoEm'] ?? '').toString())?.toLocal() ?? DateTime.now(),
      pendenteEnvio: json['pendenteEnvio'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'bairro': bairro,
        'tipo': tipo,
        'horasSemAgua': horasSemAgua,
        'pessoasAfetadas': pessoasAfetadas,
        'descricao': descricao,
        'prioridade': prioridade,
        'lat': lat,
        'lng': lng,
        'criadoEm': criadoEm.toUtc().toIso8601String(),
        'pendenteEnvio': pendenteEnvio,
      };

  /// Corpo enviado no POST /api/ocorrencias (o servidor calcula prioridade e coordenadas).
  Map<String, dynamic> paraEnvio() => {
        'bairro': bairro,
        'tipo': tipo,
        'horasSemAgua': horasSemAgua,
        'pessoasAfetadas': pessoasAfetadas,
        'descricao': descricao,
      };
}

/// Ponto de uma série temporal diária.
class PontoSerie {
  const PontoSerie(this.data, this.valor);
  final DateTime data;
  final double valor;
}

/// Sistema produtor de água (reservatório) com sua série de volume armazenado (%).
class SistemaManancial {
  const SistemaManancial({required this.nome, required this.lat, required this.lng, required this.serie});
  final String nome;
  final double lat;
  final double lng;
  final List<PontoSerie> serie;

  double get volumeAtual => serie.last.valor;
  DateTime get ultimaLeitura => serie.last.data;
}

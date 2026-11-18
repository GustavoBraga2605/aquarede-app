/// Dados diários de clima (observados nos últimos dias e previstos para os próximos).
class DiaClima {
  const DiaClima({required this.data, required this.chuva, required this.tMax, required this.tMin, required this.previsto});
  final DateTime data;
  final double? chuva; // mm
  final double? tMax; // °C
  final double? tMin; // °C
  final bool previsto;
}

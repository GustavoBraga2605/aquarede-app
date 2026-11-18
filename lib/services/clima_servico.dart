import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/carga.dart';
import '../models/clima.dart';
import 'armazenamento_local.dart';

/// Busca chuva e temperatura reais na API pública Open-Meteo (sem chave de acesso).
/// Guarda a última resposta para o app continuar útil sem conexão.
class ClimaServico {
  ClimaServico(this._local, {http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final ArmazenamentoLocal _local;
  final http.Client _cliente;

  // Centro de São Paulo. Últimos 30 dias observados + 7 dias de previsão.
  static final Uri _url = Uri.parse(
    'https://api.open-meteo.com/v1/forecast?latitude=-23.55&longitude=-46.63'
    '&daily=precipitation_sum,temperature_2m_max,temperature_2m_min'
    '&past_days=30&forecast_days=7&timezone=America%2FSao_Paulo',
  );

  Future<Carga<List<DiaClima>>> buscar() async {
    try {
      final resposta = await _cliente.get(_url).timeout(const Duration(seconds: 8));
      if (resposta.statusCode != 200) {
        throw Exception('Open-Meteo respondeu ${resposta.statusCode}');
      }
      final corpo = jsonDecode(resposta.body) as Map<String, dynamic>;
      final dias = _converter(corpo);
      final agora = DateTime.now();
      await _local.salvarJson(Chaves.cacheClima, {'salvoEm': agora.toIso8601String(), 'corpo': corpo});
      return Carga(dados: dias, origem: OrigemDados.aoVivo, atualizadoEm: agora);
    } catch (_) {
      final cache = _local.json(Chaves.cacheClima);
      if (cache is Map<String, dynamic> && cache['corpo'] is Map<String, dynamic>) {
        return Carga(
          dados: _converter(cache['corpo'] as Map<String, dynamic>),
          origem: OrigemDados.cache,
          atualizadoEm: DateTime.tryParse(cache['salvoEm'].toString()) ?? DateTime.now(),
        );
      }
      rethrow;
    }
  }

  List<DiaClima> _converter(Map<String, dynamic> corpo) {
    final daily = corpo['daily'] as Map<String, dynamic>;
    final datas = (daily['time'] as List).cast<String>();
    final chuva = daily['precipitation_sum'] as List;
    final maxima = daily['temperature_2m_max'] as List;
    final minima = daily['temperature_2m_min'] as List;
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    return [
      for (var i = 0; i < datas.length; i++)
        DiaClima(
          data: DateTime.parse(datas[i]),
          chuva: (chuva[i] as num?)?.toDouble(),
          tMax: (maxima[i] as num?)?.toDouble(),
          tMin: (minima[i] as num?)?.toDouble(),
          // O dia de hoje ainda está em andamento: é tratado como previsão
          previsto: !DateTime.parse(datas[i]).isBefore(inicioHoje),
        ),
    ];
  }
}

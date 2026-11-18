import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/carga.dart';
import '../models/manancial.dart';

/// Serviço SIMULADO de mananciais. Lê uma série sintética de 365 dias embutida no app
/// e desloca as datas para terminar ontem, como se fosse um serviço atualizado diariamente.
/// Em produção, seria trocado pela série real (ex.: exportada pelo notebook de Data Science).
class MananciaisServico {
  Future<Carga<List<SistemaManancial>>> buscar() async {
    await Future<void>.delayed(const Duration(milliseconds: 600)); // simula a latência de rede
    final bruto = jsonDecode(await rootBundle.loadString('assets/dados/mananciais.json')) as Map<String, dynamic>;
    final hoje = DateTime.now();
    final ontem = DateTime(hoje.year, hoje.month, hoje.day).subtract(const Duration(days: 1));
    final sistemas = (bruto['sistemas'] as List).map((s) {
      final mapa = s as Map<String, dynamic>;
      final volumes = (mapa['volumes'] as List).map((v) => (v as num).toDouble()).toList();
      final inicio = ontem.subtract(Duration(days: volumes.length - 1));
      return SistemaManancial(
        nome: mapa['nome'] as String,
        lat: (mapa['lat'] as num).toDouble(),
        lng: (mapa['lng'] as num).toDouble(),
        serie: [for (var i = 0; i < volumes.length; i++) PontoSerie(inicio.add(Duration(days: i)), volumes[i])],
      );
    }).toList();
    return Carga(dados: sistemas, origem: OrigemDados.simulado, atualizadoEm: DateTime.now());
  }
}

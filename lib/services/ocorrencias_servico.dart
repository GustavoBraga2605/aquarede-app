import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../models/carga.dart';
import '../models/ocorrencia.dart';
import 'armazenamento_local.dart';

/// Resultado do envio de uma ocorrência ao servidor.
class ResultadoEnvio {
  const ResultadoEnvio({required this.sucesso, this.ocorrencia, this.erros = const []});
  final bool sucesso;
  final Ocorrencia? ocorrencia;
  final List<String> erros; // erros de validação devolvidos pelo servidor (HTTP 400)
}

/// Consome a API do AquaRede (Node.js + Express + MongoDB, projeto de Application Development).
/// Ordem de fallback: servidor → cache local → dados de exemplo embutidos.
class OcorrenciasServico {
  OcorrenciasServico(this._local, {http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final ArmazenamentoLocal _local;
  final http.Client _cliente;

  Future<Carga<List<Ocorrencia>>> buscar(String urlBase) async {
    try {
      final resposta = await _cliente
          .get(Uri.parse('$urlBase/api/ocorrencias'))
          .timeout(const Duration(seconds: 5));
      if (resposta.statusCode != 200) throw Exception('Servidor respondeu ${resposta.statusCode}');
      final lista = (jsonDecode(resposta.body) as List).cast<Map<String, dynamic>>();
      final agora = DateTime.now();
      await _local.salvarJson(Chaves.cacheOcorrencias, {'salvoEm': agora.toIso8601String(), 'itens': lista});
      return Carga(dados: lista.map(Ocorrencia.fromJson).toList(), origem: OrigemDados.aoVivo, atualizadoEm: agora);
    } catch (_) {
      final cache = _local.json(Chaves.cacheOcorrencias);
      if (cache is Map<String, dynamic> && cache['itens'] is List) {
        return Carga(
          dados: (cache['itens'] as List).cast<Map<String, dynamic>>().map(Ocorrencia.fromJson).toList(),
          origem: OrigemDados.cache,
          atualizadoEm: DateTime.tryParse(cache['salvoEm'].toString()) ?? DateTime.now(),
        );
      }
      return Carga(dados: await _exemplos(), origem: OrigemDados.exemplo, atualizadoEm: DateTime.now());
    }
  }

  Future<ResultadoEnvio> enviar(String urlBase, Ocorrencia ocorrencia) async {
    try {
      final resposta = await _cliente
          .post(
            Uri.parse('$urlBase/api/ocorrencias'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(ocorrencia.paraEnvio()),
          )
          .timeout(const Duration(seconds: 5));
      final corpo = jsonDecode(resposta.body) as Map<String, dynamic>;
      if (resposta.statusCode == 201) {
        return ResultadoEnvio(
          sucesso: true,
          ocorrencia: Ocorrencia.fromJson(corpo['ocorrencia'] as Map<String, dynamic>),
        );
      }
      if (resposta.statusCode == 400) {
        return ResultadoEnvio(sucesso: false, erros: (corpo['erros'] as List? ?? []).cast<String>());
      }
      return const ResultadoEnvio(sucesso: false);
    } catch (_) {
      return const ResultadoEnvio(sucesso: false); // sem conexão
    }
  }

  Future<List<Ocorrencia>> _exemplos() async {
    final bruto = jsonDecode(await rootBundle.loadString('assets/dados/ocorrencias_exemplo.json')) as Map<String, dynamic>;
    final agora = DateTime.now();
    return (bruto['ocorrencias'] as List).cast<Map<String, dynamic>>().map((json) {
      final dias = (json['diasAtras'] as num).toInt();
      return Ocorrencia.fromJson({
        ...json,
        'criadoEm': agora.subtract(Duration(days: dias, hours: dias * 3 % 11)).toUtc().toIso8601String(),
      });
    }).toList();
  }
}

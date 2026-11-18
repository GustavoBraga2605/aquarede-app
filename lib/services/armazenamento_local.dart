import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistência local simples (shared_preferences) com leitura e escrita em JSON.
class ArmazenamentoLocal {
  ArmazenamentoLocal._(this._prefs);
  final SharedPreferences _prefs;

  static Future<ArmazenamentoLocal> abrir() async => ArmazenamentoLocal._(await SharedPreferences.getInstance());

  String? texto(String chave) => _prefs.getString(chave);
  Future<void> salvarTexto(String chave, String valor) => _prefs.setString(chave, valor);

  bool? booleano(String chave) => _prefs.getBool(chave);
  Future<void> salvarBooleano(String chave, bool valor) => _prefs.setBool(chave, valor);

  double? decimal(String chave) => _prefs.getDouble(chave);
  Future<void> salvarDecimal(String chave, double valor) => _prefs.setDouble(chave, valor);

  dynamic json(String chave) {
    final bruto = _prefs.getString(chave);
    if (bruto == null) return null;
    try {
      return jsonDecode(bruto);
    } catch (_) {
      return null;
    }
  }

  Future<void> salvarJson(String chave, Object valor) => _prefs.setString(chave, jsonEncode(valor));

  Future<void> remover(String chave) => _prefs.remove(chave);

  Future<void> limparTudo() => _prefs.clear();
}

/// Chaves usadas no armazenamento local.
class Chaves {
  static const consentimento = 'consentimento';
  static const perfil = 'perfil';
  static const tema = 'tema';
  static const escalaFonte = 'escala_fonte';
  static const limiares = 'limiares';
  static const urlServidor = 'url_servidor';
  static const cacheClima = 'cache_clima';
  static const cacheOcorrencias = 'cache_ocorrencias';
  static const ocorrenciasPendentes = 'ocorrencias_pendentes';
  static const avaliacoes = 'avaliacoes';
}

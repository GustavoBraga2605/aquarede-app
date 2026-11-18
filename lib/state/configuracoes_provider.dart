import 'package:flutter/foundation.dart';

import '../core/app_theme.dart';
import '../models/limiares.dart';
import '../services/armazenamento_local.dart';

enum Perfil { cidadao, gestor }

/// Estado GLOBAL de configurações: consentimento, perfil, tema, fonte, limiares e servidor.
/// Tudo é persistido localmente e compartilhado por várias telas.
class ConfiguracoesProvider extends ChangeNotifier {
  ConfiguracoesProvider(this._local) {
    _carregar();
  }

  final ArmazenamentoLocal _local;

  static const urlPadrao = 'http://10.0.2.2:3000'; // localhost do computador visto pelo emulador Android

  bool _consentimento = false;
  Perfil _perfil = Perfil.cidadao;
  ModoTema _tema = ModoTema.claro;
  double _escalaFonte = 1.0;
  Limiares _limiares = const Limiares();
  String _urlServidor = urlPadrao;

  bool get consentimento => _consentimento;
  Perfil get perfil => _perfil;
  bool get ehGestor => _perfil == Perfil.gestor;
  ModoTema get tema => _tema;
  double get escalaFonte => _escalaFonte;
  Limiares get limiares => _limiares;
  String get urlServidor => _urlServidor;

  void _carregar() {
    _consentimento = _local.booleano(Chaves.consentimento) ?? false;
    _perfil = Perfil.values.firstWhere((p) => p.name == _local.texto(Chaves.perfil), orElse: () => Perfil.cidadao);
    _tema = ModoTema.values.firstWhere((t) => t.name == _local.texto(Chaves.tema), orElse: () => ModoTema.claro);
    _escalaFonte = _local.decimal(Chaves.escalaFonte) ?? 1.0;
    final json = _local.json(Chaves.limiares);
    if (json is Map<String, dynamic>) _limiares = Limiares.fromJson(json);
    _urlServidor = _local.texto(Chaves.urlServidor) ?? urlPadrao;
  }

  Future<void> darConsentimento() async {
    _consentimento = true;
    await _local.salvarBooleano(Chaves.consentimento, true);
    notifyListeners();
  }

  /// Revoga o consentimento e apaga todos os dados guardados no aparelho.
  Future<void> revogarConsentimentoEApagar() async {
    await _local.limparTudo();
    _consentimento = false;
    _perfil = Perfil.cidadao;
    _tema = ModoTema.claro;
    _escalaFonte = 1.0;
    _limiares = const Limiares();
    _urlServidor = urlPadrao;
    notifyListeners();
  }

  Future<void> definirPerfil(Perfil perfil) async {
    _perfil = perfil;
    await _local.salvarTexto(Chaves.perfil, perfil.name);
    notifyListeners();
  }

  Future<void> definirTema(ModoTema tema) async {
    _tema = tema;
    await _local.salvarTexto(Chaves.tema, tema.name);
    notifyListeners();
  }

  Future<void> definirEscalaFonte(double escala) async {
    _escalaFonte = escala;
    await _local.salvarDecimal(Chaves.escalaFonte, escala);
    notifyListeners();
  }

  Future<void> salvarLimiares(Limiares limiares) async {
    _limiares = limiares;
    await _local.salvarJson(Chaves.limiares, limiares.toJson());
    notifyListeners();
  }

  Future<void> salvarUrlServidor(String url) async {
    _urlServidor = url.trim().replaceAll(RegExp(r'/+$'), '');
    await _local.salvarTexto(Chaves.urlServidor, _urlServidor);
    notifyListeners();
  }
}

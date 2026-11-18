import 'package:flutter/foundation.dart';

import '../logic/bairros.dart';
import '../logic/indicadores.dart';
import '../logic/motor_alertas.dart';
import '../models/alerta.dart';
import '../models/carga.dart';
import '../models/clima.dart';
import '../models/manancial.dart';
import '../models/ocorrencia.dart';
import '../services/armazenamento_local.dart';
import '../services/clima_servico.dart';
import '../services/mananciais_servico.dart';
import '../services/ocorrencias_servico.dart';
import 'configuracoes_provider.dart';

/// Resultado do registro de uma ocorrência feito pelo morador.
enum ResultadoRegistro { enviada, salvaOffline, recusada }

/// Estado GLOBAL dos dados do território: carrega as três fontes, controla carregamento e erro,
/// guarda ocorrências pendentes e avaliações humanas, e calcula os alertas.
class TerritorioProvider extends ChangeNotifier {
  TerritorioProvider({
    required this.configuracoes,
    required ArmazenamentoLocal local,
    required ClimaServico clima,
    required MananciaisServico mananciais,
    required OcorrenciasServico ocorrencias,
  })  : _local = local,
        _climaServico = clima,
        _mananciaisServico = mananciais,
        _ocorrenciasServico = ocorrencias {
    _carregarDadosLocais();
    configuracoes.addListener(_aoMudarConfiguracoes);
  }

  final ConfiguracoesProvider configuracoes;
  final ArmazenamentoLocal _local;
  final ClimaServico _climaServico;
  final MananciaisServico _mananciaisServico;
  final OcorrenciasServico _ocorrenciasServico;

  // Mananciais
  StatusCarga statusMananciais = StatusCarga.carregando;
  Carga<List<SistemaManancial>>? mananciais;
  String? erroMananciais;

  // Clima
  StatusCarga statusClima = StatusCarga.carregando;
  Carga<List<DiaClima>>? clima;
  String? erroClima;

  // Ocorrências
  StatusCarga statusOcorrencias = StatusCarga.carregando;
  Carga<List<Ocorrencia>>? ocorrenciasRemotas;
  String? erroOcorrencias;

  List<Ocorrencia> _pendentes = [];
  Map<String, AvaliacaoHumana> _avaliacoes = {};

  List<Ocorrencia> get pendentes => List.unmodifiable(_pendentes);

  /// Ocorrências do servidor (ou cache/exemplo) somadas às registradas offline neste aparelho.
  List<Ocorrencia> get ocorrencias {
    final lista = [..._pendentes, ...?ocorrenciasRemotas?.dados];
    lista.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    return lista;
  }

  bool get carregandoAlgo =>
      statusMananciais == StatusCarga.carregando ||
      statusClima == StatusCarga.carregando ||
      statusOcorrencias == StatusCarga.carregando;

  List<Alerta>? _alertasCache;

  /// Alertas calculados com os limiares atuais (recalculados quando dados ou limiares mudam).
  List<Alerta> get alertas {
    return _alertasCache ??= gerarAlertas(
      sistemas: mananciais?.dados ?? const [],
      clima: clima?.dados ?? const [],
      ocorrencias: ocorrencias,
      limiares: configuracoes.limiares,
      agora: DateTime.now(),
      mananciaisSinteticos: mananciais?.origem == OrigemDados.simulado,
    );
  }

  Alerta? alertaPorId(String id) {
    for (final a in alertas) {
      if (a.id == id) return a;
    }
    return null;
  }

  AvaliacaoHumana? avaliacaoDe(String alertaId) => _avaliacoes[alertaId];

  /// Indicador de benefício social: pessoas afetadas em bairros cujos alertas
  /// já foram avaliados por um gestor e encaminhados para ação.
  int get pessoasComAlertaEncaminhado => alertas
      .where((a) => _avaliacoes[a.id]?.decisao == DecisaoHumana.encaminhado)
      .fold(0, (s, a) => s + a.pessoasAlcancadas);

  /// Pessoas afetadas com relatos que geraram algum alerta (avisadas antecipadamente aos gestores).
  int get pessoasEmAlertasAtivos => alertas.fold(0, (s, a) => s + a.pessoasAlcancadas);

  int get alertasAvaliados => alertas.where((a) => _avaliacoes.containsKey(a.id)).length;

  List<IndicadoresManancial> get indicadoresMananciais =>
      (mananciais?.dados ?? const <SistemaManancial>[])
          .where((s) => s.serie.length >= 30)
          .map((s) => IndicadoresManancial.calcular(s, configuracoes.limiares))
          .toList();

  IndicadoresClima? get indicadoresClima {
    final dias = clima?.dados;
    return dias == null || dias.isEmpty ? null : IndicadoresClima.calcular(dias);
  }

  IndicadoresOcorrencias get indicadoresOcorrencias => IndicadoresOcorrencias.calcular(ocorrencias, DateTime.now());

  void _aoMudarConfiguracoes() {
    _alertasCache = null;
    notifyListeners();
  }

  void _atualizar() {
    _alertasCache = null;
    notifyListeners();
  }

  void _carregarDadosLocais() {
    final pendentes = _local.json(Chaves.ocorrenciasPendentes);
    if (pendentes is List) {
      _pendentes = pendentes.cast<Map<String, dynamic>>().map(Ocorrencia.fromJson).toList();
    }
    final avaliacoes = _local.json(Chaves.avaliacoes);
    if (avaliacoes is List) {
      _avaliacoes = {
        for (final a in avaliacoes.cast<Map<String, dynamic>>().map(AvaliacaoHumana.fromJson)) a.alertaId: a,
      };
    }
  }

  Future<void> carregarTudo() async {
    await Future.wait([carregarMananciais(), carregarClima(), carregarOcorrencias()]);
  }

  Future<void> carregarMananciais() async {
    statusMananciais = StatusCarga.carregando;
    notifyListeners();
    try {
      mananciais = await _mananciaisServico.buscar();
      statusMananciais = StatusCarga.pronto;
      erroMananciais = null;
    } catch (e) {
      statusMananciais = StatusCarga.erro;
      erroMananciais = 'Não foi possível carregar os dados dos mananciais.';
    }
    _atualizar();
  }

  Future<void> carregarClima() async {
    statusClima = StatusCarga.carregando;
    notifyListeners();
    try {
      clima = await _climaServico.buscar();
      statusClima = StatusCarga.pronto;
      erroClima = null;
    } catch (e) {
      statusClima = StatusCarga.erro;
      erroClima = 'Sem conexão e sem dados de clima salvos. Conecte-se à internet e tente de novo.';
    }
    _atualizar();
  }

  Future<void> carregarOcorrencias() async {
    statusOcorrencias = StatusCarga.carregando;
    notifyListeners();
    try {
      ocorrenciasRemotas = await _ocorrenciasServico.buscar(configuracoes.urlServidor);
      statusOcorrencias = StatusCarga.pronto;
      erroOcorrencias = null;
    } catch (e) {
      statusOcorrencias = StatusCarga.erro;
      erroOcorrencias = 'Não foi possível carregar as ocorrências.';
    }
    _atualizar();
  }

  /// Registra a ocorrência: tenta enviar ao servidor; sem conexão, guarda no aparelho para enviar depois.
  Future<(ResultadoRegistro, List<String>)> registrarOcorrencia({
    required String bairro,
    required String tipo,
    required double horasSemAgua,
    required int pessoasAfetadas,
    required String descricao,
  }) async {
    final coordenada = bairrosAquaRede[bairro];
    final nova = Ocorrencia(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      bairro: bairro,
      tipo: tipo,
      horasSemAgua: horasSemAgua,
      pessoasAfetadas: pessoasAfetadas,
      descricao: descricao,
      prioridade: calcularPrioridade(tipo: tipo, horasSemAgua: horasSemAgua, pessoasAfetadas: pessoasAfetadas),
      lat: coordenada?[0],
      lng: coordenada?[1],
      criadoEm: DateTime.now(),
      pendenteEnvio: true,
    );

    final resultado = await _ocorrenciasServico.enviar(configuracoes.urlServidor, nova);
    if (resultado.sucesso) {
      await carregarOcorrencias();
      return (ResultadoRegistro.enviada, const <String>[]);
    }
    if (resultado.erros.isNotEmpty) {
      return (ResultadoRegistro.recusada, resultado.erros);
    }
    _pendentes = [nova, ..._pendentes];
    await _salvarPendentes();
    _atualizar();
    return (ResultadoRegistro.salvaOffline, const <String>[]);
  }

  /// Tenta enviar as ocorrências guardadas offline. Retorna quantas foram enviadas.
  Future<int> sincronizarPendentes() async {
    var enviadas = 0;
    final restantes = <Ocorrencia>[];
    for (final o in _pendentes) {
      final r = await _ocorrenciasServico.enviar(configuracoes.urlServidor, o);
      if (r.sucesso) {
        enviadas++;
      } else {
        restantes.add(o);
      }
    }
    _pendentes = restantes;
    await _salvarPendentes();
    if (enviadas > 0) await carregarOcorrencias();
    _atualizar();
    return enviadas;
  }

  Future<void> _salvarPendentes() =>
      _local.salvarJson(Chaves.ocorrenciasPendentes, _pendentes.map((o) => o.toJson()).toList());

  /// Registra a decisão humana sobre um alerta (somente perfil gestor).
  Future<void> avaliarAlerta(String alertaId, DecisaoHumana decisao, String justificativa) async {
    _avaliacoes[alertaId] = AvaliacaoHumana(
      alertaId: alertaId,
      decisao: decisao,
      justificativa: justificativa.trim(),
      data: DateTime.now(),
    );
    await _local.salvarJson(Chaves.avaliacoes, _avaliacoes.values.map((a) => a.toJson()).toList());
    _atualizar();
  }

  /// Usado ao revogar o consentimento: limpa os dados em memória.
  void limparDadosLocais() {
    _pendentes = [];
    _avaliacoes = {};
    _atualizar();
  }

  @override
  void dispose() {
    configuracoes.removeListener(_aoMudarConfiguracoes);
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../core/rotas.dart';
import '../logic/validadores.dart';
import '../models/limiares.dart';
import '../state/configuracoes_provider.dart';
import '../state/territorio_provider.dart';
import '../widgets/componentes.dart';

/// Ajustes: perfil, acessibilidade, limiares de alerta (formulário), servidor e privacidade.
class AjustesTela extends StatelessWidget {
  const AjustesTela({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfiguracoesProvider>();
    final t = context.watch<TerritorioProvider>();
    final tema = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(Espaco.md),
      children: [
        const TituloSecao('Perfil'),
        SegmentedButton<Perfil>(
          segments: const [
            ButtonSegment(value: Perfil.cidadao, label: Text('Cidadão'), icon: Icon(Icons.person_rounded)),
            ButtonSegment(value: Perfil.gestor, label: Text('Gestor'), icon: Icon(Icons.badge_rounded)),
          ],
          selected: {config.perfil},
          onSelectionChanged: (s) => config.definirPerfil(s.first),
        ),
        const SizedBox(height: Espaco.xs),
        Text(
          config.ehGestor
              ? 'Como gestor, você pode registrar a decisão humana sobre cada alerta e ajustar os limiares.'
              : 'Como cidadão, você acompanha os painéis e registra ocorrências do seu bairro.',
          style: tema.textTheme.bodySmall,
        ),
        const TituloSecao('Aparência e acessibilidade'),
        Wrap(spacing: Espaco.sm, runSpacing: Espaco.sm, children: [
          for (final (modo, rotulo, icone) in const [
            (ModoTema.claro, 'Claro', Icons.light_mode_rounded),
            (ModoTema.escuro, 'Escuro', Icons.dark_mode_rounded),
            (ModoTema.altoContraste, 'Alto contraste', Icons.contrast_rounded),
          ])
            ChoiceChip(
              avatar: Icon(icone, size: 18),
              label: Text(rotulo),
              selected: config.tema == modo,
              onSelected: (_) => config.definirTema(modo),
            ),
        ]),
        const SizedBox(height: Espaco.md),
        Text('Tamanho do texto: ${formatarNumero(config.escalaFonte * 100)}%', style: tema.textTheme.titleSmall),
        Slider(
          value: config.escalaFonte,
          min: 1.0,
          max: 1.6,
          divisions: 6,
          label: '${formatarNumero(config.escalaFonte * 100)}%',
          semanticFormatterCallback: (v) => 'Tamanho do texto ${formatarNumero(v * 100)} por cento',
          onChanged: config.definirEscalaFonte,
        ),
        TituloSecao('Limiares de alerta', acao: config.ehGestor ? null : const Text('Somente gestor')),
        _FormLimiares(habilitado: config.ehGestor, inicial: config.limiares),
        const TituloSecao('Servidor AquaRede'),
        _FormServidor(inicial: config.urlServidor),
        const SizedBox(height: Espaco.sm),
        OutlinedButton.icon(
          onPressed: t.pendentes.isEmpty
              ? null
              : () async {
                  final enviadas = await context.read<TerritorioProvider>().sincronizarPendentes();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(enviadas > 0
                        ? '$enviadas ocorrência(s) enviada(s).'
                        : 'Ainda sem conexão com o servidor. Tente mais tarde.'),
                  ));
                },
          icon: const Icon(Icons.cloud_upload_rounded),
          label: Text('Enviar pendentes (${t.pendentes.length})'),
        ),
        const TituloSecao('Privacidade'),
        const Text(
          'As ocorrências são anônimas: o app não coleta nome, telefone, e-mail, localização do aparelho nem '
          'endereço exato. Preferências, limiares, avaliações e ocorrências sem conexão ficam salvos apenas neste aparelho.',
        ),
        const SizedBox(height: Espaco.sm),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: context.coresAqua.critico),
          onPressed: () => _revogar(context),
          icon: const Icon(Icons.delete_forever_rounded),
          label: const Text('Revogar consentimento e apagar dados'),
        ),
        const SizedBox(height: Espaco.xl),
        Text('AquaRede 1.0 · Global Solution 2026.2 · FIAP', style: tema.textTheme.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: Espaco.lg),
      ],
    );
  }

  Future<void> _revogar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Apagar dados locais?'),
        content: const Text('Isso apaga preferências, limiares, avaliações e ocorrências que ainda não foram enviadas. '
            'Você voltará para a tela de consentimento.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Apagar')),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    context.read<TerritorioProvider>().limparDadosLocais();
    await context.read<ConfiguracoesProvider>().revogarConsentimentoEApagar();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Rotas.consentimento, (_) => false);
  }
}

/// Formulário de limiares com validação (faixas e ordem entre os valores).
class _FormLimiares extends StatefulWidget {
  const _FormLimiares({required this.habilitado, required this.inicial});
  final bool habilitado;
  final Limiares inicial;

  @override
  State<_FormLimiares> createState() => _FormLimiaresState();
}

class _FormLimiaresState extends State<_FormLimiares> {
  final _form = GlobalKey<FormState>();
  late final _atencao = TextEditingController(text: _txt(widget.inicial.volumeAtencao));
  late final _alerta = TextEditingController(text: _txt(widget.inicial.volumeAlerta));
  late final _critico = TextEditingController(text: _txt(widget.inicial.volumeCritico));
  late final _diasSeco = TextEditingController(text: '${widget.inicial.diasSemChuva}');
  late final _calor = TextEditingController(text: _txt(widget.inicial.temperaturaCalor));
  late final _ocorrencias = TextEditingController(text: '${widget.inicial.ocorrenciasPorBairro}');
  String? _erroOrdem;

  static String _txt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  static double _num(TextEditingController c) => double.parse(c.text.trim().replaceAll(',', '.'));

  void _restaurar(Limiares l) {
    _atencao.text = _txt(l.volumeAtencao);
    _alerta.text = _txt(l.volumeAlerta);
    _critico.text = _txt(l.volumeCritico);
    _diasSeco.text = '${l.diasSemChuva}';
    _calor.text = _txt(l.temperaturaCalor);
    _ocorrencias.text = '${l.ocorrenciasPorBairro}';
  }

  @override
  void dispose() {
    for (final c in [_atencao, _alerta, _critico, _diasSeco, _calor, _ocorrencias]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _erroOrdem = null);
    if (!_form.currentState!.validate()) return;
    final novos = Limiares(
      volumeAtencao: _num(_atencao),
      volumeAlerta: _num(_alerta),
      volumeCritico: _num(_critico),
      diasSemChuva: int.parse(_diasSeco.text.trim()),
      temperaturaCalor: _num(_calor),
      ocorrenciasPorBairro: int.parse(_ocorrencias.text.trim()),
    );
    final erro = Validadores.ordemLimiares(novos);
    if (erro != null) {
      setState(() => _erroOrdem = erro);
      return;
    }
    await context.read<ConfiguracoesProvider>().salvarLimiares(novos);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Limiares salvos. Os alertas foram recalculados.')),
    );
  }

  Widget _campo(TextEditingController c, String rotulo, String sufixo, String? Function(String?) validar) {
    return TextFormField(
      controller: c,
      enabled: widget.habilitado,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: rotulo, suffixText: sufixo),
      validator: validar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Espaco.md),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Volume dos reservatórios', style: tema.textTheme.titleSmall),
            const SizedBox(height: Espaco.sm),
            _campo(_atencao, 'Atenção abaixo de', '%', (v) => Validadores.numeroEntre(v, 10, 95)),
            const SizedBox(height: Espaco.sm),
            _campo(_alerta, 'Alerta abaixo de', '%', (v) => Validadores.numeroEntre(v, 5, 90)),
            const SizedBox(height: Espaco.sm),
            _campo(_critico, 'Crítico abaixo de', '%', (v) => Validadores.numeroEntre(v, 1, 80)),
            const SizedBox(height: Espaco.md),
            Text('Clima e comunidade', style: tema.textTheme.titleSmall),
            const SizedBox(height: Espaco.sm),
            _campo(_diasSeco, 'Dias seguidos sem chuva', 'dias', (v) => Validadores.numeroEntre(v, 3, 60, inteiro: true)),
            const SizedBox(height: Espaco.sm),
            _campo(_calor, 'Temperatura de calor', '°C', (v) => Validadores.numeroEntre(v, 25, 45)),
            const SizedBox(height: Espaco.sm),
            _campo(_ocorrencias, 'Ocorrências por bairro em 7 dias', 'relatos',
                (v) => Validadores.numeroEntre(v, 1, 50, inteiro: true)),
            if (_erroOrdem != null)
              Padding(
                padding: const EdgeInsets.only(top: Espaco.sm),
                child: Text(_erroOrdem!, style: TextStyle(color: tema.colorScheme.error)),
              ),
            const SizedBox(height: Espaco.md),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.habilitado ? () => _restaurar(const Limiares()) : null,
                  child: const Text('Restaurar padrão'),
                ),
              ),
              const SizedBox(width: Espaco.sm),
              Expanded(
                child: FilledButton(
                  onPressed: widget.habilitado ? _salvar : null,
                  child: const Text('Salvar'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _FormServidor extends StatefulWidget {
  const _FormServidor({required this.inicial});
  final String inicial;

  @override
  State<_FormServidor> createState() => _FormServidorState();
}

class _FormServidorState extends State<_FormServidor> {
  final _form = GlobalKey<FormState>();
  late final _url = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: TextFormField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Endereço da API',
              helperText: 'Emulador Android: http://10.0.2.2:3000',
            ),
            validator: Validadores.urlServidor,
          ),
        ),
        const SizedBox(width: Espaco.sm),
        IconButton.filled(
          tooltip: 'Salvar endereço e recarregar ocorrências',
          onPressed: () async {
            if (!_form.currentState!.validate()) return;
            final territorio = context.read<TerritorioProvider>();
            await context.read<ConfiguracoesProvider>().salvarUrlServidor(_url.text);
            await territorio.carregarOcorrencias();
          },
          icon: const Icon(Icons.check_rounded),
        ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/rotas.dart';
import 'screens/alerta_detalhe_tela.dart';
import 'screens/consentimento_tela.dart';
import 'screens/indicador_detalhe_tela.dart';
import 'screens/painel_clima_tela.dart';
import 'screens/painel_mananciais_tela.dart';
import 'screens/painel_ocorrencias_tela.dart';
import 'screens/registrar_ocorrencia_tela.dart';
import 'screens/shell_tela.dart';
import 'state/configuracoes_provider.dart';

class AquaRedeApp extends StatelessWidget {
  const AquaRedeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfiguracoesProvider>();
    return MaterialApp(
      title: 'AquaRede',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.construir(config.tema),
      // Tamanho da fonte escolhido no app, somado ao ajuste de acessibilidade do sistema
      builder: (context, filho) {
        final midia = MediaQuery.of(context);
        final escalaSistema = midia.textScaler.scale(1);
        return MediaQuery(
          data: midia.copyWith(textScaler: TextScaler.linear((escalaSistema * config.escalaFonte).clamp(0.8, 2.2))),
          child: filho!,
        );
      },
      initialRoute: config.consentimento ? Rotas.inicio : Rotas.consentimento,
      onGenerateRoute: gerarRota,
    );
  }
}

/// Rotas nomeadas com passagem de parâmetros (ex.: id do alerta, chave do indicador).
Route<dynamic> gerarRota(RouteSettings settings) {
  Widget tela;
  switch (settings.name) {
    case Rotas.consentimento:
      tela = const ConsentimentoTela();
    case Rotas.inicio:
      tela = const ShellTela();
    case Rotas.mananciais:
      tela = PainelMananciaisTela(sistemaInicial: settings.arguments as String?);
    case Rotas.clima:
      tela = const PainelClimaTela();
    case Rotas.ocorrencias:
      tela = const PainelOcorrenciasTela();
    case Rotas.indicador:
      tela = IndicadorDetalheTela(chave: settings.arguments as String);
    case Rotas.alerta:
      tela = AlertaDetalheTela(alertaId: settings.arguments as String);
    case Rotas.registrar:
      tela = RegistrarOcorrenciaTela(bairroInicial: settings.arguments as String?);
    default:
      tela = const _RotaInexistente();
  }
  return MaterialPageRoute(builder: (_) => tela, settings: settings);
}

class _RotaInexistente extends StatelessWidget {
  const _RotaInexistente();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: const Center(child: Text('Essa tela não existe.')),
    );
  }
}

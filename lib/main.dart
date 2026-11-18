import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/armazenamento_local.dart';
import 'services/clima_servico.dart';
import 'services/mananciais_servico.dart';
import 'services/ocorrencias_servico.dart';
import 'state/configuracoes_provider.dart';
import 'state/territorio_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final local = await ArmazenamentoLocal.abrir();
  final configuracoes = ConfiguracoesProvider(local);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: configuracoes),
        ChangeNotifierProvider(
          create: (_) => TerritorioProvider(
            configuracoes: configuracoes,
            local: local,
            clima: ClimaServico(local),
            mananciais: MananciaisServico(),
            ocorrencias: OcorrenciasServico(local),
          )..carregarTudo(),
        ),
      ],
      child: const AquaRedeApp(),
    ),
  );
}

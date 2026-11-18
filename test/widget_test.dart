import 'package:aquarede/core/app_theme.dart';
import 'package:aquarede/models/alerta.dart';
import 'package:aquarede/widgets/componentes.dart';
import 'package:aquarede/widgets/estados.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget emApp(Widget filho, {ModoTema tema = ModoTema.claro}) =>
    MaterialApp(theme: AppTheme.construir(tema), home: Scaffold(body: filho));

void main() {
  testWidgets('selo de nível mostra o texto, não só a cor', (tester) async {
    await tester.pumpWidget(emApp(Builder(builder: (c) => SeloNivel.nivel(c, NivelAlerta.critico))));
    expect(find.text('Crítico'), findsOneWidget);
  });

  testWidgets('tela de erro oferece tentar de novo', (tester) async {
    var tentou = false;
    await tester.pumpWidget(emApp(ErroView(mensagem: 'Falhou', aoTentarDeNovo: () => tentou = true)));
    await tester.tap(find.text('Tentar de novo'));
    expect(tentou, isTrue);
  });

  testWidgets('aviso de decisão humana aparece no tema de alto contraste', (tester) async {
    await tester.pumpWidget(emApp(const AvisoDecisaoHumana(), tema: ModoTema.altoContraste));
    expect(find.textContaining('não substituem'), findsOneWidget);
  });
}

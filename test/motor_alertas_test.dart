import 'package:aquarede/logic/motor_alertas.dart';
import 'package:aquarede/models/alerta.dart';
import 'package:aquarede/models/clima.dart';
import 'package:aquarede/models/limiares.dart';
import 'package:aquarede/models/manancial.dart';
import 'package:aquarede/models/ocorrencia.dart';
import 'package:flutter_test/flutter_test.dart';

final agora = DateTime(2026, 11, 10, 12);

SistemaManancial sistema(String nome, double inicio, double fim, {int dias = 60}) {
  final primeiro = agora.subtract(Duration(days: dias));
  return SistemaManancial(
    nome: nome,
    lat: 0,
    lng: 0,
    serie: [
      for (var i = 0; i < dias; i++) PontoSerie(primeiro.add(Duration(days: i)), inicio + (fim - inicio) * i / (dias - 1)),
    ],
  );
}

Ocorrencia ocorrencia(String bairro, String tipo, {int diasAtras = 1, int pessoas = 5}) => Ocorrencia(
      id: '$bairro-$tipo-$diasAtras',
      bairro: bairro,
      tipo: tipo,
      horasSemAgua: 10,
      pessoasAfetadas: pessoas,
      descricao: '',
      prioridade: 'Média',
      lat: 0,
      lng: 0,
      criadoEm: agora.subtract(Duration(days: diasAtras)),
    );

List<Alerta> gerar({
  List<SistemaManancial> sistemas = const [],
  List<DiaClima> clima = const [],
  List<Ocorrencia> ocorrencias = const [],
  Limiares limiares = const Limiares(),
}) =>
    gerarAlertas(sistemas: sistemas, clima: clima, ocorrencias: ocorrencias, limiares: limiares, agora: agora);

void main() {
  group('Mananciais', () {
    test('sistema estável acima de 60% não gera alerta', () {
      expect(gerar(sistemas: [sistema('Cheio', 80, 80)]), isEmpty);
    });

    test('queda que cruza o limiar gera alerta de piora com evidências e limitações', () {
      final alertas = gerar(sistemas: [sistema('Caindo', 50, 41)]);
      expect(alertas, hasLength(1));
      final a = alertas.first;
      expect(a.categoria, CategoriaAlerta.mananciais);
      expect(a.nivel.index, greaterThanOrEqualTo(NivelAlerta.alerta.index));
      expect(a.evidencias, isNotEmpty);
      expect(a.limitacoes, isNotEmpty);
      expect(a.confianca, inInclusiveRange(0, 1));
    });

    test('volume abaixo do limiar crítico gera alerta Crítico', () {
      final alertas = gerar(sistemas: [sistema('Seco', 25, 22)]);
      expect(alertas.single.nivel, NivelAlerta.critico);
    });

    test('limiares configurados mudam o resultado', () {
      final s = sistema('Meio', 55, 55);
      expect(gerar(sistemas: [s]).single.nivel, NivelAlerta.atencao);
      expect(gerar(sistemas: [s], limiares: const Limiares(volumeAtencao: 50, volumeAlerta: 40, volumeCritico: 30)), isEmpty);
    });

    test('séries curtas (menos de 30 dias) são ignoradas', () {
      expect(gerar(sistemas: [sistema('Curto', 20, 10, dias: 10)]), isEmpty);
    });
  });

  group('Ocorrências', () {
    test('bairro com ocorrências acima do limiar gera alerta', () {
      final lista = [for (var i = 0; i < 3; i++) ocorrencia('Grajaú', 'Falta de água', diasAtras: i + 1)];
      final a = gerar(ocorrencias: lista).single;
      expect(a.nivel, NivelAlerta.alerta);
      expect(a.pessoasAlcancadas, 15);
    });

    test('um relato de água contaminada já gera alerta', () {
      expect(gerar(ocorrencias: [ocorrencia('Perus', 'Água contaminada')]).single.nivel, NivelAlerta.alerta);
    });

    test('relatos com mais de 7 dias não contam', () {
      final antigos = [for (var i = 0; i < 5; i++) ocorrencia('Perus', 'Falta de água', diasAtras: 10 + i)];
      expect(gerar(ocorrencias: antigos), isEmpty);
    });
  });

  group('Clima', () {
    List<DiaClima> dias({required int secos, double chuvaPrevista = 0, double tMax = 25}) => [
          for (var i = secos; i > 0; i--)
            DiaClima(data: agora.subtract(Duration(days: i)), chuva: 0, tMax: 25, tMin: 15, previsto: false),
          for (var i = 0; i < 7; i++)
            DiaClima(data: agora.add(Duration(days: i)), chuva: chuvaPrevista / 7, tMax: tMax, tMin: 18, previsto: true),
        ];

    test('estiagem acima do limiar gera alerta', () {
      expect(gerar(clima: dias(secos: 12)).any((a) => a.id == 'clima-estiagem'), isTrue);
    });

    test('poucos dias secos não geram alerta', () {
      expect(gerar(clima: dias(secos: 4)), isEmpty);
    });

    test('calor forte sem chuva gera alerta de consumo', () {
      expect(gerar(clima: dias(secos: 2, tMax: 34)).any((a) => a.id == 'clima-calor'), isTrue);
    });
  });

  test('alertas vêm ordenados do mais grave para o menos grave', () {
    final alertas = gerar(
      sistemas: [sistema('Meio', 55, 55), sistema('Seco', 25, 22)],
      ocorrencias: [ocorrencia('Perus', 'Água contaminada')],
    );
    for (var i = 1; i < alertas.length; i++) {
      expect(alertas[i - 1].nivel.index, greaterThanOrEqualTo(alertas[i].nivel.index));
    }
  });
}

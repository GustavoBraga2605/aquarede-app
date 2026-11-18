import 'package:aquarede/logic/bairros.dart';
import 'package:aquarede/logic/previsao.dart';
import 'package:aquarede/logic/validadores.dart';
import 'package:aquarede/models/limiares.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formulário de ocorrência', () {
    test('bairro precisa estar na lista', () {
      expect(Validadores.bairro(null), isNotNull);
      expect(Validadores.bairro('Moema'), isNotNull);
      expect(Validadores.bairro('Grajaú'), isNull);
    });

    test('horas sem água aceita vírgula e respeita a faixa', () {
      expect(Validadores.horasSemAgua(''), isNotNull);
      expect(Validadores.horasSemAgua('abc'), isNotNull);
      expect(Validadores.horasSemAgua('-1'), isNotNull);
      expect(Validadores.horasSemAgua('12,5'), isNull);
    });

    test('pessoas afetadas precisa ser inteiro entre 1 e 10.000', () {
      expect(Validadores.pessoasAfetadas('0'), isNotNull);
      expect(Validadores.pessoasAfetadas('2.5'), isNotNull);
      expect(Validadores.pessoasAfetadas('4'), isNull);
    });

    test('descrição bloqueia dados pessoais', () {
      expect(Validadores.descricao('Me liga no 11 98765-4321'), isNotNull);
      expect(Validadores.descricao('fulano@email.com'), isNotNull);
      expect(Validadores.descricao('Cano estourado na esquina'), isNull);
    });
  });

  test('limiares de volume precisam estar em ordem', () {
    expect(Validadores.ordemLimiares(const Limiares()), isNull);
    expect(Validadores.ordemLimiares(const Limiares(volumeAtencao: 30, volumeAlerta: 40, volumeCritico: 20)), isNotNull);
  });

  test('prioridade segue a mesma regra do servidor', () {
    expect(calcularPrioridade(tipo: 'Água contaminada', horasSemAgua: 0, pessoasAfetadas: 1), 'Alta');
    expect(calcularPrioridade(tipo: 'Falta de água', horasSemAgua: 30, pessoasAfetadas: 1), 'Alta');
    expect(calcularPrioridade(tipo: 'Vazamento', horasSemAgua: 0, pessoasAfetadas: 1), 'Média');
    expect(calcularPrioridade(tipo: 'Baixa pressão', horasSemAgua: 2, pessoasAfetadas: 1), 'Baixa');
  });

  test('regressão linear recupera uma reta conhecida', () {
    final t = regressaoLinear([10, 12, 14, 16, 18]);
    expect(t.inclinacao, closeTo(2, 1e-9));
    expect(t.r2, closeTo(1, 1e-9));
    expect(t.projetar(5), closeTo(28, 1e-9));
  });
}

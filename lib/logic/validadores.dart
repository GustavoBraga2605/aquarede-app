import '../models/limiares.dart';
import 'bairros.dart';

/// Validações dos formulários. Retornam a mensagem de erro, ou null quando o valor é válido.
class Validadores {
  static String? bairro(String? valor) {
    if (valor == null || valor.isEmpty) return 'Escolha o bairro.';
    if (!bairrosAquaRede.containsKey(valor)) return 'Escolha um bairro da lista.';
    return null;
  }

  static String? tipo(String? valor) {
    if (valor == null || valor.isEmpty) return 'Escolha o tipo de ocorrência.';
    if (!tiposOcorrencia.contains(valor)) return 'Tipo de ocorrência inválido.';
    return null;
  }

  static String? horasSemAgua(String? valor) {
    final texto = (valor ?? '').trim().replaceAll(',', '.');
    if (texto.isEmpty) return 'Informe as horas sem água (use 0 se não faltou).';
    final numero = double.tryParse(texto);
    if (numero == null) return 'Digite apenas números.';
    if (numero < 0 || numero > 720) return 'Informe um valor entre 0 e 720 horas.';
    return null;
  }

  static String? pessoasAfetadas(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Informe quantas pessoas foram afetadas.';
    final numero = int.tryParse(texto);
    if (numero == null) return 'Digite um número inteiro.';
    if (numero < 1 || numero > 10000) return 'Informe um valor entre 1 e 10.000.';
    return null;
  }

  /// Bloqueia descrições longas e textos que parecem conter dados pessoais (telefone, e-mail, CPF).
  static String? descricao(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.length > 300) return 'Use no máximo 300 caracteres.';
    if (RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+').hasMatch(texto)) {
      return 'Não inclua e-mail. A ocorrência é anônima.';
    }
    if (RegExp(r'\d{3}\.?\d{3}\.?\d{3}-?\d{2}').hasMatch(texto) ||
        RegExp(r'(\(?\d{2}\)?\s?)?9?\d{4}-?\d{4}').hasMatch(texto)) {
      return 'Não inclua telefone ou CPF. A ocorrência é anônima.';
    }
    return null;
  }

  static String? numeroEntre(String? valor, double minimo, double maximo, {bool inteiro = false}) {
    final texto = (valor ?? '').trim().replaceAll(',', '.');
    if (texto.isEmpty) return 'Campo obrigatório.';
    final numero = inteiro ? int.tryParse(texto)?.toDouble() : double.tryParse(texto);
    if (numero == null) return inteiro ? 'Digite um número inteiro.' : 'Digite um número.';
    if (numero < minimo || numero > maximo) {
      return 'Use um valor entre ${_semZeros(minimo)} e ${_semZeros(maximo)}.';
    }
    return null;
  }

  /// Os limiares de volume precisam estar em ordem: crítico < alerta < atenção.
  static String? ordemLimiares(Limiares l) {
    if (!(l.volumeCritico < l.volumeAlerta && l.volumeAlerta < l.volumeAtencao)) {
      return 'Os limiares de volume precisam seguir a ordem: Crítico < Alerta < Atenção.';
    }
    return null;
  }

  static String? urlServidor(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Informe o endereço do servidor.';
    final uri = Uri.tryParse(texto);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
      return 'Use um endereço completo, como http://10.0.2.2:3000';
    }
    return null;
  }

  static String? justificativaAvaliacao(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.length < 10) return 'Explique a decisão em pelo menos 10 caracteres.';
    if (texto.length > 500) return 'Use no máximo 500 caracteres.';
    return null;
  }

  static String _semZeros(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

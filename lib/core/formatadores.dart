/// Funções simples de formatação em português (sem dependência de pacotes de localização).
String formatarData(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

String formatarDataHora(DateTime d) => '${formatarData(d)} ${_dois(d.hour)}:${_dois(d.minute)}';

String formatarDiaMes(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}';

String formatarNumero(num valor, {int casas = 0}) {
  final texto = valor.toStringAsFixed(casas);
  final negativo = texto.startsWith('-');
  final semSinal = negativo ? texto.substring(1) : texto;
  final partes = semSinal.split('.');
  final inteiro = partes[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  final corpo = partes.length > 1 ? '$inteiro,${partes[1]}' : inteiro;
  return negativo ? '-$corpo' : corpo;
}

String formatarPorcentagem(num valor, {int casas = 1}) => '${formatarNumero(valor, casas: casas)}%';

String formatarSinal(num valor, {int casas = 1}) => '${valor > 0 ? '+' : ''}${formatarNumero(valor, casas: casas)}';

String _dois(int n) => n.toString().padLeft(2, '0');

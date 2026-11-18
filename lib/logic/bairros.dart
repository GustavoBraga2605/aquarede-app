/// Bairros atendidos (mesma lista do servidor AquaRede), com coordenada aproximada do centro.
const Map<String, List<double>> bairrosAquaRede = {
  'Brasilândia': [-23.468, -46.687],
  'Capão Redondo': [-23.668, -46.779],
  'Cidade Ademar': [-23.672, -46.650],
  'Cidade Tiradentes': [-23.582, -46.402],
  'Grajaú': [-23.785, -46.665],
  'Guaianases': [-23.541, -46.413],
  'Heliópolis': [-23.609, -46.596],
  'Itaim Paulista': [-23.501, -46.398],
  'Jardim Ângela': [-23.712, -46.770],
  'Jardim São Luís': [-23.660, -46.735],
  'Paraisópolis': [-23.617, -46.721],
  'Parelheiros': [-23.827, -46.727],
  'Perus': [-23.405, -46.752],
  'Sapopemba': [-23.603, -46.508],
};

const List<String> tiposOcorrencia = ['Falta de água', 'Vazamento', 'Água contaminada', 'Baixa pressão'];

/// Mesma regra de prioridade do servidor AquaRede.
String calcularPrioridade({required String tipo, required double horasSemAgua, required int pessoasAfetadas}) {
  if (tipo == 'Água contaminada') return 'Alta';
  if (horasSemAgua >= 24 || pessoasAfetadas >= 50) return 'Alta';
  if (horasSemAgua >= 8 || tipo == 'Vazamento') return 'Média';
  return 'Baixa';
}

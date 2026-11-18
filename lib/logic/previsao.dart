import 'dart:math' as math;

/// Resultado de uma regressão linear simples (y = a + b·x).
class Tendencia {
  const Tendencia({required this.inclinacao, required this.intercepto, required this.r2, required this.desvioResiduo, required this.n});
  final double inclinacao; // variação por dia
  final double intercepto;
  final double r2;
  final double desvioResiduo;
  final int n;

  /// Valor projetado [dias] depois da última observação.
  double projetar(int dias) => intercepto + inclinacao * (n - 1 + dias);
}

/// Ajusta uma reta aos valores (um por dia, em ordem). Precisa de pelo menos 3 pontos.
Tendencia regressaoLinear(List<double> valores) {
  final n = valores.length;
  if (n < 3) {
    throw ArgumentError('São necessários pelo menos 3 pontos para calcular a tendência.');
  }
  final mediaX = (n - 1) / 2;
  final mediaY = valores.reduce((a, b) => a + b) / n;
  var sxy = 0.0, sxx = 0.0, syy = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = i - mediaX, dy = valores[i] - mediaY;
    sxy += dx * dy;
    sxx += dx * dx;
    syy += dy * dy;
  }
  final b = sxy / sxx;
  final a = mediaY - b * mediaX;
  var sse = 0.0;
  for (var i = 0; i < n; i++) {
    final e = valores[i] - (a + b * i);
    sse += e * e;
  }
  final r2 = syy == 0 ? 1.0 : (1 - sse / syy).clamp(0.0, 1.0);
  final desvio = n > 2 ? math.sqrt(sse / (n - 2)) : 0.0;
  return Tendencia(inclinacao: b, intercepto: a, r2: r2.toDouble(), desvioResiduo: desvio, n: n);
}

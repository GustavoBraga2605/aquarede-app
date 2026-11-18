/// De onde vieram os dados exibidos.
enum OrigemDados { aoVivo, cache, simulado, exemplo }

extension OrigemDadosTexto on OrigemDados {
  String get rotulo {
    switch (this) {
      case OrigemDados.aoVivo:
        return 'Dados ao vivo';
      case OrigemDados.cache:
        return 'Sem conexão: dados salvos';
      case OrigemDados.simulado:
        return 'Serviço simulado (dados sintéticos)';
      case OrigemDados.exemplo:
        return 'Dados de exemplo (servidor indisponível)';
    }
  }
}

/// Resultado de uma busca de dados, com a origem e o horário da última atualização.
class Carga<T> {
  const Carga({required this.dados, required this.origem, required this.atualizadoEm});
  final T dados;
  final OrigemDados origem;
  final DateTime atualizadoEm;
}

/// Situação de carregamento de cada fonte.
enum StatusCarga { carregando, pronto, erro }

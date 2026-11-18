import '../core/formatadores.dart';
import '../models/alerta.dart';
import '../models/clima.dart';
import '../models/limiares.dart';
import '../models/manancial.dart';
import '../models/ocorrencia.dart';
import 'indicadores.dart';

/// Gera os alertas a partir dos dados do território. É uma função pura (sem estado),
/// o que permite testá-la com testes de unidade.
///
/// Os alertas são RECOMENDAÇÕES para avaliação humana: nenhum deles dispara ação automática.
List<Alerta> gerarAlertas({
  required List<SistemaManancial> sistemas,
  required List<DiaClima> clima,
  required List<Ocorrencia> ocorrencias,
  required Limiares limiares,
  required DateTime agora,
  bool mananciaisSinteticos = true,
}) {
  final alertas = <Alerta>[
    ..._alertasMananciais(sistemas, limiares, agora, mananciaisSinteticos),
    ..._alertasClima(clima, limiares, agora),
    ..._alertasOcorrencias(ocorrencias, limiares, agora),
  ];
  alertas.sort((a, b) {
    final porNivel = b.nivel.index.compareTo(a.nivel.index);
    return porNivel != 0 ? porNivel : b.confianca.compareTo(a.confianca);
  });
  return alertas;
}

List<Alerta> _alertasMananciais(List<SistemaManancial> sistemas, Limiares l, DateTime agora, bool sinteticos) {
  final lista = <Alerta>[];
  for (final s in sistemas) {
    if (s.serie.length < 30) continue;
    final ind = IndicadoresManancial.calcular(s, l);
    var nivel = maiorNivel(ind.faixaAtual, ind.faixaPrevista);
    final quedaForte = ind.tendencia30d <= -3;
    if (nivel == NivelAlerta.normal && quedaForte) nivel = NivelAlerta.atencao;
    if (nivel == NivelAlerta.normal) continue;

    final diasDesdeLeitura = agora.difference(s.ultimaLeitura).inDays;
    var confianca = (0.4 + 0.5 * ind.r2).clamp(0.3, 0.9).toDouble();
    if (diasDesdeLeitura > 3) confianca -= 0.2;
    if (sinteticos) confianca = (confianca - 0.1).clamp(0.2, 0.9).toDouble();

    final evidencias = <String>[
      'Volume atual de ${formatarPorcentagem(ind.atual)}, na faixa ${ind.faixaAtual.rotulo}.',
      'Variação de ${formatarSinal(ind.tendencia30d)} p.p. nos últimos 30 dias.',
      'Projeção para $horizontePrevisao dias: ${formatarPorcentagem(ind.previsao30d)} '
          '(±${formatarNumero(ind.margemPrevisao, casas: 1)} p.p.), faixa ${ind.faixaPrevista.rotulo}.',
      'A reta de tendência explica ${formatarNumero(ind.r2 * 100)}% da variação recente (R²).',
      if (ind.autonomiaDias != null && ind.autonomiaDias! > 0)
        'No ritmo atual, chegaria a ${formatarNumero(l.volumeCritico)}% em cerca de ${ind.autonomiaDias} dias.',
      if (ind.autonomiaDias == 0) 'O volume já está abaixo do limiar crítico de ${formatarNumero(l.volumeCritico)}%.',
    ];

    final piora = ind.faixaPrevista.index > ind.faixaAtual.index;
    lista.add(Alerta(
      id: 'man-${s.nome}',
      categoria: CategoriaAlerta.mananciais,
      nivel: nivel,
      titulo: piora
          ? '${s.nome}: tendência de piora para ${ind.faixaPrevista.rotulo}'
          : '${s.nome}: volume em faixa ${ind.faixaAtual.rotulo}',
      resumo: piora
          ? 'Se o ritmo dos últimos 30 dias continuar, o sistema deve passar para a faixa ${ind.faixaPrevista.rotulo} em até $horizontePrevisao dias.'
          : 'O volume armazenado está abaixo do limiar configurado e merece acompanhamento.',
      evidencias: evidencias,
      confianca: confianca,
      limitacoes: [
        'A projeção é linear: supõe que o ritmo dos últimos 30 dias se mantém e não considera chuva futura.',
        'Não considera consumo, transferências entre sistemas nem decisões de operação.',
        if (sinteticos) 'No protótipo, a série de mananciais vem de um serviço simulado com dados sintéticos.',
      ],
      naoConfiavelQuando:
          'Quando o R² for baixo (abaixo de 50%), na virada para a estação chuvosa ou quando houver mudança na operação do sistema.',
      fonte: sinteticos ? 'Serviço simulado de mananciais (dados sintéticos)' : 'Portal dos Mananciais (Sabesp)',
      geradoEm: agora,
      regiao: s.nome,
      indicadorChave: 'manancial:${s.nome}',
    ));
  }
  return lista;
}

List<Alerta> _alertasClima(List<DiaClima> dias, Limiares l, DateTime agora) {
  if (dias.isEmpty) return const [];
  final ind = IndicadoresClima.calcular(dias);
  final lista = <Alerta>[];

  if (ind.diasSemChuva >= l.diasSemChuva) {
    final nivel = ind.diasSemChuva >= l.diasSemChuva * 2 ? NivelAlerta.alerta : NivelAlerta.atencao;
    final semAlivio = ind.chuvaPrevista7d < 10;
    lista.add(Alerta(
      id: 'clima-estiagem',
      categoria: CategoriaAlerta.clima,
      nivel: semAlivio ? nivel : NivelAlerta.atencao,
      titulo: 'Estiagem: ${ind.diasSemChuva} dias seguidos sem chuva',
      resumo: semAlivio
          ? 'Período seco prolongado e pouca chuva prevista para a semana. Os reservatórios tendem a continuar caindo.'
          : 'Período seco prolongado, mas há chuva prevista para os próximos dias.',
      evidencias: [
        '${ind.diasSemChuva} dias seguidos com menos de 1 mm de chuva (limiar: ${l.diasSemChuva} dias).',
        'Chuva acumulada nos últimos 30 dias: ${formatarNumero(ind.chuva30d, casas: 1)} mm.',
        'Chuva prevista para os próximos 7 dias: ${formatarNumero(ind.chuvaPrevista7d, casas: 1)} mm.',
      ],
      confianca: ind.diasObservados >= 25 ? 0.8 : 0.6,
      limitacoes: [
        'Os dados são de um único ponto (centro de São Paulo) e não representam toda a bacia dos mananciais.',
        'A chuva prevista vem de modelo meteorológico e muda a cada atualização.',
      ],
      naoConfiavelQuando: 'Quando faltarem dias de observação ou em chuvas muito localizadas, comuns no verão.',
      fonte: 'Open-Meteo (observação recente e previsão)',
      geradoEm: agora,
      regiao: 'São Paulo',
      indicadorChave: 'clima:chuva',
    ));
  }

  final tMax = ind.tMaxPrevista3d;
  if (tMax != null && tMax >= l.temperaturaCalor && ind.chuvaPrevista7d < 10) {
    lista.add(Alerta(
      id: 'clima-calor',
      categoria: CategoriaAlerta.clima,
      nivel: NivelAlerta.atencao,
      titulo: 'Calor forte: consumo de água deve aumentar',
      resumo: 'Temperaturas altas sem chuva costumam elevar o consumo e a pressão sobre a rede, principalmente nas partes altas dos bairros.',
      evidencias: [
        'Máxima prevista de ${formatarNumero(tMax, casas: 1)} °C nos próximos 3 dias (limiar: ${formatarNumero(l.temperaturaCalor)} °C).',
        'Chuva prevista para 7 dias: ${formatarNumero(ind.chuvaPrevista7d, casas: 1)} mm.',
      ],
      confianca: 0.65,
      limitacoes: [
        'A relação entre calor e consumo é uma regra geral. O app não mede o consumo real.',
        'Previsões de temperatura perdem precisão depois de 3 dias.',
      ],
      naoConfiavelQuando: 'Em frentes frias ou mudanças bruscas do tempo, que a previsão pode não captar.',
      fonte: 'Open-Meteo (previsão)',
      geradoEm: agora,
      regiao: 'São Paulo',
      indicadorChave: 'clima:temperatura',
    ));
  }
  return lista;
}

List<Alerta> _alertasOcorrencias(List<Ocorrencia> ocorrencias, Limiares l, DateTime agora) {
  final ind = IndicadoresOcorrencias.calcular(ocorrencias, agora);
  final lista = <Alerta>[];
  ind.porBairro7d.forEach((bairro, itens) {
    final contaminacao = itens.where((o) => o.tipo == 'Água contaminada').length;
    final quantidade = itens.length;
    var nivel = NivelAlerta.normal;
    if (quantidade >= l.ocorrenciasPorBairro) nivel = NivelAlerta.alerta;
    if (quantidade >= l.ocorrenciasPorBairro * 2) nivel = NivelAlerta.critico;
    if (contaminacao >= 1) nivel = maiorNivel(nivel, NivelAlerta.alerta);
    if (contaminacao >= 2) nivel = NivelAlerta.critico;
    if (nivel == NivelAlerta.normal) return;

    final pessoas = itens.fold<int>(0, (s, o) => s + o.pessoasAfetadas);
    final semAgua = itens.where((o) => o.tipo == 'Falta de água').length;
    lista.add(Alerta(
      id: 'oco-$bairro',
      categoria: CategoriaAlerta.ocorrencias,
      nivel: nivel,
      titulo: contaminacao > 0 ? '$bairro: relatos de água contaminada' : '$bairro: concentração de ocorrências',
      resumo: contaminacao > 0
          ? 'Há relatos de água com aparência ou cheiro alterados. Por envolver risco à saúde, recomenda-se verificação prioritária.'
          : 'O número de ocorrências na última semana passou do limiar configurado para o bairro.',
      evidencias: [
        '$quantidade ocorrência(s) nos últimos 7 dias (limiar: ${l.ocorrenciasPorBairro}).',
        if (semAgua > 0) '$semAgua relato(s) de falta de água.',
        if (contaminacao > 0) '$contaminacao relato(s) de água contaminada.',
        '${formatarNumero(pessoas)} pessoa(s) afetada(s), segundo os moradores.',
      ],
      confianca: (0.4 + 0.1 * quantidade).clamp(0.4, 0.9).toDouble(),
      limitacoes: [
        'Os relatos são enviados pelos moradores e não são verificados no local.',
        'Pode haver subnotificação em áreas onde o app é pouco usado, e duplicidade quando vizinhos relatam o mesmo problema.',
      ],
      naoConfiavelQuando: 'Quando há poucos relatos (1 ou 2) ou quando eles vêm todos do mesmo momento, o que pode indicar duplicidade.',
      fonte: 'Ocorrências da comunidade (AquaRede)',
      geradoEm: agora,
      regiao: bairro,
      indicadorChave: 'ocorrencias:total',
      pessoasAlcancadas: pessoas,
    ));
  });
  return lista;
}

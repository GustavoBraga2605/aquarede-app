import 'package:flutter/material.dart';

/// Modos de tema disponíveis no app.
enum ModoTema { claro, escuro, altoContraste }

/// Espaçamentos padronizados usados em todas as telas.
class Espaco {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double raio = 16;
}

/// Paleta da identidade AquaRede (mesma do site): azul de represa, azul de caixa d'água e aqua.
class Cores {
  static const mar = Color(0xFF0A2A55);
  static const caixa = Color(0xFF1F5FD1);
  static const agua = Color(0xFF2EC5D9);
  static const normal = Color(0xFF2E7D4F);
  static const atencao = Color(0xFF8A5F00);
  static const alerta = Color(0xFFB45300);
  static const critico = Color(0xFFC62828);
}

/// Cores semânticas extras que mudam conforme o tema (ex.: cores das faixas de risco).
@immutable
class CoresAquaRede extends ThemeExtension<CoresAquaRede> {
  const CoresAquaRede({
    required this.normal,
    required this.atencao,
    required this.alerta,
    required this.critico,
    required this.destaque,
    required this.cabecalho,
    required this.textoCabecalho,
  });

  final Color normal;
  final Color atencao;
  final Color alerta;
  final Color critico;
  final Color destaque;
  final Color cabecalho;
  final Color textoCabecalho;

  @override
  CoresAquaRede copyWith({
    Color? normal,
    Color? atencao,
    Color? alerta,
    Color? critico,
    Color? destaque,
    Color? cabecalho,
    Color? textoCabecalho,
  }) {
    return CoresAquaRede(
      normal: normal ?? this.normal,
      atencao: atencao ?? this.atencao,
      alerta: alerta ?? this.alerta,
      critico: critico ?? this.critico,
      destaque: destaque ?? this.destaque,
      cabecalho: cabecalho ?? this.cabecalho,
      textoCabecalho: textoCabecalho ?? this.textoCabecalho,
    );
  }

  @override
  CoresAquaRede lerp(ThemeExtension<CoresAquaRede>? other, double t) {
    if (other is! CoresAquaRede) return this;
    return CoresAquaRede(
      normal: Color.lerp(normal, other.normal, t)!,
      atencao: Color.lerp(atencao, other.atencao, t)!,
      alerta: Color.lerp(alerta, other.alerta, t)!,
      critico: Color.lerp(critico, other.critico, t)!,
      destaque: Color.lerp(destaque, other.destaque, t)!,
      cabecalho: Color.lerp(cabecalho, other.cabecalho, t)!,
      textoCabecalho: Color.lerp(textoCabecalho, other.textoCabecalho, t)!,
    );
  }
}

class AppTheme {
  static ThemeData construir(ModoTema modo) {
    switch (modo) {
      case ModoTema.claro:
        return _base(
          ColorScheme.fromSeed(seedColor: Cores.caixa, brightness: Brightness.light).copyWith(
            primary: Cores.caixa,
            secondary: Cores.agua,
            surface: Colors.white,
          ),
          const CoresAquaRede(
            normal: Cores.normal,
            atencao: Cores.atencao,
            alerta: Cores.alerta,
            critico: Cores.critico,
            destaque: Cores.agua,
            cabecalho: Cores.mar,
            textoCabecalho: Colors.white,
          ),
          const Color(0xFFF2F7FB),
        );
      case ModoTema.escuro:
        return _base(
          ColorScheme.fromSeed(seedColor: Cores.caixa, brightness: Brightness.dark).copyWith(
            primary: const Color(0xFF8DB2F7),
            secondary: const Color(0xFF4FD6E8),
            surface: const Color(0xFF142238),
          ),
          const CoresAquaRede(
            normal: Color(0xFF66CF96),
            atencao: Color(0xFFF0C24F),
            alerta: Color(0xFFF59A4A),
            critico: Color(0xFFF27C71),
            destaque: Color(0xFF4FD6E8),
            cabecalho: Color(0xFF071A36),
            textoCabecalho: Colors.white,
          ),
          const Color(0xFF0C1626),
        );
      case ModoTema.altoContraste:
        return _base(
          const ColorScheme.highContrastDark(
            primary: Color(0xFFFFE500),
            onPrimary: Colors.black,
            secondary: Color(0xFF00FFFF),
            onSecondary: Colors.black,
            surface: Colors.black,
            onSurface: Colors.white,
          ),
          const CoresAquaRede(
            normal: Color(0xFF7CFF9B),
            atencao: Color(0xFFFFE500),
            alerta: Color(0xFFFFA64D),
            critico: Color(0xFFFF6B6B),
            destaque: Color(0xFF00FFFF),
            cabecalho: Colors.black,
            textoCabecalho: Colors.white,
          ),
          Colors.black,
          bordasFortes: true,
        );
    }
  }

  static ThemeData _base(ColorScheme esquema, CoresAquaRede extras, Color fundo, {bool bordasFortes = false}) {
    final borda = bordasFortes
        ? BorderSide(color: esquema.onSurface, width: 2)
        : BorderSide(color: esquema.outlineVariant);
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: fundo,
      extensions: [extras],
      appBarTheme: AppBarTheme(
        backgroundColor: extras.cabecalho,
        foregroundColor: extras.textoCabecalho,
        centerTitle: false,
        titleTextStyle: TextStyle(color: extras.textoCabecalho, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: esquema.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Espaco.raio), side: borda),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: borda),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: Espaco.lg, vertical: Espaco.md),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48), shape: const StadiumBorder()),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

extension TemaAquaRede on BuildContext {
  CoresAquaRede get coresAqua => Theme.of(this).extension<CoresAquaRede>()!;
}

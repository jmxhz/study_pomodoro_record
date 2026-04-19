import 'package:flutter/material.dart';

class AppTheme {
  static const palettes = <String, _ThemePalette>{
    'monet-mist': _ThemePalette(
      name: '莫奈薄雾',
      seedColor: Color(0xFF7FA7A3),
      scaffoldColor: Color(0xFFF4F6F3),
      cardBorderColor: Color(0xFFB8CEC9),
    ),
    'monet-water': _ThemePalette(
      name: '莫奈睡莲',
      seedColor: Color(0xFF6A8FB3),
      scaffoldColor: Color(0xFFF2F5F7),
      cardBorderColor: Color(0xFFBED0DE),
    ),
    'monet-sunset': _ThemePalette(
      name: '莫奈日出',
      seedColor: Color(0xFFD88C6A),
      scaffoldColor: Color(0xFFFBF4EE),
      cardBorderColor: Color(0xFFEBC3B1),
    ),
    'monet-garden': _ThemePalette(
      name: '莫奈花园',
      seedColor: Color(0xFF8C9D6F),
      scaffoldColor: Color(0xFFF6F7F1),
      cardBorderColor: Color(0xFFD0D8BF),
    ),
  };

  static ThemeData lightTheme({String paletteKey = 'monet-mist'}) {
    final palette = palettes[paletteKey] ?? palettes.values.first;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.seedColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: palette.scaffoldColor,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: palette.cardBorderColor.withValues(alpha: 0.45),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _ThemePalette {
  const _ThemePalette({
    required this.name,
    required this.seedColor,
    required this.scaffoldColor,
    required this.cardBorderColor,
  });

  final String name;
  final Color seedColor;
  final Color scaffoldColor;
  final Color cardBorderColor;
}

import 'package:flutter/material.dart';

class MaterialYouPalette {
  final String name;
  final Color seedColor;
  final IconData icon;

  const MaterialYouPalette({
    required this.name,
    required this.seedColor,
    required this.icon,
  });
}

class AppTheme {
  static const List<MaterialYouPalette> palettes = [
    MaterialYouPalette(
      name: 'Índigo Clínico',
      seedColor: Color(0xFF4F46E5),
      icon: Icons.medical_information_rounded,
    ),
    MaterialYouPalette(
      name: 'Esmeralda Natural',
      seedColor: Color(0xFF059669),
      icon: Icons.eco_rounded,
    ),
    MaterialYouPalette(
      name: 'Océano Turquesa',
      seedColor: Color(0xFF0284C7),
      icon: Icons.water_drop_rounded,
    ),
    MaterialYouPalette(
      name: 'Violeta Real',
      seedColor: Color(0xFF7C3AED),
      icon: Icons.auto_awesome_rounded,
    ),
    MaterialYouPalette(
      name: 'Rosa Cálido',
      seedColor: Color(0xFFE11D48),
      icon: Icons.favorite_rounded,
    ),
    MaterialYouPalette(
      name: 'Ámbar Solar',
      seedColor: Color(0xFFD97706),
      icon: Icons.wb_sunny_rounded,
    ),
  ];

  // Constantes de compatibilidad
  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color primaryDarkColor = Color(0xFF4338CA);
  static const Color backgroundColor = Color(0xFFF6F7FB);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF49454F);

  static Color seedForIndex(int index) {
    if (index < 0 || index >= palettes.length) {
      return palettes.first.seedColor;
    }
    return palettes[index].seedColor;
  }

  static ThemeData get lightTheme => buildTheme(
        seedIndex: 0,
        brightness: Brightness.light,
      );

  static ThemeData buildTheme({
    required int seedIndex,
    required Brightness brightness,
  }) {
    final seed = seedForIndex(seedIndex);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }
}

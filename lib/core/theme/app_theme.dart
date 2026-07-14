import 'package:flutter/material.dart';

/// Uygulamanın tüm görsel kimliği tek yerde.
///
/// Ekranlar renk/şekil için doğrudan sabit yazmaz, Theme.of(context)
/// üzerinden bunu okur. Firma paleti gelirse ya da Angular ekibiyle
/// renk anlaşılırsa, sadece bu dosya değişir - hiçbir ekrana dokunulmaz.
///
/// Palet: koyu lacivert (ana) + altın (vurgu). Otel/prestij hissi.
class AppTheme {
  AppTheme._();

  // --- Marka renkleri ---
  // Bu iki renk kimliğin çekirdeği. Değiştirmek istersen buradan.
  static const Color _navy = Color(0xFF1A2A4F); // koyu lacivert
  static const Color _gold = Color(0xFFC9A24B); // altın

  // --- Şekil ---
  // "Yumuşak, çok yuvarlak" tercihine göre geniş yarıçap.
  static const double _radius = 18.0;

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    // ColorScheme.fromSeed marka renginden uyumlu bir palet üretir;
    // altını da secondary olarak sabitliyoruz ki vurgu tutarlı olsun.
    final scheme = ColorScheme.fromSeed(
      seedColor: _navy,
      brightness: brightness,
      secondary: _gold,
      tertiary: _gold,
    );

    final borderRadius = BorderRadius.circular(_radius);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,

      // --- Butonlar ---
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),

      // --- Form alanları ---
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: borderRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
      ),

      // --- Kartlar ---
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // --- AppBar ---
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),

      // --- Diğer ---
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radius + 6)),
        ),
      ),
    );
  }
}
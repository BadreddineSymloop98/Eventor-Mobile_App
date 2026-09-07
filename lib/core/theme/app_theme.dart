import 'package:flutter/material.dart';

import '../constants/ui_helpers.dart';
import 'app_semantic_colors.dart';

/// Central theme definition for the app.
///
/// Sizes, spacing, colours and the type ramps come from `ui_helpers.dart`;
/// this file is only responsible for assembling them into a [ThemeData].
///
/// Both the palette and the ramp depend on the locale, which is why every
/// entry point here takes one: Arabic is set in a different typeface at
/// different sizes, so the theme — not the widget — is where that is decided.
abstract final class AppTheme {
  static ThemeData light([Locale? locale]) =>
      _buildTheme(Brightness.light, locale);

  /// Dark mode is **not designed yet**.
  ///
  /// The foundations publish a single light palette — white surfaces, purple
  /// chrome — and no dark counterpart. This derives one from the brand colour
  /// so the app does not invert into something unreadable if the device asks
  /// for dark, but it is a safety net, not the design. Replace it wholesale
  /// when a dark palette is published.
  static ThemeData dark([Locale? locale]) =>
      _buildTheme(Brightness.dark, locale);

  static ThemeData _buildTheme(Brightness brightness, Locale? locale) {
    final ColorScheme colorScheme = _colorScheme(brightness);
    final TextTheme textTheme = AppTextStyles.forLocale(locale).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
      fontFamily: AppFonts.forLocale(locale),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: AppFonts.forLocale(locale),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: AppRadii.mdAll),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppSemanticColors.of(brightness),
      ],
    );
  }

  /// The scheme for [brightness].
  ///
  /// Light is pinned to the published tokens rather than derived: Material's
  /// tonal palette would shift the brand purple, and the design states its
  /// contrast ratios against the exact values. Dark is left derived — see
  /// [dark].
  static ColorScheme _colorScheme(Brightness brightness) {
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    );

    if (brightness == Brightness.dark) return base;

    return base.copyWith(
      primary: AppColors.brand,
      onPrimary: AppColors.textOnBrand,
      secondary: AppColors.bgAccent,
      onSecondary: AppColors.textOnAccent,
      // The design's only tint sits behind a screen; cards sit on white.
      surface: AppColors.bgCanvas,
      onSurface: AppColors.textPrimary,
      surfaceContainerLowest: AppColors.bgSurface,
      surfaceContainer: AppColors.bgSurface,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderDefault,
      outlineVariant: AppColors.borderBrandSubtle,
      error: AppColors.statusDeclined,
      onError: AppColors.textOnBrand,
    );
  }
}

/// Which font family each locale is set in.
///
/// Latin and Arabic rarely share a typeface well, so the two are chosen
/// separately: Inter sets the Latin copy and Cairo the Arabic. The names live
/// in [AppFontFamilies] and the files are declared in `pubspec.yaml`.
///
/// Note that this keys off the *app's* language, not off the script of any
/// individual string. A Latin word inside Arabic copy is therefore set in
/// Cairo, which covers both scripts; the reverse — Arabic inside an English
/// UI — falls back to the platform font, which is the right trade for an app
/// whose English copy is not expected to contain Arabic.
abstract final class AppFonts {
  static const String arabicLanguageCode = 'ar';

  static String forLocale(Locale? locale) {
    return switch (locale?.languageCode) {
      arabicLanguageCode => AppFontFamilies.arabic,
      _ => AppFontFamilies.latin,
    };
  }
}

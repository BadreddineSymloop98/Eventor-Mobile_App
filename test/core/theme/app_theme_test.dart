import 'dart:io';

import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

/// Registers a real font file with the test engine.
///
/// Widget tests otherwise lay every string out in a placeholder font, which
/// would make the width comparisons below measure nothing.
Future<void> _loadFont(String family, String path) {
  final File file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is missing');

  return (FontLoader(family)
        ..addFont(
          Future<ByteData>.value(
            ByteData.sublistView(file.readAsBytesSync()),
          ),
        ))
      .load();
}

/// Lays [text] out in [family] at [weight] and reports how wide it came out.
double _width(
  String text, {
  required String family,
  required FontWeight weight,
  TextDirection direction = TextDirection.ltr,
}) {
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: family, fontWeight: weight, fontSize: 48),
    ),
    textDirection: direction,
  )..layout();

  final double width = painter.width;
  painter.dispose();
  return width;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont(
      AppFontFamilies.latin,
      'assets/fonts/Inter-Variable.ttf',
    );
    await _loadFont(
      AppFontFamilies.arabic,
      'assets/fonts/Cairo-Variable.ttf',
    );
  });

  group('AppFonts', () {
    test('sets Arabic in Cairo and everything else in Inter', () {
      expect(AppFonts.forLocale(arabicLocale), AppFontFamilies.arabic);
      expect(AppFonts.forLocale(englishLocale), AppFontFamilies.latin);
    });

    test('falls back to Latin when the locale is unknown', () {
      // Null is the "follow the device" state, which reaches here before the
      // platform locale has been resolved.
      expect(AppFonts.forLocale(null), AppFontFamilies.latin);
      expect(AppFonts.forLocale(const Locale('fr')), AppFontFamilies.latin);
    });
  });

  group('the bundled variable fonts', () {
    // Both families ship as a single file carrying a `wght` axis rather than
    // as four static cuts. That only pays off if Flutter actually drives the
    // axis from `fontWeight` — if it did not, every weight in the type ramp
    // would silently render identically.
    test('render Latin differently at each weight of the ramp', () {
      final double regular = _width(
        'Eventor',
        family: AppFontFamilies.latin,
        weight: FontWeight.w400,
      );
      final double semiBold = _width(
        'Eventor',
        family: AppFontFamilies.latin,
        weight: FontWeight.w600,
      );
      final double bold = _width(
        'Eventor',
        family: AppFontFamilies.latin,
        weight: FontWeight.w700,
      );

      expect(regular, greaterThan(0));
      expect(semiBold, greaterThan(regular));
      expect(bold, greaterThan(semiBold));
    });

    test('render Arabic, and differently at each weight', () {
      const String arabic = 'منصة خدمات المناسبات';

      final double regular = _width(
        arabic,
        family: AppFontFamilies.arabic,
        weight: FontWeight.w400,
        direction: TextDirection.rtl,
      );
      final double bold = _width(
        arabic,
        family: AppFontFamilies.arabic,
        weight: FontWeight.w700,
        direction: TextDirection.rtl,
      );

      expect(regular, greaterThan(0));
      expect(bold, greaterThan(regular));
    });
  });

  group('AppTheme', () {
    test('sets the font family from the locale', () {
      expect(AppTheme.light(arabicLocale).textTheme.bodyLarge?.fontFamily,
          AppFontFamilies.arabic);
      expect(AppTheme.light(englishLocale).textTheme.bodyLarge?.fontFamily,
          AppFontFamilies.latin);
      expect(AppTheme.dark(arabicLocale).textTheme.bodyLarge?.fontFamily,
          AppFontFamilies.arabic);
    });

    test('derives both brightnesses from the brand colour', () {
      // Material's tonal palette will not hand back the seed unchanged, so
      // this checks the scheme was actually derived rather than left default.
      final ColorScheme light = AppTheme.light(englishLocale).colorScheme;
      final ColorScheme dark = AppTheme.dark(englishLocale).colorScheme;

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.primary, isNot(dark.primary));
    });

    test('keeps the true brand colour reachable', () {
      // The design's brand colour is a ground, not an accent, so screens that
      // need it read the constant rather than the derived scheme.
      expect(AppColors.brand, const Color(0xFF2B075D));
      expect(AppColors.textOnBrand, const Color(0xFFFFFFFF));
    });
  });
}

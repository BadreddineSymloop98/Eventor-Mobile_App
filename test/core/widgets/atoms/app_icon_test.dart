import 'dart:io';

import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  /// The mirroring transform [AppIcon] wraps a directional glyph in, if any.
  Finder mirrorOf() => find.descendant(
        of: find.byType(AppIcon),
        matching: find.byType(Transform),
      );

  /// Whether the pumped icon is drawn flipped left to right.
  bool isMirrored(WidgetTester tester) =>
      tester.widget<Transform>(mirrorOf()).transform.entry(0, 0) < 0;

  group('AppIcons', () {
    test('has a file behind every name', () {
      // A missing export fails on the one screen that draws it, at runtime;
      // this finds it here instead.
      for (final AppIcons icon in AppIcons.values) {
        expect(
          File(icon.assetPath).existsSync(),
          isTrue,
          reason: '${icon.name} → ${icon.assetPath}',
        );
      }
    });

    test('marks only the chevrons that point sideways as directional', () {
      final Set<AppIcons> directional = AppIcons.values
          .where((AppIcons icon) => icon.isDirectional)
          .toSet();

      expect(directional, <AppIcons>{
        AppIcons.chevronLeft,
        AppIcons.chevronRight,
      });
    });
  });

  group('AppIcon', () {
    testWidgets('draws a directional glyph as it is in English',
        (WidgetTester tester) async {
      await pumpAppWidget(tester, const AppIcon(AppIcons.chevronLeft));

      expect(isMirrored(tester), isFalse);
    });

    testWidgets('mirrors a directional glyph in Arabic',
        (WidgetTester tester) async {
      // "Back" points left in English and right in Arabic.
      await pumpAppWidget(
        tester,
        const AppIcon(AppIcons.chevronLeft),
        locale: arabicLocale,
      );

      expect(isMirrored(tester), isTrue);
    });

    testWidgets('mirrors the forward chevron in Arabic too',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const AppIcon(AppIcons.chevronRight),
        locale: arabicLocale,
      );

      expect(isMirrored(tester), isTrue);
    });

    testWidgets('never mirrors a glyph that points nowhere',
        (WidgetTester tester) async {
      // A bell or a down-chevron reads the same in either direction.
      for (final AppIcons icon in <AppIcons>[
        AppIcons.bell,
        AppIcons.chevronDown,
      ]) {
        await pumpAppWidget(tester, AppIcon(icon), locale: arabicLocale);

        expect(mirrorOf(), findsNothing, reason: icon.name);
      }
    });

    testWidgets('tints the glyph from one colour', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const AppIcon(AppIcons.star, color: AppColors.iconAccent),
      );

      expect(
        tester.widget<SvgPicture>(find.byType(SvgPicture)).colorFilter,
        const ColorFilter.mode(AppColors.iconAccent, BlendMode.srcIn),
      );
    });

    testWidgets('stays square, sized from the width',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const Center(child: AppIcon(AppIcons.bell, size: AppSizes.iconMd)),
      );

      final SvgPicture picture =
          tester.widget<SvgPicture>(find.byType(SvgPicture));

      expect(picture.width, AppSizes.iconMd.dw);
      expect(picture.height, AppSizes.iconMd.dw);
    });

    testWidgets('is silent unless given a label', (WidgetTester tester) async {
      await pumpAppWidget(tester, const AppIcon(AppIcons.bell));
      expect(
        tester.widget<SvgPicture>(find.byType(SvgPicture)).excludeFromSemantics,
        isTrue,
      );

      await pumpAppWidget(
        tester,
        const AppIcon(AppIcons.bell, semanticLabel: 'Notifications'),
      );
      expect(
        tester.widget<SvgPicture>(find.byType(SvgPicture)).excludeFromSemantics,
        isFalse,
      );
    });
  });
}

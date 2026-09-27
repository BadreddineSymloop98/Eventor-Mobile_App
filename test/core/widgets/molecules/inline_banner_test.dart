import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/molecules/inline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

const String _title = 'That code has expired.';
const String _message = 'Codes last ten minutes.';
const String _action = 'Send a new code';

BoxDecoration _box(WidgetTester tester) => tester
    .widget<Container>(find
        .descendant(
          of: find.byType(InlineBanner),
          matching: find.byType(Container),
        )
        .first)
    .decoration! as BoxDecoration;

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  group('InlineBanner', () {
    testWidgets('shows the title and the body', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const InlineBanner(title: _title, message: _message),
      );

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_message), findsOneWidget);
    });

    testWidgets('can be a title alone', (WidgetTester tester) async {
      await pumpAppWidget(tester, const InlineBanner(title: _title));

      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('is a red callout by default', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const InlineBanner(title: _title, message: _message),
      );

      expect(_box(tester).color, AppColors.bgDangerSubtle);
      expect((_box(tester).border! as Border).top.color, AppColors.borderDanger);
      expect(_colorOf(tester, _title), AppColors.textDanger);
      expect(_colorOf(tester, _message), AppColors.textPrimary);
    });

    testWidgets('is a quiet purple note in the info tone',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const InlineBanner(title: _title, tone: InlineBannerTone.info),
      );

      expect(_box(tester).color, AppColors.bgBrandSubtle);
      expect(_box(tester).border, isNull);
      expect(_colorOf(tester, _title), AppColors.textBrand);
    });

    testWidgets('offers the follow-up link, and reports the tap',
        (WidgetTester tester) async {
      int taps = 0;
      await pumpAppWidget(
        tester,
        InlineBanner(
          title: _title,
          message: _message,
          actionLabel: _action,
          onAction: () => taps++,
        ),
      );

      expect(_colorOf(tester, _action), AppColors.textBrand);

      await tester.tap(find.text(_action));

      expect(taps, 1);
    });

    testWidgets('greys the link out when it cannot be followed',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const InlineBanner(title: _title, actionLabel: _action),
      );

      expect(_colorOf(tester, _action), AppColors.textSecondary);
      final Semantics link = tester.widget<Semantics>(
        find.ancestor(of: find.text(_action), matching: find.byType(Semantics))
            .first,
      );
      expect(link.properties.button, isFalse);
    });

    testWidgets('has no link without a label', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        InlineBanner(title: _title, onAction: () {}),
      );

      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('is announced the moment it appears',
        (WidgetTester tester) async {
      // A live region: a screen reader reads it without the user having to
      // go looking for why the form did not submit.
      await pumpAppWidget(
        tester,
        const InlineBanner(title: _title, message: _message),
      );

      expect(
        tester.getSemantics(find.byType(InlineBanner)),
        isSemantics(isLiveRegion: true),
      );
      final Semantics region = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(InlineBanner),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(region.properties.liveRegion, isTrue);
      expect(region.container, isTrue);
    });

    testWidgets('starts its text on the right in Arabic',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const InlineBanner(title: 'انتهت صلاحية الرمز.'),
        locale: arabicLocale,
      );

      expect(
        tester.getTopRight(find.text('انتهت صلاحية الرمز.')).dx,
        greaterThan(tester.getCenter(find.byType(InlineBanner)).dx),
      );
    });
  });
}

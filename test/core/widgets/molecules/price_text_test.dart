import 'package:eventor/core/localization/app_localizations_x.dart';
import 'package:eventor/core/widgets/molecules/price_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  Future<void> pumpPrice(WidgetTester tester, {required Locale locale}) {
    return pumpAppWidget(
      tester,
      Center(
        // Read from the tree being built — the test helper needs a pumped one.
        child: Builder(
          builder: (BuildContext context) => PriceText(
            amount: '45000.00',
            prefix: context.l10n.priceFrom,
            unit: 'per day',
          ),
        ),
      ),
      locale: locale,
    );
  }

  double xOf(WidgetTester tester, String text) =>
      tester.getCenter(find.text(text)).dx;

  group('PriceText', () {
    testWidgets('reads prefix, amount, currency, unit left to right',
        (WidgetTester tester) async {
      await pumpPrice(tester, locale: englishLocale);
      final String from = l10n(tester).priceFrom;
      final String currency = l10n(tester).currencyDzd;

      expect(xOf(tester, from), lessThan(xOf(tester, '45 000')));
      expect(xOf(tester, '45 000'), lessThan(xOf(tester, currency)));
      expect(xOf(tester, currency), lessThan(xOf(tester, 'per day')));
    });

    testWidgets('reads the same order right to left in Arabic',
        (WidgetTester tester) async {
      // The number-token rule: the leading word has the greatest x, and the
      // amount sits to the right of its currency.
      await pumpPrice(tester, locale: arabicLocale);
      final String from = l10n(tester).priceFrom;
      final String currency = l10n(tester).currencyDzd;

      expect(xOf(tester, from), greaterThan(xOf(tester, '45 000')));
      expect(xOf(tester, '45 000'), greaterThan(xOf(tester, currency)));
    });

    testWidgets('keeps the amount itself left to right in Arabic',
        (WidgetTester tester) async {
      await pumpPrice(tester, locale: arabicLocale);

      expect(
        tester.widget<Text>(find.text('45 000')).textDirection,
        TextDirection.ltr,
      );
    });

    testWidgets('leaves out a prefix and unit it was not given',
        (WidgetTester tester) async {
      await pumpAppWidget(tester, const Center(child: PriceText(amount: '1200.00')));

      expect(find.byType(Text), findsNWidgets(2)); // Amount and currency.
    });
  });
}

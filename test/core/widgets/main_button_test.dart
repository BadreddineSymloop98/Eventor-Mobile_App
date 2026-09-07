import 'package:eventor/core/widgets/main_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, VoidCallback? onPressed) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MainButton(label: 'Tap me', onPressed: onPressed),
        ),
      ),
    );
  }

  group('MainButton', () {
    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      int taps = 0;
      await pumpButton(tester, () => taps++);

      await tester.tap(find.byType(MainButton));

      expect(taps, 1);
    });

    testWidgets('does nothing while canBeTapped is false',
        (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MainButton(
              label: 'Tap me',
              canBeTapped: false,
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MainButton));

      expect(taps, 0);
    });

    testWidgets('reports itself disabled when canBeTapped is false',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MainButton(
              label: 'Tap me',
              canBeTapped: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(MainButton)),
        isSemantics(label: 'Tap me', isButton: true, isEnabled: false),
      );

      handle.dispose();
    });

    testWidgets('does nothing while disabled', (WidgetTester tester) async {
      await pumpButton(tester, null);

      // Must not throw: a null onPressed simply ignores the tap.
      await tester.tap(find.byType(MainButton));
    });

    testWidgets('exposes itself as a button to accessibility tools',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpButton(tester, () {});

      expect(
        tester.getSemantics(find.byType(MainButton)),
        isSemantics(label: 'Tap me', isButton: true, isEnabled: true),
      );

      handle.dispose();
    });

    testWidgets('is at least 48dp tall', (WidgetTester tester) async {
      await pumpButton(tester, () {});

      expect(
        tester.getSize(find.byType(MainButton)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });
}

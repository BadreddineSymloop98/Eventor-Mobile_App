import 'package:eventor/core/widgets/molecules/back_to_exit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  /// The platform calls the app made to close itself.
  late List<MethodCall> exits;

  setUp(() {
    exits = <MethodCall>[];
  });

  Future<void> pump(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'SystemNavigator.pop') exits.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await pumpAppWidget(
      tester,
      Builder(
        builder: (BuildContext context) => BackToExit(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const Text('details')),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pump();
  }

  group('BackToExit', () {
    testWidgets('asks for a second press instead of closing', (WidgetTester tester) async {
      await pump(tester);

      await pressBack(tester);

      expect(find.text(l10n(tester).pressBackAgainToExit), findsOneWidget);
      expect(exits, isEmpty);
    });

    testWidgets('closes on a second press in time', (WidgetTester tester) async {
      await pump(tester);

      await pressBack(tester);
      await tester.pump(const Duration(milliseconds: 1500));
      await pressBack(tester);

      expect(exits, hasLength(1));
    });

    testWidgets('asks again once the window has passed', (WidgetTester tester) async {
      await pump(tester);

      await pressBack(tester);
      await tester.pump(BackToExit.window + const Duration(milliseconds: 100));
      await pressBack(tester);

      expect(exits, isEmpty);
      expect(find.text(l10n(tester).pressBackAgainToExit), findsOneWidget);
    });

    testWidgets('leaves Back to a screen opened on top', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await pressBack(tester);
      await tester.pumpAndSettle();

      expect(find.text('details'), findsNothing);
      expect(find.text(l10n(tester).pressBackAgainToExit), findsNothing);
      expect(exits, isEmpty);
    });
  });
}

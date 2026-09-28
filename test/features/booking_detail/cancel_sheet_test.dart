import 'package:eventor/core/widgets/molecules/note_callout.dart';
import 'package:eventor/features/booking_detail/view/widgets/booking_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/booking_fakes.dart';
import '../../support/test_app.dart';

void main() {
  /// Opens B5 for a pending request, as booking detail does.
  Future<void> openSheet(WidgetTester tester) async {
    await pumpAppWidget(
      tester,
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showCancelBookingSheet(
            context,
            booking: testBooking(status: 'pending'),
            daysToEvent: 12,
            maxReason: 60,
            onCancel: (_) async => null,
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  FocusNode reasonFocus(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText)).focusNode;

  testWidgets('the reason keeps focus when the keyboard rises (B5 → B5a)', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetViewInsets);
    await openSheet(tester);
    expect(find.byType(NoteCallout), findsOneWidget);

    await tester.tap(find.byType(EditableText));
    await tester.pump();
    expect(reasonFocus(tester).hasFocus, isTrue);

    // The keyboard comes up: B5a folds the recap and the note away.
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pumpAndSettle();

    expect(find.byType(NoteCallout), findsNothing);
    expect(reasonFocus(tester).hasFocus, isTrue);

    // And what is typed survives the change too.
    await tester.enterText(find.byType(EditableText), 'Plans changed');
    await tester.pump();
    expect(find.text('Plans changed'), findsOneWidget);
    expect(reasonFocus(tester).hasFocus, isTrue);
  });
}

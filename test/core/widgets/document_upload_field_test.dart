import 'package:eventor/core/widgets/document_upload_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  const String label = 'National ID card';
  const String helper = 'Front and back, in one file';
  const String error = 'Attach this document.';

  Future<int> pumpField(
    WidgetTester tester, {
    String? fileName,
    String? helperText = helper,
    String? errorText,
  }) async {
    int taps = 0;
    await pumpAppWidget(
      tester,
      DocumentUploadField(
        label: label,
        fileName: fileName,
        helperText: helperText,
        errorText: errorText,
        onTap: () => taps++,
      ),
    );
    return taps;
  }

  group('DocumentUploadField', () {
    testWidgets('states which paper is meant while it is empty',
        (WidgetTester tester) async {
      await pumpField(tester);

      expect(find.text(label), findsOneWidget);
      expect(find.text(helper), findsOneWidget);
    });

    testWidgets('drops the instruction once a file is attached',
        (WidgetTester tester) async {
      await pumpField(tester, fileName: 'id-card.pdf');

      // The rule has been met, so it has nothing left to say — the same rule
      // the typed fields follow.
      expect(find.text(helper), findsNothing);
      expect(find.text('id-card.pdf'), findsOneWidget);
    });

    testWidgets('prefers the error over the instruction',
        (WidgetTester tester) async {
      await pumpField(tester, errorText: error);

      expect(find.text(error), findsOneWidget);
      expect(find.text(helper), findsNothing);
    });

    testWidgets('keeps showing the error even once something is attached',
        (WidgetTester tester) async {
      // An error is a verdict on the field, not on its emptiness, so it
      // outranks both the instruction and the attachment.
      await pumpField(tester, fileName: 'id-card.pdf', errorText: error);

      expect(find.text(error), findsOneWidget);
    });

    testWidgets('says nothing at all when there is nothing to say',
        (WidgetTester tester) async {
      await pumpField(tester, fileName: 'id-card.pdf', helperText: null);

      // The label and the file name, and no third line.
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('reports the tap that opens the picker',
        (WidgetTester tester) async {
      int taps = 0;
      await pumpAppWidget(
        tester,
        DocumentUploadField(
          label: label,
          helperText: helper,
          onTap: () => taps++,
        ),
      );

      await tester.tap(find.text(label));
      // The label is outside the box; the box itself is what takes the tap.
      expect(taps, 0);

      await tester.tap(find.byType(CustomPaint).last);
      expect(taps, 1);
    });

    testWidgets('announces itself as a button carrying its file',
        (WidgetTester tester) async {
      await pumpField(tester, fileName: 'id-card.pdf');

      expect(
        tester.getSemantics(find.byType(GestureDetector)),
        matchesSemantics(isButton: true, label: label, value: 'id-card.pdf'),
      );
    });
  });
}

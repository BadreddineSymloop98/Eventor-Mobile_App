import 'package:eventor/core/widgets/atoms/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  group('AppAvatar.initialsOf', () {
    test('takes the first and last word', () {
      expect(AppAvatar.initialsOf('Amina Benali'), 'AB');
      expect(AppAvatar.initialsOf('Amina Zohra Benali'), 'AB');
      expect(AppAvatar.initialsOf('Studio Lumière'), 'SL');
    });

    test('takes one letter from a single word', () {
      expect(AppAvatar.initialsOf('Amina'), 'A');
    });

    test('capitalises, accents included', () {
      expect(AppAvatar.initialsOf('élodie durand'), 'ÉD');
    });

    test('ignores surrounding and repeated spaces', () {
      expect(AppAvatar.initialsOf('  Amina   Benali  '), 'AB');
    });

    test('is empty for a blank name', () {
      expect(AppAvatar.initialsOf(''), '');
      expect(AppAvatar.initialsOf('   '), '');
    });

    test('works on Arabic names', () {
      // Arabic has no case; the first letters come through untouched.
      expect(AppAvatar.initialsOf('أمينة بن علي'), 'أع');
      expect(AppAvatar.initialsOf('ياسين'), 'ي');
    });

    test('keeps a letter whole when it is more than one code unit', () {
      // An emoji or a combined accent is one character to a reader; cutting
      // it in half would leave a broken glyph.
      expect(AppAvatar.initialsOf('👩🏽 Benali'), '👩🏽B');
    });
  });

  group('AppAvatar', () {
    testWidgets('shows initials when there is no photo',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const Center(child: AppAvatar(name: 'Amina Benali')),
      );

      expect(find.text('AB'), findsOneWidget);
    });

    testWidgets('announces the name, not the initials',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const Center(child: AppAvatar(name: 'أمينة بن علي')),
        locale: arabicLocale,
      );

      expect(
        tester.getSemantics(find.byType(AppAvatar)),
        isSemantics(label: 'أمينة بن علي', isImage: true),
      );
    });

    testWidgets('stays round at every size', (WidgetTester tester) async {
      for (final AppAvatarSize size in AppAvatarSize.values) {
        await pumpAppWidget(
          tester,
          Center(child: AppAvatar(name: 'Amina Benali', size: size)),
        );

        final Size drawn = tester.getSize(find.byType(AppAvatar));
        expect(drawn.width, drawn.height, reason: size.name);
      }
    });
  });
}

import 'package:eventor/core/widgets/back_icon_button.dart';
import 'package:eventor/core/widgets/language_switch.dart';
import 'package:eventor/core/widgets/main_button.dart';
import 'package:eventor/features/role_selection/model/user_role.dart';
import 'package:eventor/features/role_selection/view/role_selection_view.dart';
import 'package:eventor/features/role_selection/view/widgets/role_card.dart';
import 'package:eventor/features/role_selection/view_model/role_selection_view_model.dart';
import 'package:eventor/features/welcome/view/welcome_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  /// Walks from the welcome screen into role selection, the way a user gets
  /// there.
  Future<void> pumpRoleSelection(
    WidgetTester tester, {
    Locale? locale,
  }) async {
    await tester.pumpWidget(
      await buildTestApp(hasSeenOnboarding: true, locale: locale),
    );
    await passSplash(tester);

    await tester.tap(find.text(l10n(tester).createAccount));
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectionView), findsOneWidget);
  }

  RoleCard cardFor(WidgetTester tester, UserRole role) => tester
      .widgetList<RoleCard>(find.byType(RoleCard))
      .firstWhere((RoleCard card) => card.role == role);

  group('RoleSelectionView', () {
    testWidgets('offers every role, with its own description',
        (WidgetTester tester) async {
      await pumpRoleSelection(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.byType(RoleCard), findsNWidgets(UserRole.values.length));
      expect(find.text(strings.rolePlannerTitle), findsOneWidget);
      expect(find.text(strings.roleProviderTitle), findsOneWidget);
      expect(find.text(strings.roleInstitutionTitle), findsOneWidget);
      expect(find.text(strings.rolePlannerDescription), findsOneWidget);
    });

    testWidgets('warns that the choice is permanent',
        (WidgetTester tester) async {
      await pumpRoleSelection(tester);

      expect(find.text(l10n(tester).roleSelectionSubtitle), findsOneWidget);
    });

    testWidgets('starts with nothing selected and Continue unavailable',
        (WidgetTester tester) async {
      // The screen says the choice cannot be undone, so it must not be made
      // for the user by a default.
      await pumpRoleSelection(tester);

      for (final UserRole role in UserRole.values) {
        expect(cardFor(tester, role).isSelected, isFalse);
      }

      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(MainButton)),
        isSemantics(
          label: l10n(tester).continueAction,
          isButton: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('selecting a role enables Continue',
        (WidgetTester tester) async {
      await pumpRoleSelection(tester);

      await tester.tap(find.text(l10n(tester).roleProviderTitle));
      await tester.pumpAndSettle();

      expect(cardFor(tester, UserRole.provider).isSelected, isTrue);

      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(MainButton)),
        isSemantics(
          label: l10n(tester).continueAction,
          isButton: true,
          isEnabled: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('only one role can be selected at a time',
        (WidgetTester tester) async {
      await pumpRoleSelection(tester);
      final AppLocalizations strings = l10n(tester);

      await tester.tap(find.text(strings.rolePlannerTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.roleInstitutionTitle));
      await tester.pumpAndSettle();

      expect(cardFor(tester, UserRole.planner).isSelected, isFalse);
      expect(cardFor(tester, UserRole.institution).isSelected, isTrue);
    });

    testWidgets('goes back to the welcome screen', (WidgetTester tester) async {
      await pumpRoleSelection(tester);

      await tester.tap(find.byType(BackIconButton));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeView), findsOneWidget);
      expect(find.byType(RoleSelectionView), findsNothing);
    });

    testWidgets('keeps the language switch available',
        (WidgetTester tester) async {
      await pumpRoleSelection(tester);

      expect(find.byType(LanguageSwitch), findsOneWidget);
    });
  });

  group('RoleSelectionViewModel', () {
    late RoleSelectionViewModel viewModel;

    setUp(() => viewModel = RoleSelectionViewModel());
    tearDown(() => viewModel.dispose());

    test('starts with no role and cannot continue', () {
      expect(viewModel.selectedRole, isNull);
      expect(viewModel.canContinue, isFalse);
    });

    test('notifies when the choice changes', () {
      int notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.selectRole(UserRole.planner);
      expect(notifications, 1);

      // Re-picking the same role is a no-op, not a toggle: there is no valid
      // "no role" state to go back to once the user has answered.
      viewModel.selectRole(UserRole.planner);
      expect(notifications, 1);
      expect(viewModel.selectedRole, UserRole.planner);

      viewModel.selectRole(UserRole.provider);
      expect(notifications, 2);
      expect(viewModel.selectedRole, UserRole.provider);
    });
  });

  group('RoleSelectionView in Arabic', () {
    testWidgets('shows the Arabic copy and mirrors the layout',
        (WidgetTester tester) async {
      await pumpRoleSelection(tester, locale: arabicLocale);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.roleSelectionTitle), findsOneWidget);
      expect(find.text(strings.rolePlannerTitle), findsOneWidget);
      expect(find.text('I\'m planning an event'), findsNothing);
      expect(
        Directionality.of(tester.element(find.byType(RoleSelectionView))),
        TextDirection.rtl,
      );
    });
  });
}

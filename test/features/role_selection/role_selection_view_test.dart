import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/widgets/molecules/back_icon_button.dart';
import 'package:eventor/core/widgets/molecules/main_button.dart';
import 'package:eventor/core/widgets/molecules/role_card.dart';
import 'package:eventor/features/register/view/register_view.dart';
import 'package:eventor/features/register/view_model/register_view_model.dart';
import 'package:eventor/features/role_selection/view/role_selection_view.dart';
import 'package:eventor/features/role_selection/view_model/role_selection_view_model.dart';
import 'package:eventor/features/welcome/view/welcome_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  /// From welcome into role selection, the way a user arrives.
  Future<void> pumpRoleSelection(WidgetTester tester, {Locale? locale}) async {
    await startApp(
      tester,
      await buildTestApp(hasSeenOnboarding: true, locale: locale),
    );
    await tapAndSettle(tester, button(l10n(tester).createAccount));
    expect(find.byType(RoleSelectionView), findsOneWidget);
  }

  RoleCard card(WidgetTester tester, String title) =>
      tester.widget<RoleCard>(find.widgetWithText(RoleCard, title));

  /// The role the register form on screen was opened for.
  UserRole registeringAs(WidgetTester tester) =>
      tester.element(find.byType(RegisterView)).read<RegisterViewModel>().role;

  group('RoleSelectionViewModel', () {
    test('offers the two app roles, client first, none picked', () {
      final RoleSelectionViewModel viewModel = RoleSelectionViewModel();
      addTearDown(viewModel.dispose);

      expect(RoleSelectionViewModel.roles, <UserRole>[
        UserRole.client,
        UserRole.provider,
      ]);
      expect(viewModel.selectedRole, isNull);
      expect(viewModel.canContinue, isFalse);
    });

    test('re-selecting the picked role is not a toggle', () {
      final RoleSelectionViewModel viewModel = RoleSelectionViewModel();
      addTearDown(viewModel.dispose);
      int notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.selectRole(UserRole.provider);
      viewModel.selectRole(UserRole.provider);

      expect(viewModel.selectedRole, UserRole.provider);
      expect(notifications, 1);
    });
  });

  group('RoleSelectionView', () {
    testWidgets('shows a card for each of the two roles', (
      WidgetTester tester,
    ) async {
      await pumpRoleSelection(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.roleSelectionTitle), findsOneWidget);
      expect(find.byType(RoleCard), findsNWidgets(2));
      expect(find.text(strings.roleClientTitle), findsOneWidget);
      expect(find.text(strings.roleClientDescription), findsOneWidget);
      expect(find.text(strings.roleProviderTitle), findsOneWidget);
      expect(find.text(strings.roleProviderDescription), findsOneWidget);
    });

    testWidgets('Continue spans the content width, not just its label', (
      WidgetTester tester,
    ) async {
      await pumpRoleSelection(tester);
      final AppLocalizations strings = l10n(tester);

      // The cards stretch between the screen's gutters, so they are the
      // width the button must match.
      final Rect cardRect = tester.getRect(
        find.widgetWithText(RoleCard, strings.roleClientTitle),
      );
      final Rect buttonRect = tester.getRect(
        find.widgetWithText(MainButton, strings.continueAction),
      );

      expect(buttonRect.left, moreOrLessEquals(cardRect.left));
      expect(buttonRect.width, moreOrLessEquals(cardRect.width));
    });

    testWidgets('nothing is picked and Continue waits for a choice', (
      WidgetTester tester,
    ) async {
      await pumpRoleSelection(tester);
      final AppLocalizations strings = l10n(tester);

      expect(card(tester, strings.roleClientTitle).isSelected, isFalse);
      expect(card(tester, strings.roleProviderTitle).isSelected, isFalse);
      expect(isTappable(tester, strings.continueAction), isFalse);

      await tapAndSettle(tester, button(strings.continueAction));
      expect(find.byType(RoleSelectionView), findsOneWidget);
    });

    testWidgets('picking a card selects it alone and allows Continue', (
      WidgetTester tester,
    ) async {
      await pumpRoleSelection(tester);
      final AppLocalizations strings = l10n(tester);

      await tapAndSettle(tester, find.text(strings.roleClientTitle));
      expect(card(tester, strings.roleClientTitle).isSelected, isTrue);
      expect(isTappable(tester, strings.continueAction), isTrue);

      await tapAndSettle(tester, find.text(strings.roleProviderTitle));
      expect(card(tester, strings.roleClientTitle).isSelected, isFalse);
      expect(card(tester, strings.roleProviderTitle).isSelected, isTrue);
    });

    testWidgets('Continue as a client pushes the client register form', (
      WidgetTester tester,
    ) async {
      await pumpRoleSelection(tester);
      final AppLocalizations strings = l10n(tester);

      await tapAndSettle(tester, find.text(strings.roleClientTitle));
      await tapAndSettle(tester, button(strings.continueAction));

      expect(find.byType(RegisterView), findsOneWidget);
      expect(registeringAs(tester), UserRole.client);
    });

    testWidgets('Continue as a provider pushes the provider register form', (
      WidgetTester tester,
    ) async {
      await pumpRoleSelection(tester);
      final AppLocalizations strings = l10n(tester);

      await tapAndSettle(tester, find.text(strings.roleProviderTitle));
      await tapAndSettle(tester, button(strings.continueAction));

      expect(find.byType(RegisterView), findsOneWidget);
      expect(registeringAs(tester), UserRole.provider);
      // Pushed, so the choice can still be reconsidered.
      await tapAndSettle(tester, find.byType(BackIconButton));
      expect(find.byType(RoleSelectionView), findsOneWidget);
    });

    testWidgets('Back returns to welcome', (WidgetTester tester) async {
      await pumpRoleSelection(tester);

      await tapAndSettle(tester, find.byType(BackIconButton));

      expect(find.byType(WelcomeView), findsOneWidget);
    });
  });

  group('RoleSelectionView in Arabic', () {
    testWidgets('mirrors the screen and the Back chevron side', (
      WidgetTester tester,
    ) async {
      await pumpRoleSelection(tester, locale: arabicLocale);

      expect(
        Directionality.of(tester.element(find.byType(RoleSelectionView))),
        TextDirection.rtl,
      );
      expect(find.text(l10n(tester).roleClientTitle), findsOneWidget);
      // Back sits on the reader's starting side — the right in Arabic.
      final double screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(
        tester.getCenter(find.byType(BackIconButton)).dx,
        greaterThan(screenWidth / 2),
      );
    });
  });
}

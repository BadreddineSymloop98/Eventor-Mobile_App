import 'package:eventor/core/bookings/bookings_repository.dart';
import 'package:eventor/core/budget/budget_repository.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/widgets/molecules/app_select_field.dart';
import 'package:eventor/core/widgets/molecules/app_text_field.dart';
import 'package:eventor/features/budget/view/budget_form_view.dart';
import 'package:eventor/features/budget/view/expense_form_view.dart';
import 'package:eventor/features/budget/view/link_booking_view.dart';
import 'package:eventor/features/home/view/home_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/budget_fakes.dart';
import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  Future<TestApp> openBudget(
    WidgetTester tester, {
    FakeBudgetRepository? budget,
    FakeBookingsRepository? bookings,
  }) async {
    final TestApp app = await buildTestApp(
      hasSeenOnboarding: true,
      auth: FakeAuthRepository()..restoredUser = testUser(),
      budget: budget,
      bookings: bookings,
    );
    await startAt(tester, app, AppRoutes.budget);
    return app;
  }

  Finder field(String label) => find.descendant(
        of: find.widgetWithText(AppTextField, label),
        matching: find.byType(TextField),
      );

  String location(TestApp app) =>
      app.services.router.routerDelegate.currentConfiguration.uri.toString();

  Future<void> back(WidgetTester tester) =>
      tapAndSettle(tester, find.bySemanticsLabel(l10n(tester).backLabel).first);

  testWidgets('offers 18a with no budget, then shows 18c once created',
      (WidgetTester tester) async {
    final TestApp app = await openBudget(tester);
    final AppLocalizations strings = l10n(tester);

    expect(find.byType(BudgetFormView), findsOneWidget);
    expect(find.text(strings.budgetCreateIntroTitle), findsOneWidget);
    expect(isTappable(tester, strings.budgetCreateAction), isFalse);

    await typeInto(tester, field(strings.budgetNameLabel), 'Our wedding');
    await typeInto(tester, field(strings.budgetTotalLabel), '400000');
    expect(isTappable(tester, strings.budgetCreateAction), isTrue);
    await tapAndSettle(tester, button(strings.budgetCreateAction));

    expect(app.budget.calls, contains('save:Our wedding'));
    expect(find.text(strings.budgetNoLinesTitle), findsOneWidget);
    expect(find.text(strings.budgetEdit), findsOneWidget);
    expect(location(app), AppRoutes.budget);
  });

  testWidgets('lists the lines, booked and not (18)', (WidgetTester tester) async {
    await openBudget(
      tester,
      budget: FakeBudgetRepository(
        budget: testBudget(items: <BudgetItem>[
          testLine(planned: 120000, spent: 110000, bookingId: 'bk-1', reference: 'EVT-2031'),
          testLine(id: 'line-2', label: 'Catering', planned: 150000, position: 1),
        ]),
      ),
    );
    final AppLocalizations strings = l10n(tester);

    expect(find.text('Venue'), findsOneWidget);
    expect(find.text('Salle Yasmine · EVT-2031'), findsOneWidget);
    expect(find.text('Catering'), findsOneWidget);
    expect(find.text(strings.budgetNotBookedYet), findsOneWidget);
    expect(find.text(strings.budgetOverTitle), findsNothing);
  });

  testWidgets('warns when over budget (18g)', (WidgetTester tester) async {
    await openBudget(
      tester,
      budget: FakeBudgetRepository(
        budget: testBudget(total: 100000, items: <BudgetItem>[testLine(spent: 150000)]),
      ),
    );

    expect(find.text(l10n(tester).budgetOverTitle), findsOneWidget);
  });

  testWidgets('adds an expense line (18d)', (WidgetTester tester) async {
    final TestApp app = await openBudget(
      tester,
      budget: FakeBudgetRepository(budget: testBudget()),
    );
    final AppLocalizations strings = l10n(tester);

    await tapAndSettle(tester, button(strings.budgetAddExpense));
    expect(find.byType(ExpenseFormView), findsOneWidget);
    expect(isTappable(tester, strings.expenseAddLine), isFalse);

    await typeInto(tester, field(strings.expenseLabelLabel), 'Wedding cake');
    await typeInto(tester, field(strings.expensePlannedLabel), '25000');
    await tapAndSettle(tester, button(strings.expenseAddLine));

    expect(find.byType(ExpenseFormView), findsNothing);
    expect(find.text('Wedding cake'), findsOneWidget);
    expect(app.budget.budget?.items.single.plannedAmount, '25000.00');
  });

  testWidgets('turns into 18i when the budget is full', (WidgetTester tester) async {
    await openBudget(
      tester,
      budget: FakeBudgetRepository(budget: testBudget(items: <BudgetItem>[testLine()]))
        ..limit = 1,
    );
    final AppLocalizations strings = l10n(tester);

    await tapAndSettle(tester, button(strings.budgetAddExpense));
    await typeInto(tester, field(strings.expenseLabelLabel), 'One too many');
    await tapAndSettle(tester, button(strings.expenseAddLine));

    expect(find.byType(ExpenseFormView), findsOneWidget);
    expect(find.text(strings.expenseFullTitle), findsOneWidget);
    expect(isTappable(tester, strings.expenseAddLine), isFalse);
  });

  testWidgets('deletes a line after asking (18e)', (WidgetTester tester) async {
    final TestApp app = await openBudget(
      tester,
      budget: FakeBudgetRepository(budget: testBudget(items: <BudgetItem>[testLine()])),
    );
    final AppLocalizations strings = l10n(tester);

    await tapAndSettle(tester, find.text('Venue'));
    expect(find.text(strings.expenseLineTitle), findsOneWidget);

    await tapAndSettle(tester, find.text(strings.expenseDelete));
    expect(find.text(strings.expenseDeleteTitle), findsOneWidget);

    await tapAndSettle(tester, button(strings.expenseDeleteKeep));
    expect(app.budget.calls.where((String c) => c.startsWith('delete')), isEmpty);

    await tapAndSettle(tester, find.text(strings.expenseDelete));
    await tapAndSettle(tester, button(strings.expenseDeleteConfirm));

    expect(app.budget.calls.last, 'delete:line-1');
    expect(find.byType(ExpenseFormView), findsNothing);
    expect(find.text(strings.budgetNoLinesTitle), findsOneWidget);
  });

  testWidgets('asks before throwing away an unsaved line', (WidgetTester tester) async {
    await openBudget(tester, budget: FakeBudgetRepository(budget: testBudget()));
    final AppLocalizations strings = l10n(tester);

    await tapAndSettle(tester, button(strings.budgetAddExpense));
    await typeInto(tester, field(strings.expenseLabelLabel), 'Half typed');
    await back(tester);

    expect(find.text(strings.discardTitle), findsOneWidget);
    await tapAndSettle(tester, button(strings.discardKeep));
    expect(find.byType(ExpenseFormView), findsOneWidget);

    await back(tester);
    await tapAndSettle(tester, button(strings.discardConfirm));
    expect(find.byType(ExpenseFormView), findsNothing);
  });

  testWidgets('leaves an untouched form without asking', (WidgetTester tester) async {
    await openBudget(tester, budget: FakeBudgetRepository(budget: testBudget()));
    final AppLocalizations strings = l10n(tester);

    await tapAndSettle(tester, button(strings.budgetAddExpense));
    await back(tester);

    expect(find.text(strings.discardTitle), findsNothing);
    expect(find.byType(ExpenseFormView), findsNothing);
  });

  testWidgets('links a booking to a line (18h)', (WidgetTester tester) async {
    final TestApp app = await openBudget(
      tester,
      budget: FakeBudgetRepository(
        budget: testBudget(items: <BudgetItem>[
          testLine(label: 'Decoration'),
          testLine(id: 'line-2', label: 'Venue', bookingId: 'bk-used', position: 1),
        ]),
      ),
      bookings: FakeBookingsRepository()
        ..tabs[BookingTab.upcoming] = <BookingCard>[
          testBooking(id: 'bk-free', reference: 'EVT-2044', provider: 'Fleurs de Yasmina'),
          testBooking(id: 'bk-used', reference: 'EVT-2031', provider: 'Salle Yasmine'),
        ],
    );
    final AppLocalizations strings = l10n(tester);

    await tapAndSettle(tester, find.text('Decoration'));
    await tapAndSettle(tester, find.widgetWithText(AppSelectField, strings.expenseBookingLabel));
    expect(find.byType(LinkBookingView), findsOneWidget);
    expect(find.text(strings.linkBookingUsedOn('Venue')), findsOneWidget);
    expect(isTappable(tester, strings.linkBookingAction), isFalse);

    // The one on "Venue" cannot be taken.
    await tapAndSettle(tester, find.text('Salle Yasmine'));
    expect(isTappable(tester, strings.linkBookingAction), isFalse);

    await tapAndSettle(tester, find.text('Fleurs de Yasmina'));
    await tapAndSettle(tester, button(strings.linkBookingAction));

    expect(find.byType(LinkBookingView), findsNothing);
    expect(find.text('EVT-2044 · Fleurs de Yasmina'), findsOneWidget);

    await tapAndSettle(tester, button(strings.expenseSaveLine));
    expect(app.budget.calls.last, 'update:line-1:bookingId');
  });

  testWidgets('deletes the budget from 18f, after asking, back to Home',
      (WidgetTester tester) async {
    final TestApp app = await openBudget(
      tester,
      budget: FakeBudgetRepository(budget: testBudget(items: <BudgetItem>[testLine()])),
    );
    final AppLocalizations strings = l10n(tester);

    await tapAndSettle(tester, find.text(strings.budgetEdit));
    await tapAndSettle(tester, button(strings.budgetDelete));
    expect(find.text(strings.budgetDeleteTitle), findsOneWidget);

    await tapAndSettle(tester, button(strings.expenseDeleteKeep));
    expect(app.budget.budget, isNotNull, reason: 'Keep it changes nothing');

    await tapAndSettle(tester, button(strings.budgetDelete));
    await tapAndSettle(tester, button(strings.budgetDeleteConfirm));

    expect(app.budget.calls.last, 'deleteBudget');
    expect(find.text(strings.budgetDeleted), findsOneWidget);
    expect(location(app), AppRoutes.home);
  });

  testWidgets('says deleting is not available while the live API lacks it',
      (WidgetTester tester) async {
    final TestApp app = await openBudget(
      tester,
      budget: FakeBudgetRepository(budget: testBudget()),
    );
    final AppLocalizations strings = l10n(tester);

    await tapAndSettle(tester, find.text(strings.budgetEdit));
    app.budget.failNext = apiFailure(ApiErrorCode.routeNotFound, statusCode: 404);
    await tapAndSettle(tester, button(strings.budgetDelete));
    await tapAndSettle(tester, button(strings.budgetDeleteConfirm));

    expect(find.text(strings.budgetDeleteUnavailable), findsOneWidget);
    expect(find.byType(BudgetFormView), findsOneWidget);
  });

  testWidgets('opens from the Home card, and Home follows', (WidgetTester tester) async {
    final TestApp app = await buildTestApp(
      hasSeenOnboarding: true,
      auth: FakeAuthRepository()..restoredUser = testUser(),
    );
    await startApp(tester, app);
    expect(find.byType(HomeView), findsOneWidget);
    final int homeLoads = app.catalog.homeCalls;

    await tester.scrollUntilVisible(find.text(l10n(tester).homeYourBudget), 300);
    await tapAndSettle(tester, find.text(l10n(tester).budgetDetails));
    expect(location(app), AppRoutes.budget);

    await back(tester);

    expect(find.byType(HomeView), findsOneWidget);
    expect(app.catalog.homeCalls, homeLoads + 1);
  });
}

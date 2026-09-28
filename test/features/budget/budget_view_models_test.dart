import 'dart:async';

import 'package:eventor/core/bookings/bookings_repository.dart';
import 'package:eventor/core/budget/budget_repository.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/features/budget/view_model/budget_form_view_model.dart';
import 'package:eventor/features/budget/view_model/budget_view_model.dart';
import 'package:eventor/features/budget/view_model/expense_form_view_model.dart';
import 'package:eventor/features/budget/view_model/link_booking_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/budget_fakes.dart';
import '../../support/fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  group('BudgetViewModel', () {
    Future<BudgetViewModel> build(FakeBudgetRepository repository) async {
      final BudgetViewModel viewModel = BudgetViewModel(budgets: repository);
      addTearDown(viewModel.dispose);
      await flushAsync();
      return viewModel;
    }

    test('is on the skeleton until the first answer', () {
      final FakeBudgetRepository repository = FakeBudgetRepository()
        ..gate = Completer<void>();
      final BudgetViewModel viewModel = BudgetViewModel(budgets: repository);
      addTearDown(viewModel.dispose);

      expect(viewModel.isFirstLoad, isTrue);
      expect(viewModel.isMissing, isFalse);
    });

    test('shows 18a when there is no budget', () async {
      final BudgetViewModel viewModel = await build(FakeBudgetRepository());

      expect(viewModel.isMissing, isTrue);
      expect(viewModel.isFirstLoad, isFalse);
    });

    test('shows the budget once loaded', () async {
      final BudgetViewModel viewModel = await build(
        FakeBudgetRepository(budget: testBudget(items: <BudgetItem>[testLine()])),
      );

      expect(viewModel.budget?.itemsCount, 1);
      expect(viewModel.isMissing, isFalse);
    });

    test('reports a failed first load and retries', () async {
      final FakeBudgetRepository repository = FakeBudgetRepository(budget: testBudget())
        ..failNext = const NetworkFailure();
      final BudgetViewModel viewModel = await build(repository);

      expect(viewModel.hasError, isTrue);
      expect(viewModel.isMissing, isFalse);

      await viewModel.load();

      expect(viewModel.hasError, isFalse);
      expect(viewModel.budget, isNotNull);
    });

    test('keeps what is on screen when a refresh fails', () async {
      final FakeBudgetRepository repository = FakeBudgetRepository(budget: testBudget());
      final BudgetViewModel viewModel = await build(repository);
      repository.failNext = const NetworkFailure();

      final Failure? failure = await viewModel.refresh();

      expect(failure, isA<NetworkFailure>());
      expect(viewModel.budget, isNotNull);
    });

    test('applies what another screen got back, without a call', () async {
      final FakeBudgetRepository repository = FakeBudgetRepository();
      final BudgetViewModel viewModel = await build(repository);
      final int calls = repository.calls.length;

      viewModel.apply(testBudget(title: 'Created'));

      expect(viewModel.budget?.title, 'Created');
      expect(viewModel.isMissing, isFalse);
      expect(repository.calls.length, calls);
    });
  });

  group('BudgetFormViewModel', () {
    test('creates once there is a name and a total above zero (18a)', () async {
      final FakeBudgetRepository repository = FakeBudgetRepository();
      final BudgetFormViewModel viewModel = BudgetFormViewModel(budgets: repository);
      addTearDown(viewModel.dispose);

      expect(viewModel.canSubmit, isFalse);
      viewModel.setTitle('  Our wedding ');
      expect(viewModel.canSubmit, isFalse);
      viewModel.setTotal(0);
      expect(viewModel.canSubmit, isFalse);
      viewModel.setTotal(400000);
      expect(viewModel.canSubmit, isTrue);

      final Budget? saved = await viewModel.submit();

      expect(saved?.title, 'Our wedding');
      expect(saved?.totalAmount, '400000.00');
      expect(repository.calls.last, 'save:Our wedding');
    });

    test('is dirty once anything is typed on 18a, and clean after saving', () async {
      final BudgetFormViewModel viewModel =
          BudgetFormViewModel(budgets: FakeBudgetRepository());
      addTearDown(viewModel.dispose);

      expect(viewModel.isDirty, isFalse);
      viewModel.setEventDate(DateTime(2026, 3, 14));
      expect(viewModel.isDirty, isTrue);
      viewModel
        ..setTitle('T')
        ..setTotal(10);

      await viewModel.submit();

      expect(viewModel.isDirty, isFalse);
    });

    test('saves only once something changed on 18f', () {
      final Budget budget = testBudget(eventDate: DateTime(2026, 3, 14));
      final BudgetFormViewModel viewModel =
          BudgetFormViewModel(budgets: FakeBudgetRepository(budget: budget), initial: budget);
      addTearDown(viewModel.dispose);

      expect(viewModel.title, 'Our wedding');
      expect(viewModel.total, 400000);
      expect(viewModel.isDirty, isFalse);
      expect(viewModel.canSubmit, isFalse);

      viewModel.setEventDate(DateTime(2026, 3, 14, 12));
      expect(viewModel.isDirty, isFalse, reason: 'same day');

      viewModel.setEventDate(null);
      expect(viewModel.isDirty, isTrue);
      expect(viewModel.canSubmit, isTrue);
    });

    test('keeps centimes set elsewhere when the dinars did not change', () async {
      final Budget budget = Budget(
        id: 'b',
        title: 'T',
        eventDate: null,
        totalAmount: '400000.50',
        plannedTotal: '0.00',
        spentTotal: '0.00',
        remaining: '400000.50',
        spentPercent: 0,
        itemsCount: 0,
        bookedCount: 0,
        items: const <BudgetItem>[],
      );
      final _RecordingBudgetRepository repository = _RecordingBudgetRepository(budget);
      final BudgetFormViewModel viewModel =
          BudgetFormViewModel(budgets: repository, initial: budget);
      addTearDown(viewModel.dispose);

      viewModel.setTitle('New name');
      await viewModel.submit();

      expect(repository.lastPlan?.totalAmount, '400000.50');
    });

    test('deletes the budget from 18f and lets the screen close', () async {
      final Budget budget = testBudget();
      final FakeBudgetRepository repository = FakeBudgetRepository(budget: budget);
      final BudgetFormViewModel viewModel =
          BudgetFormViewModel(budgets: repository, initial: budget)..setTitle('Changed');
      addTearDown(viewModel.dispose);

      final Future<Failure?> pending = viewModel.delete();
      expect(viewModel.isDeleting, isTrue);
      final Failure? failure = await pending;

      expect(failure, isNull);
      expect(repository.calls.last, 'deleteBudget');
      expect(repository.budget, isNull);
      expect(viewModel.isDeleting, isFalse);
      expect(viewModel.isDirty, isFalse, reason: 'nothing left to discard');
    });

    test('hands back why a delete failed, the form untouched', () async {
      final Budget budget = testBudget();
      final FakeBudgetRepository repository = FakeBudgetRepository(budget: budget)
        ..failNext = apiFailure(ApiErrorCode.routeNotFound, statusCode: 404);
      final BudgetFormViewModel viewModel =
          BudgetFormViewModel(budgets: repository, initial: budget);
      addTearDown(viewModel.dispose);

      final Failure? failure = await viewModel.delete();

      expect(failure, isA<ApiFailure>());
      expect(viewModel.failure, isNull, reason: 'returned, not set');
      expect(repository.budget, isNotNull);
    });

    test('cannot delete from 18a, where there is nothing yet', () async {
      final FakeBudgetRepository repository = FakeBudgetRepository();
      final BudgetFormViewModel viewModel = BudgetFormViewModel(budgets: repository);
      addTearDown(viewModel.dispose);

      expect(await viewModel.delete(), isNull);
      expect(repository.calls, isEmpty);
    });

    test('reports a failed save and stays dirty', () async {
      final FakeBudgetRepository repository = FakeBudgetRepository()
        ..failNext = const NetworkFailure();
      final BudgetFormViewModel viewModel = BudgetFormViewModel(budgets: repository)
        ..setTitle('T')
        ..setTotal(1);
      addTearDown(viewModel.dispose);

      final Budget? saved = await viewModel.submit();

      expect(saved, isNull);
      expect(viewModel.failure, isA<NetworkFailure>());
      expect(viewModel.isDirty, isTrue);
    });
  });

  group('ExpenseFormViewModel', () {
    final CategoryRef venue = testCategory();
    final CategoryRef cakes = testCategory(id: 'cat-cakes', name: 'Cakes & pastry', icon: 'cake');

    ExpenseFormViewModel build(
      FakeBudgetRepository repository, {
      BudgetItem? item,
    }) {
      final ExpenseFormViewModel viewModel = ExpenseFormViewModel(
        budgets: repository,
        catalog: FakeCatalogRepository(),
        args: ExpenseLineArgs(budget: repository.budget!, item: item),
      );
      addTearDown(viewModel.dispose);
      return viewModel;
    }

    test('needs only a label to add a line (18d)', () async {
      final FakeBudgetRepository repository = FakeBudgetRepository(budget: testBudget());
      final ExpenseFormViewModel viewModel = build(repository);

      expect(viewModel.canSubmit, isFalse);
      viewModel.setLabel('Wedding cake');
      expect(viewModel.canSubmit, isTrue);

      final Budget? saved = await viewModel.submit();

      expect(saved?.items.single.label, 'Wedding cake');
      expect(saved?.items.single.plannedAmount, '0.00');
      expect(saved?.items.single.spentAmount, '0.00');
    });

    test('names an unnamed line after its category, and follows a new pick', () {
      final ExpenseFormViewModel viewModel = build(FakeBudgetRepository(budget: testBudget()));

      expect(viewModel.setCategory(venue, name: 'Venue'), 'Venue');
      expect(viewModel.label, 'Venue');
      expect(viewModel.setCategory(cakes, name: 'Cakes & pastry'), 'Cakes & pastry');
      expect(viewModel.label, 'Cakes & pastry');
    });

    test('never overwrites a label the client typed', () {
      final ExpenseFormViewModel viewModel = build(FakeBudgetRepository(budget: testBudget()))
        ..setLabel('Floral arch');

      expect(viewModel.setCategory(venue, name: 'Venue'), isNull);
      expect(viewModel.label, 'Floral arch');
      expect(viewModel.category, venue);
    });

    test('turns into 18i when the server refuses the line', () async {
      final FakeBudgetRepository repository =
          FakeBudgetRepository(budget: testBudget(items: <BudgetItem>[testLine()]))
            ..limit = 1;
      final ExpenseFormViewModel viewModel = build(repository)..setLabel('Two');

      final Budget? saved = await viewModel.submit();

      expect(saved, isNull);
      expect(viewModel.isFull, isTrue);
      expect(viewModel.failure, isNull, reason: 'shown as the banner, not a toast');
      expect(viewModel.canSubmit, isFalse);
    });

    test('opens as 18i when the limit is already known', () async {
      final FakeBudgetRepository repository =
          FakeBudgetRepository(budget: testBudget(items: <BudgetItem>[testLine()]))
            ..limit = 1;
      await build(repository).also((ExpenseFormViewModel v) => v.setLabel('x')).submit();

      final ExpenseFormViewModel next = build(repository);

      expect(next.isFull, isTrue);
    });

    test('is never full while editing a line', () async {
      final BudgetItem line = testLine();
      final FakeBudgetRepository repository =
          FakeBudgetRepository(budget: testBudget(items: <BudgetItem>[line]))..limit = 1;
      await build(repository).also((ExpenseFormViewModel v) => v.setLabel('x')).submit();

      expect(build(repository, item: line).isFull, isFalse);
    });

    test('reports other failures as they are', () async {
      final FakeBudgetRepository repository = FakeBudgetRepository(budget: testBudget())
        ..failNext = const NetworkFailure();
      final ExpenseFormViewModel viewModel = build(repository)..setLabel('x');

      await viewModel.submit();

      expect(viewModel.failure, isA<NetworkFailure>());
      expect(viewModel.isFull, isFalse);
    });

    test('opens 18b with the line, clean, and saves only the changes', () async {
      final BudgetItem line = testLine(
        category: venue,
        planned: 30000,
        spent: 25000,
        bookingId: 'bk-1',
        reference: 'EVT-2044',
        provider: 'Fleurs de Yasmina',
      );
      final FakeBudgetRepository repository =
          FakeBudgetRepository(budget: testBudget(items: <BudgetItem>[line]));
      final ExpenseFormViewModel viewModel = build(repository, item: line);

      expect(viewModel.planned, 30000);
      expect(viewModel.spent, 25000);
      expect(viewModel.booking?.reference, 'EVT-2044');
      expect(viewModel.isDirty, isFalse);
      expect(viewModel.canSubmit, isFalse);

      viewModel.setSpent(28000);
      await viewModel.submit();

      expect(repository.calls.last, 'update:${line.id}:spentAmount');
    });

    test('unlinks a booking', () async {
      final BudgetItem line = testLine(bookingId: 'bk-1');
      final FakeBudgetRepository repository =
          FakeBudgetRepository(budget: testBudget(items: <BudgetItem>[line]));
      final ExpenseFormViewModel viewModel = build(repository, item: line)..setBooking(null);

      final Budget? saved = await viewModel.submit();

      expect(repository.calls.last, 'update:${line.id}:bookingId');
      expect(saved?.items.single.isBooked, isFalse);
    });

    test("lists the bookings on the budget's other lines", () {
      final BudgetItem mine = testLine(id: 'mine', bookingId: 'bk-1');
      final BudgetItem other = testLine(id: 'other', label: 'Photography', bookingId: 'bk-2');
      final FakeBudgetRepository repository =
          FakeBudgetRepository(budget: testBudget(items: <BudgetItem>[mine, other, testLine(id: 'free')]));

      expect(build(repository, item: mine).bookingsInUse, <String, String>{'bk-2': 'Photography'});
    });

    test('deletes the line (18e)', () async {
      final BudgetItem line = testLine();
      final FakeBudgetRepository repository =
          FakeBudgetRepository(budget: testBudget(items: <BudgetItem>[line]));
      final ExpenseFormViewModel viewModel = build(repository, item: line);

      final Budget? saved = await viewModel.delete();

      expect(saved?.items, isEmpty);
      expect(repository.calls.last, 'delete:${line.id}');
      expect(viewModel.isDirty, isFalse);
    });

    test('shows the category field loading until the list arrives', () async {
      final FakeCatalogRepository catalog = FakeCatalogRepository()..gate = Completer<void>();
      final ExpenseFormViewModel viewModel = ExpenseFormViewModel(
        budgets: FakeBudgetRepository(budget: testBudget()),
        catalog: catalog,
        args: ExpenseLineArgs(budget: testBudget()),
      );
      addTearDown(viewModel.dispose);

      final Future<List<CategoryWithCount>> pending = viewModel.categories();
      expect(viewModel.isLoadingCategories, isTrue);

      catalog.gate!.complete();
      await pending;

      expect(viewModel.isLoadingCategories, isFalse);
    });

    test('tries the categories again after a failed load', () async {
      final _FailingOnceCatalog catalog = _FailingOnceCatalog();
      final ExpenseFormViewModel viewModel = ExpenseFormViewModel(
        budgets: FakeBudgetRepository(budget: testBudget()),
        catalog: catalog,
        args: ExpenseLineArgs(budget: testBudget()),
      );
      addTearDown(viewModel.dispose);

      await expectLater(viewModel.categories(), throwsA(isA<NetworkFailure>()));
      expect(viewModel.isLoadingCategories, isFalse);

      expect(await viewModel.categories(), isNotEmpty);
    });

    test('is deleting while 18e runs, and not after', () async {
      final BudgetItem line = testLine();
      final FakeBudgetRepository repository =
          FakeBudgetRepository(budget: testBudget(items: <BudgetItem>[line]));
      final ExpenseFormViewModel viewModel = build(repository, item: line);
      repository.gate = Completer<void>();

      final Future<Budget?> pending = viewModel.delete();
      expect(viewModel.isDeleting, isTrue);

      repository.gate!.complete();
      await pending;

      expect(viewModel.isDeleting, isFalse);
    });

    test('loads the categories once', () async {
      final ExpenseFormViewModel viewModel = build(FakeBudgetRepository(budget: testBudget()));

      final List<CategoryWithCount> first = await viewModel.categories();
      final List<CategoryWithCount> second = await viewModel.categories();

      expect(identical(first, second), isTrue);
    });
  });

  group('LinkBookingViewModel', () {
    final BookingCard upcoming = testBooking(id: 'up', reference: 'EVT-1');
    final BookingCard pending = testBooking(id: 'pend', reference: 'EVT-2', status: 'pending');
    final BookingCard past = testBooking(id: 'past', reference: 'EVT-3', status: 'completed');

    Future<LinkBookingViewModel> build({
      LinkedBooking? current,
      Map<String, String> usedBy = const <String, String>{},
      FakeBookingsRepository? repository,
    }) async {
      final FakeBookingsRepository bookings = repository ??
          (FakeBookingsRepository()
            ..tabs[BookingTab.upcoming] = <BookingCard>[upcoming]
            ..tabs[BookingTab.pending] = <BookingCard>[pending]
            ..tabs[BookingTab.past] = <BookingCard>[past]
            ..tabs[BookingTab.cancelled] = <BookingCard>[testBooking(id: 'gone', status: 'cancelled')]);
      final LinkBookingViewModel viewModel = LinkBookingViewModel(
        bookings: bookings,
        args: LinkBookingArgs(current: current, usedBy: usedBy),
      );
      addTearDown(viewModel.dispose);
      await flushAsync();
      return viewModel;
    }

    test('lists upcoming, pending and past — never cancelled', () async {
      final LinkBookingViewModel viewModel = await build();

      expect(viewModel.items?.map((BookingCard b) => b.id), <String>['up', 'pend', 'past']);
    });

    test('starts on the line\'s booking, unchanged', () async {
      final LinkBookingViewModel viewModel = await build(
        current: const LinkedBooking(id: 'pend', reference: 'EVT-2', providerName: 'P'),
      );

      expect(viewModel.selectedId, 'pend');
      expect(viewModel.hasChanged, isFalse);
    });

    test('picks a booking and hands it back', () async {
      final LinkBookingViewModel viewModel = await build();

      viewModel.select('past');

      expect(viewModel.hasChanged, isTrue);
      expect(viewModel.choice.booking?.id, 'past');
      expect(viewModel.choice.booking?.reference, 'EVT-3');
    });

    test('will not pick a booking used on another line', () async {
      final LinkBookingViewModel viewModel = await build(usedBy: <String, String>{'up': 'Venue'});

      viewModel.select('up');

      expect(viewModel.selectedId, isNull);
      expect(viewModel.isInUse('up'), isTrue);
    });

    test('unlinks with Not linked', () async {
      final LinkBookingViewModel viewModel = await build(
        current: const LinkedBooking(id: 'up', reference: 'EVT-1', providerName: 'P'),
      );

      viewModel.select(null);

      expect(viewModel.hasChanged, isTrue);
      expect(viewModel.choice.booking, isNull);
    });

    test('keeps showing a linked booking that has left the lists', () async {
      final LinkBookingViewModel viewModel = await build(
        current: const LinkedBooking(id: 'gone', reference: 'EVT-9', providerName: 'Old'),
      );

      expect(viewModel.orphan?.id, 'gone');
      expect(viewModel.choice.booking?.id, 'gone');
    });

    test('reports a failed load and retries', () async {
      final FakeBookingsRepository repository = FakeBookingsRepository()
        ..failNext = const NetworkFailure();
      final LinkBookingViewModel viewModel = await build(repository: repository);

      expect(viewModel.hasError, isTrue);
      expect(viewModel.items, isNull);

      await viewModel.load();

      expect(viewModel.items, isEmpty);
    });

    test('asks for each tab at the largest page', () async {
      final FakeBookingsRepository repository = FakeBookingsRepository();
      await build(repository: repository);

      expect(repository.calls, <String>['list:upcoming:100', 'list:pending:100', 'list:past:100']);
    });
  });
}

extension<T> on T {
  T also(void Function(T value) action) {
    action(this);
    return this;
  }
}

/// Fails its first categories load, then answers.
class _FailingOnceCatalog extends FakeCatalogRepository {
  bool _failed = false;

  @override
  Future<List<CategoryWithCount>> categories() {
    if (!_failed) {
      _failed = true;
      return Future<List<CategoryWithCount>>.error(const NetworkFailure());
    }
    return super.categories();
  }
}

/// Records the plan it was asked to save.
class _RecordingBudgetRepository extends FakeBudgetRepository {
  _RecordingBudgetRepository(Budget budget) : super(budget: budget);

  BudgetPlan? lastPlan;

  @override
  Future<Budget> save(BudgetPlan plan) {
    lastPlan = plan;
    return super.save(plan);
  }
}

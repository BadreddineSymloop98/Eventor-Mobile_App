import 'package:eventor/core/bookings/bookings_repository.dart';
import 'package:eventor/core/budget/budget_repository.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/network/api_page.dart';
import 'package:eventor/mock/mock_backend.dart';
import 'package:eventor/mock/mock_budget.dart';
import 'package:eventor/mock/mock_catalog.dart';
import 'package:eventor/mock/mock_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // A fixed "today", so the seeded dates are stable.
  final DateTime today = DateTime(2026, 9, 24, 10);

  late MockBackend backend;
  late MockAuthRepository auth;
  late MockBudgetRepository budgets;
  late MockBookingsRepository bookings;
  late MockCatalogRepository catalog;

  Future<void> start() async {
    backend = await MockBackend.load(
      prefs: await SharedPreferences.getInstance(),
      latency: Duration.zero,
      now: () => today,
    );
    auth = MockAuthRepository(backend);
    budgets = MockBudgetRepository(
      backend,
      MockCatalogLookups(backend, languageCode: () => 'en'),
    );
    bookings = MockBookingsRepository(backend, languageCode: () => 'en');
    catalog = MockCatalogRepository(backend, languageCode: () => 'en');
  }

  Future<void> signIn(String email) =>
      auth.login(email: email, password: MockBackend.seedPassword);

  const BudgetItemInput cake = BudgetItemInput(
    categoryId: null,
    label: 'Wedding cake',
    plannedAmount: '25000.00',
    spentAmount: '0.00',
    bookingId: null,
  );

  Future<void> expectCode(Future<Object?> call, String code) => expectLater(
        call,
        throwsA(isA<ApiFailure>().having((ApiFailure f) => f.code, 'code', code)),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await start();
  });

  group('the seeded client', () {
    setUp(() => signIn('client@eventor.test'));

    test("has 18's budget: 180 000 of 400 000, 3 of 6 booked", () async {
      final Budget budget = (await budgets.get())!;

      expect(budget.title, 'Our wedding');
      expect(budget.totalAmount, '400000.00');
      expect(budget.spentTotal, '180000.00');
      expect(budget.plannedTotal, '380000.00');
      expect(budget.remaining, '220000.00');
      expect(budget.spentPercent, 45);
      expect(budget.itemsCount, 6);
      expect(budget.bookedCount, 3);
      expect(budget.eventDate, DateTime(2026, 10, 15));
    });

    test('fills the provider and reference of a linked line', () async {
      final BudgetItem venue = (await budgets.get())!.items.first;

      expect(venue.bookingId, 'mock-booking-3');
      expect(venue.bookingReference, 'EVT-002031');
      expect(venue.providerName, isNotEmpty);
      expect(venue.category?.icon, 'building');
    });

    test('goes over budget when the spending passes the total (18g)', () async {
      final Budget budget = (await budgets.get())!;
      final BudgetItem catering = budget.items[3];

      final Budget after = await budgets.updateItem(
        catering,
        BudgetItemInput(
          categoryId: catering.category?.id,
          label: catering.label,
          plannedAmount: catering.plannedAmount,
          spentAmount: '300000.00',
          bookingId: null,
        ),
      );

      expect(after.isOverBudget, isTrue);
      expect(after.remaining, '-80000.00');
    });

    test('links a booking and counts it as booked', () async {
      final Budget budget = (await budgets.get())!;
      final BudgetItem catering = budget.items[3];

      final Budget after = await budgets.updateItem(
        catering,
        BudgetItemInput(
          categoryId: catering.category?.id,
          label: catering.label,
          plannedAmount: catering.plannedAmount,
          spentAmount: catering.spentAmount,
          bookingId: 'mock-booking-2',
        ),
      );

      expect(after.bookedCount, 4);
      expect(after.items[3].bookingReference, 'EVT-002050');
    });

    test('refuses a booking that is not theirs', () async {
      await expectCode(
        budgets.addItem(
          const BudgetItemInput(
            categoryId: null,
            label: 'Other',
            plannedAmount: '0.00',
            spentAmount: '0.00',
            bookingId: 'not-mine',
          ),
        ),
        ApiErrorCode.bookingNotFound,
      );
    });

    test('refuses an unknown category', () async {
      await expectCode(
        budgets.addItem(
          const BudgetItemInput(
            categoryId: 'nope',
            label: 'Other',
            plannedAmount: '0.00',
            spentAmount: '0.00',
            bookingId: null,
          ),
        ),
        ApiErrorCode.categoryNotFound,
      );
    });

    test('adds a line at the end', () async {
      final Budget after = await budgets.addItem(cake);

      expect(after.itemsCount, 7);
      expect(after.items.last.label, 'Wedding cake');
      expect(after.plannedTotal, '405000.00');
    });

    test('deletes a line and recomputes', () async {
      final Budget budget = (await budgets.get())!;

      final Budget after = await budgets.deleteItem(budget.items.first.id);

      expect(after.itemsCount, 5);
      expect(after.spentTotal, '70000.00');
      expect(after.bookedCount, 2);
    });

    test('answers BUDGET_ITEM_NOT_FOUND for a line that is gone', () async {
      await expectCode(budgets.deleteItem('gone'), ApiErrorCode.budgetItemNotFound);
    });

    test('stops at the line limit and learns it (18i)', () async {
      for (int i = 6; i < MockBudgetRepository.maxItems; i++) {
        await budgets.addItem(cake);
      }
      // Known before any refusal: the config states it.
      expect(budgets.itemLimit, MockBudgetRepository.maxItems);

      await expectCode(budgets.addItem(cake), ApiErrorCode.budgetItemLimit);

      expect(budgets.itemLimit, MockBudgetRepository.maxItems);
    });

    test('replaces the header and keeps the lines', () async {
      final Budget after = await budgets.save(
        BudgetPlan(title: 'Our henna', eventDate: DateTime(2026, 12, 1), totalAmount: '500000.00'),
      );

      expect(after.title, 'Our henna');
      expect(after.eventDate, DateTime(2026, 12, 1));
      expect(after.remaining, '320000.00');
      expect(after.itemsCount, 6);
    });

    test('refuses an empty name', () async {
      await expectCode(
        budgets.save(const BudgetPlan(title: '  ', eventDate: null, totalAmount: '1.00')),
        ApiErrorCode.validationFailed,
      );
    });

    test("puts the budget on Home's card", () async {
      await budgets.addItem(cake);

      final HomeFeed feed = await catalog.home();

      expect(feed.budget.exists, isTrue);
      expect(feed.budget.itemsCount, 7);
      expect(feed.budget.spentTotal, '180000.00');
    });

    test('keeps the budget across a restart', () async {
      await budgets.addItem(cake);

      await start();

      expect((await budgets.get())!.itemsCount, 7);
    });

    test('deletes the budget, which puts Home back on 11c', () async {
      await budgets.delete();

      expect(await budgets.get(), isNull);
      expect((await catalog.home()).budget.exists, isFalse);
      await expectCode(budgets.addItem(cake), ApiErrorCode.budgetNotFound);
    });

    test('deleting twice is fine, and a new budget starts empty', () async {
      await budgets.delete();
      await budgets.delete();

      final Budget fresh = await budgets.save(
        const BudgetPlan(title: 'Our henna', eventDate: null, totalAmount: '200000.00'),
      );

      expect(fresh.items, isEmpty);
    });

    test('goes back to the seed on "Reset mock data"', () async {
      await budgets.addItem(cake);

      await backend.reset();
      await signIn('client@eventor.test');

      expect((await budgets.get())!.itemsCount, 6);
    });
  });

  group('a client without a budget', () {
    setUp(() async {
      // The seed's second client, confirmed so it can sign in.
      backend.accountByEmail('unverified@eventor.test')!.emailVerified = true;
      await signIn('unverified@eventor.test');
    });

    test('starts on 11c and creates one', () async {
      expect(await budgets.get(), isNull);
      expect((await catalog.home()).budget.exists, isFalse);
      await expectCode(budgets.addItem(cake), ApiErrorCode.budgetNotFound);

      final Budget created = await budgets.save(
        const BudgetPlan(title: 'Our wedding', eventDate: null, totalAmount: '400000.00'),
      );

      expect(created.items, isEmpty);
      expect(created.remaining, '400000.00');
      expect((await catalog.home()).budget.exists, isTrue);
    });

    test('has no bookings to link', () async {
      final ApiPage<BookingCard> page = await bookings.list(tab: BookingTab.upcoming);

      expect(page.items, isEmpty);
    });
  });

  group('the seeded bookings', () {
    setUp(() => signIn('client@eventor.test'));

    Future<List<String>> ids(BookingTab tab) async {
      final ApiPage<BookingCard> page = await bookings.list(tab: tab);
      return page.items.map((BookingCard b) => b.id).toList();
    }

    test('split into the API tabs', () async {
      expect(await ids(BookingTab.upcoming), containsAll(<String>['mock-booking-1', 'mock-booking-3', 'mock-booking-4']));
      expect(await ids(BookingTab.pending), <String>['mock-booking-2']);
      // Past: completed, or accepted with the event behind us (B7).
      expect(await ids(BookingTab.past), containsAll(<String>['mock-booking-5', 'mock-booking-8']));
      // Cancelled holds the declined ones too.
      expect(await ids(BookingTab.cancelled), containsAll(<String>['mock-booking-6', 'mock-booking-7']));
    });

    test("name the provider the client knows", () async {
      final ApiPage<BookingCard> page = await bookings.list(tab: BookingTab.pending);

      expect(page.items.single.providerName, isNotEmpty);
      expect(page.items.single.reference, 'EVT-002050');
    });

    test('feed Home the next two', () async {
      final HomeFeed feed = await catalog.home();

      expect(feed.upcomingBookings, hasLength(2));
    });
  });
}

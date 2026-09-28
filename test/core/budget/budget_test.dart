import 'package:eventor/core/budget/budget_repository.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/formatting/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/budget_fakes.dart';

Map<String, Object?> _budgetJson({
  String remaining = '220000.00',
  String plannedTotal = '380000.00',
  List<Map<String, Object?>> items = const <Map<String, Object?>>[],
}) =>
    <String, Object?>{
      'id': 'b-1',
      'title': 'Our wedding',
      'eventDate': '2026-03-14',
      'totalAmount': '400000.00',
      'plannedTotal': plannedTotal,
      'spentTotal': '180000.00',
      'remaining': remaining,
      'spentPercent': 45,
      'itemsCount': items.length,
      'bookedCount': 1,
      'items': items,
      'updatedAt': '2026-09-24T10:00:00.000Z',
    };

Map<String, Object?> _lineJson(String id, int position, {String? bookingId}) =>
    <String, Object?>{
      'id': id,
      'category': <String, Object?>{
        'id': 'c-1',
        'slug': 'venues',
        'name': 'Venues',
        'nameEn': 'Venues',
        'nameAr': 'قاعات',
        'icon': 'building',
      },
      'label': 'Venue',
      'plannedAmount': '120000.00',
      'spentAmount': '110000.00',
      'bookingId': bookingId,
      'bookingReference': bookingId == null ? null : 'EVT-002031',
      'providerName': bookingId == null ? null : 'Salle Yasmine',
      'position': position,
      'createdAt': '2026-09-24T10:00:00.000Z',
    };

void main() {
  group('Budget.fromJson', () {
    test('reads the header and the date as a local day', () {
      final Budget budget = Budget.fromJson(_budgetJson());

      expect(budget.title, 'Our wedding');
      expect(budget.eventDate, DateTime(2026, 3, 14));
      expect(budget.totalAmount, '400000.00');
      expect(budget.spentPercent, 45);
    });

    test('keeps the lines in position order', () {
      final Budget budget = Budget.fromJson(
        _budgetJson(items: <Map<String, Object?>>[
          _lineJson('b', 1),
          _lineJson('a', 0, bookingId: 'bk-1'),
        ]),
      );

      expect(budget.items.map((BudgetItem i) => i.id), <String>['a', 'b']);
      expect(budget.items.first.isBooked, isTrue);
      expect(budget.items.first.providerName, 'Salle Yasmine');
      expect(budget.items.last.isBooked, isFalse);
      expect(budget.items.first.category?.icon, 'building');
    });

    test('reads a null date and a null category', () {
      final Map<String, Object?> json = _budgetJson(
        items: <Map<String, Object?>>[_lineJson('a', 0)..['category'] = null],
      )..['eventDate'] = null;

      final Budget budget = Budget.fromJson(json);

      expect(budget.eventDate, isNull);
      expect(budget.items.single.category, isNull);
    });

    test('is over budget only when remaining is negative (18g)', () {
      expect(Budget.fromJson(_budgetJson()).isOverBudget, isFalse);
      expect(Budget.fromJson(_budgetJson(remaining: '0.00')).isOverBudget, isFalse);
      expect(Budget.fromJson(_budgetJson(remaining: '-30000.00')).isOverBudget, isTrue);
    });

    test('is over-allocated when the lines promise more than the total', () {
      expect(Budget.fromJson(_budgetJson()).isOverAllocated, isFalse);
      expect(
        Budget.fromJson(_budgetJson(plannedTotal: '445000.00')).isOverAllocated,
        isTrue,
      );
    });
  });

  group('BudgetItemInput.changesFrom', () {
    final BudgetItem line = testLine(
      category: testCategory(),
      bookingId: 'bk-1',
      planned: 30000,
      spent: 25000,
    );

    BudgetItemInput input({
      String? categoryId = 'cat-venue',
      String label = 'Venue',
      String planned = '30000.00',
      String spent = '25000.00',
      String? bookingId = 'bk-1',
    }) =>
        BudgetItemInput(
          categoryId: categoryId,
          label: label,
          plannedAmount: planned,
          spentAmount: spent,
          bookingId: bookingId,
        );

    test('is empty when nothing changed', () {
      expect(input().changesFrom(line), isEmpty);
    });

    test('carries only the changed fields', () {
      expect(
        input(label: 'Floral arch', spent: '28000.00').changesFrom(line),
        <String, Object?>{'label': 'Floral arch', 'spentAmount': '28000.00'},
      );
    });

    test('sends an explicit null to clear the category or the booking', () {
      final Map<String, Object?> changes =
          input(categoryId: null, bookingId: null).changesFrom(line);

      expect(changes.containsKey('categoryId'), isTrue);
      expect(changes['categoryId'], isNull);
      expect(changes.containsKey('bookingId'), isTrue);
      expect(changes['bookingId'], isNull);
    });
  });

  group('BudgetPlan', () {
    test('writes the date as the API day, or null', () {
      expect(
        BudgetPlan(title: 'T', eventDate: DateTime(2026, 3, 4), totalAmount: '1.00').toJson(),
        <String, Object?>{'title': 'T', 'eventDate': '2026-03-04', 'totalAmount': '1.00'},
      );
      expect(
        const BudgetPlan(title: 'T', eventDate: null, totalAmount: '1.00').toJson()['eventDate'],
        isNull,
      );
    });
  });

  group('BudgetItemLimitMemory', () {
    test('knows no limit until an add is refused', () async {
      final FakeBudgetRepository repository = FakeBudgetRepository(budget: testBudget())
        ..limit = 1;

      expect(repository.itemLimit, isNull);
      await repository.addItem(
        const BudgetItemInput(
          categoryId: null,
          label: 'One',
          plannedAmount: '0.00',
          spentAmount: '0.00',
          bookingId: null,
        ),
      );
      expect(repository.itemLimit, isNull);
    });

    test("learns the server's max from the refusal", () async {
      final FakeBudgetRepository repository = FakeBudgetRepository(
        budget: testBudget(items: <BudgetItem>[testLine()]),
      )..limit = 1;

      await expectLater(
        repository.addItem(
          const BudgetItemInput(
            categoryId: null,
            label: 'Two',
            plannedAmount: '0.00',
            spentAmount: '0.00',
            bookingId: null,
          ),
        ),
        throwsA(
          isA<ApiFailure>().having((ApiFailure f) => f.code, 'code', ApiErrorCode.budgetItemLimit),
        ),
      );
      expect(repository.itemLimit, 1);
    });

    test('uses the configured limit before any refusal', () async {
      final _NoMaxRepository repository = _NoMaxRepository(configured: 60);

      expect(repository.itemLimit, 60);
    });

    test('a refusal outranks the configured limit', () async {
      final _NoMaxRepository repository = _NoMaxRepository(configured: 60);
      repository.remember(testBudget(items: <BudgetItem>[testLine(), testLine(id: 'l-2')]));

      await expectLater(repository.refuse(), throwsA(isA<ApiFailure>()));

      expect(repository.itemLimit, 2);
    });

    test('falls back to the count it was refused at when there is no max', () async {
      final _NoMaxRepository repository = _NoMaxRepository();
      repository.remember(testBudget(items: <BudgetItem>[testLine(), testLine(id: 'l-2')]));

      await expectLater(repository.refuse(), throwsA(isA<ApiFailure>()));

      expect(repository.itemLimit, 2);
    });
  });

  group('money helpers', () {
    test('amountCents reads signs and fractions without doubles', () {
      expect(amountCents('400000.00'), 40000000);
      expect(amountCents('2500.5'), 250050);
      expect(amountCents('-30000.00'), -3000000);
      expect(amountCents('nope'), 0);
    });

    test('apiAmountOf writes whole dinars', () {
      expect(apiAmountOf(400000), '400000.00');
      expect(apiAmountOf(0), '0.00');
    });

    test('apiDate pads the parts', () {
      expect(apiDate(DateTime(2026, 3, 4)), '2026-03-04');
    });
  });
}

class _NoMaxRepository with BudgetItemLimitMemory {
  _NoMaxRepository({this.configured});

  final int? configured;

  @override
  int? get configuredItemLimit => configured;

  Future<Budget> refuse() => learningLimit(
        () async => throw const ApiFailure(
          statusCode: 422,
          code: ApiErrorCode.budgetItemLimit,
          message: 'Full.',
        ),
      );
}

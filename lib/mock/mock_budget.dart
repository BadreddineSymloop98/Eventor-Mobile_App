import '../core/budget/budget_repository.dart';
import '../core/errors/failure.dart';
import '../core/formatting/money_format.dart';
import 'mock_backend.dart';
import 'mock_catalog.dart';

// Category ids from the catalog snapshot.
const String _venues = 'bb28c638-c0ea-4140-b9d9-fd5535a6c4b6';
const String _photography = '7d3855dd-4bd3-430a-9ffc-09d4f269eb4a';
const String _decoration = '9ec8cbe5-ead7-42b4-99d1-fccc49fdad50';
const String _catering = 'd892155b-2c9b-4e0f-8fb5-db15b54af350';
const String _music = '601c07e5-d2c8-4619-bbb4-bbb546803413';
const String _cakes = '137d6aeb-8aa1-4c3e-a9cd-ca5a67c4e1d1';

/// The seeded client's budget, as drawn on 18: three lines booked, three
/// still to book, 180 000 of 400 000 spent. The bookings are the seeded
/// ones in `mock_catalog.dart`; the event is on their date.
Map<String, Object?> mockSeedBudget(DateTime now) {
  final DateTime event = DateTime(now.year, now.month, now.day + mockEventInDays);
  Map<String, Object?> line(
    int position,
    String categoryId,
    String label,
    int planned,
    int spent,
    String? bookingId,
  ) =>
      <String, Object?>{
        'id': 'mock-line-${position + 1}',
        'categoryId': categoryId,
        'label': label,
        'plannedAmount': apiAmountOf(planned),
        'spentAmount': apiAmountOf(spent),
        'bookingId': bookingId,
        'position': position,
        'createdAt': now.millisecondsSinceEpoch,
      };

  return <String, Object?>{
    'id': 'mock-budget-1',
    'title': 'Our wedding',
    'eventDate': apiDate(event),
    'totalAmount': apiAmountOf(400000),
    'updatedAt': now.millisecondsSinceEpoch,
    'items': <Map<String, Object?>>[
      line(0, _venues, 'Venue', 120000, 110000, 'mock-booking-3'),
      line(1, _photography, 'Photography', 45000, 45000, 'mock-booking-1'),
      line(2, _decoration, 'Decoration', 30000, 25000, 'mock-booking-4'),
      line(3, _catering, 'Catering', 130000, 0, null),
      line(4, _music, 'Music & DJ', 30000, 0, null),
      line(5, _cakes, 'Cakes & pastry', 25000, 0, null),
    ],
  };
}

/// A stored budget as `GET /app/me/budget` answers — the sums worked out the
/// way the server works them out.
Map<String, Object?> mockBudgetJson(
  Map<String, Object?> stored,
  MockCatalogLookups lookups,
) {
  final List<Map<String, Object?>> items = _items(stored);
  int planned = 0;
  int spent = 0;
  int booked = 0;
  final List<Map<String, Object?>> lines = <Map<String, Object?>>[];
  for (final Map<String, Object?> item in items) {
    planned += amountCents(item['plannedAmount']! as String);
    spent += amountCents(item['spentAmount']! as String);
    final String? bookingId = item['bookingId'] as String?;
    final Map<String, Object?>? booking =
        bookingId == null ? null : lookups.booking(bookingId);
    if (bookingId != null) booked++;
    final Map<String, Object?>? party =
        booking?['counterparty'] as Map<String, Object?>?;
    lines.add(<String, Object?>{
      'id': item['id'],
      'category': lookups.category(item['categoryId'] as String?),
      'label': item['label'],
      'plannedAmount': item['plannedAmount'],
      'spentAmount': item['spentAmount'],
      'bookingId': bookingId,
      'bookingReference': booking?['reference'],
      'providerName': party?['businessName'] ?? party?['fullName'],
      'position': item['position'],
      'createdAt': DateTime.fromMillisecondsSinceEpoch(
        (item['createdAt'] as num? ?? 0).toInt(),
      ).toUtc().toIso8601String(),
    });
  }
  final int total = amountCents(stored['totalAmount']! as String);

  String money(int cents) {
    final String sign = cents < 0 ? '-' : '';
    final int abs = cents.abs();
    return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }

  return <String, Object?>{
    'id': stored['id'],
    'title': stored['title'],
    'eventDate': stored['eventDate'],
    'totalAmount': stored['totalAmount'],
    'plannedTotal': money(planned),
    'spentTotal': money(spent),
    'remaining': money(total - spent),
    'spentPercent': total == 0 ? 0 : (spent * 100 / total).round(),
    'itemsCount': items.length,
    'bookedCount': booked,
    'items': lines,
    'updatedAt': DateTime.fromMillisecondsSinceEpoch(
      (stored['updatedAt'] as num? ?? 0).toInt(),
    ).toUtc().toIso8601String(),
  };
}

List<Map<String, Object?>> _items(Map<String, Object?> stored) =>
    <Map<String, Object?>>[
      for (final Object? item in stored['items'] as List<Object?>? ?? <Object?>[])
        Map<String, Object?>.of(item! as Map<String, Object?>),
    ]..sort(
        (Map<String, Object?> a, Map<String, Object?> b) =>
            (a['position']! as num).compareTo(b['position']! as num),
      );

/// [BudgetRepository] on the in-app [MockBackend], with the live API's rules:
/// one budget per client, [maxItems] lines, only the client's own bookings,
/// and the same error codes.
class MockBudgetRepository with BudgetItemLimitMemory implements BudgetRepository {
  MockBudgetRepository(this._backend, this._lookups);

  final MockBackend _backend;
  final MockCatalogLookups _lookups;

  /// The live limit (`/app/config` `limits.budgetItemsMax`, 2026-09-27).
  static const int maxItems = 60;

  @override
  int? get configuredItemLimit => maxItems;
  static const int _maxText = 160;

  @override
  Future<Budget?> get() async {
    await _backend.delay();
    final Map<String, Object?>? stored = _backend.budget();
    return stored == null ? null : remember(_parse(stored));
  }

  @override
  Future<Budget> save(BudgetPlan plan) async {
    await _backend.delay();
    _checkText(plan.title, 'title');
    _checkAmount(plan.totalAmount, 'totalAmount');
    final Map<String, Object?> stored = Map<String, Object?>.of(
      _backend.budget() ??
          <String, Object?>{
            'id': 'mock-budget-${_backend.now.millisecondsSinceEpoch}',
            'items': <Map<String, Object?>>[],
          },
    )
      ..['title'] = plan.title.trim()
      ..['eventDate'] = plan.eventDate == null ? null : apiDate(plan.eventDate!)
      ..['totalAmount'] = plan.totalAmount
      ..['updatedAt'] = _backend.now.millisecondsSinceEpoch;
    await _backend.putBudget(stored);
    return remember(_parse(stored));
  }

  @override
  Future<Budget> addItem(BudgetItemInput input) => learningLimit(() async {
        await _backend.delay();
        final Map<String, Object?> stored = _requireBudget();
        final List<Map<String, Object?>> items = _items(stored);
        if (items.length >= maxItems) {
          throw const ApiFailure(
            statusCode: 422,
            code: ApiErrorCode.budgetItemLimit,
            message: 'A budget cannot hold more than $maxItems lines.',
            details: <String, Object?>{'max': maxItems},
          );
        }
        _checkLine(input.toJson(), items: items);
        final int now = _backend.now.millisecondsSinceEpoch;
        items.add(<String, Object?>{
          'id': 'mock-line-$now',
          ...input.toJson(),
          'label': input.label.trim(),
          'position': items.isEmpty ? 0 : (items.last['position']! as num).toInt() + 1,
          'createdAt': now,
        });
        return _store(stored, items);
      });

  @override
  Future<Budget> updateItem(BudgetItem item, BudgetItemInput input) async {
    await _backend.delay();
    final Map<String, Object?> stored = _requireBudget();
    final List<Map<String, Object?>> items = _items(stored);
    final int index =
        items.indexWhere((Map<String, Object?> row) => row['id'] == item.id);
    if (index < 0) throw _itemNotFound();
    final Map<String, Object?> changes = input.changesFrom(item);
    _checkLine(changes, items: items, lineId: item.id);
    items[index] = <String, Object?>{
      ...items[index],
      ...changes,
      if (changes['label'] case final String label) 'label': label.trim(),
    };
    return remember(await _store(stored, items));
  }

  @override
  Future<Budget> deleteItem(String id) async {
    await _backend.delay();
    final Map<String, Object?> stored = _requireBudget();
    final List<Map<String, Object?>> items = _items(stored);
    final int before = items.length;
    items.removeWhere((Map<String, Object?> row) => row['id'] == id);
    if (items.length == before) throw _itemNotFound();
    return remember(await _store(stored, items));
  }

  /// Ahead of the live API (backend issues, item 15): the mock implements
  /// the delete the backend is asked for, so the flow can be used today.
  @override
  Future<void> delete() async {
    await _backend.delay();
    await _backend.deleteBudget();
  }

  Future<Budget> _store(
    Map<String, Object?> stored,
    List<Map<String, Object?>> items,
  ) async {
    final Map<String, Object?> next = Map<String, Object?>.of(stored)
      ..['items'] = items
      ..['updatedAt'] = _backend.now.millisecondsSinceEpoch;
    await _backend.putBudget(next);
    return _parse(next);
  }

  Budget _parse(Map<String, Object?> stored) =>
      Budget.fromJson(mockBudgetJson(stored, _lookups));

  Map<String, Object?> _requireBudget() {
    final Map<String, Object?>? stored = _backend.budget();
    if (stored == null) {
      throw const ApiFailure(
        statusCode: 404,
        code: ApiErrorCode.budgetNotFound,
        message: 'You have not created a budget yet.',
      );
    }
    return stored;
  }

  /// The checks a line's fields get on the server, for whichever of them
  /// [fields] carries.
  void _checkLine(
    Map<String, Object?> fields, {
    required List<Map<String, Object?>> items,
    String? lineId,
  }) {
    // One line per booking, as live (2026-09-27): the same amount is never
    // counted twice.
    if (fields['bookingId'] case final String bookingId) {
      for (final Map<String, Object?> line in items) {
        if (line['bookingId'] == bookingId && line['id'] != lineId) {
          throw ApiFailure(
            statusCode: 409,
            code: ApiErrorCode.budgetBookingAlreadyLinked,
            message: 'This booking is already linked to another budget line.',
            details: <String, Object?>{'itemId': line['id']},
          );
        }
      }
    }
    if (fields.containsKey('label')) _checkText(fields['label']! as String, 'label');
    for (final String key in const <String>['plannedAmount', 'spentAmount']) {
      if (fields[key] case final String amount) _checkAmount(amount, key);
    }
    if (fields['categoryId'] case final String categoryId
        when _lookups.category(categoryId) == null) {
      throw const ApiFailure(
        statusCode: 404,
        code: ApiErrorCode.categoryNotFound,
        message: 'The category was not found.',
      );
    }
    if (fields['bookingId'] case final String bookingId
        when _lookups.booking(bookingId) == null) {
      throw const ApiFailure(
        statusCode: 404,
        code: ApiErrorCode.bookingNotFound,
        message: 'The booking was not found.',
      );
    }
  }

  static void _checkText(String value, String field) {
    final String text = value.trim();
    if (text.isEmpty || text.length > _maxText) throw _invalid(field);
  }

  static void _checkAmount(String value, String field) {
    if (!RegExp(r'^\d+\.\d{2}$').hasMatch(value)) throw _invalid(field);
  }

  static ApiFailure _invalid(String field) => ApiFailure(
        statusCode: 400,
        code: ApiErrorCode.validationFailed,
        message: 'Some fields are invalid.',
        fieldErrors: <FieldError>[
          FieldError(field: field, code: 'INVALID', message: 'Invalid value.'),
        ],
      );

  static ApiFailure _itemNotFound() => const ApiFailure(
        statusCode: 404,
        code: ApiErrorCode.budgetItemNotFound,
        message: 'This budget line was not found.',
      );
}

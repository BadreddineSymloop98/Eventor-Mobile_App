import 'dart:async';

import 'package:eventor/core/bookings/bookings_repository.dart';
import 'package:eventor/core/budget/budget_repository.dart';
import 'package:eventor/core/catalog/models/catalog_ref.dart';
import 'package:eventor/core/catalog/models/json_read.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/formatting/money_format.dart';
import 'package:eventor/core/network/api_page.dart';

/// A category for budget lines.
CategoryRef testCategory({
  String id = 'cat-venue',
  String name = 'Venue',
  String icon = 'building',
}) =>
    CategoryRef(
      id: id,
      slug: name.toLowerCase(),
      name: LocalizedText(en: name, ar: 'قاعة'),
      icon: icon,
    );

/// One expense line; amounts in whole dinars.
BudgetItem testLine({
  String id = 'line-1',
  String label = 'Venue',
  int planned = 120000,
  int spent = 0,
  CategoryRef? category,
  String? bookingId,
  String? reference,
  String? provider,
  int position = 0,
}) =>
    BudgetItem(
      id: id,
      category: category,
      label: label,
      plannedAmount: apiAmountOf(planned),
      spentAmount: apiAmountOf(spent),
      bookingId: bookingId,
      bookingReference: bookingId == null ? null : reference ?? 'EVT-000001',
      providerName: bookingId == null ? null : provider ?? 'Salle Yasmine',
      position: position,
    );

/// A budget whose sums are worked out from [items], as the server would.
Budget testBudget({
  String title = 'Our wedding',
  DateTime? eventDate,
  int total = 400000,
  List<BudgetItem> items = const <BudgetItem>[],
}) {
  int planned = 0;
  int spent = 0;
  for (final BudgetItem item in items) {
    planned += amountCents(item.plannedAmount);
    spent += amountCents(item.spentAmount);
  }
  String money(int cents) {
    final String sign = cents < 0 ? '-' : '';
    final int abs = cents.abs();
    return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }

  return Budget(
    id: 'budget-1',
    title: title,
    eventDate: eventDate,
    totalAmount: apiAmountOf(total),
    plannedTotal: money(planned),
    spentTotal: money(spent),
    remaining: money(total * 100 - spent),
    spentPercent: total == 0 ? 0 : (spent / total).round(),
    itemsCount: items.length,
    bookedCount: items.where((BudgetItem i) => i.isBooked).length,
    items: items,
  );
}

/// [BudgetRepository] in memory, with the live limit behaviour: at [limit]
/// lines an add is refused with `BUDGET_ITEM_LIMIT`, and the shared mixin
/// learns it.
class FakeBudgetRepository with BudgetItemLimitMemory implements BudgetRepository {
  FakeBudgetRepository({this.budget});

  /// `null` until created.
  Budget? budget;

  /// Lines the fake budget can hold; `null` for no limit.
  int? limit;

  /// `get`, `save:<title>`, `add:<label>`, `update:<id>:<changes>`, `delete:<id>`.
  final List<String> calls = <String>[];

  /// Thrown by the next call only.
  Failure? failNext;

  /// When set, calls wait on it — for asserting the in-flight state.
  Completer<void>? gate;

  Future<void> _enter(String call) async {
    calls.add(call);
    final Completer<void>? pending = gate;
    if (pending != null) await pending.future;
    final Failure? failure = failNext;
    if (failure != null) {
      failNext = null;
      throw failure;
    }
  }

  Budget _require() {
    final Budget? current = budget;
    if (current == null) {
      throw const ApiFailure(
        statusCode: 404,
        code: ApiErrorCode.budgetNotFound,
        message: 'You have not created a budget yet.',
      );
    }
    return current;
  }

  Budget _with(List<BudgetItem> items) {
    final Budget current = _require();
    return budget = testBudget(
      title: current.title,
      eventDate: current.eventDate,
      total: amountCents(current.totalAmount) ~/ 100,
      items: items,
    );
  }

  @override
  Future<Budget?> get() async {
    await _enter('get');
    final Budget? current = budget;
    return current == null ? null : remember(current);
  }

  @override
  Future<Budget> save(BudgetPlan plan) async {
    await _enter('save:${plan.title}');
    return remember(
      budget = testBudget(
        title: plan.title,
        eventDate: plan.eventDate,
        total: amountCents(plan.totalAmount) ~/ 100,
        items: budget?.items ?? const <BudgetItem>[],
      ),
    );
  }

  @override
  Future<Budget> addItem(BudgetItemInput input) => learningLimit(() async {
        await _enter('add:${input.label}');
        final Budget current = _require();
        final int? max = limit;
        if (max != null && current.items.length >= max) {
          throw ApiFailure(
            statusCode: 422,
            code: ApiErrorCode.budgetItemLimit,
            message: 'A budget cannot hold more than $max lines.',
            details: <String, Object?>{'max': max},
          );
        }
        return _with(<BudgetItem>[
          ...current.items,
          BudgetItem(
            id: 'line-new-${current.items.length + 1}',
            category: null,
            label: input.label,
            plannedAmount: input.plannedAmount,
            spentAmount: input.spentAmount,
            bookingId: input.bookingId,
            bookingReference: input.bookingId == null ? null : 'EVT-000009',
            providerName: input.bookingId == null ? null : 'Studio Lumière',
            position: current.items.length,
          ),
        ]);
      });

  @override
  Future<Budget> updateItem(BudgetItem item, BudgetItemInput input) async {
    await _enter('update:${item.id}:${input.changesFrom(item).keys.join(',')}');
    final Budget current = _require();
    if (!current.items.any((BudgetItem i) => i.id == item.id)) {
      throw const ApiFailure(
        statusCode: 404,
        code: ApiErrorCode.budgetItemNotFound,
        message: 'This budget line was not found.',
      );
    }
    return remember(
      _with(<BudgetItem>[
        for (final BudgetItem line in current.items)
          if (line.id == item.id)
            BudgetItem(
              id: line.id,
              category: line.category,
              label: input.label,
              plannedAmount: input.plannedAmount,
              spentAmount: input.spentAmount,
              bookingId: input.bookingId,
              bookingReference: input.bookingId == null ? null : line.bookingReference,
              providerName: input.bookingId == null ? null : line.providerName,
              position: line.position,
            )
          else
            line,
      ]),
    );
  }

  @override
  Future<void> delete() async {
    await _enter('deleteBudget');
    budget = null;
  }

  @override
  Future<Budget> deleteItem(String id) async {
    await _enter('delete:$id');
    final Budget current = _require();
    return remember(
      _with(current.items.where((BudgetItem i) => i.id != id).toList()),
    );
  }
}

/// A client booking as `/app/bookings` lists it.
BookingCard testBooking({
  String id = 'booking-1',
  String reference = 'EVT-002044',
  String status = 'accepted',
  DateTime? eventDate,
  String title = 'Floral arch',
  String provider = 'Fleurs de Yasmina',
}) =>
    BookingCard(
      id: id,
      reference: reference,
      status: status,
      eventDate: eventDate ?? DateTime(2026, 3, 14),
      title: LocalizedText(en: title),
      providerName: provider,
    );

/// [BookingsRepository] with one scripted list per tab.
class FakeBookingsRepository implements BookingsRepository {
  final Map<BookingTab, List<BookingCard>> tabs = <BookingTab, List<BookingCard>>{};

  /// `list:<tab>:<limit>`.
  final List<String> calls = <String>[];

  /// Thrown by the next call only.
  Failure? failNext;

  @override
  Future<ApiPage<BookingCard>> list({
    required BookingTab tab,
    int page = 1,
    int limit = 20,
  }) async {
    calls.add('list:${tab.apiValue}:$limit');
    final Failure? failure = failNext;
    if (failure != null) {
      failNext = null;
      throw failure;
    }
    final List<BookingCard> items = tabs[tab] ?? <BookingCard>[];
    return ApiPage<BookingCard>(
      items: items,
      page: 1,
      totalPages: 1,
      total: items.length,
    );
  }
}

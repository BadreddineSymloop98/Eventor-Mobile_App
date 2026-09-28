import 'package:eventor/core/bookings/bookings_repository.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/features/bookings/view_model/bookings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/booking_fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  late ScriptedBookingsRepository bookings;

  BookingCard card(String id) =>
      BookingCard.fromJson(bookingJson(id: id));

  setUp(() {
    bookings = ScriptedBookingsRepository()
      ..tabs[BookingTab.upcoming] = <BookingCard>[card('u-1'), card('u-2')]
      ..tabs[BookingTab.pending] = <BookingCard>[card('p-1')];
  });

  Future<BookingsViewModel> build() async {
    final BookingsViewModel viewModel = BookingsViewModel(bookings: bookings);
    addTearDown(viewModel.dispose);
    await flushAsync();
    return viewModel;
  }

  test('opens on Upcoming', () async {
    final BookingsViewModel viewModel = await build();

    expect(viewModel.tab, BookingTab.upcoming);
    expect(viewModel.items.map((BookingCard b) => b.id), <String>['u-1', 'u-2']);
  });

  test('loads a tab once, then keeps it', () async {
    final BookingsViewModel viewModel = await build();

    viewModel.setTab(BookingTab.pending);
    await flushAsync();
    viewModel.setTab(BookingTab.upcoming);
    viewModel.setTab(BookingTab.pending);
    await flushAsync();

    expect(bookings.calls.where((String c) => c.startsWith('list:pending')), hasLength(1));
    expect(viewModel.items.single.id, 'p-1');
  });

  test('an empty tab is empty, not an error', () async {
    final BookingsViewModel viewModel = await build();

    viewModel.setTab(BookingTab.cancelled);
    await flushAsync();

    expect(viewModel.isEmpty, isTrue);
    expect(viewModel.loadFailed, isFalse);
  });

  test('a failed first load offers a retry', () async {
    bookings.failNext = const NetworkFailure();
    final BookingsViewModel viewModel = await build();

    expect(viewModel.loadFailed, isTrue);

    await viewModel.load();
    expect(viewModel.items, hasLength(2));
  });

  test('pages on', () async {
    bookings
      ..pageSize = 1
      ..tabs[BookingTab.upcoming] = <BookingCard>[card('u-1'), card('u-2')];
    final BookingsViewModel viewModel = await build();
    expect(viewModel.hasMore, isTrue);

    await viewModel.loadMore();

    expect(viewModel.items.map((BookingCard b) => b.id), <String>['u-1', 'u-2']);
    expect(viewModel.hasMore, isFalse);
  });

  test('a refresh that fails keeps the list', () async {
    final BookingsViewModel viewModel = await build();
    bookings.failNext = const NetworkFailure();

    expect(await viewModel.refresh(), isA<NetworkFailure>());
    expect(viewModel.items, hasLength(2));
  });
}

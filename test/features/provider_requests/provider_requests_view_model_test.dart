import 'dart:async';

import 'package:eventor/core/bookings/models/booking_card.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/network/api_page.dart';
import 'package:eventor/core/provider/provider_repository.dart';
import 'package:eventor/features/provider_requests/view_model/provider_requests_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/provider_fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  /// Two requests, one booking ahead, one done.
  List<Map<String, Object?>> seeded() => <Map<String, Object?>>[
        providerBookingDetailJson(),
        providerBookingDetailJson(id: 'req-2', client: 'Yacine Meddour'),
        providerBookingDetailJson(id: 'up-1', client: 'Lila Hamadi', status: 'accepted'),
        providerBookingDetailJson(id: 'past-1', client: 'Samir Bouzid', status: 'completed'),
      ];

  Future<ProviderRequestsViewModel> build(
    FakeProviderRepository provider, {
    ProviderBookingTab initialTab = ProviderBookingTab.requests,
    DateTime? now,
  }) async {
    final ProviderRequestsViewModel viewModel = ProviderRequestsViewModel(
      provider: provider,
      replyDeadlineHours: 48,
      initialTab: initialTab,
      now: () => now ?? DateTime.utc(2026, 3, 3, 10, 50).toLocal(),
    );
    addTearDown(viewModel.dispose);
    await flushAsync();
    return viewModel;
  }

  FakeProviderRepository verified({List<Map<String, Object?>>? bookings}) =>
      FakeProviderRepository(home: providerHomeJson(), bookings: bookings ?? seeded());

  test('is on the skeleton until the first answer', () {
    final FakeProviderRepository provider = verified()..gate = Completer<void>();
    final ProviderRequestsViewModel viewModel = ProviderRequestsViewModel(
      provider: provider,
      replyDeadlineHours: 48,
    );
    addTearDown(viewModel.dispose);

    expect(viewModel.isFirstLoad, isTrue);
    expect(viewModel.loadFailed, isFalse);
  });

  test('loads the account and the requests together', () async {
    final FakeProviderRepository provider = verified();
    final ProviderRequestsViewModel viewModel = await build(provider);

    expect(provider.calls, containsAll(<String>['home', 'list:requests:1']));
    expect(viewModel.isFirstLoad, isFalse);
    expect(viewModel.isUnderReview, isFalse);
    expect(viewModel.items.map((BookingCard b) => b.id), <String>['req-1', 'req-2']);
  });

  test('counts the hours left to reply', () async {
    final ProviderRequestsViewModel viewModel = await build(verified());

    expect(viewModel.replyHoursLeft(viewModel.items.first), 48);
  });

  test('opens on the list it was linked to, and loads each list once', () async {
    final FakeProviderRepository provider = verified();
    final ProviderRequestsViewModel viewModel =
        await build(provider, initialTab: ProviderBookingTab.upcoming);

    expect(viewModel.items.single.id, 'up-1');

    viewModel.setTab(ProviderBookingTab.past);
    await flushAsync();
    expect(viewModel.items.single.id, 'past-1');

    viewModel.setTab(ProviderBookingTab.upcoming);
    await flushAsync();
    expect(provider.calls.where((String c) => c == 'list:upcoming:1'), hasLength(1));
  });

  test('says a list is empty', () async {
    final ProviderRequestsViewModel viewModel = await build(
      verified(bookings: <Map<String, Object?>>[providerBookingDetailJson(status: 'accepted')]),
    );

    expect(viewModel.isEmpty, isTrue);
  });

  test('shows P1b while the profile is reviewed or refused', () async {
    final ProviderRequestsViewModel pending = await build(
      FakeProviderRepository(home: providerHomeJson(state: 'pending')),
    );
    final ProviderRequestsViewModel rejected = await build(
      FakeProviderRepository(home: providerHomeJson(state: 'rejected')),
    );

    expect(pending.isUnderReview, isTrue);
    expect(pending.isRejected, isFalse);
    expect(pending.isFirstLoad, isFalse);
    expect(rejected.isRejected, isTrue);
  });

  test('keeps a blocked account on its lists', () async {
    final ProviderRequestsViewModel viewModel = await build(
      FakeProviderRepository(home: providerHomeJson(state: 'blocked'), bookings: seeded()),
    );

    expect(viewModel.isBlocked, isTrue);
    expect(viewModel.isUnderReview, isFalse);
    expect(viewModel.items, hasLength(2));
  });

  test('reports a failed first load and retries', () async {
    final _ListFailsOnce provider = _ListFailsOnce(seeded());
    final ProviderRequestsViewModel viewModel = await build(provider);

    expect(viewModel.loadFailed, isTrue);
    expect(viewModel.isFirstLoad, isFalse);

    await viewModel.load();

    expect(viewModel.loadFailed, isFalse);
    expect(viewModel.items, hasLength(2));
  });

  test('shows the list even when the account could not be read', () async {
    final FakeProviderRepository provider = verified()..failNext = const NetworkFailure();
    final ProviderRequestsViewModel viewModel = await build(provider);

    expect(provider.calls.first, 'home', reason: 'the failure went to the account');
    expect(viewModel.loadFailed, isFalse);
    expect(viewModel.items, hasLength(2));
  });

  test('pages on, keeps what it has when a page fails, and tries again', () async {
    final FakeProviderRepository provider = verified(bookings: <Map<String, Object?>>[
      for (int i = 0; i < ProviderRequestsViewModel.pageSize + 5; i++)
        providerBookingDetailJson(id: 'req-$i'),
    ]);
    final ProviderRequestsViewModel viewModel = await build(provider);
    expect(viewModel.items, hasLength(ProviderRequestsViewModel.pageSize));
    expect(viewModel.hasMore, isTrue);

    provider.failNext = const NetworkFailure();
    await viewModel.loadMore();
    expect(viewModel.loadMoreFailed, isTrue);
    expect(viewModel.items, hasLength(ProviderRequestsViewModel.pageSize));

    await viewModel.loadMore();
    expect(viewModel.items, hasLength(ProviderRequestsViewModel.pageSize + 5));
    expect(viewModel.hasMore, isFalse);
  });

  test('accepts in one tap: off the requests, Upcoming reloads when opened', () async {
    final FakeProviderRepository provider = verified();
    final ProviderRequestsViewModel viewModel = await build(provider);
    viewModel.setTab(ProviderBookingTab.upcoming);
    await flushAsync();
    viewModel.setTab(ProviderBookingTab.requests);

    final Future<Failure?> pending = viewModel.accept(viewModel.items.first);
    expect(viewModel.accepting, 'req-1');
    expect(await viewModel.accept(viewModel.items.last), isNull, reason: 'one at a time');
    final Failure? failure = await pending;

    expect(failure, isNull);
    expect(viewModel.accepting, isNull);
    expect(viewModel.items.map((BookingCard b) => b.id), <String>['req-2']);

    provider.calls.clear();
    viewModel.setTab(ProviderBookingTab.upcoming);
    await flushAsync();
    expect(provider.calls, contains('list:upcoming:1'));
    expect(viewModel.items.map((BookingCard b) => b.id), containsAll(<String>['up-1', 'req-1']));
  });

  test('reloads when an accept finds the request moved', () async {
    final FakeProviderRepository provider = verified();
    final ProviderRequestsViewModel viewModel = await build(provider);
    provider
      ..calls.clear()
      ..failNext = apiFailure(ApiErrorCode.bookingInvalidTransition, statusCode: 409);

    final Failure? failure = await viewModel.accept(viewModel.items.first);

    expect(failure, isA<ApiFailure>());
    expect(provider.calls, containsAll(<String>['accept:req-1', 'list:requests:1']));
  });

  test('declines with the trimmed reason, and hands a refusal back to the sheet', () async {
    final FakeProviderRepository provider = verified();
    final ProviderRequestsViewModel viewModel = await build(provider);
    provider.failNext = const NetworkFailure();

    expect(await viewModel.decline(viewModel.items.first, 'No'), isA<NetworkFailure>());
    expect(viewModel.items, hasLength(2));

    expect(await viewModel.decline(viewModel.items.first, '  Already booked  '), isNull);
    expect(provider.calls, contains('decline:req-1:Already booked'));
    expect(viewModel.items.map((BookingCard b) => b.id), <String>['req-2']);
  });

  test('refreshes the list on screen and keeps it when that fails', () async {
    final FakeProviderRepository provider = verified();
    final ProviderRequestsViewModel viewModel = await build(provider);
    provider.details['req-3'] = providerBookingDetailJson(id: 'req-3', client: 'Karima Ait Ali');

    expect(await viewModel.refresh(), isNull);
    expect(viewModel.items, hasLength(3));

    provider.failNext = const NetworkFailure();
    expect(await viewModel.refresh(), isA<NetworkFailure>());
    expect(viewModel.items, hasLength(3));
  });
}

/// A verified provider whose first list call fails — offline on opening.
class _ListFailsOnce extends FakeProviderRepository {
  _ListFailsOnce(List<Map<String, Object?>> bookings)
      : super(home: providerHomeJson(), bookings: bookings);

  bool _failed = false;

  @override
  Future<ApiPage<BookingCard>> bookings({
    required ProviderBookingTab tab,
    int page = 1,
    int limit = 20,
  }) async {
    if (!_failed) {
      _failed = true;
      throw const NetworkFailure();
    }
    return super.bookings(tab: tab, page: page, limit: limit);
  }
}

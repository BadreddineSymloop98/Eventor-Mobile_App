import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/provider/provider_repository.dart';
import 'package:eventor/features/provider_booking/view_model/provider_check_in_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/provider_fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  /// P2b: the event was yesterday, nobody confirmed yet.
  Map<String, Object?> passed({bool clientConfirmed = false}) => providerBookingDetailJson(
        status: 'accepted',
        eventDate: '2026-03-14',
        phone: '+213770551288',
        otherCheckedIn: clientConfirmed,
        allowedActions: <String>['message', 'check_in', 'dispute'],
      );

  Future<ProviderCheckInViewModel> build(
    FakeProviderRepository provider, {
    bool withBooking = true,
  }) async {
    final ProviderCheckInViewModel viewModel = ProviderCheckInViewModel(
      id: 'req-1',
      provider: provider,
      booking: withBooking ? ProviderBooking.fromJson(provider.details['req-1']!) : null,
    );
    addTearDown(viewModel.dispose);
    await flushAsync();
    return viewModel;
  }

  FakeProviderRepository repository({bool clientConfirmed = false}) => FakeProviderRepository(
        bookings: <Map<String, Object?>>[passed(clientConfirmed: clientConfirmed)],
      );

  test('uses the booking P2 handed over, without a reload', () async {
    final FakeProviderRepository provider = repository();
    final ProviderCheckInViewModel viewModel = await build(provider);

    expect(provider.calls, isEmpty);
    expect(viewModel.canConfirm, isTrue);
  });

  test('loads the booking when opened from a notification', () async {
    final FakeProviderRepository provider = repository();
    final ProviderCheckInViewModel viewModel = await build(provider, withBooking: false);

    expect(provider.calls, <String>['booking:req-1']);
    expect(viewModel.booking!.clientName, 'Nadia Kaci');
  });

  test('says a booking is gone, and retries a failed load', () async {
    final FakeProviderRepository gone = repository()
      ..failNext = apiFailure(ApiErrorCode.bookingNotFound, statusCode: 404);
    expect((await build(gone, withBooking: false)).isGone, isTrue);

    final FakeProviderRepository offline = repository()..failNext = const NetworkFailure();
    final ProviderCheckInViewModel viewModel = await build(offline, withBooking: false);
    expect(viewModel.hasError, isTrue);
    await viewModel.load();
    expect(viewModel.booking, isNotNull);
  });

  test('has nothing to confirm on a booking that moved on', () async {
    final FakeProviderRepository provider = FakeProviderRepository(
      bookings: <Map<String, Object?>>[providerBookingDetailJson(status: 'completed')],
    );
    final ProviderCheckInViewModel viewModel = await build(provider, withBooking: false);

    expect(viewModel.canConfirm, isFalse);
  });

  test('"All good" waits for the client when they have not confirmed', () async {
    final FakeProviderRepository provider = repository();
    final ProviderCheckInViewModel viewModel = await build(provider);

    final ProviderBooking? updated = await viewModel.confirm();

    expect(provider.calls, <String>['checkIn:req-1']);
    expect(updated!.checkedIn, isTrue);
    expect(updated.status, 'accepted');
  });

  test('"All good" closes it when the client said so too', () async {
    final ProviderCheckInViewModel viewModel = await build(repository(clientConfirmed: true));

    final ProviderBooking? updated = await viewModel.confirm();

    expect(updated!.status, 'completed');
  });

  test('hands a refused check-in back with its reason', () async {
    final FakeProviderRepository provider = repository()
      ..failNext = apiFailure(ApiErrorCode.checkInNotAllowed, statusCode: 409);
    final ProviderCheckInViewModel viewModel = await build(provider);

    expect(await viewModel.confirm(), isNull);

    expect((viewModel.failure! as ApiFailure).code, ApiErrorCode.checkInNotAllowed);
    expect(viewModel.isConfirming, isFalse);
  });

  test('a problem opens a dispute on the shared route, a refusal goes back to the sheet', () async {
    final FakeProviderRepository provider = repository();
    final ProviderCheckInViewModel viewModel = await build(provider);

    provider.failNext = apiFailure(ApiErrorCode.disputeWindowClosed);
    expect(await viewModel.reportProblem(ProviderDisputeType.clientNoShow, 'Nobody came that evening at all.'),
        isA<ApiFailure>());

    expect(await viewModel.reportProblem(ProviderDisputeType.clientNoShow, 'Nobody came that evening at all.'),
        isNull);
    expect(provider.calls.last, 'dispute:req-1:client_no_show');
  });
}

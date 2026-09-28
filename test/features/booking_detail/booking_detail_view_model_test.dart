import 'package:eventor/core/bookings/bookings_repository.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/features/booking_detail/view_model/booking_detail_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/booking_fakes.dart';
import '../../support/fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  late ScriptedBookingsRepository bookings;
  late FakeMessagingRepository messaging;

  setUp(() {
    bookings = ScriptedBookingsRepository();
    messaging = FakeMessagingRepository();
  });

  Future<BookingDetailViewModel> build() async {
    final BookingDetailViewModel viewModel = BookingDetailViewModel(
      id: 'b-1',
      bookings: bookings,
      messaging: messaging,
      replyDeadlineHours: 48,
      now: () => DateTime(2026, 3, 5, 9),
    );
    addTearDown(viewModel.dispose);
    await flushAsync();
    return viewModel;
  }

  test('loads the booking', () async {
    final BookingDetailViewModel viewModel = await build();

    expect(viewModel.detail?.id, 'b-1');
    expect(viewModel.daysToEvent, 9);
    expect(viewModel.eventPassed, isFalse);
  });

  test('a booking that is not the client’s is gone, not an error', () async {
    bookings.failNext = apiFailure(ApiErrorCode.notOwner, statusCode: 403);
    final BookingDetailViewModel viewModel = await build();

    expect(viewModel.isGone, isTrue);
    expect(viewModel.hasError, isFalse);
  });

  test('B5: cancelling shows the booking as it now stands', () async {
    final BookingDetailViewModel viewModel = await build();
    bookings.afterWrite = testBooking(status: 'cancelled', allowedActions: <String>['message']);

    expect(await viewModel.cancel('Venue changed.'), isNull);

    expect(bookings.calls, contains('cancel:b-1:Venue changed.'));
    expect(viewModel.detail?.status, 'cancelled');
  });

  test('a refusal that means it moved reloads it', () async {
    final BookingDetailViewModel viewModel = await build();
    bookings.failNext = apiFailure(ApiErrorCode.bookingInvalidTransition, statusCode: 409);

    expect(await viewModel.cancel('Late.'), isA<ApiFailure>());

    expect(bookings.calls.where((String c) => c == 'detail:b-1'), hasLength(2));
  });

  test('B6a: accepting the provider’s date', () async {
    bookings.booking = testBooking(reschedules: <Map<String, Object?>>[proposalJson()]);
    final BookingDetailViewModel viewModel = await build();
    final Reschedule proposal = viewModel.detail!.proposalForMe!;
    bookings.afterWrite = testBooking();

    final Future<Failure?> pending = viewModel.acceptProposal(proposal);
    expect(viewModel.answering, 'accept');
    expect(await pending, isNull);

    expect(viewModel.answering, isNull);
    expect(bookings.calls, contains('accept:r-1'));
    expect(viewModel.detail?.proposalForMe, isNull);
  });

  test('a review reloads the booking', () async {
    final BookingDetailViewModel viewModel = await build();

    expect(await viewModel.review(5, 'Wonderful team, thank you.'), isNull);

    expect(bookings.calls, containsAllInOrder(<String>['review:b-1:5', 'detail:b-1']));
  });

  test('Message finds the chat with the provider', () async {
    final BookingDetailViewModel viewModel = await build();

    final String? route = await viewModel.chatRoute();

    // The booking carries no chat id: the existing chat with the provider.
    expect(route, AppRoutes.chatFor('c-lumiere'));
    expect(messaging.calls, contains('findWith:p-lumiere'));
  });
}

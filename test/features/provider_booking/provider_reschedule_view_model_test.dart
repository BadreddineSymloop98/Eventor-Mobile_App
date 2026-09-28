import 'package:eventor/core/catalog/models/availability.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/provider/provider_repository.dart';
import 'package:eventor/features/provider_booking/view_model/provider_reschedule_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/provider_fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  // The 5th of March 2026; the booking is on the 14th, 13:00 → 23:00.
  final DateTime today = DateTime(2026, 3, 5, 9);

  ProviderBooking booking({String status = 'accepted'}) =>
      ProviderBooking.fromJson(providerBookingDetailJson(status: status));

  Future<ProviderRescheduleViewModel> build(
    FakeProviderRepository provider, {
    String status = 'accepted',
  }) async {
    final ProviderRescheduleViewModel viewModel = ProviderRescheduleViewModel(
      booking: booking(status: status),
      provider: provider,
      today: () => today,
    );
    addTearDown(viewModel.dispose);
    await flushAsync();
    return viewModel;
  }

  FakeProviderRepository repository() => FakeProviderRepository(
        bookings: <Map<String, Object?>>[providerBookingDetailJson(status: 'accepted')],
      );

  group('the calendar', () {
    test('opens on the booking’s month, from the provider’s own calendar', () async {
      final FakeProviderRepository provider = repository();
      final ProviderRescheduleViewModel viewModel = await build(provider);

      expect(provider.calls, contains('month:2026-03'));
      expect(viewModel.visibleMonth, DateTime(2026, 3));
    });

    test('greys out the past and blocked days, strikes full ones, leaves the rest free', () async {
      final ProviderRescheduleViewModel viewModel = await build(repository());
      final Availability month = viewModel.availability!;

      expect(month.stateOf(DateTime(2026, 3, 2)), DayState.blocked, reason: 'past');
      expect(month.stateOf(DateTime(2026, 3, 9)), DayState.blocked, reason: 'blocked by the provider');
      expect(month.stateOf(DateTime(2026, 3, 7)), DayState.busy, reason: 'another booking fills it');
      expect(month.stateOf(DateTime(2026, 3, 14)), DayState.busy, reason: 'its own current day');
      expect(month.stateOf(DateTime(2026, 3, 21)), DayState.available);
      expect(month.stateOf(DateTime(2026, 3, 5)), DayState.available, reason: 'today is not past');
    });

    test('a day with room for one more is free', () async {
      final FakeProviderRepository provider = repository()..monthJson = providerMonthJson(maxEventsPerDay: 2);
      final ProviderRescheduleViewModel viewModel = await build(provider);

      expect(viewModel.availability!.stateOf(DateTime(2026, 3, 7)), DayState.available);
    });

    test('picks only a free day', () async {
      final ProviderRescheduleViewModel viewModel = await build(repository());

      viewModel.selectDate(DateTime(2026, 3, 7));
      expect(viewModel.selectedDate, isNull);

      viewModel.selectDate(DateTime(2026, 3, 21));
      expect(viewModel.selectedDate, DateTime(2026, 3, 21));
    });
  });

  group('the form', () {
    test('starts with the booking’s times and nothing to lose', () async {
      final ProviderRescheduleViewModel viewModel = await build(repository());

      expect(viewModel.startTime, '13:00');
      expect(viewModel.endTime, '23:00');
      expect(viewModel.isDirty, isFalse);
      expect(viewModel.isProposal, isTrue);
    });

    test('is dirty once a time, a date or a reason changed', () async {
      final ProviderRescheduleViewModel viewModel = await build(repository());

      viewModel.setStartTime('14:00');
      expect(viewModel.isDirty, isTrue);
    });

    test('drops an end equal to the new start', () async {
      final ProviderRescheduleViewModel viewModel = await build(repository());

      viewModel.setStartTime('23:00');

      expect(viewModel.endTime, isNull);
    });

    test('needs a date and a reason before sending', () async {
      final FakeProviderRepository provider = repository();
      final ProviderRescheduleViewModel viewModel = await build(provider);

      expect(await viewModel.submit(), isNull);

      expect(viewModel.dateMissing, isTrue);
      expect(viewModel.reasonMissing, isTrue);
      expect(provider.calls.where((String c) => c.startsWith('reschedule')), isEmpty);
    });
  });

  group('sending', () {
    Future<ProviderRescheduleViewModel> filled(FakeProviderRepository provider, {String status = 'accepted'}) async {
      final ProviderRescheduleViewModel viewModel = await build(provider, status: status);
      viewModel
        ..selectDate(DateTime(2026, 3, 21))
        ..setEndTime('01:00')
        ..setReason('  The hall is only free the week after.  ');
      return viewModel;
    }

    test('an accepted booking becomes a proposal, with the times and the trimmed reason', () async {
      final FakeProviderRepository provider = repository();
      final ProviderRescheduleViewModel viewModel = await filled(provider);

      final ProviderBooking? updated = await viewModel.submit();

      expect(provider.calls.last, 'reschedule:req-1:2026-03-21:13:00-01:00:The hall is only free the week after.');
      expect(updated!.myPendingProposal?.newDate, DateTime(2026, 3, 21));
    });

    test('a request moves at once', () async {
      final FakeProviderRepository provider = FakeProviderRepository(
        bookings: <Map<String, Object?>>[providerBookingDetailJson()],
      );
      final ProviderRescheduleViewModel viewModel = await filled(provider, status: 'pending');
      expect(viewModel.isProposal, isFalse);

      final ProviderBooking? updated = await viewModel.submit();

      expect(updated!.card.eventDate, DateTime(2026, 3, 21));
    });

    test('a day taken meanwhile is struck through and let go of', () async {
      final FakeProviderRepository provider = repository();
      final ProviderRescheduleViewModel viewModel = await filled(provider);
      provider.failNext = apiFailure(ApiErrorCode.dateUnavailable, statusCode: 409);

      expect(await viewModel.submit(), isNull);

      expect(viewModel.problem, ProviderRescheduleProblem.dateTaken);
      expect(viewModel.takenDate, DateTime(2026, 3, 21));
      expect(viewModel.selectedDate, isNull);
      expect(viewModel.availability!.stateOf(DateTime(2026, 3, 21)), DayState.busy);
    });

    test('an open proposal sends the user back to P2', () async {
      final FakeProviderRepository provider = repository();
      final ProviderRescheduleViewModel viewModel = await filled(provider);
      provider.failNext = apiFailure(ApiErrorCode.reschedulePendingExists, statusCode: 409);

      expect(await viewModel.submit(), isNull);

      expect(viewModel.problem, ProviderRescheduleProblem.stale);
    });

    test('a refused reason marks the field', () async {
      final FakeProviderRepository provider = repository();
      final ProviderRescheduleViewModel viewModel = await filled(provider);
      provider.failNext = const ApiFailure(
        statusCode: 400,
        code: ApiErrorCode.validationFailed,
        message: 'Some fields are invalid.',
        fieldErrors: <FieldError>[FieldError(field: 'reason', code: 'MAX_LENGTH', message: 'Too long.')],
      );

      expect(await viewModel.submit(), isNull);

      expect(viewModel.reasonMissing, isTrue);
      expect(viewModel.problem, isNull);
    });

    test('offline keeps everything to try again', () async {
      final FakeProviderRepository provider = repository();
      final ProviderRescheduleViewModel viewModel = await filled(provider);
      provider.failNext = const NetworkFailure();

      expect(await viewModel.submit(), isNull);

      expect(viewModel.problem, ProviderRescheduleProblem.failed);
      expect(viewModel.selectedDate, DateTime(2026, 3, 21));
      expect(await viewModel.submit(), isNotNull);
    });
  });
}

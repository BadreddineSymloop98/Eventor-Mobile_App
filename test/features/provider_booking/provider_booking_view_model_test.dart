import 'dart:async';

import 'package:eventor/core/bookings/models/booking_card.dart';
import 'package:eventor/core/bookings/models/booking_detail.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/provider/provider_repository.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/features/provider_booking/view_model/provider_booking_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/provider_fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  late FakeMessagingRepository messaging;

  setUp(() => messaging = FakeMessagingRepository());

  Future<ProviderBookingViewModel> build(
    FakeProviderRepository provider, {
    String id = 'req-1',
    DateTime? now,
  }) async {
    final ProviderBookingViewModel viewModel = ProviderBookingViewModel(
      id: id,
      provider: provider,
      messaging: messaging,
      replyDeadlineHours: 48,
      now: () => now ?? DateTime(2026, 3, 5, 12),
    );
    addTearDown(viewModel.dispose);
    await flushAsync();
    return viewModel;
  }

  FakeProviderRepository with1(Map<String, Object?> booking) =>
      FakeProviderRepository(bookings: <Map<String, Object?>>[booking]);

  group('loading', () {
    test('is on the skeleton until the booking comes', () {
      final FakeProviderRepository provider = with1(providerBookingDetailJson())..gate = Completer<void>();
      final ProviderBookingViewModel viewModel = ProviderBookingViewModel(
        id: 'req-1',
        provider: provider,
        messaging: messaging,
        replyDeadlineHours: 48,
      );
      addTearDown(viewModel.dispose);

      expect(viewModel.isFirstLoad, isTrue);
    });

    test('reads the booking, with the client behind it', () async {
      final ProviderBookingViewModel viewModel = await build(with1(providerBookingDetailJson()));

      expect(viewModel.booking!.clientName, 'Nadia Kaci');
      expect(viewModel.booking!.client.phone, isNull);
      expect(viewModel.isRequest, isTrue);
    });

    test('says a booking is gone rather than failing', () async {
      final FakeProviderRepository provider = with1(providerBookingDetailJson())
        ..failNext = apiFailure(ApiErrorCode.notOwner, statusCode: 403);
      final ProviderBookingViewModel viewModel = await build(provider);

      expect(viewModel.isGone, isTrue);
      expect(viewModel.hasError, isFalse);
      expect(viewModel.isFirstLoad, isFalse);
    });

    test('reports a failed load and retries', () async {
      final FakeProviderRepository provider = with1(providerBookingDetailJson())
        ..failNext = const NetworkFailure();
      final ProviderBookingViewModel viewModel = await build(provider);

      expect(viewModel.hasError, isTrue);
      await viewModel.load();
      expect(viewModel.booking, isNotNull);
    });
  });

  group('P2 · a request', () {
    test('counts the hours left to reply', () async {
      final ProviderBookingViewModel viewModel = await build(
        with1(providerBookingDetailJson()),
        now: DateTime.utc(2026, 3, 3, 10, 50).toLocal(),
      );

      expect(viewModel.replyHoursLeft, 48);
    });

    test('accepts in one tap and becomes P2a in place', () async {
      final FakeProviderRepository provider = with1(providerBookingDetailJson());
      final ProviderBookingViewModel viewModel = await build(provider);

      final Future<Failure?> pending = viewModel.accept();
      expect(viewModel.busy, ProviderBookingBusy.accept);
      expect(await viewModel.accept(), isNull, reason: 'a double tap sends once');
      expect(await pending, isNull);

      expect(provider.calls.where((String c) => c.startsWith('accept')), hasLength(1));
      expect(viewModel.booking!.status, 'accepted');
      expect(viewModel.isRequest, isFalse);
      expect(viewModel.busy, isNull);
    });

    test('declines through P3 and shows P2c at once', () async {
      final FakeProviderRepository provider = with1(providerBookingDetailJson());
      final ProviderBookingViewModel viewModel = await build(provider);

      expect(await viewModel.decline('  Already booked  '), isNull);

      expect(provider.calls, contains('decline:req-1:Already booked'));
      expect(viewModel.booking!.status, 'declined');
      expect(viewModel.booking!.declineReason, 'Already booked');
      expect(viewModel.isRequest, isTrue, reason: 'a declined request stays a request');
    });

    test('reloads when the request moved meanwhile', () async {
      final FakeProviderRepository provider = with1(providerBookingDetailJson());
      final ProviderBookingViewModel viewModel = await build(provider);
      provider
        ..calls.clear()
        ..failNext = apiFailure(ApiErrorCode.bookingInvalidTransition, statusCode: 409);

      final Failure? failure = await viewModel.accept();

      expect(failure, isA<ApiFailure>());
      expect(provider.calls, <String>['accept:req-1', 'booking:req-1']);
    });
  });

  group('P2a · an accepted booking', () {
    Map<String, Object?> accepted({List<Map<String, Object?>> reschedules = const <Map<String, Object?>>[]}) =>
        providerBookingDetailJson(
          status: 'accepted',
          phone: '+213770551288',
          allowedActions: <String>[
            'message',
            'cancel',
            if (reschedules.isEmpty) 'reschedule',
            if (reschedules.any((Map<String, Object?> r) => r['awaitingMe'] == true)) 'respond_reschedule',
          ],
          reschedules: reschedules,
          timeline: <Map<String, Object?>>[
            <String, Object?>{'type': 'created', 'toStatus': 'pending', 'actorLabel': null, 'reason': null, 'at': '2026-03-03T10:00:00.000Z'},
            <String, Object?>{'type': 'accepted', 'toStatus': 'accepted', 'actorLabel': null, 'reason': null, 'at': '2026-03-03T16:05:00.000Z'},
          ],
        );

    test('shows the client’s phone, and is a booking for good', () async {
      final ProviderBookingViewModel viewModel = await build(with1(accepted()));

      expect(viewModel.booking!.client.phone, '+213770551288');
      expect(viewModel.isRequest, isFalse);
      expect(viewModel.eventPassed, isFalse);
    });

    test('cancels with a reason and shows P2d at once', () async {
      final FakeProviderRepository provider = with1(accepted());
      final ProviderBookingViewModel viewModel = await build(provider);

      expect(await viewModel.cancel('The hall is closed.'), isNull);

      expect(viewModel.booking!.status, 'cancelled');
      expect(viewModel.booking!.cancelledBy, CancelledBy.provider);
      expect(viewModel.isRequest, isFalse, reason: 'it had been accepted');
    });

    test('answers the client’s proposal (P4a) — accept', () async {
      final FakeProviderRepository provider = with1(accepted(reschedules: <Map<String, Object?>>[providerRescheduleJson()]));
      final ProviderBookingViewModel viewModel = await build(provider);
      final Reschedule proposal = clientProposal(viewModel.booking!)!;

      final Future<Failure?> pending = viewModel.acceptProposal(proposal);
      expect(viewModel.busy, ProviderBookingBusy.acceptProposal);
      expect(await pending, isNull);

      expect(provider.calls, contains('acceptReschedule:req-1:rs-1'));
      expect(viewModel.booking!.card.eventDate, DateTime(2026, 3, 21));
      expect(clientProposal(viewModel.booking!), isNull);
    });

    test('answers the client’s proposal — decline keeps the date', () async {
      final FakeProviderRepository provider = with1(accepted(reschedules: <Map<String, Object?>>[providerRescheduleJson()]));
      final ProviderBookingViewModel viewModel = await build(provider);

      expect(await viewModel.rejectProposal(clientProposal(viewModel.booking!)!), isNull);

      expect(viewModel.booking!.card.eventDate, DateTime(2026, 3, 14));
      expect(clientProposal(viewModel.booking!), isNull);
    });

    test('shows no proposal to answer unless the server allows it', () async {
      final Map<String, Object?> json = accepted(reschedules: <Map<String, Object?>>[providerRescheduleJson()])
        ..['allowedActions'] = <String>['message'];
      final ProviderBookingViewModel viewModel = await build(with1(json));

      expect(viewModel.booking!.proposalForMe, isNotNull);
      expect(clientProposal(viewModel.booking!), isNull);
    });

    test('withdraws its own proposal', () async {
      final FakeProviderRepository provider = with1(accepted(reschedules: <Map<String, Object?>>[
        providerRescheduleJson(id: 'rs-mine', by: 'provider', awaitingMe: false),
      ]));
      final ProviderBookingViewModel viewModel = await build(provider);
      final Reschedule mine = viewModel.booking!.myPendingProposal!;

      expect(await viewModel.withdrawProposal(mine), isNull);

      expect(provider.calls, contains('withdrawReschedule:req-1:rs-mine'));
      expect(viewModel.booking!.myPendingProposal, isNull);
    });

    test('reloads when the proposal was already answered', () async {
      final FakeProviderRepository provider = with1(accepted(reschedules: <Map<String, Object?>>[providerRescheduleJson()]));
      final ProviderBookingViewModel viewModel = await build(provider);
      provider
        ..calls.clear()
        ..failNext = apiFailure(ApiErrorCode.rescheduleNotPending, statusCode: 409);

      final Failure? failure = await viewModel.rejectProposal(clientProposal(viewModel.booking!)!);

      expect(failure, isA<ApiFailure>());
      expect(provider.calls.last, 'booking:req-1');
      expect(viewModel.busy, isNull);
    });

    test('takes what P4 came back with', () async {
      final ProviderBookingViewModel viewModel = await build(with1(accepted()));

      viewModel.replace(ProviderBooking.fromJson(accepted()..['eventDate'] = '2026-03-28'));

      expect(viewModel.booking!.card.eventDate, DateTime(2026, 3, 28));
    });
  });

  group('P2b · the event has passed', () {
    test('knows it, and reports a problem then reloads', () async {
      final FakeProviderRepository provider = with1(providerBookingDetailJson(
        status: 'accepted',
        eventDate: '2026-03-04',
        allowedActions: <String>['message', 'check_in', 'dispute'],
      ));
      final ProviderBookingViewModel viewModel = await build(provider);

      expect(viewModel.eventPassed, isTrue);
      expect(viewModel.booking!.can(BookingAction.checkIn), isTrue);

      expect(
        await viewModel.reportProblem(ProviderDisputeType.clientNoShow, 'Nobody came, nobody answered.'),
        isNull,
      );
      expect(provider.calls, containsAllInOrder(<String>['dispute:req-1:client_no_show', 'booking:req-1']));
      expect(viewModel.booking!.dispute?.isOpen, isTrue);
    });

    test('reloads when a problem is already open', () async {
      final FakeProviderRepository provider = with1(providerBookingDetailJson(status: 'accepted', eventDate: '2026-03-04'));
      final ProviderBookingViewModel viewModel = await build(provider);
      provider
        ..calls.clear()
        ..failNext = apiFailure(ApiErrorCode.disputeAlreadyOpen, statusCode: 409);

      final Failure? failure =
          await viewModel.reportProblem(ProviderDisputeType.other, 'Something else went wrong that night.');

      expect(failure, isA<ApiFailure>());
      expect(provider.calls.last, 'booking:req-1');
    });
  });

  group('Message client', () {
    test('opens the booking’s chat when it has one', () async {
      final ProviderBookingViewModel viewModel =
          await build(with1(providerBookingDetailJson()..['conversationId'] = 'c-42'));

      expect(await viewModel.chatRoute(), AppRoutes.chatFor('c-42'));
    });

    test('else looks the client up, or starts a draft', () async {
      final ProviderBookingViewModel viewModel = await build(with1(providerBookingDetailJson()));

      final String? route = await viewModel.chatRoute();

      expect(messaging.calls, contains('findWith:client-1'));
      expect(route, AppRoutes.chatDraftFor(userId: 'client-1', name: 'Nadia Kaci'));
    });
  });
}

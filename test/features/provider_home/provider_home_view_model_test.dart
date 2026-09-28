import 'dart:async';

import 'package:eventor/core/bookings/models/booking_card.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/provider/provider_repository.dart';
import 'package:eventor/core/session/session_controller.dart';
import 'package:eventor/features/auth/data/documents_repository.dart';
import 'package:eventor/features/provider_home/view_model/provider_home_view_model.dart';
import 'package:eventor/features/shell/shell_badges.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/provider_fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  group('ProviderHome.fromJson', () {
    test('reads 21: counts, requests with their actions, services', () {
      final ProviderHome home = ProviderHome.fromJson(providerHomeJson());

      expect(home.isVerified, isTrue);
      expect(home.documents, isNull);
      expect(home.counts.requests, 2);
      expect(home.requests.first.counterpartyName, 'Nadia Kaci');
      expect(home.requests.first.can(BookingAction.accept), isTrue);
      expect(home.requests.first.can(BookingAction.decline), isTrue);
      expect(home.upcoming.single.status, 'accepted');
      expect(home.services.single.status, ProviderServiceStatus.draft);
      expect(home.services.single.basePrice, '45000.00');
    });

    test('reads 21a: the steps and the documents', () {
      final ProviderHome home = ProviderHome.fromJson(
        providerHomeJson(state: 'pending', documents: <String>['pending', 'pending', 'missing']),
      );

      expect(home.state, ProviderHomeState.pending);
      expect(home.steps.map((VerificationStep s) => s.key), VerificationStepKey.values);
      expect(home.documents?.sentCount, 2);
      expect(
        home.documents?.needingAction.single.type,
        ProviderDocumentType.taxCard,
      );
    });

    test('reads 21b and a blocked account', () {
      expect(
        ProviderHome.fromJson(providerHomeJson(state: 'rejected')).state,
        ProviderHomeState.rejected,
      );
      expect(
        ProviderHome.fromJson(providerHomeJson(state: 'blocked')).state,
        ProviderHomeState.blocked,
      );
    });

    test('ignores actions and steps it does not know', () {
      final Map<String, Object?> json = providerHomeJson();
      (json['requests']! as List<Object?>)[0] = providerBookingJson(
        allowedActions: <String>['accept', 'teleport'],
      );
      (json['verificationSteps']! as List<Object?>).add(
        <String, Object?>{'key': 'future_step', 'done': false, 'current': false},
      );

      final ProviderHome home = ProviderHome.fromJson(json);

      expect(home.requests.first.allowedActions, <BookingAction>{BookingAction.accept});
      expect(home.steps, hasLength(4));
    });
  });

  group('ProviderHomeViewModel', () {
    late FakeAuthRepository auth;
    late SessionController session;
    late ShellBadges badges;

    setUp(() {
      auth = FakeAuthRepository();
      session = SessionController(auth)
        ..signedIn(testUser(role: UserRole.provider, fullName: 'Karim Belkacem'));
      badges = ShellBadges(notifications: FakeNotificationsRepository());
    });

    Future<ProviderHomeViewModel> build(
      FakeProviderRepository provider, {
      DateTime? now,
    }) async {
      final ProviderHomeViewModel viewModel = ProviderHomeViewModel(
        provider: provider,
        session: session,
        badges: badges,
        replyDeadlineHours: 48,
        now: () => now ?? DateTime(2026, 3, 3, 20),
      );
      addTearDown(viewModel.dispose);
      await flushAsync();
      return viewModel;
    }

    test('is on the skeleton until the first answer', () {
      final FakeProviderRepository provider = FakeProviderRepository()..gate = Completer<void>();
      final ProviderHomeViewModel viewModel = ProviderHomeViewModel(
        provider: provider,
        session: session,
        badges: badges,
        replyDeadlineHours: 48,
      );
      addTearDown(viewModel.dispose);

      expect(viewModel.isFirstLoad, isTrue);
    });

    test('greets the person, and in the evening', () async {
      final ProviderHomeViewModel viewModel = await build(FakeProviderRepository());

      expect(viewModel.fullName, 'Karim Belkacem');
      expect(viewModel.greeting, Greeting.evening);
    });

    test('puts the unread counts on the tab bar', () async {
      await build(FakeProviderRepository(home: providerHomeJson()));

      expect(badges.unreadConversations, 2);
      expect(badges.unreadNotifications, 1);
    });

    test('counts the hours left to reply, rounded up and never below zero', () async {
      final ProviderHomeViewModel viewModel = await build(
        FakeProviderRepository(home: providerHomeJson()),
        now: DateTime.utc(2026, 3, 3, 10, 50).toLocal(),
      );
      final BookingCard made10am = viewModel.home!.requests.first;

      expect(viewModel.replyHoursLeft(made10am), 48);

      final ProviderHomeViewModel late = await build(
        FakeProviderRepository(home: providerHomeJson()),
        now: DateTime.utc(2026, 3, 6).toLocal(),
      );
      expect(late.replyHoursLeft(late.home!.requests.first), 0);
    });

    test('reports a failed first load and retries', () async {
      final FakeProviderRepository provider = FakeProviderRepository()
        ..failNext = const NetworkFailure();
      final ProviderHomeViewModel viewModel = await build(provider);

      expect(viewModel.hasError, isTrue);
      expect(viewModel.isFirstLoad, isFalse);

      await viewModel.load();

      expect(viewModel.home, isNotNull);
    });

    test('accepts a request and reloads, the request now upcoming', () async {
      final FakeProviderRepository provider = FakeProviderRepository(home: providerHomeJson());
      final ProviderHomeViewModel viewModel = await build(provider);
      final BookingCard request = viewModel.home!.requests.first;

      final Future<Failure?> pending = viewModel.accept(request);
      expect(viewModel.accepting, request.id);
      final Failure? failure = await pending;

      expect(failure, isNull);
      expect(provider.calls, containsAllInOrder(<String>['accept:req-1', 'home']));
      expect(viewModel.home!.requests.map((BookingCard r) => r.id), <String>['req-2']);
      expect(viewModel.home!.upcoming.first.id, 'req-1');
      expect(viewModel.accepting, isNull);
    });

    test('reports a refused accept and still reloads', () async {
      final FakeProviderRepository provider = FakeProviderRepository(home: providerHomeJson());
      final ProviderHomeViewModel viewModel = await build(provider);
      provider.calls.clear();
      provider.failNext = apiFailure(ApiErrorCode.dateUnavailable, statusCode: 409);

      final Failure? failure = await viewModel.accept(viewModel.home!.requests.first);

      expect(failure, isA<ApiFailure>());
      expect(provider.calls.last, 'home');
    });

    test('declines with the trimmed reason and reloads', () async {
      final FakeProviderRepository provider = FakeProviderRepository(home: providerHomeJson());
      final ProviderHomeViewModel viewModel = await build(provider);

      final Failure? failure =
          await viewModel.decline(viewModel.home!.requests.first, '  Already booked  ');

      expect(failure, isNull);
      expect(provider.calls, contains('decline:req-1:Already booked'));
      expect(viewModel.home!.requests, hasLength(1));
    });

    test('hands a refused decline back to the sheet', () async {
      final FakeProviderRepository provider = FakeProviderRepository(home: providerHomeJson());
      final ProviderHomeViewModel viewModel = await build(provider);
      provider.failNext = const NetworkFailure();

      final Failure? failure = await viewModel.decline(viewModel.home!.requests.first, 'No');

      expect(failure, isA<NetworkFailure>());
      expect(viewModel.home!.requests, hasLength(2));
    });

    test('pauses bookings at once and keeps it', () async {
      final FakeProviderRepository provider = FakeProviderRepository(home: providerHomeJson());
      final ProviderHomeViewModel viewModel = await build(provider);

      final Future<Failure?> pending = viewModel.setAcceptingBookings(false);
      expect(viewModel.home!.acceptingBookings, isFalse);
      expect(await pending, isNull);

      expect(provider.calls.last, 'accepting:false');
      expect(viewModel.home!.acceptingBookings, isFalse);
    });

    test('puts the availability back when the server refuses', () async {
      final FakeProviderRepository provider = FakeProviderRepository(home: providerHomeJson());
      final ProviderHomeViewModel viewModel = await build(provider);
      provider.failNext = const NetworkFailure();

      final Failure? failure = await viewModel.setAcceptingBookings(false);

      expect(failure, isA<NetworkFailure>());
      expect(viewModel.home!.acceptingBookings, isTrue);
    });

    test('keeps a blocked account signed in, on 21c', () async {
      final ProviderHomeViewModel viewModel = await build(
        FakeProviderRepository(home: providerHomeJson(state: 'blocked')),
      );
      await flushAsync();

      expect(session.isSignedIn, isTrue);
      expect(viewModel.home!.isBlocked, isTrue);
    });
  });
}

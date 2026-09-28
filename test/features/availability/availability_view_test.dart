import 'package:eventor/core/availability/availability_repository.dart';
import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/provider/models/provider_home.dart';
import 'package:eventor/features/availability/view/availability_view.dart';
import 'package:eventor/features/availability/view_model/availability_view_model.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/availability_fakes.dart';
import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  final DateTime now = DateTime(2026, 3, 10, 9);
  late FakeAvailabilityRepository repository;

  Future<void> open(WidgetTester tester) async {
    usePhoneSurface(tester);
    await pumpAppWidget(
      tester,
      ChangeNotifierProvider<AvailabilityViewModel>(
        create: (_) => AvailabilityViewModel(
          availability: repository,
          loadServices: () async => <ProviderServiceRow>[testServiceRow('svc-1', 'Grande salle')],
          config: const AppConfig(),
          today: () => now,
        ),
        child: const AvailabilityView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = FakeAvailabilityRepository(
      items: <Map<String, Object?>>[
        blockItemJson(id: 'b-21', date: DateTime(2026, 3, 21), note: 'Family wedding'),
        bookingItemJson(bookingId: 'bk-26', date: DateTime(2026, 3, 26), reference: 'EVT-2026-0142'),
      ],
    );
  });

  testWidgets('a day with a block: Remove at once, then Undo puts it back', (WidgetTester tester) async {
    await open(tester);
    final AppLocalizations strings = l10n(tester);

    await tester.tap(find.text('21'));
    await tester.pumpAndSettle();

    expect(find.text('Saturday 21 March'), findsOneWidget);
    expect(find.text(strings.availabilityItemBlockedAllDay), findsOneWidget);
    expect(find.text(strings.availabilityItemNote('Family wedding')), findsOneWidget);
    // Already blocked all day: no block actions, and why.
    expect(find.text(strings.availabilityAlreadyBlocked), findsOneWidget);
    expect(button(strings.availabilityBlockWholeDay), findsNothing);

    await tester.tap(find.text(strings.availabilityRemove));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('unblock:b-21'));
    expect(find.text(strings.availabilityRemovedToast), findsOneWidget);

    await tester.tap(find.text(strings.undo));
    await tester.pumpAndSettle();

    expect(repository.blocks.single.date, DateTime(2026, 3, 21));
    expect(repository.blocks.single.note, 'Family wedding');
    expect(find.text(strings.availabilityRestoredToast), findsOneWidget);
  });

  testWidgets('a booked day names the booking and cannot be removed', (WidgetTester tester) async {
    await open(tester);
    final AppLocalizations strings = l10n(tester);

    await tester.tap(find.text('26'));
    await tester.pumpAndSettle();

    // The reference is isolated inside its sentence, so match on it alone.
    expect(find.textContaining('EVT-2026-0142'), findsOneWidget);
    expect(find.text(strings.availabilityCannotRemove), findsOneWidget);
    expect(find.text(strings.availabilityRemove), findsNothing);
    // One accepted booking fills a one-event day.
    expect(find.text(strings.availabilityFullyBooked), findsOneWidget);
  });

  testWidgets('"Block a day" waits for a day, then blocks it through P15a', (WidgetTester tester) async {
    await open(tester);
    final AppLocalizations strings = l10n(tester);
    expect(isTappable(tester, strings.availabilityBlockDay), isFalse);

    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.availabilityClose));
    await tester.pumpAndSettle();
    expect(isTappable(tester, strings.availabilityBlockDay), isTrue);

    await tester.tap(button(strings.availabilityBlockDay));
    await tester.pumpAndSettle();
    expect(find.text(strings.availabilityBlockDayTitle('Thursday 12 March')), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Family wedding');
    await tester.tap(button(strings.availabilityConfirmDay));
    await tester.pumpAndSettle();

    final BlockRequest sent = repository.blocks.single;
    expect(sent.date, DateTime(2026, 3, 12));
    expect(sent.isWholeDay, isTrue);
    expect(sent.serviceId, isNull);
    expect(sent.note, 'Family wedding');
    expect(find.text(strings.availabilityBlockedDayToast('Thursday 12 March')), findsOneWidget);
  });

  testWidgets('a time slot needs both times; a refusal stays in the sheet', (WidgetTester tester) async {
    await open(tester);
    final AppLocalizations strings = l10n(tester);

    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    await tester.tap(button(strings.availabilityBlockSlot));
    await tester.pumpAndSettle();

    await tester.tap(button(strings.availabilityConfirmSlot));
    await tester.pumpAndSettle();
    expect(find.text(strings.availabilityTimesMissing), findsOneWidget);
    expect(repository.blocks, isEmpty);

    // Back to a whole day, refused by the server: the sheet stays open.
    await tester.tap(find.text(strings.availabilityModeWholeDay));
    await tester.pumpAndSettle();
    repository.failNext['block'] = apiFailure(ApiErrorCode.availabilityDatePast);
    await tester.tap(button(strings.availabilityConfirmDay));
    await tester.pumpAndSettle();

    expect(find.text(strings.availabilityErrorDatePast), findsOneWidget);
    expect(button(strings.availabilityConfirmDay), findsOneWidget);
  });
}

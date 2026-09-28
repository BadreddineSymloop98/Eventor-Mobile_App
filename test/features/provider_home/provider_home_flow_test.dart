import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/features/auth/data/documents_repository.dart';
import 'package:eventor/features/documents/view/documents_view.dart';
import 'package:eventor/features/messages/view/messages_view.dart';
import 'package:eventor/features/provider_home/view/provider_home_view.dart';
import 'package:eventor/features/resubmit_documents/view/resubmit_documents_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/provider_fakes.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  Future<TestApp> openHome(
    WidgetTester tester, {
    Map<String, Object?>? home,
    FakeDocumentsRepository? documents,
  }) async {
    final TestApp app = await buildTestApp(
      hasSeenOnboarding: true,
      auth: FakeAuthRepository()
        ..restoredUser = testUser(role: UserRole.provider, fullName: 'Karim Belkacem'),
      provider: FakeProviderRepository(home: home ?? providerHomeJson()),
    );
    if (documents != null) {
      // The harness builds its own; swap the statuses in for this test.
      app.documents.statuses.addAll(documents.statuses);
    }
    await startApp(tester, app);
    expect(find.byType(ProviderHomeView), findsOneWidget);
    return app;
  }

  String location(TestApp app) =>
      app.services.router.routerDelegate.currentConfiguration.uri.toString();

  group('21 · verified', () {
    testWidgets('shows the counters, the requests and the services', (WidgetTester tester) async {
      await openHome(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.text('Karim Belkacem'), findsOneWidget);
      expect(find.text(strings.providerAccepting), findsOneWidget);
      expect(find.text('Nadia Kaci'), findsOneWidget);
      expect(find.text('Yacine Meddour'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Wedding photography'), 300);
      expect(find.text(strings.serviceStatusDraft), findsOneWidget);
    });

    testWidgets('accepts a request in one tap', (WidgetTester tester) async {
      final TestApp app = await openHome(tester);
      final AppLocalizations strings = l10n(tester);

      await tapAndSettle(tester, button(strings.requestAccept).first);

      expect(app.provider.calls, contains('accept:req-1'));
      expect(find.text(strings.providerAccepted('Nadia Kaci')), findsOneWidget);
      expect(button(strings.requestAccept), findsOneWidget, reason: 'one request left');
    });

    testWidgets('declines through P3, only with a reason', (WidgetTester tester) async {
      final TestApp app = await openHome(tester);
      final AppLocalizations strings = l10n(tester);

      await tapAndSettle(tester, button(strings.requestDecline).first);
      expect(find.text(strings.declineTitle), findsOneWidget);
      expect(isTappable(tester, strings.declineConfirm), isFalse);

      await tester.enterText(find.byType(TextField).last, 'Already booked that day');
      await tester.pump();
      expect(find.text('23/60'), findsOneWidget);
      await tapAndSettle(tester, button(strings.declineConfirm));

      expect(app.provider.calls, contains('decline:req-1:Already booked that day'));
      expect(find.text(strings.declineTitle), findsNothing);
      expect(find.text(strings.providerDeclined), findsOneWidget);
    });

    testWidgets('Go back leaves the request as it was', (WidgetTester tester) async {
      final TestApp app = await openHome(tester);
      final AppLocalizations strings = l10n(tester);

      await tapAndSettle(tester, button(strings.requestDecline).first);
      await tapAndSettle(tester, button(strings.declineGoBack));

      expect(app.provider.calls.where((String c) => c.startsWith('decline')), isEmpty);
    });

    testWidgets('pauses bookings from the pill', (WidgetTester tester) async {
      final TestApp app = await openHome(tester);
      final AppLocalizations strings = l10n(tester);

      await tapAndSettle(tester, find.text(strings.providerAccepting));
      await tapAndSettle(tester, find.text(strings.providerPaused).last);

      expect(app.provider.calls.last, 'accepting:false');
      expect(find.text(strings.providerPaused), findsOneWidget);
    });

    testWidgets('says so when there is no request', (WidgetTester tester) async {
      await openHome(tester, home: providerHomeJson(requests: <Map<String, Object?>>[]));

      expect(find.text(l10n(tester).providerNoRequestsTitle), findsOneWidget);
    });

    testWidgets('has the provider tabs, with Messages shared', (WidgetTester tester) async {
      final TestApp app = await openHome(tester);

      await tapAndSettle(tester, find.text(l10n(tester).navMessages));

      expect(location(app), AppRoutes.providerMessages);
      expect(find.byType(MessagesView), findsOneWidget);
    });
  });

  group('21a · pending', () {
    testWidgets('asks for the missing tax card and opens 08e', (WidgetTester tester) async {
      final TestApp app = await openHome(
        tester,
        home: providerHomeJson(state: 'pending', documents: <String>['pending', 'pending', 'missing']),
      );
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.providerFinishTitle), findsOneWidget);
      expect(find.text(strings.providerStepDocumentsCount(2, 3)), findsOneWidget);
      expect(find.text(strings.documentStateMissing), findsOneWidget);
      expect(isTappable(tester, strings.providerAddService), isFalse);

      await tapAndSettle(tester, button(strings.providerUploadTaxCard));

      expect(find.byType(DocumentsView), findsOneWidget);
      expect(location(app), AppRoutes.documents);
    });

    testWidgets('waits, with nothing to do, once everything is sent', (WidgetTester tester) async {
      await openHome(
        tester,
        home: providerHomeJson(state: 'pending', documents: <String>['pending', 'pending', 'pending']),
      );
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.providerReviewTitle), findsOneWidget);
      expect(button(strings.homeUploadDocuments), findsNothing);
    });
  });

  group('21b · rejected', () {
    testWidgets('names the refused document and opens 08d', (WidgetTester tester) async {
      final FakeDocumentsRepository documents = FakeDocumentsRepository()
        ..statuses[ProviderDocumentType.nationalId] = ProviderDocumentStatus.approved
        ..statuses[ProviderDocumentType.commercialRegister] = ProviderDocumentStatus.approved
        ..statuses[ProviderDocumentType.taxCard] = ProviderDocumentStatus.rejected;
      final TestApp app = await openHome(
        tester,
        home: providerHomeJson(state: 'rejected', documents: <String>['approved', 'approved', 'rejected']),
        documents: documents,
      );
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.providerRejectedTitle), findsOneWidget);
      expect(find.text(strings.providerRejectedOne(strings.documentPhraseTaxCard)), findsOneWidget);
      expect(find.text(strings.providerStepNotApproved), findsOneWidget);

      await tapAndSettle(tester, button(strings.providerResubmit));

      expect(find.byType(ResubmitDocumentsView), findsOneWidget);
      expect(location(app), AppRoutes.resubmitDocuments);
      expect(find.text(strings.resubmitTitle), findsOneWidget);
      expect(find.text(strings.resubmitUploadNew), findsOneWidget);
      // Nothing picked yet: nothing to send.
      expect(isTappable(tester, strings.providerResubmit), isFalse);

      await tapAndSettle(tester, button(strings.resubmitNotNow));
      expect(find.byType(ProviderHomeView), findsOneWidget);
    });
  });
}

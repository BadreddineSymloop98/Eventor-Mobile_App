import 'package:eventor/features/provider_services/view/service_form_view.dart';
import 'package:eventor/features/provider_services/view_model/service_form_view_model.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/fakes.dart';
import '../../support/provider_catalog_fakes.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

/// P7 → P9 → back to the field: the publish checklist is the riskiest path
/// of the form — it saves first, opens a sheet, then jumps to what is
/// missing in the other language.
void main() {
  Future<FakeProviderCatalogRepository> open(
    WidgetTester tester, {
    String? id,
    FakeProviderCatalogRepository? repository,
  }) async {
    final FakeProviderCatalogRepository catalog = repository ?? FakeProviderCatalogRepository();
    await pumpAppWidget(
      tester,
      ChangeNotifierProvider<ServiceFormViewModel>(
        create: (_) => ServiceFormViewModel(
          catalog: catalog,
          reference: FakeReferenceRepository(),
          serviceId: id,
        ),
        child: const ServiceFormView(),
      ),
    );
    await tester.pumpAndSettle();
    return catalog;
  }

  testWidgets('Publish on an empty P7 flags what a draft needs', (WidgetTester tester) async {
    final FakeProviderCatalogRepository catalog = await open(tester);
    final AppLocalizations strings = l10n(tester);

    await tapAndSettle(tester, find.text(strings.providerServicePublish));

    expect(find.text(strings.providerServiceFieldRequired), findsWidgets);
    expect(catalog.calls, isNot(contains('createService')));
  });

  testWidgets('P9 lists what is missing and jumps to the Arabic', (WidgetTester tester) async {
    await open(
      tester,
      id: 'svc-1',
      repository: FakeProviderCatalogRepository(
        serviceDetails: <String, Map<String, Object?>>{
          'svc-1': serviceDetailJson(
            status: 'draft',
            titleAr: '',
            descriptionAr: '',
            publishMissing: <String>['titleAr', 'descriptionAr'],
          ),
        },
      ),
    );
    final AppLocalizations strings = l10n(tester);
    expect(find.text(strings.providerServiceTitleLabel('en')), findsOneWidget);

    await tapAndSettle(tester, find.text(strings.providerServicePublish));

    expect(find.text(strings.providerServiceChecklistTitle), findsOneWidget);
    expect(find.text(strings.providerServiceCheckArabic), findsOneWidget);

    await tapAndSettle(tester, find.text(strings.providerServiceFixArabic));

    expect(find.text(strings.providerServiceChecklistTitle), findsNothing);
    expect(find.text(strings.providerServiceTitleLabel('ar')), findsOneWidget);
  });

  testWidgets('a published service offers Unpublish and Save changes', (WidgetTester tester) async {
    await open(tester, id: 'svc-1');
    final AppLocalizations strings = l10n(tester);

    expect(find.text(strings.providerServiceEditTitle), findsOneWidget);
    expect(find.text(strings.providerServiceUnpublish), findsOneWidget);
    expect(find.text(strings.providerServiceSaveChanges), findsOneWidget);
    expect(find.text(strings.providerServiceDeleteButton), findsOneWidget);
  });
}

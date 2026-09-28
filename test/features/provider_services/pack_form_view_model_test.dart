import 'package:eventor/core/catalog/models/pack.dart' show EventType;
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/provider_catalog/provider_catalog_repository.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/features/provider_services/view_model/catalog_outcomes.dart';
import 'package:eventor/features/provider_services/view_model/choose_services_view_model.dart';
import 'package:eventor/features/provider_services/view_model/pack_form_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/provider_catalog_fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  const Wilaya alger = Wilaya(code: 16, nameEn: 'Alger', nameAr: 'الجزائر');

  /// Three published services (200 000 + 45 000 + 120 000 = 365 000), a
  /// draft and a hidden one, and one that covers only Blida.
  FakeProviderCatalogRepository catalog() => FakeProviderCatalogRepository(
        serviceRows: <Map<String, Object?>>[
          serviceRowJson(id: 'svc-venue', basePrice: '200000.00'),
          serviceRowJson(id: 'svc-photo', basePrice: '45000.00'),
          serviceRowJson(id: 'svc-food', basePrice: '120000.00'),
          serviceRowJson(id: 'svc-draft', status: 'draft', visibleInApp: false),
          serviceRowJson(id: 'svc-hidden', status: 'hidden', visibleInApp: false),
          serviceRowJson(id: 'svc-blida', basePrice: '24000.00', wilayas: <int>[9]),
        ],
        packDetails: <String, Map<String, Object?>>{
          'pack-1': packDetailJson(serviceIds: <String>['svc-venue', 'svc-photo']),
        },
      );

  group('PackFormViewModel', () {
    Future<PackFormViewModel> build(FakeProviderCatalogRepository repository, {String? id}) async {
      final PackFormViewModel viewModel = PackFormViewModel(
        catalog: repository,
        reference: FakeReferenceRepository(),
        packId: id,
      );
      addTearDown(viewModel.dispose);
      await flushAsync();
      await flushAsync();
      return viewModel;
    }

    void fill(PackFormViewModel viewModel, {int price = 320000}) {
      viewModel
        ..setName('Essentiel Mariage')
        ..setServices(<String>['svc-venue', 'svc-photo', 'svc-food'])
        ..setPrice(price)
        ..setEventType(EventType.wedding)
        ..setWilaya(alger);
    }

    test('works out the sum and the saving live', () async {
      final PackFormViewModel viewModel = await build(catalog());
      fill(viewModel);

      expect(viewModel.sumCents, 36500000);
      expect(viewModel.savingsCents, 4500000);
      expect(viewModel.savingsPercent, 12);
      expect(viewModel.isPriceBelowSum, isTrue);

      viewModel.setPrice(365000);
      expect(viewModel.isPriceBelowSum, isFalse);
      expect(viewModel.savingsPercent, isNull);
    });

    test('flags an item that does not cover the wilaya', () async {
      final PackFormViewModel viewModel = await build(catalog());
      viewModel
        ..setServices(<String>['svc-venue', 'svc-blida'])
        ..setWilaya(alger);

      expect(
        viewModel.items.map((PackFormItem i) => i.coversWilaya),
        <bool>[true, false],
      );
    });

    test('a draft needs 2 to 6 services and the required fields', () async {
      final FakeProviderCatalogRepository repository = catalog();
      final PackFormViewModel viewModel = await build(repository);
      viewModel.setServices(<String>['svc-venue']);

      final PackSaveOutcome? outcome = await viewModel.save();

      expect(outcome, isA<PackSaveInvalid>());
      expect((outcome! as PackSaveInvalid).fields, containsAll(<PackField>[
        PackField.nameEn,
        PackField.services,
        PackField.price,
        PackField.eventType,
        PackField.wilaya,
      ]));
      expect(viewModel.problemOf(PackField.services), FieldProblem.outOfRange);
      expect(repository.calls, isNot(contains('createPack')));
    });

    test('creates a draft with everything the API needs', () async {
      final FakeProviderCatalogRepository repository = catalog();
      final PackFormViewModel viewModel = await build(repository);
      fill(viewModel);

      expect(await viewModel.save(), isA<PackSaveDone>());

      final Map<String, Object?> sent = repository.lastPackInput!.toJson();
      expect(sent['serviceIds'], <String>['svc-venue', 'svc-photo', 'svc-food']);
      expect(sent['price'], '320000.00');
      expect(sent['wilayaCode'], 16);
      expect(sent['eventType'], 'wedding');
      expect(viewModel.isNew, isFalse);
    });

    test('Publish saves, then opens P14 from the checklist — no publish call', () async {
      final FakeProviderCatalogRepository repository = catalog();
      final PackFormViewModel viewModel = await build(repository);
      fill(viewModel);

      final PublishOutcome<PackMissing>? outcome = await viewModel.publish();

      expect(outcome, isA<PublishChecklist<PackMissing>>());
      expect((outcome! as PublishChecklist<PackMissing>).missing, <PackMissing>[PackMissing.nameAr]);
      expect(repository.calls.where((String c) => c.startsWith('publishPack')), isEmpty);
    });

    test('edits send only what changed', () async {
      final FakeProviderCatalogRepository repository = catalog();
      final PackFormViewModel viewModel = await build(repository, id: 'pack-1');

      expect(viewModel.serviceIds, <String>['svc-venue', 'svc-photo']);
      viewModel.setLanguage(ContentLanguage.arabic);
      viewModel.setName('باقة جديدة');
      await viewModel.save();

      expect(repository.lastPackInput!.toJson().keys, <String>['nameAr']);
    });

    test('a pack refused by PACK_WILAYA_NOT_COVERED shows the wilaya row', () async {
      final FakeProviderCatalogRepository repository = catalog()
        ..failNext['publishPack'] = apiFailure(ApiErrorCode.packWilayaNotCovered);
      final PackFormViewModel viewModel = await build(repository, id: 'pack-1');

      final PublishOutcome<PackMissing>? outcome = await viewModel.publish();

      expect((outcome! as PublishChecklist<PackMissing>).missing, <PackMissing>[PackMissing.wilayaNotCovered]);
    });

    test('Photos on an unsaved pack saves it first', () async {
      final FakeProviderCatalogRepository repository = catalog();
      final PackFormViewModel viewModel = await build(repository);

      expect(await viewModel.openPhotos(), isA<PackPhotosNeedDraft>());
      fill(viewModel);
      final PackPhotosAccess? access = await viewModel.openPhotos();

      expect((access! as PackPhotosReady).packId, 'pack-new');
    });

    test('a refused delete names the bookings', () async {
      final FakeProviderCatalogRepository repository = catalog()
        ..failNext['deletePack'] = apiFailure(ApiErrorCode.packHasBookings, statusCode: 409);
      final PackFormViewModel viewModel = await build(repository, id: 'pack-1');

      final DeleteOutcome? outcome = await viewModel.delete();

      expect((outcome! as DeleteRefused).blockers.single.kind, DeleteBlockerKind.bookings);
    });
  });

  group('ChooseServicesViewModel (P11a)', () {
    Future<ChooseServicesViewModel> build({
      List<String> selected = const <String>[],
      int? wilayaCode = 16,
    }) async {
      final ChooseServicesViewModel viewModel = ChooseServicesViewModel(
        catalog: catalog(),
        reference: FakeReferenceRepository(),
        args: ChooseServicesArgs(selected: selected, wilayaCode: wilayaCode),
      );
      addTearDown(viewModel.dispose);
      await flushAsync();
      await flushAsync();
      return viewModel;
    }

    ProviderServiceSummary byId(ChooseServicesViewModel vm, String id) =>
        vm.services.firstWhere((ProviderServiceSummary s) => s.id == id);

    test('only published services covering the wilaya can be picked', () async {
      final ChooseServicesViewModel viewModel = await build();

      expect(viewModel.eligibilityOf(byId(viewModel, 'svc-venue')), PackEligibility.eligible);
      expect(viewModel.eligibilityOf(byId(viewModel, 'svc-draft')), PackEligibility.draft);
      expect(viewModel.eligibilityOf(byId(viewModel, 'svc-hidden')), PackEligibility.hidden);
      expect(viewModel.eligibilityOf(byId(viewModel, 'svc-blida')), PackEligibility.notCovering);
      expect(viewModel.wilaya?.nameEn, 'Alger');
      // Eligible first.
      expect(viewModel.services.first.id, 'svc-venue');
      expect(viewModel.toggle(byId(viewModel, 'svc-draft')), ChooseToggle.ineligible);
    });

    test('without a wilaya yet, coverage does not count', () async {
      final ChooseServicesViewModel viewModel = await build(wilayaCode: null);

      expect(viewModel.eligibilityOf(byId(viewModel, 'svc-blida')), PackEligibility.eligible);
    });

    test('Done needs at least 2', () async {
      final ChooseServicesViewModel viewModel = await build();

      viewModel.toggle(byId(viewModel, 'svc-venue'));
      expect(viewModel.canFinish, isFalse);
      viewModel.toggle(byId(viewModel, 'svc-photo'));
      expect(viewModel.canFinish, isTrue);
      expect(viewModel.selected, <String>['svc-venue', 'svc-photo']);
      expect(viewModel.sumCents, 24500000);
    });

    test('stops at 6', () async {
      final ChooseServicesViewModel viewModel = await build(
        selected: <String>['a', 'b', 'c', 'd', 'e', 'f'],
      );

      expect(viewModel.toggle(byId(viewModel, 'svc-venue')), ChooseToggle.full);
      expect(viewModel.count, 6);
    });

    test('a chosen service that no longer qualifies can still be taken out', () async {
      final ChooseServicesViewModel viewModel = await build(selected: <String>['svc-draft']);

      expect(viewModel.isSelected(byId(viewModel, 'svc-draft')), isTrue);
      expect(viewModel.toggle(byId(viewModel, 'svc-draft')), ChooseToggle.toggled);
      expect(viewModel.count, 0);
    });
  });
}

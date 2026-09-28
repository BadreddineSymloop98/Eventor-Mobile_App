import 'dart:async';

import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/provider_catalog/provider_catalog_repository.dart';
import 'package:eventor/features/provider_services/view_model/catalog_outcomes.dart';
import 'package:eventor/features/provider_services/view_model/provider_services_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/provider_catalog_fakes.dart';
import '../feature_test_helpers.dart';

/// Lets the load, then the background details, land.
Future<void> settle() async {
  for (int i = 0; i < 6; i++) {
    await flushAsync();
  }
}

void main() {
  FakeProviderCatalogRepository catalog() => FakeProviderCatalogRepository(
        serviceRows: <Map<String, Object?>>[
          serviceRowJson(),
          serviceRowJson(id: 'svc-draft', status: 'draft', visibleInApp: false),
          serviceRowJson(id: 'svc-closed', visibleInApp: false, wilayas: <int>[15]),
          serviceRowJson(id: 'svc-hidden', status: 'hidden', visibleInApp: false),
        ],
        serviceDetails: <String, Map<String, Object?>>{
          'svc-1': serviceDetailJson(),
          'svc-draft': serviceDetailJson(
            id: 'svc-draft',
            status: 'draft',
            titleAr: '',
            descriptionAr: '',
            publishMissing: <String>['titleAr', 'descriptionAr'],
            visibilityReasons: <String>['not_published'],
          ),
          'svc-closed': serviceDetailJson(
            id: 'svc-closed',
            visibleInApp: false,
            wilayas: <int>[15],
            closedWilayas: <int>{15},
            visibilityReasons: <String>['no_open_wilaya'],
          ),
          'svc-hidden': serviceDetailJson(
            id: 'svc-hidden',
            status: 'hidden',
            visibleInApp: false,
            hidden: <String, Object?>{
              'reason': 'misleading_content',
              'message': 'Wrong photos.',
              'allowResubmit': true,
              'hiddenBy': null,
              'hiddenAt': '2026-03-12T10:00:00.000Z',
            },
          ),
        },
        packRows: <Map<String, Object?>>[packRowJson()],
      );

  Future<ProviderServicesViewModel> build(
    FakeProviderCatalogRepository repository, {
    bool openPacks = false,
  }) async {
    final ProviderServicesViewModel viewModel =
        ProviderServicesViewModel(catalog: repository, openPacks: openPacks);
    addTearDown(viewModel.dispose);
    await settle();
    return viewModel;
  }

  ProviderServiceSummary byId(ProviderServicesViewModel vm, String id) =>
      vm.services.firstWhere((ProviderServiceSummary s) => s.id == id);

  test('is on the skeleton until the lists arrive', () {
    final FakeProviderCatalogRepository repository = catalog()..gate = Completer<void>();
    final ProviderServicesViewModel viewModel = ProviderServicesViewModel(catalog: repository);
    addTearDown(viewModel.dispose);

    expect(viewModel.isFirstLoad, isTrue);
    expect(viewModel.loadFailed, isFalse);
  });

  test('opens on the Packs chip when asked', () async {
    final ProviderServicesViewModel viewModel = await build(catalog(), openPacks: true);

    expect(viewModel.tab, CatalogTab.packs);
    expect(viewModel.packs, hasLength(1));
  });

  test('fetches the detail of every service that is not live, and only those', () async {
    final FakeProviderCatalogRepository repository = catalog();
    await build(repository);

    expect(repository.calls, containsAll(<String>['service:svc-draft', 'service:svc-closed', 'service:svc-hidden']));
    expect(repository.calls, isNot(contains('service:svc-1')));
  });

  test('explains each card that is not live (decision 4)', () async {
    final ProviderServicesViewModel viewModel = await build(catalog());

    expect(viewModel.noteFor(byId(viewModel, 'svc-1')), isNull);
    final ServiceNote? draft = viewModel.noteFor(byId(viewModel, 'svc-draft'));
    expect(draft, isA<MissingNote>());
    expect((draft! as MissingNote).missing, <ServiceMissing>[ServiceMissing.titleAr, ServiceMissing.descriptionAr]);
    final ServiceNote? closed = viewModel.noteFor(byId(viewModel, 'svc-closed'));
    expect(closed, isA<NotVisibleNote>());
    expect((closed! as NotVisibleNote).closedWilayas.single.code, 15);
    final ServiceNote? hidden = viewModel.noteFor(byId(viewModel, 'svc-hidden'));
    expect((hidden! as HiddenNote).info?.allowResubmit, isTrue);
    expect(viewModel.hiddenAt(byId(viewModel, 'svc-hidden')), isNotNull);
  });

  test('a failed background detail leaves the card without a note', () async {
    final FakeProviderCatalogRepository repository = catalog()
      ..failNext['service:svc-draft'] = const NetworkFailure();
    final ProviderServicesViewModel viewModel = await build(repository);

    expect(viewModel.noteFor(byId(viewModel, 'svc-draft')), isNull);
    expect(viewModel.loadFailed, isFalse);
  });

  test('reports a failed first load and retries', () async {
    final FakeProviderCatalogRepository repository = catalog()..failNext['services'] = const NetworkFailure();
    final ProviderServicesViewModel viewModel = await build(repository);

    expect(viewModel.loadFailed, isTrue);
    await viewModel.load();
    await settle();
    expect(viewModel.loadFailed, isFalse);
    expect(viewModel.services, hasLength(4));
  });

  test('a known checklist opens P9 without calling publish', () async {
    final FakeProviderCatalogRepository repository = catalog();
    final ProviderServicesViewModel viewModel = await build(repository);

    final PublishOutcome<ServiceMissing>? outcome =
        await viewModel.publishService(byId(viewModel, 'svc-draft'));

    expect(outcome, isA<PublishChecklist<ServiceMissing>>());
    expect(repository.calls, isNot(contains('publishService:svc-draft')));
  });

  test('publishes a ready draft and reloads the list', () async {
    final FakeProviderCatalogRepository repository = catalog();
    repository.serviceDetails['svc-draft']!['publishMissing'] = <String>[];
    final ProviderServicesViewModel viewModel = await build(repository);
    repository.calls.clear();

    final PublishOutcome<ServiceMissing>? outcome =
        await viewModel.publishService(byId(viewModel, 'svc-draft'));

    expect(outcome, isA<PublishDone<ServiceMissing>>());
    expect(repository.calls, containsAllInOrder(<String>['publishService:svc-draft', 'services']));
    expect(byId(viewModel, 'svc-draft').isPublished, isTrue);
  });

  test('says when the profile is still under review', () async {
    final FakeProviderCatalogRepository repository = catalog()
      ..failNext['publishService'] = apiFailure(ApiErrorCode.providerNotVerified);
    repository.serviceDetails['svc-draft']!['publishMissing'] = <String>[];
    final ProviderServicesViewModel viewModel = await build(repository);

    expect(
      await viewModel.publishService(byId(viewModel, 'svc-draft')),
      isA<PublishNotVerified<ServiceMissing>>(),
    );
  });

  test('unpublishes and reloads', () async {
    final FakeProviderCatalogRepository repository = catalog();
    final ProviderServicesViewModel viewModel = await build(repository);

    final Failure? failure = await viewModel.unpublishService(byId(viewModel, 'svc-1'));

    expect(failure, isNull);
    expect(byId(viewModel, 'svc-1').isPublished, isFalse);
    expect(viewModel.busyId, isNull);
  });

  test('a pack needs two published services (P10a)', () async {
    final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository(
      serviceRows: <Map<String, Object?>>[
        serviceRowJson(),
        serviceRowJson(id: 'svc-2', status: 'draft', visibleInApp: false),
      ],
    );
    final ProviderServicesViewModel viewModel = await build(repository, openPacks: true);

    expect(viewModel.isEmpty, isTrue);
    expect(viewModel.publishedServicesCount, 1);
    expect(viewModel.canBuildPack, isFalse);
  });

  test('a pack refusal lists what the server says is missing', () async {
    final FakeProviderCatalogRepository repository = catalog();
    repository.packDetails['pack-1'] =
        packDetailJson(publishMissing: <String>['nameAr', 'priceNotBelowSum']);
    final ProviderServicesViewModel viewModel = await build(repository, openPacks: true);

    final PublishOutcome<PackMissing>? outcome = await viewModel.publishPack(viewModel.packs.single);

    expect(outcome, isA<PublishChecklist<PackMissing>>());
    expect(
      (outcome! as PublishChecklist<PackMissing>).missing,
      <PackMissing>[PackMissing.nameAr, PackMissing.priceNotBelowSum],
    );
  });

  test('ignores a second tap while one card is busy', () async {
    final FakeProviderCatalogRepository repository = catalog();
    final ProviderServicesViewModel viewModel = await build(repository);
    repository.gate = Completer<void>();

    final Future<Failure?> first = viewModel.unpublishService(byId(viewModel, 'svc-1'));
    final Failure? second = await viewModel.unpublishService(byId(viewModel, 'svc-1'));
    expect(viewModel.busyId, 'svc-1');
    repository.gate!.complete();
    await first;

    expect(second, isNull);
    expect(repository.calls.where((String c) => c.startsWith('unpublishService')), hasLength(1));
  });
}

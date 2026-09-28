import 'package:eventor/core/catalog/models/price_type.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/provider_catalog/provider_catalog_repository.dart';
import 'package:eventor/features/provider_services/view_model/catalog_outcomes.dart';
import 'package:eventor/features/provider_services/view_model/service_form_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/provider_catalog_fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  const ServiceCategory photography =
      ServiceCategory(id: 'cat-photo', nameEn: 'Photography', nameAr: 'التصوير');
  const Wilaya alger = Wilaya(code: 16, nameEn: 'Alger', nameAr: 'الجزائر');

  Future<ServiceFormViewModel> build(
    FakeProviderCatalogRepository repository, {
    String? id,
  }) async {
    final ServiceFormViewModel viewModel = ServiceFormViewModel(
      catalog: repository,
      reference: FakeReferenceRepository(),
      serviceId: id,
    );
    addTearDown(viewModel.dispose);
    await flushAsync();
    return viewModel;
  }

  /// The four things a draft needs.
  void fillDraft(ServiceFormViewModel viewModel) {
    viewModel
      ..setCategory(photography)
      ..setTitle('Engagement session')
      ..setBasePrice(34000)
      ..setPriceType(PriceType.perEvent);
  }

  group('a new service (P7)', () {
    test('starts clean, with one event a day', () async {
      final ServiceFormViewModel viewModel = await build(FakeProviderCatalogRepository());

      expect(viewModel.isNew, isTrue);
      expect(viewModel.isFirstLoad, isFalse);
      expect(viewModel.isDirty, isFalse);
      expect(viewModel.maxEventsPerDay, 1);
    });

    test('will not save a draft without its four required fields', () async {
      final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository();
      final ServiceFormViewModel viewModel = await build(repository);

      final SaveOutcome? outcome = await viewModel.save();

      expect(outcome, isA<SaveInvalid>());
      expect((outcome! as SaveInvalid).fields, <ServiceField>[
        ServiceField.category,
        ServiceField.titleEn,
        ServiceField.basePrice,
        ServiceField.priceType,
      ]);
      expect(viewModel.problemOf(ServiceField.titleEn), FieldProblem.required);
      expect(repository.calls, isNot(contains('createService')));
    });

    test('keeps each language apart', () async {
      final ServiceFormViewModel viewModel = await build(FakeProviderCatalogRepository());

      viewModel.setTitle('Drone footage');
      viewModel.setLanguage(ContentLanguage.arabic);
      viewModel.setTitle('تصوير بالدرون');

      expect(viewModel.titleEn, 'Drone footage');
      expect(viewModel.titleAr, 'تصوير بالدرون');
      expect(viewModel.title, 'تصوير بالدرون');
      expect(viewModel.textGaps, <ServiceMissing>[ServiceMissing.descriptionEn, ServiceMissing.descriptionAr]);
    });

    test('saves a draft, then becomes P7a', () async {
      final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository();
      final ServiceFormViewModel viewModel = await build(repository);
      fillDraft(viewModel);

      final SaveOutcome? outcome = await viewModel.save();

      expect(outcome, isA<SaveDone>());
      expect((outcome! as SaveDone).created, isTrue);
      expect(viewModel.isNew, isFalse);
      expect(viewModel.isEditing, isTrue);
      expect(viewModel.isDirty, isFalse);
      final Map<String, Object?> sent = repository.lastServiceInput!.toJson();
      expect(sent['basePrice'], '34000.00');
      expect(sent['priceType'], 'per_event');
      expect(sent.containsKey('titleAr'), isFalse);
    });

    test('Publish saves first, then opens P9 with what is missing — no publish call', () async {
      final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository();
      final ServiceFormViewModel viewModel = await build(repository);
      fillDraft(viewModel);

      final PublishOutcome<ServiceMissing>? outcome = await viewModel.publish();

      expect(outcome, isA<PublishChecklist<ServiceMissing>>());
      expect(
        (outcome! as PublishChecklist<ServiceMissing>).missing,
        containsAll(<ServiceMissing>[ServiceMissing.titleAr, ServiceMissing.photos]),
      );
      expect(repository.calls, contains('createService'));
      expect(repository.calls.where((String c) => c.startsWith('publishService')), isEmpty);
    });

    test('Publish on an unsavable form flags the fields', () async {
      final ServiceFormViewModel viewModel = await build(FakeProviderCatalogRepository());

      expect(await viewModel.publish(), isA<PublishInvalid<ServiceMissing>>());
      expect(viewModel.problemOf(ServiceField.category), FieldProblem.required);
    });

    test('Photos on an unsaved service saves the draft first (decision 5)', () async {
      final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository();
      final ServiceFormViewModel viewModel = await build(repository);

      final PhotosAccess? refused = await viewModel.openPhotos();
      expect(refused, isA<PhotosNeedDraft>());
      expect(repository.calls, isNot(contains('createService')));

      fillDraft(viewModel);
      final PhotosAccess? access = await viewModel.openPhotos();
      expect(access, isA<PhotosReady>());
      expect((access! as PhotosReady).serviceId, 'svc-new');
      expect(viewModel.isNew, isFalse);
    });

    test('puts the server’s field errors on the fields', () async {
      final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository()
        ..failNext['createService'] = const ApiFailure(
          statusCode: 400,
          code: ApiErrorCode.validationFailed,
          message: 'Some fields are invalid.',
          fieldErrors: <FieldError>[
            FieldError(field: 'titleEn', code: 'MAX_LENGTH', message: 'Too long'),
            FieldError(field: 'facts.0.label_ar', code: 'IS_NOT_EMPTY', message: 'Needed'),
          ],
        );
      final ServiceFormViewModel viewModel = await build(repository);
      fillDraft(viewModel);

      expect(await viewModel.save(), isA<SaveFailed>());
      expect(viewModel.serverErrorOf(ServiceField.titleEn), 'Too long');
      expect(viewModel.serverErrorOf(ServiceField.facts), 'Needed');

      viewModel.setTitle('Shorter');
      expect(viewModel.serverErrorOf(ServiceField.titleEn), isNull);
    });

    test('a closed wilaya is flagged on the wilayas', () async {
      final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository()
        ..failNext['createService'] = apiFailure(ApiErrorCode.wilayaClosed, message: 'Closed: Tizi Ouzou.');
      final ServiceFormViewModel viewModel = await build(repository);
      fillDraft(viewModel);
      viewModel.setWilayas(<Wilaya>[alger]);

      await viewModel.save();

      expect(viewModel.serverErrorOf(ServiceField.wilayas), 'Closed: Tizi Ouzou.');
    });

    test('checks the capacity bounds', () async {
      final ServiceFormViewModel viewModel = await build(FakeProviderCatalogRepository());
      fillDraft(viewModel);
      viewModel.setMaxEventsPerDay(21);

      final SaveOutcome? outcome = await viewModel.save();

      expect((outcome! as SaveInvalid).fields, <ServiceField>[ServiceField.maxEventsPerDay]);
      expect(viewModel.problemOf(ServiceField.maxEventsPerDay), FieldProblem.outOfRange);
    });
  });

  group('an existing service (P7a)', () {
    test('loads its detail into the form', () async {
      final ServiceFormViewModel viewModel =
          await build(FakeProviderCatalogRepository(), id: 'svc-1');

      expect(viewModel.isFirstLoad, isFalse);
      expect(viewModel.titleEn, 'Wedding photo & video coverage');
      expect(viewModel.basePrice, 45000);
      expect(viewModel.priceType, PriceType.perDay);
      expect(viewModel.isPublished, isTrue);
      expect(viewModel.photosCount, 2);
      expect(viewModel.isDirty, isFalse);
    });

    test('a missing service is gone, not an error to retry', () async {
      final ServiceFormViewModel viewModel =
          await build(FakeProviderCatalogRepository(), id: 'nope');

      expect(viewModel.loadFailed, isTrue);
      expect(viewModel.isGone, isTrue);
    });

    test('sends only what changed', () async {
      final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository();
      final ServiceFormViewModel viewModel = await build(repository, id: 'svc-1');

      viewModel
        ..setBasePrice(50000)
        ..putFact(const ServiceFact(labelEn: 'Team', labelAr: 'الفريق', valueEn: '2', valueAr: '2'));
      expect(viewModel.isDirty, isTrue);
      await viewModel.save();

      expect(repository.lastServiceInput!.toJson().keys, unorderedEquals(<String>['basePrice', 'facts']));
      expect(viewModel.isDirty, isFalse);
    });

    test('clearing the guest cap sends null', () async {
      final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository(
        serviceDetails: <String, Map<String, Object?>>{'svc-1': serviceDetailJson(maxGuests: 400)},
      );
      final ServiceFormViewModel viewModel = await build(repository, id: 'svc-1');

      viewModel.setMaxGuests(null);
      await viewModel.save();

      final Map<String, Object?> sent = repository.lastServiceInput!.toJson();
      expect(sent.containsKey('maxGuests'), isTrue);
      expect(sent['maxGuests'], isNull);
    });

    test('publishes a complete draft', () async {
      final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository(
        serviceDetails: <String, Map<String, Object?>>{'svc-1': serviceDetailJson(status: 'draft')},
      );
      final ServiceFormViewModel viewModel = await build(repository, id: 'svc-1');

      expect(await viewModel.publish(), isA<PublishDone<ServiceMissing>>());
      expect(viewModel.isPublished, isTrue);
    });

    test('says when publishing waits for the profile review', () async {
      final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository(
        serviceDetails: <String, Map<String, Object?>>{'svc-1': serviceDetailJson(status: 'draft')},
      )..failNext['publishService'] = apiFailure(ApiErrorCode.providerNotVerified);
      final ServiceFormViewModel viewModel = await build(repository, id: 'svc-1');

      expect(await viewModel.publish(), isA<PublishNotVerified<ServiceMissing>>());
    });

    test('unpublishes, keeping what was typed', () async {
      final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository();
      final ServiceFormViewModel viewModel = await build(repository, id: 'svc-1');
      viewModel.setTitle('New title');

      expect(await viewModel.unpublish(), isNull);
      expect(viewModel.isPublished, isFalse);
      expect(viewModel.titleEn, 'New title');
      expect(viewModel.isDirty, isTrue);
    });

    test('a refused delete names the blocker and its count (P7b)', () async {
      final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository()
        ..failNext['deleteService'] = apiFailure(
          ApiErrorCode.serviceHasBookings,
          statusCode: 409,
          message: 'This service has 2 accepted upcoming bookings.',
        );
      final ServiceFormViewModel viewModel = await build(repository, id: 'svc-1');

      final DeleteOutcome? outcome = await viewModel.delete();

      expect(outcome, isA<DeleteRefused>());
      final DeleteBlocker blocker = (outcome! as DeleteRefused).blockers.single;
      expect(blocker.kind, DeleteBlockerKind.bookings);
      expect(blocker.count, 2);
    });

    test('deletes', () async {
      final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository();
      final ServiceFormViewModel viewModel = await build(repository, id: 'svc-1');

      expect(await viewModel.delete(), isA<DeleteDone>());
      expect(repository.serviceDetails.containsKey('svc-1'), isFalse);
    });

    test('back from P8 takes the new gallery and keeps the edits', () async {
      final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository();
      final ServiceFormViewModel viewModel = await build(repository, id: 'svc-1');
      viewModel.setTitle('Edited');
      repository.serviceDetails['svc-1']!['photos'] = <Object?>[catalogPhotoJson('only')];

      await viewModel.reloadPhotos();

      expect(viewModel.photosCount, 1);
      expect(viewModel.titleEn, 'Edited');
    });

    test('a P9 fix asked for from the list is handed over once', () async {
      final ServiceFormViewModel viewModel = ServiceFormViewModel(
        catalog: FakeProviderCatalogRepository(),
        reference: FakeReferenceRepository(),
        serviceId: 'svc-1',
        fix: ServiceChecklistItem.arabicText,
      );
      addTearDown(viewModel.dispose);

      expect(viewModel.takeFix(), ServiceChecklistItem.arabicText);
      expect(viewModel.takeFix(), isNull);
    });
  });
}

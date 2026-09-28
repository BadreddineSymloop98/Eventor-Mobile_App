import 'dart:typed_data';

import 'package:eventor/core/catalog/models/pack.dart' show EventType;
import 'package:eventor/core/catalog/models/price_type.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/provider_catalog/provider_catalog_repository.dart';
import 'package:eventor/mock/mock_backend.dart';
import 'package:eventor/mock/mock_catalog.dart';
import 'package:eventor/mock/mock_catalog_data.dart';
import 'package:eventor/mock/mock_provider_catalog.dart';
import 'package:eventor/mock/mock_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final DateTime today = DateTime(2026, 9, 24, 10);
  const String grandeSalle = 'f491ca64-3892-4191-b146-e557b441374d';
  const String menu = '6252a3b3-cd93-4126-ad2a-2010a598aaa8';
  const String decor = 'b15c4ecc-6ada-4da7-85b2-684aeefaa4fa';
  const String essentiel = '309d67dd-6c33-4dc5-84f9-90ff00884bb3';

  late MockBackend backend;
  late MockAuthRepository auth;
  late MockProviderCatalogRepository catalog;
  final Set<String> servicesWithBookings = <String>{};

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    backend = await MockBackend.load(
      prefs: await SharedPreferences.getInstance(),
      latency: Duration.zero,
      now: () => today,
    );
    auth = MockAuthRepository(backend);
    servicesWithBookings.clear();
    catalog = MockProviderCatalogRepository(
      backend,
      languageCode: () => 'en',
      hasUpcomingBookings: servicesWithBookings.contains,
    );
  });

  Future<void> signIn(String email) =>
      auth.login(email: email, password: MockBackend.seedPassword);

  Future<void> expectCode(Future<Object?> call, String code) => expectLater(
        call,
        throwsA(isA<ApiFailure>().having((ApiFailure f) => f.code, 'code', code)),
      );

  PickedImage image() => PickedImage(name: 'a.jpg', bytes: Uint8List(64), extension: 'jpg');

  /// A draft with everything the checklist asks for but photos.
  const ServiceInput complete = ServiceInput(
    categoryId: '7d3855dd-4bd3-430a-9ffc-09d4f269eb4a',
    titleEn: 'Engagement session',
    titleAr: 'جلسة خطوبة',
    descriptionEn: 'Two hours in a garden.',
    descriptionAr: 'ساعتان في حديقة.',
    basePrice: '34000.00',
    priceType: PriceType.perEvent,
    wilayaCodes: <int>[16],
  );

  group('the verified provider', () {
    setUp(() => signIn('verified.provider@eventor.test'));

    test('starts from the const catalog plus one card of every other state', () async {
      final List<ProviderServiceSummary> services = await catalog.services();

      final Set<String> lookupIds = <String>{
        for (final Map<String, Object?> row
            in MockCatalogLookups(backend, languageCode: () => 'en').providerServices('Salle Yasmine'))
          row['id']! as String,
      };
      expect(services.map((ProviderServiceSummary s) => s.id), containsAll(lookupIds));
      expect(services.where((ProviderServiceSummary s) => s.isHidden), hasLength(1));
      expect(services.where((ProviderServiceSummary s) => s.status == ProviderServiceStatus.draft), hasLength(1));
      expect(services.where((ProviderServiceSummary s) => s.isPublished && !s.visibleInApp), hasLength(1));
      expect(catalog.serviceIdsOf(backend.accountByEmail('verified.provider@eventor.test')!),
          containsAll(lookupIds));
    });

    test('the draft misses its Arabic; the tent sits in a closed wilaya', () async {
      final ProviderServiceDetail draft = await catalog.service('mock-service-henna-decor');
      final ProviderServiceDetail tent = await catalog.service('mock-service-reception-tent');
      final ProviderServiceDetail hidden = await catalog.service('mock-service-garden-terrace');

      expect(draft.publishMissing, <ServiceMissing>[ServiceMissing.titleAr, ServiceMissing.descriptionAr]);
      expect(tent.visibilityReasons, <ServiceVisibilityReason>[ServiceVisibilityReason.noOpenWilaya]);
      expect(tent.closedWilayas.single.code, 15);
      expect(hidden.hidden?.allowResubmit, isTrue);
    });

    test('has the Essentiel Mariage pack, published and below its sum', () async {
      final List<ProviderPackSummary> packs = await catalog.packs();
      final ProviderPackSummary pack =
          packs.firstWhere((ProviderPackSummary p) => p.id == essentiel);

      expect(pack.isPublished, isTrue);
      expect(pack.needsAttention, isFalse);
      expect(pack.savings, '66800.00');
    });

    test('a new service needs its four fields, and starts as a draft', () async {
      await expectCode(
        catalog.createService(const ServiceInput(titleEn: 'x')),
        ApiErrorCode.validationFailed,
      );

      final ProviderServiceDetail created = await catalog.createService(complete);

      expect(created.isDraft, isTrue);
      expect(created.publishMissing, <ServiceMissing>[ServiceMissing.photos]);
      expect((await catalog.services()).first.id, created.id);
    });

    test('publish follows the checklist', () async {
      final ProviderServiceDetail created = await catalog.createService(complete);

      await expectLater(
        catalog.publishService(created.id),
        throwsA(isA<ApiFailure>()
            .having((ApiFailure f) => f.code, 'code', ApiErrorCode.servicePublishInvalid)
            .having((ApiFailure f) => f.details?['missing'], 'missing', <String>['photos'])),
      );
      await catalog.addServicePhoto(created.id, image());
      final ProviderServiceDetail live = await catalog.publishService(created.id);

      expect(live.isPublished, isTrue);
      expect(live.visibleInApp, isTrue);
      await expectCode(catalog.publishService(created.id), ApiErrorCode.serviceInvalidTransition);
      expect((await catalog.unpublishService(created.id)).isDraft, isTrue);
    });

    test('refuses a closed wilaya', () async {
      await expectCode(
        catalog.updateService(grandeSalle, const ServiceInput(wilayaCodes: <int>[15])),
        ApiErrorCode.wilayaClosed,
      );
    });

    test('updates only what it is sent', () async {
      final ProviderServiceDetail before = await catalog.service(grandeSalle);
      final ProviderServiceDetail after =
          await catalog.updateService(grandeSalle, const ServiceInput(basePrice: '260000'));

      expect(after.basePrice, '260000.00');
      expect(after.titleEn, before.titleEn);
      expect(after.facts, before.facts);
    });

    test('refuses to delete a service with bookings ahead, or in a pack', () async {
      servicesWithBookings.add(decor);
      await expectCode(catalog.deleteService(decor), ApiErrorCode.serviceHasBookings);

      servicesWithBookings.clear();
      await expectCode(catalog.deleteService(grandeSalle), ApiErrorCode.serviceInPacks);

      await catalog.deleteService('mock-service-garden-terrace');
      await expectCode(catalog.service('mock-service-garden-terrace'), ApiErrorCode.serviceNotFound);
    });

    test('photos: the order sets the cover, and a bad order is refused', () async {
      final List<CatalogPhoto> photos = (await catalog.service(grandeSalle)).photos;
      final List<String> reversed = <String>[for (final CatalogPhoto p in photos.reversed) p.id];

      final List<CatalogPhoto> ordered = await catalog.orderServicePhotos(grandeSalle, reversed);

      expect(ordered.first.id, reversed.first);
      expect(ordered.first.isCover, isTrue);
      await expectCode(
        catalog.orderServicePhotos(grandeSalle, reversed.take(1).toList()),
        ApiErrorCode.photoOrderInvalid,
      );
      await expectCode(catalog.removeServicePhoto(grandeSalle, 'nope'), ApiErrorCode.photoNotFound);
    });

    test('photos: the last one of a published service stays', () async {
      const String tent = 'mock-service-reception-tent';
      final CatalogPhoto only = (await catalog.service(tent)).photos.single;

      await expectCode(catalog.removeServicePhoto(tent, only.id), ApiErrorCode.servicePublishInvalid);
    });

    test('photos: stops at the config limit', () async {
      final ProviderServiceDetail created = await catalog.createService(complete);
      for (int i = 0; i < 12; i++) {
        await catalog.addServicePhoto(created.id, image());
      }

      await expectCode(catalog.addServicePhoto(created.id, image()), ApiErrorCode.photoLimitReached);
      expect((await catalog.service(created.id)).photos, hasLength(12));
    });

    test('photos: refuses a type the server does not take', () async {
      await expectCode(
        catalog.addServicePhoto(
          grandeSalle,
          PickedImage(name: 'a.gif', bytes: Uint8List(8), extension: 'gif'),
        ),
        ApiErrorCode.fileTypeNotAllowed,
      );
    });

    test('a pack takes 2 to 6 of the provider’s own services', () async {
      PackInput pack(List<String> ids) => PackInput(
            nameEn: 'Test pack',
            eventType: EventType.wedding,
            wilayaCode: 16,
            price: '60000.00',
            serviceIds: ids,
          );

      await expectCode(catalog.createPack(pack(<String>[decor])), ApiErrorCode.validationFailed);
      await expectCode(catalog.createPack(pack(<String>[decor, 'ghost'])), ApiErrorCode.packServiceNotFound);
      final String elsewhere = mockCatalogServices.firstWhere(
        (Map<String, Object?> s) => s['providerId'] != MockProviderCatalogRepository.catalogProviderId,
      )['id']! as String;
      await expectCode(catalog.createPack(pack(<String>[decor, elsewhere])), ApiErrorCode.packServiceOtherProvider);

      final ProviderPackDetail created = await catalog.createPack(pack(<String>[decor, menu]));
      expect(created.status, PackStatus.draft);
      expect(created.sumOfItems, '67800.00');
    });

    test('pack publish needs a price below the sum and the Arabic name', () async {
      final ProviderPackDetail draft = await catalog.pack('mock-pack-decor-menu');
      expect(draft.publishMissing, <PackMissing>[PackMissing.nameAr, PackMissing.priceNotBelowSum]);

      await expectCode(catalog.publishPack(draft.id), ApiErrorCode.packPublishInvalid);
      await catalog.updatePack(draft.id, const PackInput(nameAr: 'ديكور وقائمة', price: '60000.00'));
      final ProviderPackDetail live = await catalog.publishPack(draft.id);

      expect(live.isPublished, isTrue);
      expect((await catalog.unpublishPack(draft.id)).status, PackStatus.unpublished);
    });

    test('a pack needs attention once an item is unpublished', () async {
      await catalog.unpublishService(menu);
      final ProviderPackDetail pack = await catalog.pack(essentiel);

      expect(pack.needsAttention, isTrue);
      expect(pack.attention.single.serviceId, menu);
      expect(pack.visibleInApp, isFalse);
    });

    test('a pack wilaya the items do not cover', () async {
      final ProviderPackDetail draft = await catalog.createPack(const PackInput(
        nameEn: 'Blida pack',
        nameAr: 'باقة البليدة',
        eventType: EventType.wedding,
        wilayaCode: 9,
        price: '1000.00',
        serviceIds: <String>[decor, 'mock-service-garden-terrace'],
      ));

      expect(draft.publishMissing, contains(PackMissing.wilayaNotCovered));
      expect(draft.publishMissing, contains(PackMissing.unpublishedItems));
    });
  });

  test('the provider under review starts empty and cannot publish', () async {
    await signIn('provider@eventor.test');
    expect(await catalog.services(), isEmpty);
    expect(await catalog.packs(), isEmpty);

    final ProviderServiceDetail created = await catalog.createService(complete);
    await catalog.addServicePhoto(created.id, image());

    await expectCode(catalog.publishService(created.id), ApiErrorCode.providerNotVerified);
  });

  test('a client is not a provider', () async {
    await signIn('client@eventor.test');

    await expectCode(catalog.services(), ApiErrorCode.notAProvider);
  });
}

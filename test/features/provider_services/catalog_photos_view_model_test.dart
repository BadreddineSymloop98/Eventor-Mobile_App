import 'dart:async';

import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/provider_catalog/provider_catalog_repository.dart';
import 'package:eventor/features/provider_services/view_model/catalog_photos_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/provider_catalog_fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  Future<CatalogPhotosViewModel> build(
    FakeProviderCatalogRepository repository, {
    int limit = 12,
    PhotoOwner owner = PhotoOwner.service,
    String id = 'svc-1',
  }) async {
    final CatalogPhotosViewModel viewModel = CatalogPhotosViewModel(
      catalog: repository,
      owner: owner,
      ownerId: id,
      limit: limit,
      maxMb: 1,
      types: const <String>['jpeg', 'png', 'webp', 'heic'],
      processingPoll: const Duration(milliseconds: 1),
    );
    addTearDown(viewModel.dispose);
    await flushAsync();
    await flushAsync();
    return viewModel;
  }

  List<String> ids(CatalogPhotosViewModel viewModel) =>
      <String>[for (final CatalogPhoto p in viewModel.photos) p.id];

  test('is on the skeleton until the gallery arrives', () {
    final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository()
      ..gate = Completer<void>();
    final CatalogPhotosViewModel viewModel = CatalogPhotosViewModel(
      catalog: repository,
      owner: PhotoOwner.service,
      ownerId: 'svc-1',
      limit: 12,
      maxMb: 10,
      types: const <String>['jpeg'],
    );
    addTearDown(viewModel.dispose);

    expect(viewModel.isFirstLoad, isTrue);
  });

  test('loads the gallery, cover first', () async {
    final CatalogPhotosViewModel viewModel = await build(FakeProviderCatalogRepository());

    expect(ids(viewModel), <String>['svc-1-p1', 'svc-1-p2']);
    expect(viewModel.photos.first.isCover, isTrue);
    expect(viewModel.count, 2);
    expect(viewModel.isFull, isFalse);
  });

  test('a missing owner is gone', () async {
    final CatalogPhotosViewModel viewModel = await build(FakeProviderCatalogRepository(), id: 'nope');

    expect(viewModel.loadFailed, isTrue);
    expect(viewModel.isGone, isTrue);
  });

  test('adds a photo and takes the gallery the server answers', () async {
    final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository();
    final CatalogPhotosViewModel viewModel = await build(repository);

    expect(viewModel.add(testImage()), isNull);
    expect(viewModel.uploads, hasLength(1));
    await flushAsync();

    expect(viewModel.uploads, isEmpty);
    expect(viewModel.photos, hasLength(3));
    expect(repository.calls, contains('addServicePhoto:svc-1'));
  });

  test('refuses a photo too large or of the wrong type before sending', () async {
    final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository();
    final CatalogPhotosViewModel viewModel = await build(repository);

    expect(viewModel.add(testImage(size: 2 * 1024 * 1024)), AddPhotoProblem.tooLarge);
    expect(viewModel.add(testImage(extension: 'gif')), AddPhotoProblem.wrongType);
    expect(repository.calls.where((String c) => c.startsWith('addServicePhoto')), isEmpty);
  });

  test('is full at the config limit', () async {
    final CatalogPhotosViewModel viewModel = await build(FakeProviderCatalogRepository(), limit: 2);

    expect(viewModel.isFull, isTrue);
    expect(viewModel.add(testImage()), AddPhotoProblem.limitReached);
  });

  test('the server’s PHOTO_LIMIT_REACHED fills it too', () async {
    final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository()
      ..failNext['addServicePhoto'] = apiFailure(ApiErrorCode.photoLimitReached);
    final CatalogPhotosViewModel viewModel = await build(repository);

    viewModel.add(testImage());
    await flushAsync();

    expect(viewModel.isFull, isTrue);
    expect(viewModel.uploads, isEmpty);
  });

  test('keeps a failed upload to retry or remove', () async {
    final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository()
      ..failNext['addServicePhoto'] = const NetworkFailure();
    final CatalogPhotosViewModel viewModel = await build(repository);

    viewModel.add(testImage());
    await flushAsync();
    final PhotoUpload failed = viewModel.uploads.single;
    expect(failed.hasFailed, isTrue);
    expect(viewModel.count, 2);

    viewModel.retry(failed);
    await flushAsync();

    expect(viewModel.uploads, isEmpty);
    expect(viewModel.photos, hasLength(3));
  });

  test('makes a photo the cover by sending the whole new order', () async {
    final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository();
    final CatalogPhotosViewModel viewModel = await build(repository);

    final Failure? failure = await viewModel.makeCover(viewModel.photos.last);

    expect(failure, isNull);
    expect(repository.lastOrder, <String>['svc-1-p2', 'svc-1-p1']);
    expect(ids(viewModel).first, 'svc-1-p2');
    expect(viewModel.photos.first.isCover, isTrue);
  });

  test('puts the order back when the server refuses it', () async {
    final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository()
      ..failNext['orderServicePhotos'] = const NetworkFailure();
    final CatalogPhotosViewModel viewModel = await build(repository);

    final Failure? failure = await viewModel.moveLater(viewModel.photos.first);

    expect(failure, isA<NetworkFailure>());
    expect(ids(viewModel), <String>['svc-1-p1', 'svc-1-p2']);
  });

  test('moves only where there is room', () async {
    final CatalogPhotosViewModel viewModel = await build(FakeProviderCatalogRepository());

    expect(viewModel.canMoveEarlier(viewModel.photos.first), isFalse);
    expect(viewModel.canMoveLater(viewModel.photos.first), isTrue);
    expect(viewModel.canMoveLater(viewModel.photos.last), isFalse);
  });

  test('removes a photo', () async {
    final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository();
    final CatalogPhotosViewModel viewModel = await build(repository);

    expect(await viewModel.remove(viewModel.photos.first), isNull);
    expect(ids(viewModel), <String>['svc-1-p2']);
  });

  test('explains the last photo of a published service', () async {
    final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository()
      ..failNext['removeServicePhoto'] = apiFailure(ApiErrorCode.servicePublishInvalid);
    final CatalogPhotosViewModel viewModel = await build(repository);

    final Failure? failure = await viewModel.remove(viewModel.photos.first);

    expect(failure, isNotNull);
    expect(CatalogPhotosViewModel.isLastPhotoRefusal(failure!), isTrue);
    expect(viewModel.photos, hasLength(2));
  });

  test('a pack gallery goes through the pack routes', () async {
    final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository(
      packDetails: <String, Map<String, Object?>>{'pack-1': packDetailJson()},
    );
    final CatalogPhotosViewModel viewModel =
        await build(repository, owner: PhotoOwner.pack, id: 'pack-1', limit: 6);

    viewModel.add(testImage());
    await flushAsync();

    expect(repository.calls, contains('addPackPhoto:pack-1'));
    expect(viewModel.photos, hasLength(1));
  });

  test('looks again at a photo still processing', () async {
    final FakeProviderCatalogRepository repository = FakeProviderCatalogRepository(
      serviceDetails: <String, Map<String, Object?>>{
        'svc-1': serviceDetailJson(
          photos: <Map<String, Object?>>[catalogPhotoJson('p1', status: 'pending')],
        ),
      },
    );
    final CatalogPhotosViewModel viewModel = await build(repository);
    expect(viewModel.photos.single.processing, PhotoProcessing.pending);

    repository.serviceDetails['svc-1']!['photos'] = <Object?>[catalogPhotoJson('p1')];
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(viewModel.photos.single.processing, PhotoProcessing.ready);
  });
}

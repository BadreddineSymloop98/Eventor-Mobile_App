import 'dart:async';
import 'dart:typed_data';

import '../../../core/base/base_view_model.dart';
import '../../../core/errors/failure.dart';
import '../../../core/provider_catalog/provider_catalog_repository.dart';

/// Whose gallery P8 / P13 manages.
enum PhotoOwner { service, pack }

/// A photo on its way up — shown in the grid with its progress, and kept
/// with its bytes when it fails so it can be sent again.
class PhotoUpload {
  PhotoUpload({required this.key, required this.image});

  /// Local only; never a server id.
  final String key;
  final PickedImage image;

  /// 0 to 1.
  double progress = 0;

  /// Set when the upload failed; the tile offers Retry and Remove.
  Failure? failure;

  bool get hasFailed => failure != null;
  Uint8List get bytes => image.bytes;
}

/// Why a picked photo was not added.
enum AddPhotoProblem { tooLarge, wrongType, limitReached }

/// P8 Service photos and P13 Pack photos — one gallery screen.
///
/// Uploads show in the grid at once with their progress; the server answers
/// each with the whole gallery, which replaces what is shown. The first photo
/// is the cover; "Make cover" and "Move earlier / later" send the whole new
/// order, shown at once and put back if the server refuses. A photo the
/// server is still processing is looked at again after a moment.
class CatalogPhotosViewModel extends BaseViewModel {
  CatalogPhotosViewModel({
    required this._catalog,
    required this._owner,
    required this._ownerId,
    required this._limit,
    required this._maxMb,
    required this._types,
    this._processingPoll = const Duration(seconds: 3),
  }) {
    load();
  }

  final ProviderCatalogRepository _catalog;
  final PhotoOwner _owner;
  final String _ownerId;
  final int _limit;
  final int _maxMb;
  final List<String> _types;

  /// How long to wait before looking again at a photo still processing.
  final Duration _processingPoll;

  /// How many times a processing photo is looked at again before the
  /// screen stops asking (it stays "Processing" until the next visit).
  static const int _maxPolls = 5;

  List<CatalogPhoto>? _photos;
  final List<PhotoUpload> _uploads = <PhotoUpload>[];
  int _uploadSeq = 0;
  bool _limitReached = false;

  /// The photo whose remove or reorder is running.
  String? _busyPhotoId;
  Timer? _poll;
  int _polls = 0;
  bool _isDisposed = false;

  PhotoOwner get owner => _owner;
  int get limit => _limit;

  /// The largest photo the server takes, in MB.
  int get maxMb => _maxMb;
  List<CatalogPhoto> get photos => _photos ?? const <CatalogPhoto>[];
  List<PhotoUpload> get uploads => List<PhotoUpload>.unmodifiable(_uploads);
  String? get busyPhotoId => _busyPhotoId;

  bool get isFirstLoad => _photos == null && !hasError;
  bool get loadFailed => _photos == null && hasError;

  /// The owner is gone — back to the form, which reloads.
  bool get isGone {
    final Failure? problem = failure;
    return _photos == null &&
        problem is ApiFailure &&
        (problem.code == ApiErrorCode.serviceNotFound ||
            problem.code == ApiErrorCode.packNotFound ||
            problem.code == ApiErrorCode.notOwner);
  }

  /// "3 of 12 photos": what is up plus what is going up.
  int get count => photos.length + _uploads.where((PhotoUpload u) => !u.hasFailed).length;

  /// No room for another: the Add tile gives way to a note.
  bool get isFull => _limitReached || count >= _limit;

  bool get hasPendingUploads => _uploads.any((PhotoUpload u) => !u.hasFailed);

  Future<void> load() async {
    final List<CatalogPhoto>? loaded = await runGuarded(_fetch);
    if (loaded != null) _setPhotos(loaded);
    notifyListeners();
  }

  Future<List<CatalogPhoto>> _fetch() async => switch (_owner) {
        PhotoOwner.service => (await _catalog.service(_ownerId)).photos,
        PhotoOwner.pack => (await _catalog.pack(_ownerId)).photos,
      };

  void _setPhotos(List<CatalogPhoto> photos) {
    _photos = photos;
    if (photos.length < _limit) _limitReached = false;
    _schedulePoll();
  }

  /// Checks [image] and starts sending it. The problem when it cannot go.
  AddPhotoProblem? add(PickedImage image) {
    if (isFull) return AddPhotoProblem.limitReached;
    switch (image.validate(maxMb: _maxMb, types: _types)) {
      case ImageProblem.tooLarge:
        return AddPhotoProblem.tooLarge;
      case ImageProblem.wrongType:
        return AddPhotoProblem.wrongType;
      case null:
        break;
    }
    final PhotoUpload upload = PhotoUpload(key: 'upload-${_uploadSeq++}', image: image);
    _uploads.add(upload);
    notifyListeners();
    unawaited(_send(upload));
    return null;
  }

  /// A failed tile's Retry.
  void retry(PhotoUpload upload) {
    if (!upload.hasFailed) return;
    if (photos.length + _uploads.where((PhotoUpload u) => !u.hasFailed).length >= _limit) {
      _limitReached = true;
      notifyListeners();
      return;
    }
    upload
      ..failure = null
      ..progress = 0;
    notifyListeners();
    unawaited(_send(upload));
  }

  /// A failed tile's Remove.
  void discard(PhotoUpload upload) {
    _uploads.remove(upload);
    notifyListeners();
  }

  Future<void> _send(PhotoUpload upload) async {
    try {
      final List<CatalogPhoto> gallery = await switch (_owner) {
        PhotoOwner.service => _catalog.addServicePhoto(
            _ownerId,
            upload.image,
            onProgress: (double p) => _progress(upload, p),
          ),
        PhotoOwner.pack => _catalog.addPackPhoto(
            _ownerId,
            upload.image,
            onProgress: (double p) => _progress(upload, p),
          ),
      };
      _uploads.remove(upload);
      _setPhotos(gallery);
    } on Failure catch (failure) {
      if (failure is ApiFailure && failure.code == ApiErrorCode.photoLimitReached) {
        // Full after all (another device added some): this one cannot go.
        _uploads.remove(upload);
        _limitReached = true;
      } else {
        upload.failure = failure;
      }
    } catch (error) {
      upload.failure = UnexpectedFailure(cause: error);
    }
    notifyListeners();
  }

  void _progress(PhotoUpload upload, double value) {
    upload.progress = value.clamp(0, 1);
    notifyListeners();
  }

  /// Removes [photo]. `null` when it went; a published service refuses to
  /// lose its last photo (422 `SERVICE_PUBLISH_INVALID`).
  Future<Failure?> remove(CatalogPhoto photo) => _write(photo.id, () => switch (_owner) {
        PhotoOwner.service => _catalog.removeServicePhoto(_ownerId, photo.id),
        PhotoOwner.pack => _catalog.removePackPhoto(_ownerId, photo.id),
      });

  /// Whether [failure] is the "last photo of a published service" refusal.
  static bool isLastPhotoRefusal(Failure failure) =>
      failure is ApiFailure && failure.code == ApiErrorCode.servicePublishInvalid;

  Future<Failure?> makeCover(CatalogPhoto photo) => _move(photo, to: 0);

  Future<Failure?> moveEarlier(CatalogPhoto photo) =>
      _move(photo, to: photos.indexOf(photo) - 1);

  Future<Failure?> moveLater(CatalogPhoto photo) =>
      _move(photo, to: photos.indexOf(photo) + 1);

  bool canMoveEarlier(CatalogPhoto photo) => photos.indexOf(photo) > 0;

  bool canMoveLater(CatalogPhoto photo) {
    final int index = photos.indexOf(photo);
    return index >= 0 && index < photos.length - 1;
  }

  Future<Failure?> _move(CatalogPhoto photo, {required int to}) async {
    final List<CatalogPhoto> before = photos;
    final int from = before.indexOf(photo);
    if (from < 0 || to < 0 || to >= before.length || from == to) return null;
    final List<CatalogPhoto> reordered = List<CatalogPhoto>.of(before)
      ..removeAt(from)
      ..insert(to, photo);
    // Shown at once; the server's answer (or the old order) replaces it.
    _photos = reordered;
    final List<String> ids = <String>[for (final CatalogPhoto p in reordered) p.id];
    final Failure? failure = await _write(photo.id, () => switch (_owner) {
          PhotoOwner.service => _catalog.orderServicePhotos(_ownerId, ids),
          PhotoOwner.pack => _catalog.orderPackPhotos(_ownerId, ids),
        });
    if (failure != null) {
      _photos = before;
      notifyListeners();
    }
    return failure;
  }

  Future<Failure?> _write(String photoId, Future<List<CatalogPhoto>> Function() call) async {
    if (_busyPhotoId != null) return null;
    _busyPhotoId = photoId;
    notifyListeners();
    Failure? failure;
    try {
      _setPhotos(await call());
    } on Failure catch (error) {
      failure = error;
      if (error is ApiFailure &&
          (error.code == ApiErrorCode.photoNotFound || error.code == ApiErrorCode.photoOrderInvalid)) {
        // Changed elsewhere: show what the server holds.
        try {
          _setPhotos(await _fetch());
        } catch (_) {
          // Kept as shown.
        }
      }
    } catch (error) {
      failure = UnexpectedFailure(cause: error);
    }
    _busyPhotoId = null;
    notifyListeners();
    return failure;
  }

  /// Looks again at photos the server is still turning into variants.
  void _schedulePoll() {
    _poll?.cancel();
    final bool processing =
        photos.any((CatalogPhoto p) => p.processing == PhotoProcessing.pending);
    if (!processing || _polls >= _maxPolls || _isDisposed) return;
    _poll = Timer(_processingPoll, () async {
      _polls++;
      try {
        final List<CatalogPhoto> fresh = await _fetch();
        if (_isDisposed) return;
        // An upload or a move meanwhile has the newer truth.
        if (_busyPhotoId == null && !hasPendingUploads) {
          _setPhotos(fresh);
          notifyListeners();
        } else {
          _schedulePoll();
        }
      } catch (_) {
        _schedulePoll();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _poll?.cancel();
    super.dispose();
  }
}

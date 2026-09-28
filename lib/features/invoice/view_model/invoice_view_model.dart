import 'package:flutter/foundation.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/bookings/bookings_repository.dart';
import '../../../core/errors/failure.dart';
import '../../../core/services/device_files.dart';

/// Draws the invoice PDF — see `buildInvoicePdf`.
typedef InvoicePdfRenderer = Future<Uint8List> Function();

/// B8 Invoice: the invoice Eventor issued when the booking was accepted,
/// with the booking beside it for the place, the guests and whether the
/// event is behind us (paid) or ahead (to pay on the day).
///
/// Download PDF saves the file onto the device (Downloads on Android, Files
/// on iOS); Share, in the top bar, hands it to another app. The PDF itself is
/// drawn by the view (it needs the strings and fonts) and handed in as an
/// [InvoicePdfRenderer].
class InvoiceViewModel extends BaseViewModel {
  InvoiceViewModel({
    required this.bookingId,
    required this._bookings,
    this._files = const PlatformDeviceFiles(),
  }) {
    load();
  }

  final String bookingId;
  final BookingsRepository _bookings;
  final DeviceFiles _files;

  Invoice? _invoice;
  BookingDetail? _booking;
  bool _isGone = false;
  bool _isDownloading = false;
  bool _isSharing = false;
  bool _saveDenied = false;

  Invoice? get invoice => _invoice;
  BookingDetail? get booking => _booking;
  bool get isGone => _isGone;
  bool get isDownloading => _isDownloading;
  bool get isSharing => _isSharing;

  /// The last download stopped on a refused storage permission.
  bool get saveDenied => _saveDenied;

  /// `INV-2026-0142.pdf`.
  String get fileName => '${_invoice?.number ?? bookingId}.pdf';
  bool get isFirstLoad => _invoice == null && !hasError && !_isGone;

  /// The event took place and the booking closed — the cash was handed
  /// over.
  bool get isPaid => _booking?.status == 'completed';

  /// Cancelled after acceptance: the invoice stands voided.
  bool get isVoided => _booking?.invoice?.voided ?? false;

  Future<void> load() async {
    _isGone = false;
    notifyListeners();
    await runGuarded(() async {
      final List<Object> both = await Future.wait<Object>(<Future<Object>>[
        _bookings.invoice(bookingId),
        _bookings.detail(bookingId),
      ]);
      _invoice = both[0] as Invoice;
      _booking = both[1] as BookingDetail;
    });
    final Failure? error = failure;
    if (error is ApiFailure &&
        (error.code == ApiErrorCode.invoiceNotFound ||
            error.code == ApiErrorCode.bookingNotFound ||
            error.code == ApiErrorCode.notOwner)) {
      _isGone = true;
      clearFailure();
    }
    notifyListeners();
  }

  /// Draws the PDF and saves it onto the device, announcing it with [notice]
  /// where the platform does. The saved file, or `null` with [failure] set —
  /// or [saveDenied], when the user refused storage.
  Future<SavedFile?> download(InvoicePdfRenderer render, {DownloadNotice? notice}) async {
    if (_isDownloading || _isSharing) return null;
    _isDownloading = true;
    _saveDenied = false;
    notifyListeners();
    SavedFile? saved;
    try {
      saved = await _files.savePdf(await render(), fileName, notice: notice);
      clearFailure();
    } on SavePermissionDenied {
      _saveDenied = true;
    } on Failure catch (error) {
      setFailure(error);
    } catch (error) {
      setFailure(UnexpectedFailure(cause: error));
    }
    _isDownloading = false;
    notifyListeners();
    return saved;
  }

  /// Opens a downloaded invoice in the device's PDF viewer; `false` when
  /// nothing can show it.
  Future<bool> open(SavedFile file) => _files.open(file);

  /// The PDF's bytes for the share sheet, or `null` with [failure].
  Future<Uint8List?> pdf(InvoicePdfRenderer render) async {
    if (_isDownloading || _isSharing) return null;
    _isSharing = true;
    notifyListeners();
    Uint8List? bytes;
    try {
      bytes = await render();
      clearFailure();
    } on Failure catch (error) {
      setFailure(error);
    } catch (error) {
      setFailure(UnexpectedFailure(cause: error));
    }
    _isSharing = false;
    notifyListeners();
    return bytes;
  }
}

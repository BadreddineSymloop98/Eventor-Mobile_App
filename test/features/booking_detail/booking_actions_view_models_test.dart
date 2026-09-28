import 'dart:typed_data';

import 'package:eventor/core/bookings/bookings_repository.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/services/device_files.dart';
import 'package:eventor/features/check_in/view_model/check_in_view_model.dart';
import 'package:eventor/features/invoice/view_model/invoice_view_model.dart';
import 'package:eventor/features/reschedule/view_model/reschedule_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/booking_fakes.dart';
import '../../support/fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  late ScriptedBookingsRepository bookings;

  setUp(() => bookings = ScriptedBookingsRepository());

  group('B6 RescheduleViewModel', () {
    Future<RescheduleViewModel> build({String status = 'accepted'}) async {
      final RescheduleViewModel viewModel = RescheduleViewModel(
        booking: testBooking(status: status),
        bookings: bookings,
        catalog: FakeCatalogRepository(),
        today: () => DateTime(2026, 3, 1, 9),
      );
      addTearDown(viewModel.dispose);
      await flushAsync();
      return viewModel;
    }

    test('opens on the booking’s month, with its times', () async {
      final RescheduleViewModel viewModel = await build();

      expect(viewModel.visibleMonth, DateTime(2026, 3));
      expect(viewModel.startTime, '13:00');
      expect(viewModel.isProposal, isTrue);
    });

    test('needs a day and a reason', () async {
      final RescheduleViewModel viewModel = await build();

      expect(await viewModel.submit(), isNull);

      expect(viewModel.dateMissing, isTrue);
      expect(viewModel.reasonMissing, isTrue);
      expect(bookings.calls.where((String c) => c.startsWith('reschedule')), isEmpty);
    });

    test('sends the day, the times and the reason', () async {
      final RescheduleViewModel viewModel = await build();
      viewModel
        ..selectDate(DateTime(2026, 3, 21))
        ..setReason('The hall moved us.');

      expect(await viewModel.submit(), isNotNull);
      expect(bookings.calls, contains('reschedule:b-1:2026-3-21:The hall moved us.'));
    });

    test('a day taken meanwhile is struck through', () async {
      final RescheduleViewModel viewModel = await build();
      viewModel
        ..selectDate(DateTime(2026, 3, 21))
        ..setReason('Moved.');
      bookings.failNext = apiFailure(ApiErrorCode.dateUnavailable, statusCode: 409);

      expect(await viewModel.submit(), isNull);

      expect(viewModel.problem, RescheduleProblem.dateTaken);
      expect(viewModel.selectedDate, isNull);
      expect(viewModel.availability!.stateOf(DateTime(2026, 3, 21)), DayState.busy);
    });

    test('a proposal already waiting sends the client back', () async {
      final RescheduleViewModel viewModel = await build();
      viewModel
        ..selectDate(DateTime(2026, 3, 21))
        ..setReason('Moved.');
      bookings.failNext = apiFailure(ApiErrorCode.reschedulePendingExists, statusCode: 409);

      await viewModel.submit();

      expect(viewModel.problem, RescheduleProblem.stale);
    });
  });

  group('B7 CheckInViewModel', () {
    test('All good answers with the booking as it now stands', () async {
      bookings.afterWrite = testBooking(status: 'completed');
      final CheckInViewModel viewModel = CheckInViewModel(booking: testBooking(), bookings: bookings);

      final BookingDetail? updated = await viewModel.confirm();

      expect(updated?.status, 'completed');
      expect(viewModel.isConfirming, isFalse);
    });

    test('too early is reported', () async {
      bookings.failNext = apiFailure(ApiErrorCode.checkInTooEarly);
      final CheckInViewModel viewModel = CheckInViewModel(booking: testBooking(), bookings: bookings);

      expect(await viewModel.confirm(), isNull);
      expect((viewModel.failure! as ApiFailure).code, ApiErrorCode.checkInTooEarly);
    });

    test('a problem opens a dispute', () async {
      final CheckInViewModel viewModel = CheckInViewModel(booking: testBooking(), bookings: bookings);

      expect(
        await viewModel.reportProblem(DisputeType.providerNoShow, 'They never came to the wedding at all.'),
        isNull,
      );
      expect(bookings.calls, contains('dispute:b-1:provider_no_show'));
    });
  });

  group('B8 InvoiceViewModel', () {
    late _FakeDeviceFiles files;
    final Uint8List drawn = Uint8List.fromList(<int>[37, 80, 68, 70, 45]);
    Future<Uint8List> render() async => drawn;

    setUp(() => files = _FakeDeviceFiles());

    Future<InvoiceViewModel> build() async {
      final InvoiceViewModel viewModel =
          InvoiceViewModel(bookingId: 'b-1', bookings: bookings, files: files);
      addTearDown(viewModel.dispose);
      await flushAsync();
      await flushAsync();
      return viewModel;
    }

    test('is paid only once the booking is completed', () async {
      final InvoiceViewModel accepted = await build();
      expect(accepted.invoice?.number, 'INV-2026-0142');
      expect(accepted.isPaid, isFalse);

      bookings.booking = testBooking(status: 'completed');
      final InvoiceViewModel completed = await build();
      expect(completed.isPaid, isTrue);
    });

    test('a cancelled booking’s invoice is void', () async {
      bookings.booking = testBooking(status: 'cancelled');

      expect((await build()).isVoided, isTrue);
    });

    test('no invoice yet is gone, not an error', () async {
      bookings.failNext = apiFailure(ApiErrorCode.invoiceNotFound, statusCode: 404);

      final InvoiceViewModel viewModel = await build();

      expect(viewModel.isGone, isTrue);
      expect(viewModel.hasError, isFalse);
    });

    test('Download PDF saves the file onto the device, named after the invoice', () async {
      final InvoiceViewModel viewModel = await build();

      final SavedFile? saved = await viewModel.download(render);

      expect(saved?.name, 'INV-2026-0142.pdf');
      expect(files.saved.single.bytes, drawn);
      expect(files.saved.single.name, 'INV-2026-0142.pdf');
      expect(viewModel.isDownloading, isFalse);
      expect(viewModel.failure, isNull);
    });

    test('the download notice goes with the file to the platform', () async {
      final InvoiceViewModel viewModel = await build();
      const DownloadNotice notice = DownloadNotice(
        channelName: 'Downloads',
        text: 'Download complete · Tap to open',
      );

      await viewModel.download(render, notice: notice);

      expect(files.notice, same(notice));
    });

    test('a refused storage permission is reported as such', () async {
      files.error = const SavePermissionDenied();
      final InvoiceViewModel viewModel = await build();

      expect(await viewModel.download(render), isNull);

      expect(viewModel.saveDenied, isTrue);
      expect(viewModel.failure, isNull);
    });

    test('a failed write is a storage failure', () async {
      files.error = const StorageFailure();
      final InvoiceViewModel viewModel = await build();

      expect(await viewModel.download(render), isNull);

      expect(viewModel.failure, isA<StorageFailure>());
      expect(viewModel.saveDenied, isFalse);
    });

    test('a PDF that could not be drawn is not saved', () async {
      final InvoiceViewModel viewModel = await build();

      expect(await viewModel.download(() async => throw StateError('no font')), isNull);

      expect(viewModel.failure, isA<UnexpectedFailure>());
      expect(files.saved, isEmpty);
      expect(viewModel.isDownloading, isFalse);
    });

    test('Open hands the saved file to the viewer', () async {
      final InvoiceViewModel viewModel = await build();
      final SavedFile saved = (await viewModel.download(render))!;

      expect(await viewModel.open(saved), isTrue);
      expect(files.opened.single, same(saved));
    });

    test('Share draws the PDF for the share sheet, saving nothing', () async {
      final InvoiceViewModel viewModel = await build();

      final Uint8List? pdf = await viewModel.pdf(render);

      expect(pdf, drawn);
      expect(viewModel.isSharing, isFalse);
      expect(files.saved, isEmpty);
    });
  });
}

/// [DeviceFiles] without a platform channel: records what was saved.
class _FakeDeviceFiles implements DeviceFiles {
  final List<({Uint8List bytes, String name})> saved = <({Uint8List bytes, String name})>[];
  final List<SavedFile> opened = <SavedFile>[];
  Exception? error;

  /// The notice the last save asked for.
  DownloadNotice? notice;

  @override
  Future<SavedFile> savePdf(Uint8List bytes, String fileName, {DownloadNotice? notice}) async {
    this.notice = notice;
    final Exception? failure = error;
    if (failure != null) throw failure;
    saved.add((bytes: bytes, name: fileName));
    return SavedFile(name: fileName, uri: 'content://downloads/1');
  }

  @override
  Future<bool> open(SavedFile file) async {
    opened.add(file);
    return true;
  }
}

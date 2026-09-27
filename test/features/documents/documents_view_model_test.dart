import 'dart:async';

import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/errors/validation_error.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/services/document_picker.dart';
import 'package:eventor/core/session/session_controller.dart';
import 'package:eventor/features/auth/data/documents_repository.dart';
import 'package:eventor/features/documents/view_model/documents_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../feature_test_helpers.dart';

/// A file that passes every local rule.
const DocumentFile _validPdf = DocumentFile(
  name: 'id-card.pdf',
  sizeInBytes: 1024,
  extension: 'pdf',
  path: '/tmp/id-card.pdf',
);

/// [FakeDocumentsRepository] whose uploads wait on [gate], so a test can look
/// at a slot mid-upload.
class _GatedDocuments extends FakeDocumentsRepository {
  final Completer<void> gate = Completer<void>();

  @override
  Future<ProviderDocuments> upload({
    required ProviderDocumentType type,
    required String path,
    required String fileName,
    ValueChanged<double>? onProgress,
  }) async {
    await gate.future;
    return super.upload(
      type: type,
      path: path,
      fileName: fileName,
      onProgress: onProgress,
    );
  }
}

void main() {
  late FakeAuthRepository auth;
  late SessionController session;

  setUp(() {
    auth = FakeAuthRepository();
    auth.user = testUser(role: UserRole.provider);
    session = SessionController(auth)
      ..signedIn(testUser(role: UserRole.provider));
  });

  /// A view model on [documents] whose picker hands back [file], with its
  /// first load done.
  Future<DocumentsViewModel> build(
    FakeDocumentsRepository documents, {
    DocumentFile? file = _validPdf,
  }) async {
    final DocumentsViewModel viewModel = DocumentsViewModel(
      documents: documents,
      session: session,
      picker: () async => file,
    );
    addTearDown(viewModel.dispose);
    await flushAsync();
    return viewModel;
  }

  group('DocumentsViewModel load', () {
    test('starts with every slot missing and Submit unavailable', () async {
      final DocumentsViewModel viewModel = await build(
        FakeDocumentsRepository(),
      );

      expect(viewModel.isLoading, isFalse);
      for (final ProviderDocumentType type in DocumentsViewModel.types) {
        expect(viewModel.slotFor(type).status, ProviderDocumentStatus.missing);
      }
      expect(viewModel.canSubmit, isFalse);
      expect(viewModel.maxMegabytes, 5);
    });

    test('shows what the server already has', () async {
      final FakeDocumentsRepository documents = FakeDocumentsRepository();
      documents.statuses[ProviderDocumentType.nationalId] =
          ProviderDocumentStatus.approved;

      final DocumentsViewModel viewModel = await build(documents);

      expect(
        viewModel.slotFor(ProviderDocumentType.nationalId).isReceived,
        isTrue,
      );
    });

    test('a failed load is reported', () async {
      final FakeDocumentsRepository documents = FakeDocumentsRepository()
        ..fetchError = const NetworkFailure();

      final DocumentsViewModel viewModel = await build(documents);

      expect(viewModel.failure, isA<NetworkFailure>());
      expect(viewModel.isLoading, isFalse);
    });
  });

  group('DocumentsViewModel pick', () {
    test('uploads the file the moment it is picked', () async {
      final FakeDocumentsRepository documents = FakeDocumentsRepository();
      final DocumentsViewModel viewModel = await build(documents);

      await viewModel.pick(ProviderDocumentType.taxCard);

      expect(documents.uploads, <ProviderDocumentType>[
        ProviderDocumentType.taxCard,
      ]);
      final DocumentSlot slot = viewModel.slotFor(ProviderDocumentType.taxCard);
      expect(slot.fileName, 'id-card.pdf');
      expect(slot.status, ProviderDocumentStatus.pending);
      expect(slot.isUploading, isFalse);
      expect(slot.error, isNull);
    });

    test('backing out of the picker changes nothing', () async {
      final FakeDocumentsRepository documents = FakeDocumentsRepository();
      final DocumentsViewModel viewModel = await build(documents, file: null);

      await viewModel.pick(ProviderDocumentType.taxCard);

      expect(documents.uploads, isEmpty);
      expect(viewModel.slotFor(ProviderDocumentType.taxCard).fileName, isNull);
    });

    test('a file of the wrong type is refused before any upload', () async {
      final FakeDocumentsRepository documents = FakeDocumentsRepository();
      final DocumentsViewModel viewModel = await build(
        documents,
        file: const DocumentFile(
          name: 'notes.docx',
          sizeInBytes: 1024,
          extension: 'docx',
          path: '/tmp/notes.docx',
        ),
      );

      await viewModel.pick(ProviderDocumentType.nationalId);

      expect(documents.uploads, isEmpty);
      expect(
        viewModel.slotFor(ProviderDocumentType.nationalId).error,
        isA<DocumentWrongType>(),
      );
    });

    test('a file over the limit is refused before any upload', () async {
      final FakeDocumentsRepository documents = FakeDocumentsRepository();
      final DocumentsViewModel viewModel = await build(
        documents,
        file: const DocumentFile(
          name: 'scan.pdf',
          sizeInBytes: 5 * 1024 * 1024 + 1,
          extension: 'pdf',
          path: '/tmp/scan.pdf',
        ),
      );

      await viewModel.pick(ProviderDocumentType.nationalId);

      expect(documents.uploads, isEmpty);
      expect(
        viewModel.slotFor(ProviderDocumentType.nationalId).error,
        isA<DocumentTooLarge>().having(
          (DocumentTooLarge e) => e.maximumMegabytes,
          'maximumMegabytes',
          5,
        ),
      );
    });

    test('a file with no path on disk cannot be uploaded', () async {
      final FakeDocumentsRepository documents = FakeDocumentsRepository();
      final DocumentsViewModel viewModel = await build(
        documents,
        file: const DocumentFile(
          name: 'scan.pdf',
          sizeInBytes: 1024,
          extension: 'pdf',
        ),
      );

      await viewModel.pick(ProviderDocumentType.nationalId);

      expect(documents.uploads, isEmpty);
      expect(
        viewModel.slotFor(ProviderDocumentType.nationalId).error,
        isA<DocumentUploadFailed>(),
      );
    });

    test('the server refusing the size is shown as too large', () async {
      final FakeDocumentsRepository documents = FakeDocumentsRepository()
        ..uploadError = apiFailure(ApiErrorCode.fileTooLarge, statusCode: 413);
      final DocumentsViewModel viewModel = await build(documents);

      await viewModel.pick(ProviderDocumentType.nationalId);

      final DocumentSlot slot = viewModel.slotFor(
        ProviderDocumentType.nationalId,
      );
      expect(slot.error, isA<DocumentTooLarge>());
      expect(slot.isUploading, isFalse);
    });

    test('the server refusing the type is shown as the wrong type', () async {
      final FakeDocumentsRepository documents = FakeDocumentsRepository()
        ..uploadError = apiFailure(ApiErrorCode.fileTypeNotAllowed);
      final DocumentsViewModel viewModel = await build(documents);

      await viewModel.pick(ProviderDocumentType.nationalId);

      expect(
        viewModel.slotFor(ProviderDocumentType.nationalId).error,
        isA<DocumentWrongType>(),
      );
    });

    test('any other failure is shown as a failed upload', () async {
      final FakeDocumentsRepository documents = FakeDocumentsRepository()
        ..uploadError = const NetworkFailure();
      final DocumentsViewModel viewModel = await build(documents);

      await viewModel.pick(ProviderDocumentType.nationalId);

      expect(
        viewModel.slotFor(ProviderDocumentType.nationalId).error,
        isA<DocumentUploadFailed>(),
      );
    });

    test(
      'a slot is uploading until the server answers, and blocks Submit',
      () async {
        final _GatedDocuments documents = _GatedDocuments();
        final DocumentsViewModel viewModel = await build(documents);

        final Future<void> pending = viewModel.pick(
          ProviderDocumentType.taxCard,
        );
        await flushAsync();

        expect(
          viewModel.slotFor(ProviderDocumentType.taxCard).isUploading,
          isTrue,
        );
        expect(viewModel.isUploading, isTrue);
        expect(viewModel.canSubmit, isFalse);

        documents.gate.complete();
        await pending;

        expect(viewModel.isUploading, isFalse);
      },
    );

    test('a new pick clears the previous error', () async {
      final FakeDocumentsRepository documents = FakeDocumentsRepository()
        ..uploadError = const NetworkFailure();
      final DocumentsViewModel viewModel = await build(documents);
      await viewModel.pick(ProviderDocumentType.nationalId);

      documents.uploadError = null;
      await viewModel.pick(ProviderDocumentType.nationalId);

      expect(viewModel.slotFor(ProviderDocumentType.nationalId).error, isNull);
    });
  });

  group('DocumentsViewModel submit', () {
    test('is available once all three are received', () async {
      final DocumentsViewModel viewModel = await build(
        FakeDocumentsRepository(),
      );

      for (final ProviderDocumentType type in DocumentsViewModel.types) {
        expect(viewModel.canSubmit, isFalse);
        await viewModel.pick(type);
      }

      expect(viewModel.canSubmit, isTrue);
    });

    test('re-reads the account, whose review status has moved', () async {
      final DocumentsViewModel viewModel = await build(
        FakeDocumentsRepository(),
      );
      for (final ProviderDocumentType type in DocumentsViewModel.types) {
        await viewModel.pick(type);
      }
      auth.user = testUser(
        role: UserRole.provider,
        verificationStatus: VerificationStatus.verified,
      );

      await viewModel.submit();

      expect(session.user?.verificationStatus, VerificationStatus.verified);
      expect(viewModel.failure, isNull);
    });

    test('does nothing while documents are missing', () async {
      final DocumentsViewModel viewModel = await build(
        FakeDocumentsRepository(),
      );
      auth.user = testUser(
        role: UserRole.provider,
        verificationStatus: VerificationStatus.verified,
      );

      await viewModel.submit();

      expect(session.user?.verificationStatus, VerificationStatus.pending);
    });
  });
}

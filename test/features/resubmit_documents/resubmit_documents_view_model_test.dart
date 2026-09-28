import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/errors/validation_error.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/services/document_picker.dart';
import 'package:eventor/core/session/session_controller.dart';
import 'package:eventor/features/auth/data/documents_repository.dart';
import 'package:eventor/features/resubmit_documents/view_model/resubmit_documents_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../feature_test_helpers.dart';

const DocumentFile _pdf = DocumentFile(
  name: 'nif.pdf',
  sizeInBytes: 1024,
  extension: 'pdf',
  path: '/tmp/nif.pdf',
);

void main() {
  late FakeDocumentsRepository documents;
  late SessionController session;
  DocumentFile? nextFile;

  setUp(() {
    documents = FakeDocumentsRepository()
      ..statuses[ProviderDocumentType.nationalId] = ProviderDocumentStatus.approved
      ..statuses[ProviderDocumentType.commercialRegister] = ProviderDocumentStatus.approved
      ..statuses[ProviderDocumentType.taxCard] = ProviderDocumentStatus.rejected;
    session = SessionController(FakeAuthRepository())
      ..signedIn(testUser(role: UserRole.provider));
    nextFile = _pdf;
  });

  Future<ResubmitDocumentsViewModel> build() async {
    final ResubmitDocumentsViewModel viewModel = ResubmitDocumentsViewModel(
      documents: documents,
      session: session,
      picker: () async => nextFile,
    );
    addTearDown(viewModel.dispose);
    await flushAsync();
    return viewModel;
  }

  test('asks for the refused document, with nothing picked yet', () async {
    final ResubmitDocumentsViewModel viewModel = await build();

    expect(viewModel.rejected.single.type, ProviderDocumentType.taxCard);
    expect(viewModel.toSend, <ProviderDocumentType>[ProviderDocumentType.taxCard]);
    expect(viewModel.canSubmit, isFalse);
    expect(viewModel.isDirty, isFalse);
  });

  test('asks for missing documents too', () async {
    documents.statuses[ProviderDocumentType.nationalId] = ProviderDocumentStatus.missing;
    final ResubmitDocumentsViewModel viewModel = await build();

    expect(
      viewModel.toSend,
      <ProviderDocumentType>[ProviderDocumentType.nationalId, ProviderDocumentType.taxCard],
    );
  });

  test('keeps a picked file on screen without sending it', () async {
    final ResubmitDocumentsViewModel viewModel = await build();

    await viewModel.pick(ProviderDocumentType.taxCard);

    expect(viewModel.slotFor(ProviderDocumentType.taxCard).file?.name, 'nif.pdf');
    expect(documents.uploads, isEmpty);
    expect(viewModel.canSubmit, isTrue);
    expect(viewModel.isDirty, isTrue);
  });

  test('backing out of the picker changes nothing', () async {
    final ResubmitDocumentsViewModel viewModel = await build();
    nextFile = null;

    await viewModel.pick(ProviderDocumentType.taxCard);

    expect(viewModel.slotFor(ProviderDocumentType.taxCard).file, isNull);
  });

  test('refuses a file that is too large or of the wrong type, before sending', () async {
    final ResubmitDocumentsViewModel viewModel = await build();

    nextFile = const DocumentFile(name: 'big.pdf', sizeInBytes: 6 * 1024 * 1024, extension: 'pdf', path: '/b');
    await viewModel.pick(ProviderDocumentType.taxCard);
    expect(viewModel.slotFor(ProviderDocumentType.taxCard).error, isA<DocumentTooLarge>());
    expect(viewModel.canSubmit, isFalse);

    nextFile = const DocumentFile(name: 'x.exe', sizeInBytes: 10, extension: 'exe', path: '/x');
    await viewModel.pick(ProviderDocumentType.taxCard);
    expect(viewModel.slotFor(ProviderDocumentType.taxCard).error, isA<DocumentWrongType>());
    expect(viewModel.canSubmit, isFalse);
  });

  test('drops a picked file', () async {
    final ResubmitDocumentsViewModel viewModel = await build();
    await viewModel.pick(ProviderDocumentType.taxCard);

    viewModel.remove(ProviderDocumentType.taxCard);

    expect(viewModel.slotFor(ProviderDocumentType.taxCard).file, isNull);
    expect(viewModel.isDirty, isFalse);
  });

  test('sends every picked file and is done', () async {
    documents.statuses[ProviderDocumentType.nationalId] = ProviderDocumentStatus.missing;
    final ResubmitDocumentsViewModel viewModel = await build();
    await viewModel.pick(ProviderDocumentType.nationalId);
    await viewModel.pick(ProviderDocumentType.taxCard);

    final bool sent = await viewModel.submit();

    expect(sent, isTrue);
    expect(
      documents.uploads,
      <ProviderDocumentType>[ProviderDocumentType.nationalId, ProviderDocumentType.taxCard],
    );
    expect(viewModel.toSend, isEmpty);
    expect(viewModel.isDirty, isFalse);
  });

  test('stops at a failed upload, which can be tried again', () async {
    final ResubmitDocumentsViewModel viewModel = await build();
    await viewModel.pick(ProviderDocumentType.taxCard);
    documents.uploadError = const NetworkFailure();

    expect(await viewModel.submit(), isFalse);
    expect(viewModel.slotFor(ProviderDocumentType.taxCard).error, isA<DocumentUploadFailed>());
    expect(viewModel.isSubmitting, isFalse);
    expect(viewModel.canSubmit, isTrue, reason: 'the same file can go again');

    documents.uploadError = null;
    expect(await viewModel.submit(), isTrue);
  });

  test('turns a server refusal into the matching document error', () async {
    final ResubmitDocumentsViewModel viewModel = await build();
    await viewModel.pick(ProviderDocumentType.taxCard);
    documents.uploadError = apiFailure(ApiErrorCode.fileTooLarge, statusCode: 413);

    await viewModel.submit();

    expect(viewModel.slotFor(ProviderDocumentType.taxCard).error, isA<DocumentTooLarge>());
  });

  test('reports a failed load', () async {
    documents.fetchError = const NetworkFailure();
    final ResubmitDocumentsViewModel viewModel = await build();

    expect(viewModel.current, isNull);
    expect(viewModel.isFirstLoad, isFalse);
  });
}

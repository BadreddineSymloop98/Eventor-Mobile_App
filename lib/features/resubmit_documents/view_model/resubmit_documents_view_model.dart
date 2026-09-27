import '../../../core/base/base_view_model.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/validation_error.dart';
import '../../../core/services/document_picker.dart';
import '../../../core/session/session_controller.dart';
import '../../auth/data/documents_repository.dart';

/// One document 08d asks for again: the file picked for it, and how its
/// upload is going.
class ResubmitSlot {
  const ResubmitSlot({
    this.file,
    this.isUploading = false,
    this.progress = 0,
    this.error,
  });

  /// Picked on this device, not sent yet.
  final DocumentFile? file;
  final bool isUploading;

  /// 0–1 while [isUploading].
  final double progress;

  /// Refused before sending (size, type) or the upload failed.
  final DocumentError? error;
}

/// `08d Resubmit documents`: the documents a reviewer refused — and any still
/// missing — sent again together.
///
/// Picked files wait on the screen (user decision, 2026-09-27): nothing
/// reaches the server until "Resubmit documents", so "Not now" leaves the
/// review exactly as it was. The files then go up one by one; one that fails
/// stops the run with its error, the ones already sent stay sent, and the
/// button carries on with what is left.
class ResubmitDocumentsViewModel extends BaseViewModel {
  ResubmitDocumentsViewModel({
    required this._documents,
    required this._session,
    this._picker = pickDocumentFile,
  }) {
    load();
  }

  final DocumentsRepository _documents;
  final SessionController _session;
  final DocumentPicker _picker;

  ProviderDocuments? _current;
  final Map<ProviderDocumentType, ResubmitSlot> _slots =
      <ProviderDocumentType, ResubmitSlot>{};
  bool _isSubmitting = false;
  bool _isDone = false;

  ProviderDocuments? get current => _current;
  bool get isFirstLoad => _current == null && !hasError;
  bool get isSubmitting => _isSubmitting;

  int get maxMegabytes =>
      _current?.maxFileSizeMb ?? InputRules.maxDocumentMegabytes;

  /// The three documents, in the design's order.
  List<ProviderDocument> get documents => <ProviderDocument>[
        for (final ProviderDocumentType type in ProviderDocumentType.values)
          ?_current?.byType(type),
      ];

  /// Refused ones — one reason card each.
  List<ProviderDocument> get rejected => documents
      .where((ProviderDocument d) => d.status == ProviderDocumentStatus.rejected)
      .toList();

  /// What still has to be sent: refused or missing.
  List<ProviderDocumentType> get toSend => <ProviderDocumentType>[
        for (final ProviderDocument document in documents)
          if (document.needsAction) document.type,
      ];

  ResubmitSlot slotFor(ProviderDocumentType type) =>
      _slots[type] ?? const ResubmitSlot();

  /// Every document to send has a file waiting that the server could take.
  /// A failed upload does not block: the same file can be tried again.
  bool get canSubmit =>
      !_isSubmitting &&
      toSend.isNotEmpty &&
      toSend.every((ProviderDocumentType t) {
        final ResubmitSlot slot = slotFor(t);
        return slot.file != null &&
            slot.error is! DocumentTooLarge &&
            slot.error is! DocumentWrongType;
      });

  /// Files picked and not sent — leaving would drop them.
  bool get isDirty =>
      !_isDone &&
      _slots.values.any((ResubmitSlot slot) => slot.file != null);

  Future<void> load() async {
    final ProviderDocuments? documents = await runGuarded(_documents.fetch);
    if (documents != null) _current = documents;
    notifyListeners();
  }

  /// Picks a file for [type] and keeps it on screen, checked but not sent.
  Future<void> pick(ProviderDocumentType type) async {
    if (_isSubmitting) return;
    final DocumentFile? file = await _picker();
    if (file == null) return; // Backed out of the picker — not an answer.
    _slots[type] = ResubmitSlot(file: file, error: _check(file));
    notifyListeners();
  }

  /// Drops the file waiting for [type].
  void remove(ProviderDocumentType type) {
    if (_isSubmitting) return;
    _slots.remove(type);
    notifyListeners();
  }

  /// Sends every waiting file. `true` once all of them are on the server and
  /// the account is back in review.
  Future<bool> submit() async {
    if (!canSubmit) return false;
    _isSubmitting = true;
    notifyListeners();

    for (final ProviderDocumentType type in List<ProviderDocumentType>.of(toSend)) {
      final DocumentFile file = slotFor(type).file!;
      final String? path = file.path;
      if (path == null) {
        _fail(type, file, const DocumentUploadFailed());
        return false;
      }
      _slots[type] = ResubmitSlot(file: file, isUploading: true);
      notifyListeners();
      try {
        _current = await _documents.upload(
          type: type,
          path: path,
          fileName: file.name,
          onProgress: (double progress) {
            _slots[type] = ResubmitSlot(file: file, isUploading: true, progress: progress);
            notifyListeners();
          },
        );
        // Sent: the document now reads "In review" and needs nothing more.
        _slots.remove(type);
        notifyListeners();
      } on ApiFailure catch (error) {
        _fail(type, file, switch (error.code) {
          ApiErrorCode.fileTooLarge => DocumentTooLarge(maxMegabytes),
          ApiErrorCode.fileTypeNotAllowed => const DocumentWrongType(),
          _ => const DocumentUploadFailed(),
        });
        return false;
      } catch (_) {
        _fail(type, file, const DocumentUploadFailed());
        return false;
      }
    }

    // The account's status moved back to pending; the rest of the app reads
    // it from the session.
    await runGuarded(_session.refreshUser);
    _isSubmitting = false;
    _isDone = true;
    notifyListeners();
    return true;
  }

  void _fail(ProviderDocumentType type, DocumentFile file, DocumentError error) {
    _slots[type] = ResubmitSlot(file: file, error: error);
    _isSubmitting = false;
    notifyListeners();
  }

  DocumentError? _check(DocumentFile file) {
    if (!InputRules.isAcceptableDocumentType(file.extension)) {
      return const DocumentWrongType();
    }
    if (file.sizeInBytes > maxMegabytes * 1024 * 1024) {
      return DocumentTooLarge(maxMegabytes);
    }
    return null;
  }
}

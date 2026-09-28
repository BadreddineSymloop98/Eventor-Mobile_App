import '../../../core/base/base_view_model.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/validation_error.dart';
import '../../../core/services/document_picker.dart';
import '../../../core/session/session_controller.dart';
import '../../auth/data/documents_repository.dart';

/// Where one document field stands on screen.
class DocumentSlot {
  const DocumentSlot({
    this.fileName,
    this.status = ProviderDocumentStatus.missing,
    this.isUploading = false,
    this.error,
    this.serverReason,
  });

  /// The file picked on this device, if any.
  final String? fileName;

  /// What the server last said about this document.
  final ProviderDocumentStatus status;
  final bool isUploading;

  /// A problem found here — too large, wrong type, upload failed.
  final DocumentError? error;

  /// A reviewer's refusal, already translated by the server.
  final String? serverReason;

  /// On the server and waiting for, or past, review.
  bool get isReceived =>
      status == ProviderDocumentStatus.pending ||
      status == ProviderDocumentStatus.approved;

  DocumentSlot copyWith({
    String? fileName,
    ProviderDocumentStatus? status,
    bool? isUploading,
    DocumentError? error,
    bool clearError = false,
    String? serverReason,
    bool clearReason = false,
  }) {
    return DocumentSlot(
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      isUploading: isUploading ?? this.isUploading,
      error: clearError ? null : (error ?? this.error),
      serverReason: clearReason ? null : (serverReason ?? this.serverReason),
    );
  }
}

/// Drives `08e Verification documents` — a new provider's three papers,
/// uploaded one by one as they are picked.
///
/// Each file goes up the moment it is chosen, so "Submit for review" has
/// nothing left to send: it only confirms all three are in and moves on.
/// "I'll do it later" (and Back) leave with whatever is done; the provider
/// home says what is still missing.
class DocumentsViewModel extends BaseViewModel {
  DocumentsViewModel({
    required this._documents,
    required this._session,
    this._picker = pickDocumentFile,
    this._acceptedExtensions = InputRules.documentExtensions,
  }) {
    load();
  }

  final DocumentsRepository _documents;
  final SessionController _session;
  final DocumentPicker _picker;

  /// From the server's `limits.documentAcceptedExtensions`, lower-cased.
  final List<String> _acceptedExtensions;

  /// The order the design lists them in.
  static const List<ProviderDocumentType> types = ProviderDocumentType.values;

  final Map<ProviderDocumentType, DocumentSlot> _slots =
      <ProviderDocumentType, DocumentSlot>{
    for (final ProviderDocumentType type in types) type: const DocumentSlot(),
  };

  int _maxMegabytes = InputRules.maxDocumentMegabytes;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  int get maxMegabytes => _maxMegabytes;

  DocumentSlot slotFor(ProviderDocumentType type) => _slots[type]!;

  bool get isUploading =>
      _slots.values.any((DocumentSlot slot) => slot.isUploading);

  bool get canSubmit =>
      !isUploading &&
      _slots.values.every((DocumentSlot slot) => slot.isReceived);

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final ProviderDocuments? current = await runGuarded(_documents.fetch);
    if (current != null) _apply(current);
    _isLoading = false;
    notifyListeners();
  }

  /// Picks a file for [type] and uploads it straight away.
  Future<void> pick(ProviderDocumentType type) async {
    if (slotFor(type).isUploading) return;

    final DocumentFile? file = await _picker();
    if (file == null) return; // Backed out of the picker — not an answer.

    final DocumentError? problem = _check(file);
    if (problem != null) {
      _slots[type] = slotFor(type).copyWith(
        fileName: file.name,
        error: problem,
        clearReason: true,
      );
      notifyListeners();
      return;
    }

    final String? path = file.path;
    if (path == null) {
      _slots[type] = slotFor(type).copyWith(
        fileName: file.name,
        error: const DocumentUploadFailed(),
      );
      notifyListeners();
      return;
    }

    _slots[type] = slotFor(type).copyWith(
      fileName: file.name,
      isUploading: true,
      clearError: true,
      clearReason: true,
    );
    notifyListeners();

    try {
      final ProviderDocuments updated = await _documents.upload(
        type: type,
        path: path,
        fileName: file.name,
      );
      _apply(updated);
      _slots[type] = slotFor(type).copyWith(isUploading: false);
    } on ApiFailure catch (error) {
      _slots[type] = slotFor(type).copyWith(
        isUploading: false,
        error: switch (error.code) {
          ApiErrorCode.fileTooLarge => DocumentTooLarge(_maxMegabytes),
          ApiErrorCode.fileTypeNotAllowed => const DocumentWrongType(),
          _ => const DocumentUploadFailed(),
        },
      );
    } catch (_) {
      _slots[type] = slotFor(type).copyWith(
        isUploading: false,
        error: const DocumentUploadFailed(),
      );
    }
    notifyListeners();
  }

  /// All three are in: re-read the account, whose verification status has
  /// moved, so the provider home shows "under review".
  Future<void> submit() async {
    if (!canSubmit) return;
    await runGuarded(_session.refreshUser);
  }

  DocumentError? _check(DocumentFile file) {
    if (!_acceptedExtensions.contains(file.extension.toLowerCase())) {
      return const DocumentWrongType();
    }
    if (file.sizeInBytes > _maxMegabytes * 1024 * 1024) {
      return DocumentTooLarge(_maxMegabytes);
    }
    return null;
  }

  void _apply(ProviderDocuments documents) {
    _maxMegabytes = documents.maxFileSizeMb;
    for (final ProviderDocumentType type in types) {
      final ProviderDocument? document = documents.byType(type);
      if (document == null) continue;
      final DocumentSlot slot = slotFor(type);
      _slots[type] = DocumentSlot(
        fileName: slot.fileName,
        status: document.status,
        isUploading: slot.isUploading,
        error: slot.error,
        serverReason: document.status == ProviderDocumentStatus.rejected
            ? (document.rejectNote ?? document.rejectReason)
            : null,
      );
    }
  }
}

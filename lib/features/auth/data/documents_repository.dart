import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/models/account.dart';
import '../../../core/network/api_client.dart';

/// The three papers a provider is reviewed on, by the API's names.
enum ProviderDocumentType {
  nationalId('national_id'),
  commercialRegister('commercial_register_or_artisan_card'),
  taxCard('tax_card');

  const ProviderDocumentType(this.apiValue);

  final String apiValue;

  static ProviderDocumentType? fromApi(String? value) {
    for (final ProviderDocumentType type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }
}

/// Where one document stands in review.
enum ProviderDocumentStatus { missing, pending, approved, rejected }

/// One of the provider's documents, as the server last saw it.
class ProviderDocument {
  const ProviderDocument({
    required this.type,
    required this.status,
    this.rejectReason,
    this.rejectNote,
    this.reviewedAt,
  });

  factory ProviderDocument.fromJson(Map<String, Object?> json) =>
      ProviderDocument(
        type: ProviderDocumentType.fromApi(json['type'] as String?) ??
            ProviderDocumentType.nationalId,
        status: switch (json['status']) {
          'pending' => ProviderDocumentStatus.pending,
          'approved' => ProviderDocumentStatus.approved,
          'rejected' => ProviderDocumentStatus.rejected,
          _ => ProviderDocumentStatus.missing,
        },
        rejectReason: json['rejectReasonLabel'] as String?,
        rejectNote: json['rejectNote'] as String?,
        reviewedAt: json['reviewedAt'] is String
            ? DateTime.tryParse(json['reviewedAt']! as String)?.toLocal()
            : null,
      );

  final ProviderDocumentType type;
  final ProviderDocumentStatus status;

  /// Already translated by the server.
  final String? rejectReason;
  final String? rejectNote;

  /// When a reviewer last decided on it — "Rejected 12 May 2025" on 08d.
  final DateTime? reviewedAt;

  /// Still to be sent, or sent again: nothing on file the reviewer accepts
  /// or is looking at.
  bool get needsAction =>
      status == ProviderDocumentStatus.missing ||
      status == ProviderDocumentStatus.rejected;
}

/// The provider's documents and what the server accepts.
class ProviderDocuments {
  const ProviderDocuments({
    required this.verificationStatus,
    required this.documents,
    required this.maxFileSizeMb,
    required this.acceptedTypes,
  });

  factory ProviderDocuments.fromJson(Map<String, Object?> json) {
    final Object? docs = json['documents'];
    final Object? types = json['acceptedTypes'];
    return ProviderDocuments(
      verificationStatus: VerificationStatus.fromApi(
        json['verificationStatus'] as String?,
      ),
      documents: docs is List<Object?>
          ? docs
              .whereType<Map<String, Object?>>()
              .map(ProviderDocument.fromJson)
              .toList()
          : const <ProviderDocument>[],
      maxFileSizeMb: (json['maxFileSizeMb'] as num?)?.toInt() ?? 5,
      acceptedTypes: types is List<Object?>
          ? types.whereType<String>().toList()
          : const <String>[],
    );
  }

  final VerificationStatus verificationStatus;
  final List<ProviderDocument> documents;
  final int maxFileSizeMb;
  final List<String> acceptedTypes;

  /// Documents that are missing or were rejected — what 21a/21b and 08d ask
  /// the provider to send, in the design's order.
  List<ProviderDocument> get needingAction => <ProviderDocument>[
        for (final ProviderDocumentType type in ProviderDocumentType.values)
          if (byType(type) case final ProviderDocument document
              when document.needsAction)
            document,
      ];

  /// How many of the three are on file, in review or approved — the
  /// "Documents sent · 2 of 3" step.
  int get sentCount => documents
      .where((ProviderDocument d) => d.status != ProviderDocumentStatus.missing)
      .length;

  ProviderDocument? byType(ProviderDocumentType type) {
    for (final ProviderDocument document in documents) {
      if (document.type == type) return document;
    }
    return null;
  }
}

/// A provider's verification papers — `08e` after sign-up.
abstract interface class DocumentsRepository {
  Future<ProviderDocuments> fetch();

  /// Uploads one document from [path], reporting 0–1 progress.
  Future<ProviderDocuments> upload({
    required ProviderDocumentType type,
    required String path,
    required String fileName,
    ValueChanged<double>? onProgress,
  });
}

class ApiDocumentsRepository implements DocumentsRepository {
  ApiDocumentsRepository(this._api);

  final ApiClient _api;

  @override
  Future<ProviderDocuments> fetch() async {
    final Object? data = await _api.get('/app/me/documents');
    return ProviderDocuments.fromJson(
      data is Map<String, Object?> ? data : const <String, Object?>{},
    );
  }

  @override
  Future<ProviderDocuments> upload({
    required ProviderDocumentType type,
    required String path,
    required String fileName,
    ValueChanged<double>? onProgress,
  }) async {
    final Object? data = await _api.upload(
      '/app/me/documents',
      form: () => FormData.fromMap(<String, Object?>{
        'type': type.apiValue,
        'file': MultipartFile.fromFileSync(path, filename: fileName),
      }),
      onProgress: onProgress,
    );
    return ProviderDocuments.fromJson(
      data is Map<String, Object?> ? data : const <String, Object?>{},
    );
  }
}

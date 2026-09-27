import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/models/account.dart';
import '../core/reference/reference_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/documents_repository.dart';
import 'mock_backend.dart';
import 'mock_reference_data.dart';

/// [AuthRepository] on the in-app [MockBackend].
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<CodeSent> register(RegistrationRequest request) async {
    await _backend.delay();
    await _backend.register(
      role: request.role,
      fullName: request.fullName,
      email: request.email,
      phone: request.phone,
      password: request.password,
      language: request.language,
      wilayaCode: request.wilayaCode,
      businessName: request.businessName,
      categoryId: request.categoryId,
      wilayaCodes: request.wilayaCodes,
      categoryExists: (String id) =>
          mockCategories.any((ServiceCategory c) => c.id == id),
      wilayaExists: (int code) => mockWilayas.any((Wilaya w) => w.code == code),
    );
    return CodeSent(
      email: request.email.trim().toLowerCase(),
      resendAfterSeconds: MockBackend.resendCooldownSeconds,
    );
  }

  @override
  Future<AppUser> verifyEmail({
    required String email,
    required String code,
  }) async {
    await _backend.delay();
    return (await _backend.verifyEmail(email, code)).toUser();
  }

  @override
  Future<CodeSent> resendVerification(String email) async {
    await _backend.delay();
    return CodeSent(email: email, resendAfterSeconds: _backend.resend(email));
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    await _backend.delay();
    return (await _backend.login(email, password)).toUser();
  }

  @override
  Future<void> forgotPassword(String email) async {
    // Always "sent", known address or not — no enumeration, as on the server.
    await _backend.delay();
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    await _backend.delay();
    await _backend.resetPassword(email, code, password);
  }

  @override
  Future<AppUser> setPassword({
    required String token,
    required String password,
  }) async {
    await _backend.delay();
    return (await _backend.setPassword(token, password)).toUser();
  }

  @override
  Future<AppUser?> restoreSession() async {
    await _backend.delay();
    return _backend.sessionAccount?.toUser();
  }

  @override
  Future<AppUser> currentUser() async {
    await _backend.delay();
    return _backend.requireSession().toUser();
  }

  @override
  Future<void> logout() => _backend.signOut();
}

/// [ReferenceRepository] serving the snapshot in `mock_reference_data.dart`.
class MockReferenceRepository implements ReferenceRepository {
  MockReferenceRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<List<Wilaya>> wilayas() async {
    await _backend.delay();
    return mockWilayas;
  }

  @override
  Future<List<ServiceCategory>> categories() async {
    await _backend.delay();
    return mockCategories;
  }
}

/// [DocumentsRepository] keeping the signed-in provider's documents in the
/// [MockBackend]. An upload lands as `pending` after a short simulated
/// transfer; review never happens by itself, like a real queue on a quiet day.
class MockDocumentsRepository implements DocumentsRepository {
  MockDocumentsRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<ProviderDocuments> fetch() async {
    await _backend.delay();
    return _snapshot();
  }

  @override
  Future<ProviderDocuments> upload({
    required ProviderDocumentType type,
    required String path,
    required String fileName,
    ValueChanged<double>? onProgress,
  }) async {
    _backend.requireSession();
    // A short, visible upload.
    for (int step = 1; step <= 4; step++) {
      await _backend.delay();
      onProgress?.call(step / 4);
      if (_backend.latency == Duration.zero) break;
    }
    await _backend.setDocument(type, 'pending');
    return _snapshot();
  }

  ProviderDocuments _snapshot() {
    final MockAccount account = _backend.requireSession();
    return ProviderDocuments(
      verificationStatus: account.verificationStatus,
      maxFileSizeMb: 5,
      acceptedTypes: const <String>['pdf', 'jpeg', 'png'],
      documents: <ProviderDocument>[
        for (final ProviderDocumentType type in ProviderDocumentType.values)
          ProviderDocument(
            type: type,
            status: switch (account.documents[type.apiValue]) {
              'pending' => ProviderDocumentStatus.pending,
              'approved' => ProviderDocumentStatus.approved,
              'rejected' => ProviderDocumentStatus.rejected,
              _ => ProviderDocumentStatus.missing,
            },
          ),
      ],
    );
  }
}

/// [AppConfigRepository] answering with today's live config, never touching
/// the network. The support address is null, as it is live.
class MockConfigRepository extends AppConfigRepository {
  MockConfigRepository(super.api);

  @override
  AppConfig get current => const AppConfig();

  @override
  Future<AppConfig> load() async => current;
}

import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/models/account.dart';
import '../core/reference/reference_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/documents_repository.dart';
import 'mock_backend.dart';
import 'mock_catalog_data.dart';
import 'mock_communes_data.dart';
import 'mock_provider.dart';
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
  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    await _backend.delay();
    _backend.verifyResetCode(email, code);
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
  Future<AppUser> updateWilaya(int wilayaCode) async {
    await _backend.delay();
    return (await _backend.setWilaya(wilayaCode)).toUser();
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
    // Counted from the catalog snapshot, as the server counts its services.
    final Map<int, int> counts = <int, int>{};
    for (final Map<String, Object?> service in mockCatalogServices) {
      for (final Object? code in service['wilayas']! as List<Object?>) {
        counts.update(code! as int, (int n) => n + 1, ifAbsent: () => 1);
      }
    }
    return <Wilaya>[
      for (final Wilaya w in mockWilayas)
        Wilaya(
          code: w.code,
          nameEn: w.nameEn,
          nameAr: w.nameAr,
          servicesCount: counts[w.code] ?? 0,
        ),
    ];
  }

  @override
  Future<List<ServiceCategory>> categories() async {
    await _backend.delay();
    return mockCategories;
  }

  @override
  Future<List<Commune>> communes(int wilayaCode) async {
    await _backend.delay();
    return <Commune>[
      for (final Map<String, Object?> row
          in mockCommunes[wilayaCode] ?? const <Map<String, Object?>>[])
        Commune.fromJson(row),
    ]..sort((Commune a, Commune b) => a.nameEn.compareTo(b.nameEn));
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

  ProviderDocuments _snapshot() => ProviderDocuments.fromJson(
        mockDocumentsJson(_backend.requireSession(), _backend.now),
      );
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

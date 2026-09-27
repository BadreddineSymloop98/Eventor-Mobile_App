import 'dart:async';

import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/network/api_client.dart';
import 'package:eventor/core/reference/reference_repository.dart';
import 'package:eventor/core/session/token_store.dart';
import 'package:eventor/features/auth/data/auth_repository.dart';
import 'package:eventor/features/auth/data/documents_repository.dart';
import 'package:flutter/foundation.dart';


/// An [ApiFailure] as the server would send it, for scripting fakes.
ApiFailure apiFailure(
  String code, {
  int statusCode = 422,
  String message = 'Server says no.',
  Map<String, Object?>? details,
}) {
  return ApiFailure(
    statusCode: statusCode,
    code: code,
    message: message,
    details: details,
  );
}

/// A signed-in account for tests.
AppUser testUser({
  UserRole role = UserRole.client,
  VerificationStatus? verificationStatus,
  String fullName = 'Amina Benali',
  String email = 'amina@example.com',
  Wilaya? wilaya,
}) {
  return AppUser(
    id: 'user-1',
    role: role,
    isBlocked: false,
    verificationStatus: verificationStatus ??
        (role == UserRole.provider
            ? VerificationStatus.pending
            : VerificationStatus.notRequired),
    fullName: fullName,
    email: email,
    emailVerified: true,
    language: 'en',
    wilaya: wilaya,
  );
}

/// [AuthRepository] with every answer scripted.
///
/// Each call records what it was given and then returns the matching
/// `…Result`, or throws the matching `…Error` when one is set. Leave both
/// alone and the call succeeds with a sensible default.
class FakeAuthRepository implements AuthRepository {
  // What the calls were given.
  final List<RegistrationRequest> registrations = <RegistrationRequest>[];
  final List<({String email, String code})> verifications =
      <({String email, String code})>[];
  final List<String> resends = <String>[];
  final List<({String email, String password})> logins =
      <({String email, String password})>[];
  final List<String> forgotten = <String>[];
  final List<({String email, String code, String password})> resets =
      <({String email, String code, String password})>[];
  final List<({String token, String password})> setPasswords =
      <({String token, String password})>[];
  int logoutCalls = 0;

  // What they answer.
  Failure? registerError;
  Failure? verifyError;
  Failure? resendError;
  Failure? loginError;
  Failure? forgotError;
  Failure? resetError;
  Failure? setPasswordError;

  AppUser user = testUser();
  AppUser? restoredUser;
  int resendAfterSeconds = 60;

  /// When set, calls wait on it — for asserting the busy state mid-flight.
  Completer<void>? gate;

  Future<void> _wait() async {
    final Completer<void>? pending = gate;
    if (pending != null) await pending.future;
  }

  @override
  Future<CodeSent> register(RegistrationRequest request) async {
    registrations.add(request);
    await _wait();
    if (registerError != null) throw registerError!;
    return CodeSent(email: request.email, resendAfterSeconds: resendAfterSeconds);
  }

  @override
  Future<AppUser> verifyEmail({
    required String email,
    required String code,
  }) async {
    verifications.add((email: email, code: code));
    await _wait();
    if (verifyError != null) throw verifyError!;
    return user;
  }

  @override
  Future<CodeSent> resendVerification(String email) async {
    resends.add(email);
    await _wait();
    if (resendError != null) throw resendError!;
    return CodeSent(email: email, resendAfterSeconds: resendAfterSeconds);
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    logins.add((email: email, password: password));
    await _wait();
    if (loginError != null) throw loginError!;
    return user;
  }

  @override
  Future<void> forgotPassword(String email) async {
    forgotten.add(email);
    await _wait();
    if (forgotError != null) throw forgotError!;
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    resets.add((email: email, code: code, password: password));
    await _wait();
    if (resetError != null) throw resetError!;
  }

  @override
  Future<AppUser> setPassword({
    required String token,
    required String password,
  }) async {
    setPasswords.add((token: token, password: password));
    await _wait();
    if (setPasswordError != null) throw setPasswordError!;
    return user;
  }

  @override
  Future<AppUser?> restoreSession() async => restoredUser;

  @override
  Future<AppUser> currentUser() async => user;

  @override
  Future<void> logout() async => logoutCalls++;
}

/// [ReferenceRepository] serving a short fixed list, or failing.
class FakeReferenceRepository implements ReferenceRepository {
  static const List<Wilaya> sampleWilayas = <Wilaya>[
    Wilaya(code: 9, nameEn: 'Blida', nameAr: 'البليدة'),
    Wilaya(code: 16, nameEn: 'Alger', nameAr: 'الجزائر'),
    Wilaya(code: 42, nameEn: 'Tipaza', nameAr: 'تيبازة'),
  ];

  static const List<ServiceCategory> sampleCategories = <ServiceCategory>[
    ServiceCategory(id: 'cat-photo', nameEn: 'Photography', nameAr: 'التصوير'),
    ServiceCategory(id: 'cat-venue', nameEn: 'Venues', nameAr: 'القاعات'),
  ];

  bool fail = false;

  @override
  Future<List<Wilaya>> wilayas() async {
    if (fail) throw const NetworkFailure();
    return sampleWilayas;
  }

  @override
  Future<List<ServiceCategory>> categories() async {
    if (fail) throw const NetworkFailure();
    return sampleCategories;
  }
}

/// [DocumentsRepository] that keeps the three documents in memory.
class FakeDocumentsRepository implements DocumentsRepository {
  final Map<ProviderDocumentType, ProviderDocumentStatus> statuses =
      <ProviderDocumentType, ProviderDocumentStatus>{
    for (final ProviderDocumentType type in ProviderDocumentType.values)
      type: ProviderDocumentStatus.missing,
  };

  final List<ProviderDocumentType> uploads = <ProviderDocumentType>[];
  Failure? uploadError;
  Failure? fetchError;

  ProviderDocuments _snapshot() => ProviderDocuments(
        verificationStatus: VerificationStatus.pending,
        maxFileSizeMb: 5,
        acceptedTypes: const <String>['pdf', 'jpeg', 'png'],
        documents: <ProviderDocument>[
          for (final MapEntry<ProviderDocumentType, ProviderDocumentStatus> e
              in statuses.entries)
            ProviderDocument(type: e.key, status: e.value),
        ],
      );

  @override
  Future<ProviderDocuments> fetch() async {
    if (fetchError != null) throw fetchError!;
    return _snapshot();
  }

  @override
  Future<ProviderDocuments> upload({
    required ProviderDocumentType type,
    required String path,
    required String fileName,
    ValueChanged<double>? onProgress,
  }) async {
    uploads.add(type);
    if (uploadError != null) throw uploadError!;
    statuses[type] = ProviderDocumentStatus.pending;
    return _snapshot();
  }
}

/// [AppConfigRepository] that never touches the network.
class FakeConfigRepository extends AppConfigRepository {
  FakeConfigRepository([this.config = const AppConfig()])
      : super(ApiClient(tokens: TokenStore(), languageCode: () => 'en'));

  AppConfig config;

  @override
  AppConfig get current => config;

  @override
  Future<AppConfig> load() async => config;
}


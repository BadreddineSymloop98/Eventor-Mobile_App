import 'dart:async';

import 'package:eventor/core/catalog/catalog_repository.dart';
import 'package:eventor/core/catalog/favourites_repository.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/catalog/service_query.dart';
import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/network/api_client.dart';
import 'package:eventor/core/reference/reference_repository.dart';
import 'package:eventor/core/session/token_store.dart';
import 'package:eventor/features/auth/data/auth_repository.dart';
import 'package:eventor/features/auth/data/documents_repository.dart';
import 'package:flutter/foundation.dart';

import 'fixtures.dart';

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
  final List<int> wilayaUpdates = <int>[];

  // What they answer.
  Failure? registerError;
  Failure? verifyError;
  Failure? resendError;
  Failure? loginError;
  Failure? forgotError;
  Failure? resetError;
  Failure? setPasswordError;
  Failure? updateWilayaError;

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
  Future<AppUser> updateWilaya(int wilayaCode) async {
    wilayaUpdates.add(wilayaCode);
    await _wait();
    final Failure? error = updateWilayaError;
    if (error != null) throw error;
    return user = testUser(
      role: user.role,
      fullName: user.fullName,
      email: user.email,
      wilaya: Wilaya(code: wilayaCode, nameEn: 'Wilaya $wilayaCode', nameAr: 'ولاية $wilayaCode'),
    );
  }

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

/// [FavouritesRepository] that records every call.
class FakeFavouritesRepository implements FavouritesRepository {
  /// `add:service:s-1`, `remove:pack:k-1`, `removeById:fav-1`, `list:…`.
  final List<String> calls = <String>[];

  /// What [list] returns, newest first.
  List<Favourite> items = fixtureList('favourites_page.json')
      .map(Favourite.fromJson)
      .toList();

  /// Thrown by the next call only.
  Failure? failNext;

  /// Thrown by every call while set — a network that is down.
  Failure? failAll;

  /// When set, calls wait on it — for asserting the in-flight state.
  Completer<void>? gate;

  Future<void> _enter(String call) async {
    calls.add(call);
    final Completer<void>? pending = gate;
    if (pending != null) await pending.future;
    final Failure? always = failAll;
    if (always != null) throw always;
    final Failure? failure = failNext;
    if (failure != null) {
      failNext = null;
      throw failure;
    }
  }

  @override
  Future<ApiPage<Favourite>> list({
    FavouriteKind? kind,
    String? categoryId,
    int page = 1,
  }) async {
    await _enter('list:${kind?.apiValue}:$categoryId:$page');
    final List<Favourite> found = items
        .where((Favourite f) => kind == null || f.kind == kind)
        .where((Favourite f) => categoryId == null || f.category?.id == categoryId)
        .toList();
    return ApiPage<Favourite>(
      items: page == 1 ? found : <Favourite>[],
      page: page,
      totalPages: found.isEmpty ? 0 : 1,
      total: found.length,
    );
  }

  @override
  Future<Favourite> add(FavouriteTarget target) async {
    await _enter('add:$target');
    return items.first;
  }

  @override
  Future<void> remove(FavouriteTarget target) => _enter('remove:$target');

  @override
  Future<void> removeById(String favouriteId) async {
    await _enter('removeById:$favouriteId');
    items = items.where((Favourite f) => f.id != favouriteId).toList();
  }
}

/// [CatalogRepository] answering from the saved live fixtures, with every
/// answer replaceable and every failure injectable.
class FakeCatalogRepository implements CatalogRepository {
  HomeFeed homeFeed = HomeFeed.fromJson(fixtureData('home.json'));
  List<CategoryWithCount> categoryList =
      fixtureList('categories.json').map(CategoryWithCount.fromJson).toList();

  /// Paged 20 at a time by [services].
  List<ServiceCard> serviceItems =
      fixtureList('services_page.json').map(ServiceCard.fromJson).toList();
  ServiceDetail serviceDetail =
      ServiceDetail.fromJson(fixtureData('service_detail.json'));
  ProviderDetail providerDetail =
      ProviderDetail.fromJson(fixtureData('provider_detail.json'));
  List<PackCard> packItems =
      fixtureList('packs_page.json').map(PackCard.fromJson).toList();
  PackDetail packDetail = PackDetail.fromJson(fixtureData('pack_detail.json'));

  /// Every day from here on is available, except the 10th of each month
  /// (busy) and the 20th (blocked).
  DateTime firstBookable = DateTime(2026, 1, 1);

  // Failures, per call.
  Failure? homeError;
  Failure? servicesError;
  Failure? serviceError;
  Failure? providerError;
  Failure? packsError;
  Failure? packError;
  Failure? availabilityError;

  // What the calls were given.
  final List<({ServiceQuery query, int page, int limit})> servicePages =
      <({ServiceQuery query, int page, int limit})>[];
  final List<({EventType? eventType, PackOrder order, int page})> packQueries =
      <({EventType? eventType, PackOrder order, int page})>[];
  final List<DateTime> availabilityMonths = <DateTime>[];
  int homeCalls = 0;

  /// When set, calls wait on it — for asserting loading states.
  Completer<void>? gate;

  Future<void> _wait() async {
    final Completer<void>? pending = gate;
    if (pending != null) await pending.future;
  }

  static ApiPage<T> _page<T>(List<T> items, int page, int limit) {
    final int start = (page - 1) * limit;
    return ApiPage<T>(
      items: start >= items.length
          ? <T>[]
          : items.sublist(start, (start + limit).clamp(0, items.length)),
      page: page,
      totalPages: (items.length / limit).ceil(),
      total: items.length,
    );
  }

  Availability _month(DateTime month) {
    final int days = DateTime(month.year, month.month + 1, 0).day;
    DayState stateOf(int d) {
      final DateTime date = DateTime(month.year, month.month, d);
      if (date.isBefore(firstBookable)) return DayState.blocked;
      if (d == 10) return DayState.busy;
      if (d == 20) return DayState.blocked;
      return DayState.available;
    }

    return Availability(
      month: monthParam(month),
      minNoticeDays: 1,
      firstBookableDate: firstBookable,
      days: <AvailabilityDay>[
        for (int d = 1; d <= days; d++)
          AvailabilityDay(
            date: DateTime(month.year, month.month, d),
            state: stateOf(d),
          ),
      ],
    );
  }

  @override
  Future<HomeFeed> home() async {
    homeCalls++;
    await _wait();
    if (homeError != null) throw homeError!;
    return homeFeed;
  }

  @override
  Future<List<CategoryWithCount>> categories() async {
    await _wait();
    return categoryList;
  }

  @override
  Future<ApiPage<ServiceCard>> services(
    ServiceQuery query, {
    int page = 1,
    int limit = 20,
  }) async {
    servicePages.add((query: query, page: page, limit: limit));
    await _wait();
    if (servicesError != null) throw servicesError!;
    return _page(serviceItems, page, limit);
  }

  @override
  Future<ServiceDetail> service(String id) async {
    await _wait();
    if (serviceError != null) throw serviceError!;
    return serviceDetail;
  }

  @override
  Future<Availability> serviceAvailability(String id, DateTime month) async {
    availabilityMonths.add(month);
    await _wait();
    if (availabilityError != null) throw availabilityError!;
    return _month(month);
  }

  @override
  Future<ProviderDetail> provider(String id) async {
    await _wait();
    if (providerError != null) throw providerError!;
    return providerDetail;
  }

  @override
  Future<ApiPage<PackCard>> packs({
    EventType? eventType,
    PackOrder order = PackOrder.savings,
    int page = 1,
  }) async {
    packQueries.add((eventType: eventType, order: order, page: page));
    await _wait();
    if (packsError != null) throw packsError!;
    return _page(
      packItems
          .where((PackCard p) => eventType == null || p.eventType == eventType)
          .toList(),
      page,
      20,
    );
  }

  @override
  Future<PackDetail> pack(String id) async {
    await _wait();
    if (packError != null) throw packError!;
    return packDetail;
  }

  @override
  Future<Availability> packAvailability(String id, DateTime month) async {
    availabilityMonths.add(month);
    await _wait();
    if (availabilityError != null) throw availabilityError!;
    return _month(month);
  }
}

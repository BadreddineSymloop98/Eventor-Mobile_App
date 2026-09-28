import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/input_rules.dart';
import '../core/errors/failure.dart';
import '../core/models/account.dart';
import '../features/auth/data/documents_repository.dart';
import 'mock_budget.dart';
import 'mock_catalog_data.dart';
import 'mock_reference_data.dart';

/// One account in the mock backend.
class MockAccount {
  MockAccount({
    required this.id,
    required this.role,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.language,
    this.emailVerified = false,
    VerificationStatus? verificationStatus,
    this.blockedMessage,
    this.wilayaCode,
    this.businessName,
    this.categoryId,
    List<int>? wilayaCodes,
    Map<String, String>? documents,
    Map<String, Map<String, Object?>>? documentReviews,
    this.acceptingBookings = true,
  })  : documentReviews = documentReviews ?? <String, Map<String, Object?>>{},
        verificationStatus = verificationStatus ??
            (role == UserRole.provider
                ? VerificationStatus.pending
                : VerificationStatus.notRequired),
        wilayaCodes = wilayaCodes ?? <int>[],
        documents = documents ?? <String, String>{};

  factory MockAccount.fromJson(Map<String, Object?> json) => MockAccount(
        id: json['id']! as String,
        role: UserRole.fromApi(json['role'] as String?) ?? UserRole.client,
        fullName: json['fullName']! as String,
        email: json['email']! as String,
        phone: json['phone']! as String,
        password: json['password'] as String?,
        language: json['language'] as String? ?? 'en',
        emailVerified: json['emailVerified'] as bool? ?? false,
        verificationStatus: VerificationStatus.fromApi(
          json['verificationStatus'] as String?,
        ),
        blockedMessage: json['blockedMessage'] as String?,
        wilayaCode: json['wilayaCode'] as int?,
        businessName: json['businessName'] as String?,
        categoryId: json['categoryId'] as String?,
        wilayaCodes: (json['wilayaCodes'] as List<Object?>? ?? <Object?>[])
            .whereType<int>()
            .toList(),
        documents: (json['documents'] as Map<String, Object?>? ??
                <String, Object?>{})
            .map((String k, Object? v) => MapEntry<String, String>(k, '$v')),
        documentReviews: (json['documentReviews'] as Map<String, Object?>? ??
                <String, Object?>{})
            .map(
              (String k, Object? v) => MapEntry<String, Map<String, Object?>>(
                k,
                Map<String, Object?>.of(v! as Map<String, Object?>),
              ),
            ),
        acceptingBookings: json['acceptingBookings'] as bool? ?? true,
      );

  final String id;
  final UserRole role;
  String fullName;
  final String email;

  /// Stored the way the server stores it: `+213XXXXXXXXX`.
  final String phone;

  /// `null` for an account an admin created and nobody has set a password
  /// for yet (the invite flow).
  String? password;
  String language;
  bool emailVerified;
  VerificationStatus verificationStatus;

  /// Non-null means blocked, with the admin's message.
  String? blockedMessage;
  int? wilayaCode;
  String? businessName;
  String? categoryId;
  List<int> wilayaCodes;

  /// Document type (API name) → status (`pending`, `approved`, `rejected`).
  Map<String, String> documents;

  /// Document type → the reviewer's decision: `reason`, `reasonLabel`,
  /// `note`, `reviewedAt` (epoch ms). Cleared when the type is sent again.
  Map<String, Map<String, Object?>> documentReviews;

  /// 21's "Accepting bookings".
  bool acceptingBookings;

  AppUser toUser() => AppUser(
        id: id,
        role: role,
        isBlocked: blockedMessage != null,
        verificationStatus: verificationStatus,
        fullName: fullName,
        email: email,
        emailVerified: emailVerified,
        language: language,
        phone: phone,
        wilaya: _wilayaFor(wilayaCode),
      );

  static Wilaya? _wilayaFor(int? code) {
    for (final Wilaya wilaya in mockWilayas) {
      if (wilaya.code == code) return wilaya;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'role': role.apiValue,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'language': language,
        'emailVerified': emailVerified,
        'verificationStatus': verificationStatus.apiValue,
        'blockedMessage': blockedMessage,
        'wilayaCode': wilayaCode,
        'businessName': businessName,
        'categoryId': categoryId,
        'wilayaCodes': wilayaCodes,
        'documents': documents,
        'documentReviews': documentReviews,
        'acceptingBookings': acceptingBookings,
      };
}

/// The fake Eventor backend used by mock builds (see `DataSource`).
///
/// It enforces the live API's own rules and answers with its own error codes
/// — email/phone taken, weak passwords, the 5-attempt lockout, unverified and
/// blocked accounts, the resend cooldown, wrong and expired codes — so every
/// screen state can be reached without a server. Its state is saved on the
/// device, so a restart keeps accounts and the session, like the real app.
///
/// Fixed values testers need:
///
/// * every emailed code is [code]; [expiredCode] simulates an expired one;
/// * invite links: [validInviteToken] and [expiredInviteToken];
/// * the seeded accounts in [seedAccounts], all with [seedPassword].
class MockBackend {
  MockBackend._(this._prefs, this.latency, this._now);

  static const String code = '123456';
  static const String expiredCode = '000000';
  static const String validInviteToken = 'valid-invite';
  static const String expiredInviteToken = 'expired-invite';
  static const String seedPassword = 'Eventor2026';

  /// The API's own limits.
  static const int resendCooldownSeconds = 60;
  static const int maxFailedLogins = 5;
  static const Duration lockDuration = Duration(minutes: 15);

  /// A few of the passwords the live server refuses as too common.
  static const Set<String> commonPasswords = <String>{
    'password123',
    'password1234',
    'azerty123',
    'azerty1234',
    'qwerty123',
    'qwerty1234',
    '1234567890a',
    'abcdefg123',
    'eventor2024',
    'eventor2025',
  };

  static const String _storageKey = 'eventor.mock_backend.v1';

  final SharedPreferences _prefs;

  /// How long each call takes, so loading states stay visible. Zero in tests.
  final Duration latency;
  final DateTime Function() _now;

  final Map<String, MockAccount> _accounts = <String, MockAccount>{};
  String? _sessionEmail;
  final Map<String, List<int>> _failedLogins = <String, List<int>>{};
  final Map<String, int> _lockedUntil = <String, int>{};
  final Map<String, int> _codeSentAt = <String, int>{};

  /// Saved services and packs, per account email — `{id, kind, targetId,
  /// createdAt}` rows, as the favourites table stores them.
  final Map<String, List<Map<String, Object?>>> _favourites =
      <String, List<Map<String, Object?>>>{};

  /// Each client's one budget, per account email, in the shape
  /// `mock_budget.dart` reads.
  final Map<String, Map<String, Object?>> _budgets =
      <String, Map<String, Object?>>{};

  /// Loads the saved state, or seeds a fresh one.
  static Future<MockBackend> load({
    SharedPreferences? prefs,
    Duration latency = const Duration(milliseconds: 600),
    DateTime Function()? now,
  }) async {
    final MockBackend backend = MockBackend._(
      prefs ?? await SharedPreferences.getInstance(),
      latency,
      now ?? DateTime.now,
    );
    backend._restore();
    return backend;
  }

  /// The accounts a fresh mock backend starts with.
  static List<MockAccount> seedAccounts() => <MockAccount>[
        MockAccount(
          id: 'mock-client',
          role: UserRole.client,
          fullName: 'Amina Benali',
          email: 'client@eventor.test',
          phone: '+213555000001',
          password: seedPassword,
          language: 'en',
          emailVerified: true,
          wilayaCode: 16,
        ),
        MockAccount(
          id: 'mock-provider',
          role: UserRole.provider,
          fullName: 'Karim Belkacem',
          email: 'provider@eventor.test',
          phone: '+213555000002',
          password: seedPassword,
          language: 'en',
          emailVerified: true,
          businessName: 'Studio Lumière',
          categoryId: '7d3855dd-4bd3-430a-9ffc-09d4f269eb4a',
          wilayaCodes: <int>[16, 9],
          // 21a as drawn: two in review, the tax card still to send.
          documents: <String, String>{
            ProviderDocumentType.nationalId.apiValue: 'pending',
            ProviderDocumentType.commercialRegister.apiValue: 'pending',
          },
        ),
        // 21b / 08d as drawn: the tax card was refused.
        MockAccount(
          id: 'mock-rejected-provider',
          role: UserRole.provider,
          fullName: 'Rym Belaid',
          email: 'rejected.provider@eventor.test',
          phone: '+213555000007',
          password: seedPassword,
          language: 'en',
          emailVerified: true,
          verificationStatus: VerificationStatus.rejected,
          businessName: 'Rym Events Déco',
          categoryId: '9ec8cbe5-ead7-42b4-99d1-fccc49fdad50',
          wilayaCodes: <int>[16],
          documents: <String, String>{
            ProviderDocumentType.nationalId.apiValue: 'approved',
            ProviderDocumentType.commercialRegister.apiValue: 'approved',
            ProviderDocumentType.taxCard.apiValue: 'rejected',
          },
          documentReviews: <String, Map<String, Object?>>{
            ProviderDocumentType.taxCard.apiValue: <String, Object?>{
              'reason': 'name_mismatch',
              'reasonLabel': 'Details do not match the account',
              'note':
                  'The name on the NIF card does not match your account name. Send a card in the same name.',
              'daysAgo': 2,
            },
          },
        ),
        MockAccount(
          id: 'mock-verified-provider',
          role: UserRole.provider,
          fullName: 'Yasmine Haddad',
          email: 'verified.provider@eventor.test',
          phone: '+213555000003',
          password: seedPassword,
          language: 'en',
          emailVerified: true,
          verificationStatus: VerificationStatus.verified,
          businessName: 'Salle Yasmine',
          categoryId: 'bb28c638-c0ea-4140-b9d9-fd5535a6c4b6',
          wilayaCodes: <int>[16],
          documents: <String, String>{
            for (final ProviderDocumentType t in ProviderDocumentType.values)
              t.apiValue: 'approved',
          },
        ),
        MockAccount(
          id: 'mock-unverified',
          role: UserRole.client,
          fullName: 'Nadia Kaci',
          email: 'unverified@eventor.test',
          phone: '+213555000004',
          password: seedPassword,
          language: 'en',
        ),
        MockAccount(
          id: 'mock-blocked',
          role: UserRole.client,
          fullName: 'Blocked User',
          email: 'blocked@eventor.test',
          phone: '+213555000005',
          password: seedPassword,
          language: 'en',
          emailVerified: true,
          blockedMessage:
              'Your account was blocked after repeated no-shows. Contact support to appeal.',
        ),
        // Created by an admin; the password is set from the invite link.
        MockAccount(
          id: 'mock-invited',
          role: UserRole.provider,
          fullName: 'Invited Provider',
          email: 'invited@eventor.test',
          phone: '+213555000006',
          password: null,
          language: 'en',
          businessName: 'Invited Studio',
          categoryId: '7d3855dd-4bd3-430a-9ffc-09d4f269eb4a',
          wilayaCodes: <int>[16],
        ),
      ];

  // ---------------------------------------------------------------- state

  /// Back to the seeded accounts, signed out. The gallery's "Reset mock data".
  Future<void> reset() async {
    _accounts
      ..clear()
      ..addEntries(
        seedAccounts().map(
          (MockAccount a) => MapEntry<String, MockAccount>(a.email, a),
        ),
      );
    _sessionEmail = null;
    _failedLogins.clear();
    _lockedUntil.clear();
    _codeSentAt.clear();
    _providerBookings.clear();
    _clientBookings.clear();
    _stores.clear();
    _seedFavourites();
    _seedBudgets();
    await _save();
  }

  void _restore() {
    final String? raw = _prefs.getString(_storageKey);
    if (raw == null) {
      for (final MockAccount a in seedAccounts()) {
        _accounts[a.email] = a;
      }
      _seedFavourites();
      _seedBudgets();
      return;
    }
    try {
      final Map<String, Object?> json =
          jsonDecode(raw) as Map<String, Object?>;
      for (final Object? a in json['accounts'] as List<Object?>) {
        final MockAccount account =
            MockAccount.fromJson(a! as Map<String, Object?>);
        _accounts[account.email] = account;
      }
      // Seed accounts added since this state was saved.
      for (final MockAccount seed in seedAccounts()) {
        _accounts.putIfAbsent(seed.email, () => seed);
      }
      _sessionEmail = json['session'] as String?;
      final Object? favourites = json['favourites'];
      if (favourites is Map<String, Object?>) {
        favourites.forEach((String email, Object? rows) {
          _favourites[email] = <Map<String, Object?>>[
            for (final Object? row in rows as List<Object?>)
              Map<String, Object?>.of(row! as Map<String, Object?>),
          ];
        });
      } else {
        // State saved before favourites existed.
        _seedFavourites();
      }
      final Object? bookings = json['providerBookings'];
      if (bookings is Map<String, Object?>) {
        bookings.forEach((String email, Object? rows) {
          _providerBookings[email] = <Map<String, Object?>>[
            for (final Object? row in rows as List<Object?>)
              Map<String, Object?>.of(row! as Map<String, Object?>),
          ];
        });
      }
      final Object? clientBookings = json['clientBookings'];
      if (clientBookings is Map<String, Object?>) {
        clientBookings.forEach((String email, Object? rows) {
          _clientBookings[email] = <Map<String, Object?>>[
            for (final Object? row in rows as List<Object?>)
              Map<String, Object?>.of(row! as Map<String, Object?>),
          ];
        });
      }
      final Object? stores = json['stores'];
      if (stores is Map<String, Object?>) {
        stores.forEach((String name, Object? value) {
          if (value is Map<String, Object?>) _stores[name] = value;
        });
      }
      final Object? budgets = json['budgets'];
      if (budgets is Map<String, Object?>) {
        budgets.forEach((String email, Object? budget) {
          _budgets[email] = Map<String, Object?>.of(budget! as Map<String, Object?>);
        });
      } else {
        // State saved before budgets existed.
        _seedBudgets();
      }
    } catch (_) {
      // A state from an older build that no longer parses: start over.
      _accounts.clear();
      for (final MockAccount a in seedAccounts()) {
        _accounts[a.email] = a;
      }
      _seedFavourites();
      _seedBudgets();
    }
  }

  Future<void> _save() => _prefs.setString(
        _storageKey,
        jsonEncode(<String, Object?>{
          'accounts': _accounts.values
              .map((MockAccount a) => a.toJson())
              .toList(),
          'session': _sessionEmail,
          'favourites': _favourites,
          'budgets': _budgets,
          'providerBookings': _providerBookings,
          'clientBookings': _clientBookings,
          'stores': _stores,
        }),
      );

  /// Waits [latency], like a network call.
  Future<void> delay() => latency == Duration.zero
      ? Future<void>.value()
      : Future<void>.delayed(latency);

  int get _nowMs => _now().millisecondsSinceEpoch;

  MockAccount? accountByEmail(String email) =>
      _accounts[email.trim().toLowerCase()];

  MockAccount? get sessionAccount =>
      _sessionEmail == null ? null : _accounts[_sessionEmail];

  bool get hasSession => sessionAccount != null;

  // ---------------------------------------------------------------- rules

  /// The API's password policy: length, letter + digit, not common.
  void checkPassword(String password) {
    if (password.length < InputRules.minPasswordLength ||
        !InputRules.hasLetterAndDigit(password) ||
        commonPasswords.contains(password.toLowerCase())) {
      throw _failure(
        422,
        ApiErrorCode.passwordWeak,
        'This password is too weak.',
        details: <String, Object?>{
          'minLength': InputRules.minPasswordLength,
        },
      );
    }
  }

  /// Registers an unverified account and "sends" the code.
  Future<void> register({
    required UserRole role,
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String language,
    int? wilayaCode,
    String? businessName,
    String? categoryId,
    List<int> wilayaCodes = const <int>[],
    required bool Function(String categoryId) categoryExists,
    required bool Function(int code) wilayaExists,
  }) async {
    final String normalisedEmail = email.trim().toLowerCase();
    final String? local = InputRules.normalisePhone(phone);
    if (local == null || !InputRules.emailPattern.hasMatch(normalisedEmail)) {
      throw _failure(400, ApiErrorCode.validationFailed, 'Some fields are invalid.');
    }
    final String storedPhone = '+213${local.substring(1)}';

    checkPassword(password);

    final bool isProvider = role == UserRole.provider;
    if (isProvider &&
        ((businessName ?? '').trim().isEmpty || categoryId == null)) {
      throw _failure(422, ApiErrorCode.providerFieldsRequired,
          'A provider needs a business name and a category.');
    }
    if (!isProvider && (businessName != null || categoryId != null)) {
      throw _failure(422, 'PROVIDER_FIELDS_NOT_ALLOWED',
          'Only a provider has business fields.');
    }
    if (categoryId != null && !categoryExists(categoryId)) {
      throw _failure(404, ApiErrorCode.categoryNotFound, 'Category not found.');
    }
    for (final int code in <int>[?wilayaCode, ...wilayaCodes]) {
      if (!wilayaExists(code)) {
        throw _failure(404, ApiErrorCode.wilayaNotFound, 'Wilaya not found.');
      }
    }
    if (_accounts.containsKey(normalisedEmail)) {
      throw _failure(409, ApiErrorCode.emailTaken,
          'An account already uses this email.');
    }
    if (_accounts.values.any((MockAccount a) => a.phone == storedPhone)) {
      throw _failure(409, ApiErrorCode.phoneTaken,
          'An account already uses this phone number.');
    }

    _accounts[normalisedEmail] = MockAccount(
      id: 'mock-${_nowMs.toRadixString(36)}',
      role: role,
      fullName: fullName.trim(),
      email: normalisedEmail,
      phone: storedPhone,
      password: password,
      language: language,
      wilayaCode: wilayaCode,
      businessName: businessName?.trim(),
      categoryId: categoryId,
      wilayaCodes: wilayaCodes,
    );
    _codeSentAt[normalisedEmail] = _nowMs;
    await _save();
  }

  /// Checks an emailed code: [code] passes, [expiredCode] is expired, anything
  /// else is wrong.
  void checkCode(String submitted) {
    if (submitted == expiredCode) {
      throw _failure(422, ApiErrorCode.codeExpired,
          'The verification code has expired. Ask for a new one.');
    }
    if (submitted != code) {
      throw _failure(
          422, ApiErrorCode.codeInvalid, 'The verification code is incorrect.');
    }
  }

  Future<MockAccount> verifyEmail(String email, String submitted) async {
    final MockAccount? account = accountByEmail(email);
    if (account == null) {
      throw _failure(
          422, ApiErrorCode.codeInvalid, 'The verification code is incorrect.');
    }
    checkCode(submitted);
    if (account.blockedMessage != null) throw _blocked(account);
    account.emailVerified = true;
    _sessionEmail = account.email;
    await _save();
    return account;
  }

  /// A new code, at most one per [resendCooldownSeconds]. Unknown addresses
  /// get the same answer, as on the server.
  int resend(String email) {
    final String key = email.trim().toLowerCase();
    final int? last = _codeSentAt[key];
    if (last != null) {
      final int wait = resendCooldownSeconds - ((_nowMs - last) ~/ 1000);
      if (wait > 0) {
        throw _failure(429, ApiErrorCode.codeResendTooSoon,
            'A code was just sent. Try again in $wait seconds.',
            details: <String, Object?>{'retryAfterSeconds': wait});
      }
    }
    _codeSentAt[key] = _nowMs;
    return resendCooldownSeconds;
  }

  Future<MockAccount> login(String email, String password) async {
    final String key = email.trim().toLowerCase();
    final int? until = _lockedUntil[key];
    if (until != null && until > _nowMs) {
      throw _failure(429, ApiErrorCode.accountLocked,
          'Too many failed attempts. Try again later.',
          details: <String, Object?>{
            'retryAfterSeconds': ((until - _nowMs) / 1000).ceil(),
          });
    }

    final MockAccount? account = _accounts[key];
    if (account == null || account.password != password) {
      final int windowStart = _nowMs - lockDuration.inMilliseconds;
      final List<int> attempts = (_failedLogins[key] ?? <int>[])
        ..removeWhere((int t) => t < windowStart)
        ..add(_nowMs);
      _failedLogins[key] = attempts;
      // Like the server: the 5th failure is still a 401, and it arms the lock
      // the 6th attempt runs into.
      if (attempts.length >= maxFailedLogins) {
        _lockedUntil[key] = _nowMs + lockDuration.inMilliseconds;
        _failedLogins.remove(key);
      }
      throw _failure(401, ApiErrorCode.invalidCredentials,
          'The email or password is incorrect.');
    }

    _failedLogins.remove(key);
    if (account.blockedMessage != null) throw _blocked(account);
    if (!account.emailVerified) {
      throw _failure(403, ApiErrorCode.emailNotVerified,
          'Verify your email address before signing in.',
          details: <String, Object?>{'email': account.email});
    }
    _sessionEmail = account.email;
    await _save();
    return account;
  }

  /// Screen 10's check: the same rules as [resetPassword], nothing spent.
  void verifyResetCode(String email, String submitted) {
    if (accountByEmail(email) == null) {
      throw _failure(
          422, ApiErrorCode.codeInvalid, 'The verification code is incorrect.');
    }
    checkCode(submitted);
  }

  Future<void> resetPassword(
    String email,
    String submitted,
    String password,
  ) async {
    final MockAccount? account = accountByEmail(email);
    if (account == null) {
      throw _failure(
          422, ApiErrorCode.codeInvalid, 'The verification code is incorrect.');
    }
    checkCode(submitted);
    checkPassword(password);
    if (account.blockedMessage != null) throw _blocked(account);
    account.password = password;
    // Every session is revoked, this device's included.
    _sessionEmail = null;
    await _save();
  }

  Future<MockAccount> setPassword(String token, String password) async {
    if (token == expiredInviteToken) {
      throw _failure(410, ApiErrorCode.resetTokenExpired,
          'This link has expired. Ask for a new one.');
    }
    final MockAccount? invited = accountByEmail('invited@eventor.test');
    if (token != validInviteToken || invited == null) {
      throw _failure(
          400, ApiErrorCode.resetTokenInvalid, 'This link is not valid.');
    }
    if (invited.password != null) {
      // Single use, as on the server.
      throw _failure(
          400, ApiErrorCode.resetTokenInvalid, 'This link is not valid.');
    }
    checkPassword(password);
    invited
      ..password = password
      ..emailVerified = true;
    _sessionEmail = invited.email;
    await _save();
    return invited;
  }

  Future<void> signOut() async {
    _sessionEmail = null;
    await _save();
  }

  // ----------------------------------------------------------- favourites

  static const String _seededFavouritesEmail = 'client@eventor.test';

  /// The seeded client starts with a few saved items, one of them no longer
  /// listed, so screen 17 has something to show.
  void _seedFavourites() {
    _favourites.clear();
    final int now = _nowMs;
    _favourites[_seededFavouritesEmail] = <Map<String, Object?>>[
      for (final (int i, Map<String, Object?> seed)
          in mockFavouriteSeeds.indexed)
        <String, Object?>{
          'id': 'mock-fav-${i + 1}',
          'kind': seed['kind'],
          'targetId': seed['targetId'],
          'createdAt': now -
              Duration(days: (seed['daysAgo']! as num).toInt()).inMilliseconds,
        },
    ];
  }

  /// A client's saved rows, newest first. A provider is refused, as live.
  List<Map<String, Object?>> favouriteRows() {
    final MockAccount account = _requireClient();
    final List<Map<String, Object?>> rows =
        _favourites[account.email] ?? <Map<String, Object?>>[];
    return List<Map<String, Object?>>.of(rows)
      ..sort(
        (Map<String, Object?> a, Map<String, Object?> b) =>
            (b['createdAt']! as num).compareTo(a['createdAt']! as num),
      );
  }

  /// Saves [targetId]; saving it again returns the same row.
  Future<Map<String, Object?>> addFavourite(String kind, String targetId) async {
    final MockAccount account = _requireClient();
    final List<Map<String, Object?>> rows =
        _favourites.putIfAbsent(account.email, () => <Map<String, Object?>>[]);
    for (final Map<String, Object?> row in rows) {
      if (row['kind'] == kind && row['targetId'] == targetId) return row;
    }
    final Map<String, Object?> row = <String, Object?>{
      'id': 'mock-fav-$_nowMs-${rows.length}',
      'kind': kind,
      'targetId': targetId,
      'createdAt': _nowMs,
    };
    rows.add(row);
    await _save();
    return row;
  }

  /// `DELETE /app/me/favourites?serviceId=|packId=` — idempotent, like live.
  Future<void> removeFavouriteByTarget(String kind, String targetId) async {
    final MockAccount account = _requireClient();
    _favourites[account.email]?.removeWhere(
      (Map<String, Object?> row) =>
          row['kind'] == kind && row['targetId'] == targetId,
    );
    await _save();
  }

  /// `DELETE /app/me/favourites/{id}`.
  Future<void> removeFavourite(String id) async {
    final MockAccount account = _requireClient();
    final List<Map<String, Object?>>? rows = _favourites[account.email];
    final int before = rows?.length ?? 0;
    rows?.removeWhere((Map<String, Object?> row) => row['id'] == id);
    if ((rows?.length ?? 0) == before) {
      throw _failure(404, ApiErrorCode.favouriteNotFound, 'No such favourite.');
    }
    await _save();
  }

  // --------------------------------------------------------------- budget

  /// The seeded client starts with the budget drawn on 18, so every state of
  /// section 7 is one tap away; everyone else starts on 11c.
  void _seedBudgets() {
    _budgets
      ..clear()
      ..[_seededFavouritesEmail] = mockSeedBudget(_now());
  }

  /// The signed-in client's budget, or `null` before they create one. A
  /// provider is refused, as live.
  Map<String, Object?>? budget() => _budgets[_requireClient().email];

  /// `DELETE /app/me/budget` — as the backend is asked to build it.
  Future<void> deleteBudget() async {
    _budgets.remove(_requireClient().email);
    await _save();
  }

  Future<void> putBudget(Map<String, Object?> budget) async {
    _budgets[_requireClient().email] = budget;
    await _save();
  }

  MockAccount _requireClient() {
    final MockAccount account = requireSession();
    if (account.role != UserRole.client) {
      throw _failure(
        403,
        ApiErrorCode.forbiddenRole,
        'Your account role cannot access this.',
      );
    }
    return account;
  }

  /// Now, as the backend's clock sees it — for relative dates in mock data.
  DateTime get now => _now();

  /// `PATCH /app/me {wilayaCode}`.
  Future<MockAccount> setWilaya(int code) async {
    final MockAccount account = requireSession();
    if (!mockWilayas.any((Wilaya w) => w.code == code)) {
      throw _failure(404, ApiErrorCode.wilayaNotFound, 'Unknown wilaya.');
    }
    account.wilayaCode = code;
    await _save();
    return account;
  }

  Future<void> setDocument(ProviderDocumentType type, String status) async {
    final MockAccount? account = sessionAccount;
    if (account == null) return;
    account.documents[type.apiValue] = status;
    // A new version wipes the old verdict.
    account.documentReviews.remove(type.apiValue);
    // status-rules §2: the account follows its current documents.
    final List<String?> statuses = <String?>[
      for (final ProviderDocumentType t in ProviderDocumentType.values)
        account.documents[t.apiValue],
    ];
    account.verificationStatus = statuses.contains('rejected')
        ? VerificationStatus.rejected
        : statuses.every((String? s) => s == 'approved')
            ? VerificationStatus.verified
            : VerificationStatus.pending;
    await _save();
  }

  // --------------------------------------------------------------- client

  /// Each client's bookings, per account email, as the mock's own stored
  /// records (see `mock_bookings.dart`) — rendered per request, in the
  /// request's language.
  final Map<String, List<Map<String, Object?>>> _clientBookings =
      <String, List<Map<String, Object?>>>{};

  /// The signed-in client's booking records. Seeded lazily from [seed] the
  /// first time, so every restore of an older state still has them.
  List<Map<String, Object?>> clientBookings(
    List<Map<String, Object?>> Function(MockAccount account) seed,
  ) {
    final MockAccount account = requireSession();
    return _clientBookings.putIfAbsent(account.email, () => seed(account));
  }

  Future<void> saveClientBookings() => _save();

  // ------------------------------------------------------------- provider

  /// Requests and bookings made to each provider, per account email, as
  /// `AppBookingCardDto` rows.
  final Map<String, List<Map<String, Object?>>> _providerBookings =
      <String, List<Map<String, Object?>>>{};

  /// The signed-in provider's bookings. Seeded lazily from [seed] the first
  /// time a verified provider asks, so every verified account has 21 as
  /// drawn.
  List<Map<String, Object?>> providerBookings(
    List<Map<String, Object?>> Function() seed,
  ) {
    final MockAccount account = requireProvider();
    return _providerBookings.putIfAbsent(account.email, seed);
  }

  Future<void> saveProvider() => _save();

  // ---------------------------------------------------------------- stores

  /// Named pieces of state for features the backend does not model field by
  /// field — the shared bookings, a provider's services, packs and
  /// availability blocks. Persisted with everything else, cleared by [reset].
  final Map<String, Map<String, Object?>> _stores = <String, Map<String, Object?>>{};

  /// The store called [name], created by [seed] the first time it is asked
  /// for. Change it in place, then call [saveStores]. JSON types only: it
  /// comes back from storage as decoded JSON.
  Map<String, Object?> store(String name, Map<String, Object?> Function() seed) =>
      _stores.putIfAbsent(name, seed);

  Future<void> saveStores() => _save();

  MockAccount requireProvider() {
    final MockAccount account = requireSession();
    if (account.role != UserRole.provider) {
      throw _failure(
        422,
        ApiErrorCode.notAProvider,
        'This action is only available for provider accounts.',
      );
    }
    return account;
  }

  MockAccount requireSession() {
    final MockAccount? account = sessionAccount;
    if (account == null) throw const SessionExpiredFailure();
    return account;
  }

  ApiFailure _blocked(MockAccount account) => _failure(
        403,
        ApiErrorCode.accountBlocked,
        'This account is blocked.',
        details: <String, Object?>{
          'message': account.blockedMessage,
          'blockedUntil': DateTime.fromMillisecondsSinceEpoch(_nowMs)
              .add(const Duration(days: 14))
              .toUtc()
              .toIso8601String(),
        },
      );

  ApiFailure _failure(
    int status,
    String code,
    String message, {
    Map<String, Object?>? details,
  }) =>
      ApiFailure(
        statusCode: status,
        code: code,
        message: message,
        details: details,
      );
}

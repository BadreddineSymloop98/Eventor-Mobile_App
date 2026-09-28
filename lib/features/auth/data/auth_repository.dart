import '../../../core/models/account.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/token_store.dart';

/// A verification code was emailed — what register, resend and the login
/// "send a new code" link all return.
class CodeSent {
  const CodeSent({
    required this.email,
    required this.resendAfterSeconds,
    this.expiresAt,
  });

  factory CodeSent.fromJson(Map<String, Object?> json) => CodeSent(
        email: json['email'] as String? ?? json['emailSentTo'] as String? ?? '',
        resendAfterSeconds: (json['resendAfterSeconds'] as num?)?.toInt() ??
            defaultResendSeconds,
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      );

  /// The server's own cooldown today, used until it says otherwise.
  static const int defaultResendSeconds = 60;

  final String email;

  /// How long before another code may be asked for.
  final int resendAfterSeconds;
  final DateTime? expiresAt;
}

/// What sign-up sends. Provider-only fields are `null` for a client — the API
/// refuses them from a client (`PROVIDER_FIELDS_NOT_ALLOWED`).
class RegistrationRequest {
  const RegistrationRequest({
    required this.role,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.language,
    this.wilayaCode,
    this.businessName,
    this.categoryId,
    this.wilayaCodes = const <int>[],
  });

  final UserRole role;
  final String fullName;
  final String email;

  /// Normalised to `0XXXXXXXXX` or `+213XXXXXXXXX` — see `InputRules`.
  final String phone;
  final String password;

  /// `en` or `ar` — the language the account's emails are sent in.
  final String language;
  final int? wilayaCode;
  final String? businessName;
  final String? categoryId;
  final List<int> wilayaCodes;

  Map<String, Object?> toJson() => <String, Object?>{
        'role': role.apiValue,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'language': language,
        if (wilayaCode != null) 'wilayaCode': wilayaCode,
        if (role == UserRole.provider) ...<String, Object?>{
          'businessName': businessName,
          'categoryId': categoryId,
          if (wilayaCodes.isNotEmpty) 'wilayaCodes': wilayaCodes,
        },
      };
}

/// Everything about getting into — and out of — an account.
///
/// Every call that ends in a session stores the tokens itself and returns the
/// [AppUser]; the session controller only ever sees who is signed in, never a
/// token.
abstract interface class AuthRepository {
  /// Creates an unverified account and emails a 6-digit code. No session yet.
  Future<CodeSent> register(RegistrationRequest request);

  /// Confirms the email with its code, and signs in.
  Future<AppUser> verifyEmail({required String email, required String code});

  Future<CodeSent> resendVerification(String email);

  Future<AppUser> login({required String email, required String password});

  /// Always succeeds from the caller's point of view — the server answers the
  /// same whether or not the address has an account.
  Future<void> forgotPassword(String email);

  /// Checks a reset code without spending it, so 10 can refuse it before 10a
  /// asks for a password. A wrong code still counts as an attempt.
  Future<void> verifyResetCode({required String email, required String code});

  /// Sets a new password with the emailed code. Every session is revoked, so
  /// the user signs in again afterwards.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  });

  /// Sets the password of an account an admin created, from its invite link,
  /// and signs in.
  Future<AppUser> setPassword({required String token, required String password});

  /// Renews a stored session and loads who it belongs to, or `null` when there
  /// is none — the app start.
  Future<AppUser?> restoreSession();

  Future<AppUser> currentUser();

  /// Saves the client's city — Home's wilaya pill. A permanent profile
  /// change: the API has no per-session override.
  Future<AppUser> updateWilaya(int wilayaCode);

  /// Ends the session on the server as well as on the device. Never throws —
  /// signing out must work offline.
  Future<void> logout();
}

/// [AuthRepository] against the live API.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  @override
  Future<CodeSent> register(RegistrationRequest request) async {
    final Object? data = await _api.post(
      '/app/auth/register',
      body: request.toJson(),
      isPublic: true,
    );
    return CodeSent.fromJson(_map(data));
  }

  @override
  Future<AppUser> verifyEmail({
    required String email,
    required String code,
  }) async {
    final Object? data = await _api.post(
      '/app/auth/verify-email',
      body: <String, Object?>{'email': email, 'code': code},
      isPublic: true,
    );
    return _startSession(data);
  }

  @override
  Future<CodeSent> resendVerification(String email) async {
    final Object? data = await _api.post(
      '/app/auth/verify-email/resend',
      body: <String, Object?>{'email': email},
      isPublic: true,
    );
    return CodeSent.fromJson(_map(data));
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final Object? data = await _api.post(
      '/app/auth/login',
      body: <String, Object?>{'email': email, 'password': password},
      isPublic: true,
    );
    return _startSession(data);
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _api.post(
      '/app/auth/forgot',
      body: <String, Object?>{'email': email},
      isPublic: true,
    );
  }

  @override
  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    await _api.post(
      '/app/auth/reset/verify',
      body: <String, Object?>{'email': email, 'code': code},
      isPublic: true,
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    await _api.post(
      '/app/auth/reset',
      body: <String, Object?>{
        'email': email,
        'code': code,
        'password': password,
      },
      isPublic: true,
    );
    // The server has just revoked every session, this device's included.
    await _tokens.clear();
  }

  @override
  Future<AppUser> setPassword({
    required String token,
    required String password,
  }) async {
    final Object? data = await _api.post(
      '/app/auth/set-password',
      body: <String, Object?>{'token': token, 'password': password},
      isPublic: true,
    );
    return _startSession(data);
  }

  @override
  Future<AppUser?> restoreSession() async {
    if (!_tokens.hasSession) return null;
    if (!await _api.restoreSession()) {
      // Refused (signed out elsewhere, expired) or unreachable. A refusal has
      // already cleared the tokens; unreachable keeps them for the next try.
      if (!_tokens.hasSession) return null;
    }
    return currentUser();
  }

  @override
  Future<AppUser> currentUser() async {
    final Object? data = await _api.get('/app/me');
    return AppUser.fromJson(_map(data));
  }

  @override
  Future<AppUser> updateWilaya(int wilayaCode) async {
    final Object? data = await _api.patch(
      '/app/me',
      body: <String, Object?>{'wilayaCode': wilayaCode},
    );
    // The update answers with the account; if it ever stops doing so, read
    // it back rather than guess.
    return data is Map<String, Object?> && data['id'] is String
        ? AppUser.fromJson(data)
        : currentUser();
  }

  @override
  Future<void> logout() async {
    final String? refreshToken = _tokens.refreshToken;
    try {
      await _api.post(
        '/app/auth/logout',
        body: <String, Object?>{
          'refreshToken': ?refreshToken,
        },
        isPublic: true,
      );
    } catch (_) {
      // Offline or already revoked: the device forgets the session anyway.
    }
    await _tokens.clear();
  }

  Future<AppUser> _startSession(Object? data) async {
    final Map<String, Object?> session = _map(data);
    await _tokens.save(
      accessToken: session['accessToken']! as String,
      refreshToken: session['refreshToken']! as String,
    );
    return AppUser.fromJson(_map(session['user']));
  }

  static Map<String, Object?> _map(Object? data) =>
      data is Map<String, Object?> ? data : const <String, Object?>{};
}

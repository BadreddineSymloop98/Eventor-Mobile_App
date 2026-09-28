import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/failure.dart';

/// The session's two tokens.
///
/// Both live in the OS keychain / keystore, never in SharedPreferences, which
/// is plaintext on disk — the refresh token is good for 30 days. They are also
/// held in memory, because the access token is read on every request and the
/// secure store is slow.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessKey = 'eventor.access_token';
  static const String _refreshKey = 'eventor.refresh_token';

  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  bool get hasSession => _refreshToken != null;

  /// Reads whatever a previous launch left behind. Call once, before the
  /// first request.
  ///
  /// A store that cannot be read — a keystore reset after a device restore is
  /// the usual cause — is treated as no session rather than as a crash.
  Future<void> load() async {
    try {
      _accessToken = await _storage.read(key: _accessKey);
      _refreshToken = await _storage.read(key: _refreshKey);
    } catch (_) {
      _accessToken = null;
      _refreshToken = null;
      await clear();
    }
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    try {
      await _storage.write(key: _accessKey, value: accessToken);
      await _storage.write(key: _refreshKey, value: refreshToken);
    } catch (error) {
      throw StorageFailure(cause: error);
    }
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (_) {
      // Nothing left to protect if it cannot even be deleted; the in-memory
      // copies are already gone, which is what signs the user out.
    }
  }
}

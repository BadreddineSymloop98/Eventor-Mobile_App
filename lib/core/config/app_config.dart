import '../network/api_client.dart';

/// What the server tells the app about itself — `GET /app/config`.
///
/// Loaded on the splash. Every field has a built-in fallback equal to today's
/// live value, so a failed load (offline on a cold start) still leaves a
/// working app rather than a blocked one.
class AppConfig {
  const AppConfig({
    this.minAppVersion = '1.0.0',
    this.maintenanceMode = false,
    this.maintenanceMessage,
    this.supportEmail,
    this.termsUrl,
    this.privacyUrl,
    this.passwordMinLength = 10,
    this.passwordNeedsLetterAndDigit = true,
    this.maxDocumentMb = 5,
    this.bookingMinNoticeDays = 1,
  });

  factory AppConfig.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> password =
        _object(json['passwordPolicy']) ?? const <String, Object?>{};
    final Map<String, Object?> uploads =
        _object(json['uploads']) ?? const <String, Object?>{};
    final Map<String, Object?> booking =
        _object(json['booking']) ?? const <String, Object?>{};
    const AppConfig fallback = AppConfig();

    // Each field is read on its own terms: one of the wrong type falls back
    // alone instead of throwing away the whole config.
    return AppConfig(
      minAppVersion: _string(json['minAppVersion']) ?? fallback.minAppVersion,
      maintenanceMode: _bool(json['maintenanceMode']) ?? false,
      maintenanceMessage: _string(json['maintenanceMessage']),
      supportEmail: _nonEmpty(json['supportEmail']),
      termsUrl: _nonEmpty(json['termsUrl']),
      privacyUrl: _nonEmpty(json['privacyUrl']),
      passwordMinLength:
          _int(password['minLength']) ?? fallback.passwordMinLength,
      passwordNeedsLetterAndDigit: _bool(password['needsLetterAndDigit']) ??
          fallback.passwordNeedsLetterAndDigit,
      maxDocumentMb: _int(uploads['maxDocumentMb']) ?? fallback.maxDocumentMb,
      bookingMinNoticeDays:
          _int(booking['minNoticeDays']) ?? fallback.bookingMinNoticeDays,
    );
  }

  static String? _string(Object? value) => value is String ? value : null;
  static bool? _bool(Object? value) => value is bool ? value : null;
  static int? _int(Object? value) => value is num ? value.toInt() : null;

  final String minAppVersion;
  final bool maintenanceMode;

  /// Already in the request's language.
  final String? maintenanceMessage;

  /// `null` live today — which is why "Contact support" hides itself.
  final String? supportEmail;
  final String? termsUrl;
  final String? privacyUrl;

  /// The password rule, stated by the server so the app and the API cannot
  /// disagree about it.
  final int passwordMinLength;
  final bool passwordNeedsLetterAndDigit;

  final int maxDocumentMb;

  /// How many days ahead a booking must be requested — "Dates need at least
  /// 1 day's notice". Stated by the server; the design's "3 days" was a
  /// placeholder.
  final int bookingMinNoticeDays;

  static Map<String, Object?>? _object(Object? value) =>
      value is Map<String, Object?> ? value : null;

  static String? _nonEmpty(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;
}

/// Loads and holds the [AppConfig].
///
/// Starts on the fallback values, so anything that reads it before the load
/// finishes still gets a sensible answer.
class AppConfigRepository {
  AppConfigRepository(this._api);

  final ApiClient _api;

  AppConfig _config = const AppConfig();
  AppConfig get current => _config;

  /// Refreshes from the server. Never throws: a failure keeps the fallback.
  Future<AppConfig> load() async {
    try {
      final Object? data = await _api.get('/app/config', isPublic: true);
      if (data is Map<String, Object?>) _config = AppConfig.fromJson(data);
    } catch (_) {
      // Offline on a cold start — the fallback is today's live config.
    }
    return _config;
  }
}

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
    this.supportEmail = 'support@eventor.dz',
    this.supportPhone = '+213 555 00 00 00',
    this.termsUrl = 'https://admin.eventor.72-60-190-211.sslip.io/en/legal/terms',
    this.privacyUrl =
        'https://admin.eventor.72-60-190-211.sslip.io/en/legal/privacy',
    this.passwordMinLength = 10,
    this.passwordNeedsLetterAndDigit = true,
    this.maxDocumentMb = 5,
    this.maxPhotoMb = 10,
    this.imageTypes = const <String>['jpeg', 'png', 'webp', 'heic'],
    this.bookingMinNoticeDays = 1,
    this.bookingReplyDeadlineHours = 48,
    this.budgetItemsMax = 60,
    this.messageMaxLength = 4000,
    this.photosPerService = 12,
    this.photosPerPack = 6,
    this.documentExtensions = const <String>[
      'pdf',
      'jpg',
      'jpeg',
      'png',
      'webp',
      'heic',
      'heif',
    ],
  });

  factory AppConfig.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> password =
        _object(json['passwordPolicy']) ?? const <String, Object?>{};
    final Map<String, Object?> uploads =
        _object(json['uploads']) ?? const <String, Object?>{};
    final Map<String, Object?> booking =
        _object(json['booking']) ?? const <String, Object?>{};
    final Map<String, Object?> limits =
        _object(json['limits']) ?? const <String, Object?>{};
    const AppConfig fallback = AppConfig();

    // Each field is read on its own terms: one of the wrong type falls back
    // alone instead of throwing away the whole config.
    return AppConfig(
      minAppVersion: _string(json['minAppVersion']) ?? fallback.minAppVersion,
      maintenanceMode: _bool(json['maintenanceMode']) ?? false,
      maintenanceMessage: _string(json['maintenanceMessage']),
      supportEmail: _nonEmpty(json['supportEmail']),
      supportPhone: _nonEmpty(json['supportPhone']),
      termsUrl: _nonEmpty(json['termsUrl']),
      privacyUrl: _nonEmpty(json['privacyUrl']),
      passwordMinLength:
          _int(password['minLength']) ?? fallback.passwordMinLength,
      passwordNeedsLetterAndDigit: _bool(password['needsLetterAndDigit']) ??
          fallback.passwordNeedsLetterAndDigit,
      maxDocumentMb: _int(uploads['maxDocumentMb']) ?? fallback.maxDocumentMb,
      maxPhotoMb: _int(uploads['maxPhotoMb']) ?? fallback.maxPhotoMb,
      imageTypes: _stringList(uploads['imageTypes']) ?? fallback.imageTypes,
      bookingMinNoticeDays:
          _int(booking['minNoticeDays']) ?? fallback.bookingMinNoticeDays,
      bookingReplyDeadlineHours: _int(booking['replyDeadlineHours']) ??
          fallback.bookingReplyDeadlineHours,
      budgetItemsMax: _int(limits['budgetItemsMax']) ?? fallback.budgetItemsMax,
      messageMaxLength:
          _int(limits['messageMaxLength']) ?? fallback.messageMaxLength,
      photosPerService: _int(limits['photosPerService']) ??
          _int(uploads['maxPhotosPerService']) ??
          fallback.photosPerService,
      photosPerPack: _int(limits['photosPerPack']) ?? fallback.photosPerPack,
      documentExtensions: _stringList(limits['documentAcceptedExtensions']) ??
          fallback.documentExtensions,
    );
  }

  static String? _string(Object? value) => value is String ? value : null;
  static bool? _bool(Object? value) => value is bool ? value : null;
  static int? _int(Object? value) => value is num ? value.toInt() : null;

  /// A `List` of lower-cased `String`s, or `null` for anything else — the
  /// wrong type, or a list with nothing usable in it — so the caller falls
  /// back to the default extensions.
  static List<String>? _stringList(Object? value) {
    if (value is! List<Object?>) return null;
    final List<String> strings =
        value.whereType<String>().map((String s) => s.toLowerCase()).toList();
    return strings.isEmpty ? null : strings;
  }

  final String minAppVersion;
  final bool maintenanceMode;

  /// Already in the request's language.
  final String? maintenanceMessage;

  /// "Contact support" hides itself while the server sends none.
  final String? supportEmail;

  /// For the blocked provider's "Contact support" (21c).
  final String? supportPhone;
  final String? termsUrl;
  final String? privacyUrl;

  /// The password rule, stated by the server so the app and the API cannot
  /// disagree about it.
  final int passwordMinLength;
  final bool passwordNeedsLetterAndDigit;

  final int maxDocumentMb;

  /// A photo attached to a chat message or a gallery upload — separate from
  /// [maxDocumentMb], which governs verification documents.
  final int maxPhotoMb;

  /// The extensions the gallery and camera pickers filter to, lower-cased.
  final List<String> imageTypes;

  /// How many days ahead a booking must be requested — "Dates need at least
  /// 1 day's notice". Stated by the server; the design's "3 days" was a
  /// placeholder.
  final int bookingMinNoticeDays;

  /// How long a provider has to answer a request before it lapses — the
  /// "reply within 47 h" on 21.
  final int bookingReplyDeadlineHours;

  // The business `limits` (since 2026-09-27) — what the app enforces before
  // the server would refuse.

  /// Lines a budget may hold (422 `BUDGET_ITEM_LIMIT` past it).
  final int budgetItemsMax;

  /// The longest message body anywhere a message can be sent.
  final int messageMaxLength;

  /// How many photos a service (P8) and a pack (P13) may hold.
  final int photosPerService;
  final int photosPerPack;

  /// What a verification document may be, as file extensions, lower-cased.
  final List<String> documentExtensions;

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

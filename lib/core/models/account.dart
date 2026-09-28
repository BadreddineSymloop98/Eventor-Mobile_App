/// The account types the app serves.
///
/// The API's own names. Academic is not an app role — institutions use the
/// public web form — and `admin` is refused at sign-in, so neither appears
/// here.
enum UserRole {
  client('client'),
  provider('provider');

  const UserRole(this.apiValue);

  final String apiValue;

  static UserRole? fromApi(String? value) {
    for (final UserRole role in values) {
      if (role.apiValue == value) return role;
    }
    return null;
  }
}

/// Where an account stands in review.
///
/// Clients are [notRequired]; providers start [pending] and move to
/// [verified] or [rejected] as their documents are reviewed.
enum VerificationStatus {
  notRequired('not_required'),
  pending('pending'),
  verified('verified'),
  rejected('rejected');

  const VerificationStatus(this.apiValue);

  final String apiValue;

  static VerificationStatus fromApi(String? value) {
    for (final VerificationStatus status in values) {
      if (status.apiValue == value) return status;
    }
    return VerificationStatus.notRequired;
  }
}

/// A wilaya — one of Algeria's 58 provinces — as the API names it.
class Wilaya {
  const Wilaya({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    this.servicesCount = 0,
  });

  factory Wilaya.fromJson(Map<String, Object?> json) => Wilaya(
        code: (json['code']! as num).toInt(),
        nameEn: json['nameEn'] as String? ?? json['name'] as String? ?? '',
        nameAr: json['nameAr'] as String? ?? json['name'] as String? ?? '',
        servicesCount: (json['servicesCount'] as num? ?? 0).toInt(),
      );

  final int code;
  final String nameEn;
  final String nameAr;

  /// Services in the app that cover it — what 11a's top wilayas rank by.
  /// `0` where the API does not say (an account's own wilaya).
  final int servicesCount;

  /// The name in [languageCode], falling back to English.
  String nameFor(String languageCode) =>
      languageCode == 'ar' && nameAr.isNotEmpty ? nameAr : nameEn;

  @override
  bool operator ==(Object other) => other is Wilaya && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// A commune of a wilaya — where exactly an event takes place (B1).
class Commune {
  const Commune({
    required this.id,
    required this.wilayaCode,
    required this.nameEn,
    required this.nameAr,
    this.postalCode,
  });

  factory Commune.fromJson(Map<String, Object?> json) => Commune(
        id: json['id']! as String,
        wilayaCode: (json['wilayaCode'] as num? ?? 0).toInt(),
        nameEn: json['nameEn'] as String? ?? json['name'] as String? ?? '',
        nameAr: json['nameAr'] as String? ?? '',
        postalCode: json['postalCode'] as String?,
      );

  final String id;
  final int wilayaCode;
  final String nameEn;
  final String nameAr;
  final String? postalCode;

  String nameFor(String languageCode) =>
      languageCode == 'ar' && nameAr.isNotEmpty ? nameAr : nameEn;

  @override
  bool operator ==(Object other) => other is Commune && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A service category — the provider picks theirs at sign-up.
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.nameEn,
    required this.nameAr,
  });

  factory ServiceCategory.fromJson(Map<String, Object?> json) =>
      ServiceCategory(
        id: json['id']! as String,
        nameEn: json['nameEn'] as String? ?? json['name'] as String? ?? '',
        nameAr: json['nameAr'] as String? ?? '',
      );

  final String id;
  final String nameEn;

  /// Can be empty on the server — "Beauty" is live with no Arabic name — so
  /// [nameFor] falls back to English rather than showing a blank row.
  final String nameAr;

  String nameFor(String languageCode) =>
      languageCode == 'ar' && nameAr.isNotEmpty ? nameAr : nameEn;

  @override
  bool operator ==(Object other) => other is ServiceCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// The signed-in account — the parts of `AppMeDto` the app reads.
class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    required this.isBlocked,
    required this.verificationStatus,
    required this.fullName,
    required this.email,
    required this.emailVerified,
    required this.language,
    this.phone,
    this.wilaya,
  });

  factory AppUser.fromJson(Map<String, Object?> json) {
    final Object? wilaya = json['wilaya'];
    return AppUser(
      id: json['id']! as String,
      // An admin never gets this far — sign-in refuses them — so an unknown
      // role is read as client rather than crashing the session.
      role: UserRole.fromApi(json['role'] as String?) ?? UserRole.client,
      isBlocked: json['status'] == 'blocked',
      verificationStatus: VerificationStatus.fromApi(
        json['verificationStatus'] as String?,
      ),
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      emailVerified: json['emailVerified'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      phone: json['phone'] as String?,
      wilaya: wilaya is Map<String, Object?> ? Wilaya.fromJson(wilaya) : null,
    );
  }

  final String id;
  final UserRole role;
  final bool isBlocked;
  final VerificationStatus verificationStatus;
  final String fullName;
  final String email;
  final bool emailVerified;
  final String language;

  /// As the server stores it: `+213XXXXXXXXX`.
  final String? phone;
  final Wilaya? wilaya;

  bool get isProvider => role == UserRole.provider;
}

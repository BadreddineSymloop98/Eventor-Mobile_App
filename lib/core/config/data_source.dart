/// Where the app's data comes from, fixed at build time.
///
/// ```
/// flutter run                                  # mock (default)
/// flutter run --dart-define=EVENTOR_DATA=live  # the real backend
/// flutter build apk --dart-define=EVENTOR_DATA=live
/// ```
///
/// Mock is the default while the live backend has open issues — it accepts a
/// sign-up but never delivers the email, so nothing behind an emailed code can
/// be used live. Once that is fixed, flip [_defaultFlag] to `live`; later the
/// whole `lib/mock/` folder can go.
///
/// Only `AppServices` reads this. Screens, view models and the router cannot
/// tell which source is behind the repositories — with one exception: the
/// code screens show "the code is always 123456" in mock builds, because a
/// tester would otherwise have no way to know it.
enum DataSource {
  /// In-app fake backend (`lib/mock/`): seeded accounts, fixed codes, the API's
  /// own rules and error codes, persisted on the device.
  mock,

  /// The Eventor API at `ApiConfig.baseUrl`.
  live;

  static const String _defaultFlag = 'mock';
  static const String _flag = String.fromEnvironment(
    'EVENTOR_DATA',
    defaultValue: _defaultFlag,
  );

  /// The source this build was made with.
  static const DataSource current = _flag == 'live' ? live : mock;

  bool get isMock => this == mock;
}

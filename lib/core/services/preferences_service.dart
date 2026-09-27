import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Typed access to the values the app persists on the device.
///
/// Wrapping [SharedPreferences] keeps raw string keys out of the view models
/// and gives every stored flag one obvious place to live.
class PreferencesService {
  const PreferencesService(this._preferences);

  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _hasSeenWelcomeKey = 'has_seen_welcome';
  static const String _localeKey = 'locale';

  final SharedPreferences _preferences;

  /// Loads the backing store. Call once, before the app starts.
  static Future<PreferencesService> load() async {
    return PreferencesService(await SharedPreferences.getInstance());
  }

  /// Whether onboarding has already been completed on this device.
  bool get hasSeenOnboarding =>
      _preferences.getBool(_hasSeenOnboardingKey) ?? false;

  Future<void> markOnboardingAsSeen() {
    return _preferences.setBool(_hasSeenOnboardingKey, true);
  }

  /// Whether the user has already taken one of Welcome's two doors on this
  /// device. From then on a signed-out launch opens on Login instead.
  bool get hasSeenWelcome => _preferences.getBool(_hasSeenWelcomeKey) ?? false;

  Future<void> markWelcomeAsSeen() {
    return _preferences.setBool(_hasSeenWelcomeKey, true);
  }

  /// The language the user picked, or `null` when they have not picked one and
  /// the device's own language should be followed.
  Locale? get locale {
    final String? languageCode = _preferences.getString(_localeKey);
    return languageCode == null ? null : Locale(languageCode);
  }

  /// Stores [locale], or forgets the choice when it is `null`.
  Future<void> setLocale(Locale? locale) {
    if (locale == null) return _preferences.remove(_localeKey);
    return _preferences.setString(_localeKey, locale.languageCode);
  }
}

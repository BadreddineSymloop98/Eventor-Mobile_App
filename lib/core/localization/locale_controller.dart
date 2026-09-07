import 'package:flutter/widgets.dart';

import '../services/preferences_service.dart';

/// Holds the language the app is displayed in.
///
/// It lives above [MaterialApp] because a language change has to rebuild every
/// screen, not just the one that requested it. A `null` [locale] means "follow
/// the device", which is the state until the user chooses otherwise.
///
/// Text direction is not handled here: Flutter derives it from the locale
/// through the global widget localisations, so switching to Arabic mirrors the
/// layout on its own.
class LocaleController extends ChangeNotifier {
  LocaleController(this._preferences) : _locale = _preferences.locale;

  final PreferencesService _preferences;

  Locale? _locale;

  /// The chosen language, or `null` while the device's own is being followed.
  Locale? get locale => _locale;

  /// Switches the app to [locale] and remembers the choice.
  ///
  /// Pass `null` to go back to following the device.
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    await _preferences.setLocale(locale);
  }
}

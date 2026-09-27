import '../services/preferences_service.dart';

/// S1's recent searches, kept on this device — the API has no history.
///
/// Newest first, at most [limit], and the same words searched twice appear
/// once (ignoring case), moved to the top.
class RecentSearches {
  RecentSearches(this._preferences);

  final PreferencesService _preferences;

  static const int limit = 8;

  List<String> get all => _preferences.recentSearches;

  Future<void> add(String query) {
    final String text = query.trim();
    if (text.isEmpty) return Future<void>.value();
    final List<String> next = <String>[
      text,
      ...all.where((String old) => old.toLowerCase() != text.toLowerCase()),
    ];
    return _preferences.setRecentSearches(next.take(limit).toList());
  }

  Future<void> remove(String query) => _preferences.setRecentSearches(
        all.where((String old) => old != query).toList(),
      );

  Future<void> clear() => _preferences.setRecentSearches(const <String>[]);
}

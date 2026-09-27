import 'package:flutter/foundation.dart';

import '../../features/auth/data/auth_repository.dart';
import '../models/account.dart';

/// Whether anyone is signed in.
enum SessionStatus {
  /// The app has not finished checking for a stored session yet. The splash
  /// covers this state; nothing should route on it.
  unknown,
  signedOut,
  signedIn,
}

/// Who is signed in, for the whole app.
///
/// Lives above the router: go_router's `redirect` listens to it, so signing
/// in, signing out and a session dying mid-use all move the user to the right
/// place from one rule instead of from every screen.
class SessionController extends ChangeNotifier {
  SessionController(this._auth);

  final AuthRepository _auth;

  SessionStatus _status = SessionStatus.unknown;
  AppUser? _user;

  /// Set when the session ended on its own (refused refresh), so the login
  /// screen can say why the user is back there.
  bool _expired = false;

  SessionStatus get status => _status;
  AppUser? get user => _user;
  bool get isSignedIn => _status == SessionStatus.signedIn;

  /// Reads the flag once; the login screen consumes it.
  bool consumeExpired() {
    final bool value = _expired;
    _expired = false;
    return value;
  }

  /// Restores a stored session on start. Never throws: whatever goes wrong,
  /// the outcome is "signed out", which is always a safe place to land.
  Future<void> restore() async {
    AppUser? user;
    try {
      user = await _auth.restoreSession();
    } catch (_) {
      user = null;
    }
    _set(user);
  }

  /// Where the router should send the user the moment they are signed in,
  /// instead of home — a new provider goes to their documents (`08e`). Read
  /// by [landing] until the router reports arrival through [arrivedAt].
  String? _landing;

  /// Called by the screens that end in a session — verify email, login, set
  /// password. [landing] overrides where the router goes next, once.
  void signedIn(AppUser user, {String? landing}) {
    _landing = landing;
    _set(user);
  }

  /// The one-off landing set by [signedIn], if the user has not reached it
  /// yet.
  ///
  /// Read without being consumed: the router may evaluate its redirect more
  /// than once for a single change, and each evaluation must agree. It is
  /// cleared by [arrivedAt] once the user is actually there.
  String? get landing => _landing;

  /// Called by the router on every settled location; retires [landing] once
  /// it has been reached. Deliberately silent — the router is mid-redirect.
  void arrivedAt(String path) {
    if (_landing == path) _landing = null;
  }

  /// Re-reads the account — after documents are uploaded, for instance, when
  /// the verification status has moved.
  Future<void> refreshUser() async {
    if (!isSignedIn) return;
    try {
      _set(await _auth.currentUser());
    } catch (_) {
      // Keep the account we have; the next successful call corrects it.
    }
  }

  Future<void> signOut() async {
    await _auth.logout();
    _set(null);
  }

  /// The session died on its own — wired to `ApiClient.onSessionExpired`.
  void expire() {
    if (_status != SessionStatus.signedIn) return;
    _expired = true;
    _set(null);
  }

  void _set(AppUser? user) {
    // A landing belongs to the session that set it; it must not survive into
    // the next account on this device.
    if (user == null) _landing = null;
    _user = user;
    _status = user == null ? SessionStatus.signedOut : SessionStatus.signedIn;
    notifyListeners();
  }
}

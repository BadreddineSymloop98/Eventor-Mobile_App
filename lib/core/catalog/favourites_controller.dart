import 'package:flutter/foundation.dart';

import '../errors/failure.dart';
import 'favourites_repository.dart';
import 'models/catalog_models.dart';

/// Which services and packs are saved, for the whole app at once.
///
/// Every card and detail carries its own `isFavourite`, fetched whenever that
/// screen loaded — so a heart tapped on 12 would still read empty on Home and
/// on the results behind it. This keeps what the user changed since, and
/// every heart asks here first, falling back to its card's flag.
///
/// A tap shows at once and the request follows. Requests for one item are
/// sent one after the other, in tap order, so the server ends in the state of
/// the last tap; a failure puts the heart back only if no newer tap has
/// replaced it.
class FavouritesController extends ChangeNotifier {
  FavouritesController(this._repository);

  final FavouritesRepository _repository;

  final Map<FavouriteTarget, bool> _overrides = <FavouriteTarget, bool>{};

  /// What the server last agreed each item is — where a failure rolls back
  /// to. Not the state the failed tap started from: when two quick taps both
  /// fail, the second started from the first's unconfirmed result.
  final Map<FavouriteTarget, bool> _confirmed = <FavouriteTarget, bool>{};

  /// The last request made for each item, so an older one that fails does
  /// not undo a newer tap.
  final Map<FavouriteTarget, int> _latest = <FavouriteTarget, int>{};

  /// The request still running for each item; the next waits for it.
  final Map<FavouriteTarget, Future<void>> _inFlight =
      <FavouriteTarget, Future<void>>{};

  int _sequence = 0;
  int _version = 0;

  /// Moves on whenever a save or removal reaches the server — screen 17
  /// reloads when it changes.
  int get version => _version;

  /// The heart for [target]: what was changed in this session, else the
  /// card's own [fallback].
  bool isFavourite(FavouriteTarget target, {required bool fallback}) =>
      _overrides[target] ?? fallback;

  /// Flips [target] from [current], the state the user was looking at.
  /// Returns the failure, after the heart has been put back, or `null`.
  Future<Failure?> toggle(
    FavouriteTarget target, {
    required bool current,
  }) async {
    final bool next = !current;
    final int ticket = ++_sequence;
    // Nothing in flight for this item: what the user sees is what the
    // server has.
    if (!_inFlight.containsKey(target)) _confirmed[target] = current;
    _latest[target] = ticket;
    _overrides[target] = next;
    notifyListeners();

    final Future<void> previous = _inFlight[target] ?? Future<void>.value();
    final Future<void> request = previous.then(
      (_) => next ? _repository.add(target) : _repository.remove(target),
    );
    // The next tap on this item waits for this one, whatever its outcome.
    _inFlight[target] = request.then((_) {}, onError: (Object _) {});

    try {
      await request;
      _confirmed[target] = next;
      _version++;
      notifyListeners();
      return null;
    } catch (error) {
      // A newer tap already decided what this heart shows; saying this older
      // one failed would describe a state the user has moved on from.
      if (_latest[target] != ticket) return null;
      _overrides[target] = _confirmed[target] ?? current;
      notifyListeners();
      return error is Failure ? error : UnexpectedFailure(cause: error);
    } finally {
      if (_latest[target] == ticket) _inFlight.remove(target);
    }
  }

  /// A removal made without a tap on a heart — screen 17's list.
  void markRemoved(FavouriteTarget target) {
    _overrides[target] = false;
    _confirmed[target] = false;
    _version++;
    notifyListeners();
  }

  /// Forgets everything; called on sign-out, so the next account on this
  /// device does not inherit these hearts.
  void clear() {
    _overrides.clear();
    _confirmed.clear();
    _latest.clear();
    _inFlight.clear();
    notifyListeners();
  }
}

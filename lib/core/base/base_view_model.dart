import 'package:flutter/foundation.dart';

import '../errors/failure.dart';
import 'view_state.dart';

/// Base class for every view model in the app.
///
/// It owns the boilerplate shared by all screens — the current [ViewState],
/// the last [Failure], and safe notification after disposal — so concrete view
/// models only describe the behaviour of their own screen.
abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  Failure? _failure;
  bool _isDisposed = false;

  ViewState get state => _state;

  /// What went wrong last, or `null` if nothing has.
  ///
  /// A type rather than a message: a view model cannot resolve a localised
  /// string without a [BuildContext]. The view turns this into text with
  /// `AppLocalizations.forFailure`.
  Failure? get failure => _failure;

  bool get isBusy => _state == ViewState.busy;
  bool get hasError => _state == ViewState.error;

  /// Runs [action] while keeping [state] in sync, and converts anything thrown
  /// into [ViewState.error] plus a [failure].
  ///
  /// A thrown [Failure] — what repositories throw — is kept as it is. Pass
  /// [onError] to classify anything else; without it the rest becomes an
  /// [UnexpectedFailure]. Returns the value produced by [action], or `null`
  /// when it failed.
  @protected
  Future<T?> runGuarded<T>(
    Future<T> Function() action, {
    Failure Function(Object error)? onError,
  }) async {
    _setState(ViewState.busy);
    try {
      final T result = await action();
      _setState(ViewState.idle);
      return result;
    } catch (error, stackTrace) {
      // The original error never reaches the user, so it is logged here or it
      // is lost.
      debugPrint('$runtimeType failed: $error\n$stackTrace');
      _setFailure(
        error is Failure
            ? error
            : onError?.call(error) ?? UnexpectedFailure(cause: error),
      );
      return null;
    }
  }

  /// Drops the last failure once the view model has turned it into state of
  /// its own — an inline banner, a field error — so the view does not also
  /// report it generically.
  @protected
  void clearFailure() {
    if (_failure == null && _state != ViewState.error) return;
    _failure = null;
    _state = ViewState.idle;
    notifyListeners();
  }

  void _setState(ViewState state) {
    if (_state == state && _failure == null) return;
    _state = state;
    _failure = null;
    notifyListeners();
  }

  void _setFailure(Failure failure) {
    _state = ViewState.error;
    _failure = failure;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    // A view model can outlive its widget while an async action is in flight;
    // notifying after disposal would throw.
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

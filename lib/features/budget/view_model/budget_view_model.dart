import '../../../core/base/base_view_model.dart';
import '../../../core/budget/budget_repository.dart';
import '../../../core/errors/failure.dart';

/// Screen 18 and its states — 18c with no lines yet, 18g over budget — or,
/// before the client has a budget, 18a in its place.
///
/// Every screen it opens (18f, 18d, 18b) hands back the budget the server
/// recomputed, which is applied as is; nothing is summed here.
class BudgetViewModel extends BaseViewModel {
  BudgetViewModel({required this._budgets}) {
    load();
  }

  final BudgetRepository _budgets;

  Budget? _budget;
  bool _hasLoaded = false;

  Budget? get budget => _budget;

  /// Nothing to show yet and nothing has failed — the skeleton.
  bool get isFirstLoad => !_hasLoaded && !hasError;

  /// Loaded, and there is no budget: 18a stands in for 18.
  bool get isMissing => _hasLoaded && _budget == null;

  Future<void> load() async {
    final Budget? budget = await runGuarded<Budget?>(_budgets.get);
    if (hasError) return;
    _budget = budget;
    _hasLoaded = true;
    notifyListeners();
  }

  /// Pull to refresh, and the quiet reload after a screen it opened comes
  /// back without a budget. What is on screen stays when it fails.
  Future<Failure?> refresh() async {
    try {
      _budget = await _budgets.get();
      _hasLoaded = true;
      clearFailure();
      notifyListeners();
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    }
  }

  /// A budget another screen got back from the server.
  void apply(Budget budget) {
    _budget = budget;
    _hasLoaded = true;
    notifyListeners();
  }
}

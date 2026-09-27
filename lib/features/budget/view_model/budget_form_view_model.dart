import '../../../core/base/base_view_model.dart';
import '../../../core/budget/budget_repository.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/money_format.dart';

/// What 18f hands back instead of a budget when the budget was deleted —
/// 18 then closes too, back to Home.
enum BudgetFormOutcome { deleted }

/// 18a (create) and 18f (edit): the budget's name, date and total.
///
/// Create is ready once there is a name and a total above zero; Edit, once
/// something has also changed. [isDirty] drives the "discard changes?"
/// guard, and drops once the save lands so the screen can close.
class BudgetFormViewModel extends BaseViewModel {
  BudgetFormViewModel({required this._budgets, this.initial})
      : _title = initial?.title ?? '',
        _eventDate = initial?.eventDate,
        _total = _dinars(initial?.totalAmount);

  final BudgetRepository _budgets;

  /// The budget being edited; `null` on 18a.
  final Budget? initial;

  /// The API's cap on the name.
  static const int maxTitleLength = 160;

  String _title;
  DateTime? _eventDate;
  int? _total;
  bool _isSaved = false;

  bool get isEditing => initial != null;
  String get title => _title;
  DateTime? get eventDate => _eventDate;
  int? get total => _total;

  bool get isDirty {
    if (_isSaved) return false;
    final Budget? budget = initial;
    if (budget == null) {
      return _title.trim().isNotEmpty || _eventDate != null || _total != null;
    }
    return _title.trim() != budget.title ||
        !_sameDay(_eventDate, budget.eventDate) ||
        _total != _dinars(budget.totalAmount);
  }

  /// Whether the form is complete. Busy-ness is the button's own spinner.
  bool get canSubmit =>
      _title.trim().isNotEmpty &&
      (_total ?? 0) > 0 &&
      (!isEditing || isDirty);

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setEventDate(DateTime? value) {
    _eventDate = value;
    notifyListeners();
  }

  void setTotal(int? value) {
    _total = value;
    notifyListeners();
  }

  /// The saved budget, or `null` with [failure] set.
  Future<Budget?> submit() async {
    if (isBusy || !canSubmit) return null;
    final Budget? saved = await runGuarded(
      () => _budgets.save(
        BudgetPlan(
          title: _title.trim(),
          eventDate: _eventDate,
          totalAmount: _totalAmount(),
        ),
      ),
    );
    if (saved != null) _isSaved = true;
    return saved;
  }

  bool get isDeleting => _isDeleting;
  bool _isDeleting = false;

  /// 18f's "Delete budget", once confirmed. `null` when it is gone; else
  /// why not — `ROUTE_NOT_FOUND` while the live API has no such route yet.
  /// A failure is returned rather than set, so the form stays as it was.
  Future<Failure?> delete() async {
    if (!isEditing || isBusy || _isDeleting) return null;
    _isDeleting = true;
    notifyListeners();
    try {
      await _budgets.delete();
      // Gone: nothing left to protect from Back.
      _isSaved = true;
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  /// The total as the API writes it — the stored string when the whole
  /// dinars did not change, so centimes set elsewhere are not lost.
  String _totalAmount() {
    final String? stored = initial?.totalAmount;
    if (stored != null && _dinars(stored) == _total) return stored;
    return apiAmountOf(_total ?? 0);
  }

  static int? _dinars(String? apiAmount) {
    if (apiAmount == null) return null;
    final int dinars = amountCents(apiAmount) ~/ 100;
    return dinars > 0 ? dinars : null;
  }

  static bool _sameDay(DateTime? a, DateTime? b) =>
      a == null || b == null
          ? a == b
          : a.year == b.year && a.month == b.month && a.day == b.day;
}

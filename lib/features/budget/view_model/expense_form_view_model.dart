import '../../../core/base/base_view_model.dart';
import '../../../core/budget/budget_repository.dart';
import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/routing/app_routes.dart';

/// 18d (add a line), 18i (the budget is full) and 18b (edit a line).
///
/// A label is all a line needs; the amounts default to zero. Picking a
/// category names an unnamed line after it. The spent amount is always
/// typed — a linked booking fills the provider, not the money (section 7
/// decision 1).
class ExpenseFormViewModel extends BaseViewModel {
  ExpenseFormViewModel({
    required this._budgets,
    required this._catalog,
    required ExpenseLineArgs args,
  })  : budget = args.budget,
        item = args.item,
        _category = args.item?.category,
        _label = args.item?.label ?? '',
        _planned = _dinars(args.item?.plannedAmount),
        _spent = _dinars(args.item?.spentAmount),
        _booking = _linkedOf(args.item);

  final BudgetRepository _budgets;
  final CatalogRepository _catalog;

  /// The budget as it stood when the screen opened.
  final Budget budget;

  /// The line being edited; `null` on 18d.
  final BudgetItem? item;

  static const int maxLabelLength = 160;

  CategoryRef? _category;
  String _label;
  int? _planned;
  int? _spent;
  LinkedBooking? _booking;

  /// The name last filled in from a category, so a second pick can replace
  /// it — but never a name the client typed.
  String? _autoLabel;
  bool _limitReached = false;
  bool _isSaved = false;
  bool _isDeleting = false;
  List<CategoryWithCount>? _categories;
  bool _isLoadingCategories = false;

  bool get isEditing => item != null;
  CategoryRef? get category => _category;
  String get label => _label;
  int? get planned => _planned;
  int? get spent => _spent;
  LinkedBooking? get booking => _booking;
  bool get isDeleting => _isDeleting;

  /// 18i: no room for another line — known from an earlier refusal, or
  /// from this screen's own.
  bool get isFull {
    if (isEditing) return false;
    if (_limitReached) return true;
    final int? limit = _budgets.itemLimit;
    return limit != null && budget.itemsCount >= limit;
  }

  /// Bookings on the budget's other lines, for 18h to grey out.
  Map<String, String> get bookingsInUse => <String, String>{
        for (final BudgetItem line in budget.items)
          if (line.bookingId != null && line.id != item?.id)
            line.bookingId!: line.label,
      };

  bool get isDirty {
    if (_isSaved) return false;
    final BudgetItem? line = item;
    if (line == null) {
      return _category != null ||
          _label.trim().isNotEmpty ||
          _planned != null ||
          _spent != null ||
          _booking != null;
    }
    return _category?.id != line.category?.id ||
        _label.trim() != line.label ||
        (_planned ?? 0) != (_dinars(line.plannedAmount) ?? 0) ||
        (_spent ?? 0) != (_dinars(line.spentAmount) ?? 0) ||
        _booking?.id != line.bookingId;
  }

  /// Whether the form is complete. Busy-ness is the button's own spinner.
  bool get canSubmit =>
      !isFull &&
      _label.trim().isNotEmpty &&
      (!isEditing || isDirty);

  /// Whether the first tap on Category is still waiting for the list — the
  /// field shows a spinner meanwhile.
  bool get isLoadingCategories => _isLoadingCategories;

  /// The categories to pick from — loaded once, on first ask. Throws the
  /// load's [Failure]; a failed load is not kept, so the next tap tries
  /// again.
  Future<List<CategoryWithCount>> categories() async {
    final List<CategoryWithCount>? loaded = _categories;
    if (loaded != null) return loaded;
    _isLoadingCategories = true;
    notifyListeners();
    try {
      return _categories = await _catalog.categories();
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  /// Sets the category and returns the label to show now: [name] when the
  /// line had none (or had the previous category's), else `null` — the
  /// typed label stays.
  String? setCategory(CategoryRef? category, {required String? name}) {
    _category = category;
    String? relabelled;
    final String current = _label.trim();
    if (name != null && (current.isEmpty || current == _autoLabel)) {
      _label = name;
      _autoLabel = name;
      relabelled = name;
    }
    notifyListeners();
    return relabelled;
  }

  void setLabel(String value) {
    _label = value;
    notifyListeners();
  }

  void setPlanned(int? value) {
    _planned = value;
    notifyListeners();
  }

  void setSpent(int? value) {
    _spent = value;
    notifyListeners();
  }

  void setBooking(LinkedBooking? value) {
    _booking = value;
    notifyListeners();
  }

  /// The recomputed budget, or `null`. A full budget is not reported as a
  /// failure: the screen turns into 18i instead.
  Future<Budget?> submit() async {
    if (isBusy || !canSubmit) return null;
    final BudgetItemInput input = BudgetItemInput(
      categoryId: _category?.id,
      label: _label.trim(),
      plannedAmount: _amount(_planned, item?.plannedAmount),
      spentAmount: _amount(_spent, item?.spentAmount),
      bookingId: _booking?.id,
    );
    final BudgetItem? line = item;
    final Budget? saved = await runGuarded(
      () => line == null
          ? _budgets.addItem(input)
          : _budgets.updateItem(line, input),
    );
    if (saved != null) {
      _isSaved = true;
      return saved;
    }
    final Failure? problem = failure;
    if (problem is ApiFailure && problem.code == ApiErrorCode.budgetItemLimit) {
      _limitReached = true;
      clearFailure();
    }
    return null;
  }

  /// 18e's "Delete line". The recomputed budget, or `null` with [failure].
  Future<Budget?> delete() async {
    final BudgetItem? line = item;
    if (line == null || _isDeleting) return null;
    _isDeleting = true;
    notifyListeners();
    final Budget? saved = await runGuarded(() => _budgets.deleteItem(line.id));
    _isDeleting = false;
    if (saved != null) _isSaved = true;
    notifyListeners();
    return saved;
  }

  /// The amount as the API writes it — the stored string when the whole
  /// dinars did not change, so centimes set elsewhere are not lost.
  static String _amount(int? dinars, String? stored) {
    if (stored != null && (_dinars(stored) ?? 0) == (dinars ?? 0)) return stored;
    return apiAmountOf(dinars ?? 0);
  }

  static int? _dinars(String? apiAmount) {
    if (apiAmount == null) return null;
    final int dinars = amountCents(apiAmount) ~/ 100;
    return dinars > 0 ? dinars : null;
  }

  static LinkedBooking? _linkedOf(BudgetItem? item) {
    final String? id = item?.bookingId;
    if (item == null || id == null) return null;
    return LinkedBooking(
      id: id,
      reference: item.bookingReference ?? '',
      providerName: item.providerName ?? '',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/budget/budget_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/amount_input.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/molecules/app_select_field.dart';
import '../../../core/widgets/molecules/app_text_field.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/inline_banner.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/organisms/bottom_action_bar.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../core/widgets/organisms/confirm_sheet.dart';
import '../../../core/widgets/organisms/discard_guard.dart';
import '../../../core/widgets/organisms/selection_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/expense_form_view_model.dart';

/// 18d Add an expense (18i once the budget is full) and 18b Expense line,
/// whose Delete asks first (18e). Closes with the recomputed budget.
class ExpenseFormView extends StatefulWidget {
  const ExpenseFormView({super.key});

  @override
  State<ExpenseFormView> createState() => _ExpenseFormViewState();
}

class _ExpenseFormViewState extends State<ExpenseFormView> {
  late final ExpenseFormViewModel _viewModel = context
      .read<ExpenseFormViewModel>();
  late final TextEditingController _label = TextEditingController(
    text: _viewModel.label,
  );
  late final TextEditingController _planned = TextEditingController(
    text: groupDinars('${_viewModel.planned ?? ''}'),
  );
  late final TextEditingController _spent = TextEditingController(
    text: groupDinars('${_viewModel.spent ?? ''}'),
  );
  final ScrollController _scroll = ScrollController();

  /// The value 18b keeps in the category field for a "no category" row —
  /// category ids are UUIDs, so it cannot collide.
  static const String _noCategory = '';

  @override
  void dispose() {
    _label.dispose();
    _planned.dispose();
    _spent.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    FocusScope.of(context).unfocus();
    final List<CategoryWithCount> categories;
    try {
      categories = await _viewModel.categories();
    } on Failure catch (failure) {
      if (mounted) {
        showAppToast(context, l10n.forFailure(failure), tone: AppToastTone.error);
      }
      return;
    }
    if (!mounted) return;

    final Set<String>? picked = await showSelectionSheet<String>(
      context,
      title: l10n.expenseCategoryLabel,
      selected: <String>{_viewModel.category?.id ?? _noCategory},
      options: <SelectionOption<String>>[
        SelectionOption<String>(
          value: _noCategory,
          label: l10n.expenseNoCategory,
        ),
        for (final CategoryWithCount category in categories)
          SelectionOption<String>(
            value: category.id,
            label: category.name.of(language),
          ),
      ],
    );
    if (picked == null || picked.isEmpty) return;
    CategoryRef? chosen;
    for (final CategoryWithCount category in categories) {
      if (category.id == picked.first) chosen = category;
    }
    final String? relabelled = _viewModel.setCategory(
      chosen,
      name: chosen?.name.of(language),
    );
    if (relabelled != null) _label.text = relabelled;
  }

  Future<void> _pickBooking() async {
    FocusScope.of(context).unfocus();
    final BookingLinkChoice? choice = await context.push<BookingLinkChoice>(
      AppRoutes.budgetLinkBooking,
      extra: LinkBookingArgs(
        current: _viewModel.booking,
        usedBy: _viewModel.bookingsInUse,
      ),
    );
    if (choice != null) _viewModel.setBooking(choice.booking);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final Budget? saved = await _viewModel.submit();
    if (!mounted) return;
    if (saved != null) {
      Navigator.of(context).pop(saved);
      return;
    }
    if (_viewModel.isFull) {
      // 18i's banner is at the top of the form.
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    _reportFailure();
  }

  Future<void> _delete() async {
    final AppLocalizations l10n = context.l10n;
    final BudgetItem? item = _viewModel.item;
    if (item == null) return;
    FocusScope.of(context).unfocus();
    final bool confirmed = await showConfirmSheet(
      context,
      title: l10n.expenseDeleteTitle,
      message: l10n.expenseDeleteBody,
      confirmLabel: l10n.expenseDeleteConfirm,
      cancelLabel: l10n.expenseDeleteKeep,
      destructive: true,
      recap: _LineRecap(item: item),
    );
    if (!confirmed || !mounted) return;
    final Budget? saved = await _viewModel.delete();
    if (!mounted) return;
    if (saved != null) {
      Navigator.of(context).pop(saved);
    } else {
      _reportFailure();
    }
  }

  /// A toast, and — when the line or the budget is gone — back to 18, which
  /// reloads.
  void _reportFailure() {
    final Failure? failure = _viewModel.failure;
    if (failure == null) return;
    showAppToast(
      context,
      context.l10n.forFailure(failure),
      tone: AppToastTone.error,
    );
    if (failure is ApiFailure &&
        (failure.code == ApiErrorCode.budgetItemNotFound ||
            failure.code == ApiErrorCode.budgetNotFound)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseFormViewModel viewModel = context
        .watch<ExpenseFormViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final BudgetItem? item = viewModel.item;
    final LinkedBooking? booking = viewModel.booking;
    final String suffix = l10n.amountFieldSuffix;
    final bool isFull = viewModel.isFull;
    final bool locked = viewModel.isBusy;

    Widget amountField(
      TextEditingController controller,
      String label,
      ValueChanged<int?> onChanged,
    ) => AppTextField(
      controller: controller,
      label: label,
      hintText: '0',
      suffixText: suffix.isEmpty ? null : suffix,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      inputFormatters: const <TextInputFormatter>[DinarInputFormatter()],
      onChanged: (String text) => onChanged(parseDinars(text)),
    );

    return DiscardGuard(
      isDirty: viewModel.isDirty,
      child: Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            BrandTopBar(
              title: item == null
                  ? l10n.budgetAddExpense
                  : l10n.expenseLineTitle,
              actionLabel: item == null ? null : l10n.expenseDelete,
              onAction: item == null || viewModel.isBusy ? null : _delete,
              isActionLoading: viewModel.isDeleting,
            ),
            Expanded(
              // The line is on its way out: nothing on it can change meanwhile.
              child: AbsorbPointer(
                absorbing: viewModel.isDeleting,
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md.dw,
                    AppSpacing.lg.dh,
                    AppSpacing.md.dw,
                    AppSpacing.lg.dh,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (isFull) ...<Widget>[
                        InlineBanner(
                          title: l10n.expenseFullTitle,
                          message: l10n.expenseFullBody,
                        ),
                        SizedBox(height: AppSpacing.lg.dh),
                      ],
                      Text(
                        item == null
                            ? l10n.expenseNewTitle
                            : item.category?.name.of(language) ?? item.label,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs2.dh),
                      Text(
                        item == null
                            ? l10n.expenseNewBody
                            : l10n.expenseEditBody,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg.dh),
                      AppSelectField(
                        label: l10n.expenseCategoryLabel,
                        value: viewModel.category?.name.of(language),
                        placeholder: l10n.expenseCategoryPlaceholder,
                        isLoading: viewModel.isLoadingCategories,
                        onTap: locked ? null : _pickCategory,
                      ),
                      SizedBox(height: AppSpacing.md.dh),
                      AppTextField(
                        controller: _label,
                        label: l10n.expenseLabelLabel,
                        hintText: l10n.expenseLabelHint,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: <TextInputFormatter>[
                          LengthLimitingTextInputFormatter(
                            ExpenseFormViewModel.maxLabelLength,
                          ),
                        ],
                        onChanged: viewModel.setLabel,
                      ),
                      SizedBox(height: AppSpacing.md.dh),
                      amountField(
                        _planned,
                        l10n.expensePlannedLabel,
                        viewModel.setPlanned,
                      ),
                      SizedBox(height: AppSpacing.md.dh),
                      amountField(
                        _spent,
                        l10n.expenseSpentLabel,
                        viewModel.setSpent,
                      ),
                      SizedBox(height: AppSpacing.md.dh),
                      AppSelectField(
                        label: l10n.expenseBookingLabel,
                        value: booking == null
                            ? null
                            : <String>[
                                if (booking.reference.isNotEmpty)
                                  booking.reference,
                                if (booking.providerName.isNotEmpty)
                                  booking.providerName,
                              ].join(' · '),
                        placeholder: l10n.expenseNotLinked,
                        onTap: locked ? null : _pickBooking,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            BottomActionBar(
              child: MainButton(
                label: item == null
                    ? l10n.expenseAddLine
                    : l10n.expenseSaveLine,
                isLoading: viewModel.isBusy && !viewModel.isDeleting,
                canBeTapped: viewModel.canSubmit && !viewModel.isDeleting,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 18e's recap of the line about to go.
class _LineRecap extends StatelessWidget {
  const _LineRecap({required this.item});

  final BudgetItem item;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? key = textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
    );
    final TextStyle? value = textTheme.labelSmall?.copyWith(
      color: AppColors.textPrimary,
    );
    final String suffix = l10n.amountFieldSuffix;

    Widget row(String label, String amount) => Padding(
      padding: EdgeInsets.only(top: AppSpacing.xs.dh),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: key)),
          Text(
            formatAmount(amount),
            textDirection: TextDirection.ltr,
            style: value,
          ),
          if (suffix.isNotEmpty) ...<Widget>[
            SizedBox(width: AppSpacing.xs2.dw),
            Text(suffix, style: value),
          ],
        ],
      ),
    );

    return Container(
      padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
      decoration: const BoxDecoration(
        color: AppColors.bgCanvas,
        borderRadius: AppRadii.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
          ),
          row(l10n.expenseDeleteSpent, item.spentAmount),
          row(l10n.expenseDeletePlanned, item.plannedAmount),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/budget/budget_repository.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/formatting/amount_input.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/widgets/molecules/app_select_field.dart';
import '../../../core/widgets/molecules/app_text_field.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/organisms/bottom_action_bar.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../core/widgets/organisms/confirm_sheet.dart';
import '../../../core/widgets/organisms/date_picker_sheet.dart';
import '../../../core/widgets/organisms/discard_guard.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/budget_form_view_model.dart';

/// 18a Create and 18f Edit — the budget's name, date and total.
///
/// Edit closes with the saved budget; Create hands it to [onSaved], since it
/// stands in 18's own place.
class BudgetFormView extends StatefulWidget {
  const BudgetFormView({this.onSaved, super.key});

  final ValueChanged<Budget>? onSaved;

  @override
  State<BudgetFormView> createState() => _BudgetFormViewState();
}

class _BudgetFormViewState extends State<BudgetFormView> {
  late final BudgetFormViewModel _viewModel = context.read<BudgetFormViewModel>();
  late final TextEditingController _title = TextEditingController(text: _viewModel.title);
  late final TextEditingController _total = TextEditingController(
    text: groupDinars('${_viewModel.total ?? ''}'),
  );

  @override
  void dispose() {
    _title.dispose();
    _total.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final AppLocalizations l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final DateChoice? choice = await showDatePickerSheet(
      context,
      title: l10n.budgetEventDateLabel,
      selected: _viewModel.eventDate,
      clearLabel: l10n.budgetEventDateClear,
    );
    if (choice != null) _viewModel.setEventDate(choice.date);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final Budget? saved = await _viewModel.submit();
    if (!mounted) return;
    if (saved == null) {
      final Failure? failure = _viewModel.failure;
      if (failure != null) {
        showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
      }
      return;
    }
    final ValueChanged<Budget>? onSaved = widget.onSaved;
    if (onSaved != null) {
      onSaved(saved);
    } else {
      Navigator.of(context).pop(saved);
    }
  }

  /// 18f's "Delete budget": asked first, then 18f and 18 close together and
  /// Home — which reloads when 18 closes — is back on the 11c invitation.
  Future<void> _delete() async {
    final AppLocalizations l10n = context.l10n;
    final Budget? budget = _viewModel.initial;
    if (budget == null) return;
    FocusScope.of(context).unfocus();
    final bool confirmed = await showConfirmSheet(
      context,
      title: l10n.budgetDeleteTitle,
      message: l10n.budgetDeleteBody,
      confirmLabel: l10n.budgetDeleteConfirm,
      cancelLabel: l10n.expenseDeleteKeep,
      destructive: true,
      recap: _BudgetRecap(budget: budget),
    );
    if (!confirmed || !mounted) return;
    final Failure? failure = await _viewModel.delete();
    if (!mounted) return;
    if (failure == null) {
      showAppToast(context, l10n.budgetDeleted, tone: AppToastTone.info);
      Navigator.of(context).pop(BudgetFormOutcome.deleted);
      return;
    }
    // The live API does not have the route yet (backend issues, item 15).
    final bool unavailable =
        failure is ApiFailure && failure.code == ApiErrorCode.routeNotFound;
    showAppToast(
      context,
      unavailable ? l10n.budgetDeleteUnavailable : l10n.forFailure(failure),
      tone: AppToastTone.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final BudgetFormViewModel viewModel = context.watch<BudgetFormViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final DateTime? date = viewModel.eventDate;
    final String suffix = l10n.amountFieldSuffix;

    return DiscardGuard(
      isDirty: viewModel.isDirty,
      child: Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            BrandTopBar(title: l10n.budgetTitle),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md.dw,
                  AppSpacing.lg.dh,
                  AppSpacing.md.dw,
                  AppSpacing.lg.dh,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      viewModel.isEditing ? l10n.budgetEditIntroTitle : l10n.budgetCreateIntroTitle,
                      style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                    ),
                    SizedBox(height: AppSpacing.xs2.dh),
                    Text(
                      viewModel.isEditing ? l10n.budgetEditIntroBody : l10n.budgetEmptyBody,
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: AppSpacing.lg.dh),
                    AppTextField(
                      controller: _title,
                      label: l10n.budgetNameLabel,
                      hintText: l10n.budgetNameHint,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: <TextInputFormatter>[
                        LengthLimitingTextInputFormatter(BudgetFormViewModel.maxTitleLength),
                      ],
                      onChanged: viewModel.setTitle,
                    ),
                    SizedBox(height: AppSpacing.md.dh),
                    AppSelectField(
                      label: l10n.budgetEventDateLabel,
                      value: date == null ? null : longDate(date, language),
                      placeholder: l10n.optionalField,
                      onTap: viewModel.isBusy ? null : _pickDate,
                    ),
                    SizedBox(height: AppSpacing.md.dh),
                    AppTextField(
                      controller: _total,
                      label: l10n.budgetTotalLabel,
                      hintText: '0',
                      suffixText: suffix.isEmpty ? null : suffix,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      textDirection: TextDirection.ltr,
                      inputFormatters: const <TextInputFormatter>[DinarInputFormatter()],
                      onChanged: (String text) => viewModel.setTotal(parseDinars(text)),
                      onSubmitted: (_) => _submit(),
                    ),
                    // Kept away from Save, at the end of the form — the one
                    // way to start over on 11c.
                    if (viewModel.isEditing) ...<Widget>[
                      SizedBox(height: AppSpacing.xl2.dh),
                      MainButton(
                        label: l10n.budgetDelete,
                        style: MainButtonStyle.ghost,
                        tone: MainButtonTone.danger,
                        icon: AppIcons.trash,
                        isLoading: viewModel.isDeleting,
                        onPressed: viewModel.isBusy ? null : _delete,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            BottomActionBar(
              child: MainButton(
                label: viewModel.isEditing ? l10n.budgetSaveChanges : l10n.budgetCreateAction,
                isLoading: viewModel.isBusy,
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

/// What the delete sheet says is about to go: the budget, its lines, and
/// what has been spent.
class _BudgetRecap extends StatelessWidget {
  const _BudgetRecap({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? key = textTheme.labelSmall?.copyWith(color: AppColors.textSecondary);
    final TextStyle? value = textTheme.labelSmall?.copyWith(color: AppColors.textPrimary);
    final String suffix = l10n.amountFieldSuffix;

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
            budget.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
          ),
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs.dh),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(l10n.budgetExpenseLines, style: key)),
                Text('${budget.itemsCount}', textDirection: TextDirection.ltr, style: value),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs.dh),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(l10n.expenseDeleteSpent, style: key)),
                // Amount and currency as separate runs, as everywhere.
                Text(formatAmount(budget.spentTotal), textDirection: TextDirection.ltr, style: value),
                if (suffix.isNotEmpty) ...<Widget>[
                  SizedBox(width: AppSpacing.xs2.dw),
                  Text(suffix, style: value),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

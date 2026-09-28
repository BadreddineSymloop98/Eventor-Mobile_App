import 'package:flutter/material.dart';

import '../../../../core/budget/budget_repository.dart';
import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/formatting/date_format.dart';
import '../../../../core/formatting/money_format.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/atoms/category_icon.dart';
import '../../../../core/widgets/atoms/dashed_border_box.dart';
import '../../../../core/widgets/atoms/icon_tile.dart';
import '../../../../core/widgets/molecules/price_text.dart';
import '../../../../l10n/app_localizations.dart';

/// An amount as its own left-to-right token, so its digit groups never
/// reverse inside Arabic copy — the number-token rule. A negative amount
/// reads "− 30 000", as 18g draws it.
class AmountToken extends StatelessWidget {
  const AmountToken(this.amount, {this.style, this.withCurrency = true, super.key});

  /// The API's string, `"30000.00"`.
  final String amount;
  final TextStyle? style;
  final bool withCurrency;

  @override
  Widget build(BuildContext context) {
    final bool negative = amountCents(amount) < 0;
    final String digits = formatAmount(negative ? amount.trim().substring(1) : amount);
    final SizedBox gap = SizedBox(width: AppSpacing.xs2.dw);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          negative ? '− $digits' : digits,
          textDirection: TextDirection.ltr,
          style: style,
        ),
        if (withCurrency) ...<Widget>[gap, Text(context.l10n.currencyDzd, style: style)],
      ],
    );
  }
}

/// The top of 18: what has been spent against the plan, what the lines add
/// up to, what is left, and how many lines are booked.
class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({required this.budget, super.key});

  final Budget budget;

  static const double _barHeight = 8;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final DateTime? date = budget.eventDate;
    final bool over = budget.isOverBudget;
    final TextStyle? secondary = textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary);
    final TextStyle? small = textTheme.labelSmall?.copyWith(
      // Lines promising more than the total are worth a glance before any
      // of it is spent.
      color: budget.isOverAllocated ? AppColors.statusPending : AppColors.textSecondary,
    );

    return Container(
      padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: AppElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            <String>[budget.title, if (date != null) longDate(date, language)].join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.xs.dh),
          PriceText(
            amount: budget.spentTotal,
            unit: l10n.budgetSpent,
            amountStyle: textTheme.displayLarge?.copyWith(color: AppColors.textPrimary),
            labelStyle: secondary,
          ),
          SizedBox(height: AppSpacing.xs.dh),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs2.dw,
            children: <Widget>[
              Text(l10n.budgetOf, style: secondary),
              AmountToken(budget.totalAmount, style: secondary),
              Text(l10n.budgetPlanned, style: secondary),
            ],
          ),
          SizedBox(height: AppSpacing.md.dh),
          ClipRRect(
            borderRadius: AppRadii.fullAll,
            child: LinearProgressIndicator(
              value: (budget.spentPercent / 100).clamp(0, 1).toDouble(),
              minHeight: _barHeight.dh,
              backgroundColor: AppColors.bgDisabled,
              color: over ? AppColors.bgDanger : AppColors.bgBrand,
            ),
          ),
          SizedBox(height: AppSpacing.sm.dh),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs2.dw,
            children: <Widget>[
              AmountToken(budget.plannedTotal, style: small, withCurrency: false),
              Text(l10n.budgetAllocatedLines(budget.itemsCount), style: small),
            ],
          ),
          SizedBox(height: AppSpacing.md.dh),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _Stat(
                    label: l10n.budgetRemaining,
                    value: AmountToken(
                      budget.remaining,
                      style: textTheme.labelLarge?.copyWith(
                        color: over ? AppColors.textDanger : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: AppColors.borderDefault),
                SizedBox(width: AppSpacing.sm.dw),
                Expanded(
                  child: _Stat(
                    label: l10n.budgetServicesBooked,
                    value: Text(
                      l10n.budgetBookedOf(budget.bookedCount, budget.itemsCount),
                      style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: AppSpacing.xs2.dh),
        value,
      ],
    );
  }
}

/// One line of 18's list: its category, who it is booked with, and what was
/// spent against what was planned.
///
/// The figure on the end is the spent amount once anything is spent — "of
/// 120 000" under it, or "on plan" when it matches — and the planned amount,
/// greyed, until then. A line spent past its plan shows in red.
class ExpenseLineRow extends StatelessWidget {
  const ExpenseLineRow({required this.item, required this.onTap, super.key});

  final BudgetItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int spent = amountCents(item.spentAmount);
    final int planned = amountCents(item.plannedAmount);
    final TextStyle? caption = textTheme.labelSmall?.copyWith(color: AppColors.textSecondary);
    final String? provider = item.providerName;
    final String? reference = item.bookingReference;

    final Widget figure;
    final Widget note;
    if (spent == 0) {
      figure = AmountToken(
        item.plannedAmount,
        style: textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
      );
      note = Text(l10n.budgetLinePlanned, style: caption);
    } else {
      figure = AmountToken(
        item.spentAmount,
        style: textTheme.labelLarge?.copyWith(
          color: spent > planned ? AppColors.textDanger : AppColors.textPrimary,
        ),
      );
      note = spent == planned
          ? Text(l10n.budgetLineOnPlan, style: caption)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(l10n.budgetOf, style: caption),
                SizedBox(width: AppSpacing.xs2.dw),
                AmountToken(item.plannedAmount, style: caption, withCurrency: false),
              ],
            );
    }

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md.dw,
            vertical: AppSpacing.sm.dh,
          ),
          child: Row(
            children: <Widget>[
              IconTile(categoryIcon(item.category?.icon), muted: !item.isBooked),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
                    ),
                    SizedBox(height: AppSpacing.xs2.dh),
                    Text(
                      item.isBooked
                          ? <String>[
                              if (provider != null && provider.isNotEmpty) provider,
                              if (reference != null && reference.isNotEmpty) reference,
                            ].join(' · ')
                          : l10n.budgetNotBookedYet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: caption,
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm.dw),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  figure,
                  SizedBox(height: AppSpacing.xs2.dh),
                  note,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 18c: the list before its first line.
class NoExpenseLinesCard extends StatelessWidget {
  const NoExpenseLinesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return DashedBorderBox(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg.dw,
        vertical: AppSpacing.xl.dh,
      ),
      child: Column(
        children: <Widget>[
          const AppIcon(AppIcons.pieChart, size: AppSizes.iconLg, color: AppColors.iconBrand),
          SizedBox(height: AppSpacing.sm.dh),
          Text(
            l10n.budgetNoLinesTitle,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: AppSpacing.xs.dh),
          Text(
            l10n.budgetNoLinesBody,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/budget/budget_repository.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/inline_banner.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/bottom_action_bar.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../core/widgets/organisms/divided_card.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/budget_form_view_model.dart';
import '../view_model/budget_view_model.dart';
import 'budget_form_view.dart';
import 'widgets/budget_widgets.dart';

/// Screen 18 — the budget, with its no-lines (18c) and over-budget (18g)
/// states. Until the client has one, 18a stands here instead, so Home's card
/// has a single place to open.
class BudgetView extends StatelessWidget {
  const BudgetView({super.key});

  @override
  Widget build(BuildContext context) {
    final BudgetViewModel viewModel = context.watch<BudgetViewModel>();
    if (viewModel.isMissing) {
      return ChangeNotifierProvider<BudgetFormViewModel>(
        create: (BuildContext context) =>
            BudgetFormViewModel(budgets: context.read<BudgetRepository>()),
        child: BudgetFormView(onSaved: viewModel.apply),
      );
    }
    return const _BudgetScreen();
  }
}

class _BudgetScreen extends StatefulWidget {
  const _BudgetScreen();

  @override
  State<_BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<_BudgetScreen> {
  /// A screen opened from here comes back with the budget the server
  /// recomputed — or with nothing, when it was left without saving or its
  /// line had gone; a quiet reload then catches any change made elsewhere.
  /// 18f can also say the budget was deleted: 18 then closes too.
  Future<void> _open(String location, Object extra) async {
    final BudgetViewModel viewModel = context.read<BudgetViewModel>();
    final Object? result = await context.push<Object?>(location, extra: extra);
    if (!mounted) return;
    if (result == BudgetFormOutcome.deleted) {
      context.canPop() ? context.pop() : context.go(AppRoutes.home);
    } else if (result is Budget) {
      viewModel.apply(result);
    } else {
      await viewModel.refresh();
    }
  }

  Future<void> _refresh(BudgetViewModel viewModel) async {
    final Failure? failure = await viewModel.refresh();
    if (failure != null && mounted) {
      showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final BudgetViewModel viewModel = context.watch<BudgetViewModel>();
    final AppLocalizations l10n = context.l10n;
    final Budget? budget = viewModel.budget;

    final Widget body;
    if (budget != null) {
      body = RefreshIndicator(
        color: AppColors.bgBrand,
        onRefresh: () => _refresh(viewModel),
        child: _BudgetContent(
          budget: budget,
          onOpenLine: (BudgetItem item) => _open(
            AppRoutes.budgetLineFor(item.id),
            ExpenseLineArgs(budget: budget, item: item),
          ),
        ),
      );
    } else if (viewModel.hasError) {
      body = ListView(
        padding: AppSpacing.screenPaddingAll,
        children: <Widget>[StateCard.error(onRetry: viewModel.load)],
      );
    } else {
      body = const _BudgetSkeleton();
    }

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BrandTopBar(
            title: l10n.budgetTitle,
            onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
            actionLabel: budget == null ? null : l10n.budgetEdit,
            onAction: budget == null ? null : () => _open(AppRoutes.budgetEdit, budget),
          ),
          Expanded(child: body),
          if (budget != null)
            BottomActionBar(
              child: MainButton(
                label: l10n.budgetAddExpense,
                icon: AppIcons.plus,
                onPressed: () => _open(
                  AppRoutes.budgetNewLine,
                  ExpenseLineArgs(budget: budget),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetContent extends StatelessWidget {
  const _BudgetContent({required this.budget, required this.onOpenLine});

  final Budget budget;
  final ValueChanged<BudgetItem> onOpenLine;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ListView(
      // Pull to refresh needs something to pull, however short the list.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md.dw,
        AppSpacing.md.dh,
        AppSpacing.md.dw,
        AppSpacing.xl.dh,
      ),
      children: <Widget>[
        BudgetSummaryCard(budget: budget),
        if (budget.isOverBudget) ...<Widget>[
          SizedBox(height: AppSpacing.md.dh),
          InlineBanner(title: l10n.budgetOverTitle, message: l10n.budgetOverBody),
        ],
        SizedBox(height: AppSpacing.lg.dh),
        if (budget.items.isEmpty)
          const NoExpenseLinesCard()
        else ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.budgetExpenseLines,
                  style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                ),
              ),
              Text(
                l10n.budgetActualVsPlanned,
                style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm.dh),
          DividedCard(
            children: <Widget>[
              for (final BudgetItem item in budget.items)
                ExpenseLineRow(
                  key: ValueKey<String>(item.id),
                  item: item,
                  onTap: () => onOpenLine(item),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BudgetSkeleton extends StatelessWidget {
  const _BudgetSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: AppSpacing.screenPaddingAll,
      children: <Widget>[
        Skeleton(height: 236.dh, radius: AppRadii.lgAll),
        SizedBox(height: AppSpacing.lg.dh),
        Skeleton(height: 20.dh, width: 140.dw),
        SizedBox(height: AppSpacing.sm.dh),
        for (int i = 0; i < 4; i++) ...<Widget>[
          Skeleton(height: 64.dh, radius: AppRadii.mdAll),
          SizedBox(height: AppSpacing.xs.dh),
        ],
      ],
    );
  }
}

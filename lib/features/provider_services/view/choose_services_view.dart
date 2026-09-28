import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/provider_catalog/provider_catalog_repository.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/price_text.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/bottom_action_bar.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/choose_services_view_model.dart';

/// P11a Choose services. Pops with the chosen service ids, in order; Back
/// keeps the pack's services as they were.
class ChooseServicesView extends StatelessWidget {
  const ChooseServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final ChooseServicesViewModel viewModel = context.watch<ChooseServicesViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final Widget body;
    if (viewModel.isFirstLoad) {
      body = ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: AppSpacing.screenPaddingAll,
        children: <Widget>[
          Skeleton(height: 40.dh),
          SizedBox(height: AppSpacing.md.dh),
          Skeleton(height: 260.dh),
        ],
      );
    } else if (viewModel.loadFailed) {
      body = Padding(
        padding: AppSpacing.screenPaddingAll,
        child: StateCard.error(onRetry: viewModel.load),
      );
    } else {
      final List<ProviderServiceSummary> services = viewModel.services;
      body = ListView(
        padding: AppSpacing.screenPaddingAll,
        children: <Widget>[
          Text(
            l10n.providerPackChooseRule,
            style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.xs.dh),
          // "3 chosen · sum 365 000 DA" — the amount its own token.
          Wrap(
            spacing: AppSpacing.xs2.dw,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                l10n.providerPackChosenCount(viewModel.count),
                style: textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
              ),
              if (viewModel.count > 0) ...<Widget>[
                Text('·', style: textTheme.labelMedium?.copyWith(color: AppColors.textPrimary)),
                PriceText(
                  prefix: l10n.providerPackChosenSum,
                  amount: '${viewModel.sumCents ~/ 100}.${(viewModel.sumCents % 100).toString().padLeft(2, '0')}',
                  amountStyle: textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
                  labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ],
          ),
          SizedBox(height: AppSpacing.md.dh),
          if (services.isEmpty)
            StateCard.empty(icon: AppIcons.briefcase, title: l10n.providerPackChooseEmpty)
          else
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppRadii.mdAll,
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Material(
                color: AppColors.bgSurface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int i = 0; i < services.length; i++) ...<Widget>[
                      if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
                      _ServiceChoiceRow(
                        key: ValueKey<String>(services[i].id),
                        service: services[i],
                        viewModel: viewModel,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BrandTopBar(title: l10n.providerPackChooseTitle),
          Expanded(child: body),
          BottomActionBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!viewModel.isFirstLoad && viewModel.count < ChooseServicesViewModel.minItems) ...<Widget>[
                  Text(
                    l10n.providerPackChooseMin,
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: AppSpacing.xs.dh),
                ],
                MainButton(
                  label: l10n.providerPackChooseDone(viewModel.count),
                  canBeTapped: viewModel.canFinish,
                  onPressed: () => Navigator.of(context).pop(viewModel.selected),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the provider's services: the name, then its category and price —
/// or, greyed out, why it cannot go in the pack. A navy tick when chosen.
class _ServiceChoiceRow extends StatelessWidget {
  const _ServiceChoiceRow({required this.service, required this.viewModel, super.key});

  final ProviderServiceSummary service;
  final ChooseServicesViewModel viewModel;

  void _tap(BuildContext context) {
    switch (viewModel.toggle(service)) {
      case ChooseToggle.full:
        showAppToast(context, context.l10n.providerPackChooseFull, tone: AppToastTone.info);
      case ChooseToggle.toggled || ChooseToggle.ineligible:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final PackEligibility eligibility = viewModel.eligibilityOf(service);
    final bool selected = viewModel.isSelected(service);
    final bool enabled = eligibility == PackEligibility.eligible || selected;
    final String? reason = switch (eligibility) {
      PackEligibility.eligible => null,
      PackEligibility.draft => l10n.providerPackReasonDraft,
      PackEligibility.hidden => l10n.providerPackReasonHidden,
      PackEligibility.notCovering => viewModel.wilaya == null
          ? l10n.providerPackReasonNotCoveringAny
          : l10n.providerPackItemNotCovering(viewModel.wilaya!.nameFor(language)),
    };
    final Color nameColor = eligibility == PackEligibility.eligible
        ? AppColors.textPrimary
        : AppColors.textSecondary;
    final TextStyle? detail = textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w500,
    );
    final String? category = service.category?.nameFor(language);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: InkWell(
        onTap: enabled ? () => _tap(context) : null,
        child: Container(
          constraints: BoxConstraints(minHeight: AppSizes.touchTarget.dh),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md.dw,
            vertical: AppSpacing.sm.dh,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      service.title.of(language),
                      style: textTheme.labelMedium?.copyWith(color: nameColor),
                    ),
                    SizedBox(height: 2.dh),
                    if (reason != null)
                      Text(reason, style: detail)
                    else
                      PriceText(
                        prefix: category == null ? null : '$category ·',
                        amount: service.basePrice,
                        amountStyle: detail,
                        labelStyle: detail,
                      ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm.dw),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: selected ? 1 : 0,
                child: const AppIcon(AppIcons.check, size: AppSizes.iconMd, color: AppColors.iconBrand),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/localization/catalog_labels.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_chip.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/pack_cards.dart';
import '../../../core/widgets/organisms/selection_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/packs_view_model.dart';

/// Screen 19 — Ready Packs: bundles from one provider at one price.
class PacksView extends StatefulWidget {
  const PacksView({super.key});

  @override
  State<PacksView> createState() => _PacksViewState();
}

class _PacksViewState extends State<PacksView> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final ScrollPosition position = _scroll.position;
      if (position.pixels >= position.maxScrollExtent - position.viewportDimension) {
        context.read<PacksViewModel>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _orderLabel(AppLocalizations l10n, PackOrder order) => switch (order) {
        PackOrder.savings => l10n.packOrderSavings,
        PackOrder.priceAsc => l10n.packOrderPriceAsc,
        PackOrder.priceDesc => l10n.packOrderPriceDesc,
        PackOrder.rating => l10n.packOrderRating,
        PackOrder.popular => l10n.packOrderPopular,
      };

  Future<void> _sort(PacksViewModel viewModel) async {
    final AppLocalizations l10n = context.l10n;
    final Set<PackOrder>? picked = await showSelectionSheet<PackOrder>(
      context,
      title: l10n.filtersSortBy,
      selected: <PackOrder>{viewModel.order},
      options: <SelectionOption<PackOrder>>[
        for (final PackOrder order in PackOrder.values)
          SelectionOption<PackOrder>(value: order, label: _orderLabel(l10n, order)),
      ],
    );
    if (picked != null && picked.isNotEmpty) viewModel.setOrder(picked.first);
  }

  Future<void> _refresh(PacksViewModel viewModel) async {
    final Failure? failure = await viewModel.refresh();
    if (failure != null && mounted) {
      showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final PacksViewModel viewModel = context.watch<PacksViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            color: AppColors.bgBrand,
            padding: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.xs.dw,
              MediaQuery.paddingOf(context).top + AppSpacing.xs.dh,
              AppSpacing.md.dw,
              AppSpacing.md.dh,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Semantics(
                      button: true,
                      label: l10n.backLabel,
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox.square(
                          dimension: AppSizes.touchTarget.dw,
                          child: Center(
                            child: AppIcon(AppIcons.chevronLeft, color: AppColors.iconOnBrand),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      l10n.homeReadyPacks,
                      style: textTheme.headlineMedium?.copyWith(color: AppColors.textOnBrand),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: AppSpacing.sm.dw),
                  child: Text(
                    l10n.packsSubtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textOnBrand.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm.dh),
          SizedBox(
            height: AppSizes.touchTarget.dh,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
              children: <Widget>[
                AppChip(
                  label: l10n.packsAll,
                  isSelected: viewModel.eventType == null,
                  onTap: () => viewModel.setEventType(null),
                ),
                for (final EventType type in EventType.browsable) ...<Widget>[
                  SizedBox(width: AppSpacing.xs.dw),
                  AppChip(
                    label: l10n.eventTypeLabel(type),
                    isSelected: viewModel.eventType == type,
                    onTap: () => viewModel.setEventType(type),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
            child: GestureDetector(
              onTap: () => _sort(viewModel),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.dh),
                child: Row(
                  children: <Widget>[
                    Text(
                      l10n.packsSortedBy(_orderLabel(l10n, viewModel.order)),
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    AppIcon(AppIcons.chevronDown, size: AppSizes.iconSm, color: AppColors.iconDefault),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _list(context, viewModel)),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, PacksViewModel viewModel) {
    final AppLocalizations l10n = context.l10n;
    if (viewModel.isFirstLoad) {
      return ListView(
        padding: AppSpacing.screenPaddingAll,
        children: <Widget>[
          for (int i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md.dh),
              child: Skeleton(height: 275.dh, radius: AppRadii.lgAll),
            ),
        ],
      );
    }
    if (viewModel.hasError && viewModel.items.isEmpty) {
      return ListView(
        padding: AppSpacing.screenPaddingAll,
        children: <Widget>[StateCard.error(onRetry: viewModel.load)],
      );
    }
    if (viewModel.isEmpty) {
      return ListView(
        padding: AppSpacing.screenPaddingAll,
        children: <Widget>[
          StateCard.empty(
            icon: AppIcons.layers,
            title: l10n.packsEmptyTitle,
            body: l10n.packsEmptyBody,
            actionLabel: viewModel.eventType == null ? null : l10n.packsAll,
            onAction: viewModel.eventType == null ? null : () => viewModel.setEventType(null),
          ),
        ],
      );
    }
    final List<PackCard> items = viewModel.items;
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () => _refresh(viewModel),
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPaddingAll,
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md.dh),
        itemBuilder: (BuildContext context, int index) {
          if (index == items.length) {
            if (viewModel.isLoadingMore) {
              return const Center(child: CircularProgressIndicator(color: AppColors.brand));
            }
            if (viewModel.loadMoreFailed) {
              return MainButton(
                label: l10n.stateRetry,
                style: MainButtonStyle.ghost,
                onPressed: viewModel.loadMore,
              );
            }
            return SizedBox(height: AppSpacing.md.dh);
          }
          final PackCard pack = items[index];
          return PackListCard(pack, onTap: () => context.push(AppRoutes.packFor(pack.id)));
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_chip.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/favourite_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/favourites_view_model.dart';

/// Screen 17 — Favorites, reached from the Profile tab.
class FavouritesView extends StatefulWidget {
  const FavouritesView({super.key});

  @override
  State<FavouritesView> createState() => _FavouritesViewState();
}

class _FavouritesViewState extends State<FavouritesView> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final ScrollPosition position = _scroll.position;
      if (position.pixels >= position.maxScrollExtent - position.viewportDimension) {
        context.read<FavouritesViewModel>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Takes the card off now; tells the server when the toast goes away
  /// without Undo (spec D6).
  Future<void> _remove(FavouritesViewModel viewModel, Favourite favourite) async {
    final AppLocalizations l10n = context.l10n;
    final int index = viewModel.removeLocally(favourite);
    if (index < 0) return;
    bool undone = false;
    final SnackBarClosedReason reason = await showAppToast(
      context,
      l10n.favouriteRemoved,
      tone: AppToastTone.info,
      actionLabel: l10n.undo,
      onAction: () {
        undone = true;
        viewModel.undoRemove(favourite, index);
      },
    ).closed;
    if (undone || reason == SnackBarClosedReason.action) return;
    final Failure? failure = await viewModel.commitRemove(favourite, index);
    if (failure != null && mounted) {
      showAppToast(context, l10n.favouriteFailed, tone: AppToastTone.error);
    }
  }

  void _open(Favourite favourite) => context.push(
        favourite.kind == FavouriteKind.pack
            ? AppRoutes.packFor(favourite.targetId)
            : AppRoutes.serviceFor(favourite.targetId),
      );

  Future<void> _refresh(FavouritesViewModel viewModel) async {
    final Failure? failure = await viewModel.refresh();
    if (failure != null && mounted) {
      showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final FavouritesViewModel viewModel = context.watch<FavouritesViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final bool onServices = viewModel.kind == FavouriteKind.service;

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
            child: Row(
              children: <Widget>[
                Semantics(
                  button: true,
                  label: l10n.backLabel,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.profile),
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
                  l10n.favouritesTitle,
                  style: textTheme.headlineMedium?.copyWith(color: AppColors.textOnBrand),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md.dw,
              AppSpacing.md.dh,
              AppSpacing.md.dw,
              AppSpacing.xs.dh,
            ),
            child: Row(
              children: <Widget>[
                AppChip(
                  label: l10n.favouritesServices,
                  isSelected: onServices,
                  onTap: () => viewModel.setKind(FavouriteKind.service),
                ),
                SizedBox(width: AppSpacing.xs.dw),
                AppChip(
                  label: l10n.favouritesPacks,
                  isSelected: !onServices,
                  onTap: () => viewModel.setKind(FavouriteKind.pack),
                ),
              ],
            ),
          ),
          if (onServices && viewModel.categories.isNotEmpty)
            SizedBox(
              height: AppSizes.touchTarget.dh,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
                children: <Widget>[
                  AppChip(
                    label: l10n.favouritesAll,
                    isSelected: viewModel.categoryId == null,
                    onTap: () => viewModel.setCategory(null),
                  ),
                  for (final CategoryWithCount category in viewModel.categories) ...<Widget>[
                    SizedBox(width: AppSpacing.xs.dw),
                    AppChip(
                      label: category.name.of(language),
                      isSelected: viewModel.categoryId == category.id,
                      onTap: () => viewModel.setCategory(category.id),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(child: _grid(context, viewModel)),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, FavouritesViewModel viewModel) {
    final AppLocalizations l10n = context.l10n;
    final SliverGridDelegate columns = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm.dh,
      crossAxisSpacing: AppSpacing.sm.dw,
      mainAxisExtent: 230.dh,
    );

    if (viewModel.isFirstLoad) {
      return GridView.builder(
        padding: AppSpacing.screenPaddingAll,
        gridDelegate: columns,
        itemCount: 4,
        itemBuilder: (_, _) => Skeleton(height: 230.dh, radius: AppRadii.lgAll),
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
            icon: AppIcons.heart,
            title: viewModel.kind == FavouriteKind.service
                ? l10n.favouritesEmptyServices
                : l10n.favouritesEmptyPacks,
            body: l10n.favouritesEmptyBody,
            actionLabel: l10n.favouritesExplore,
            onAction: () => context.go(AppRoutes.search),
          ),
        ],
      );
    }

    final List<Favourite> items = viewModel.items;
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () => _refresh(viewModel),
      child: GridView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPaddingAll,
        gridDelegate: columns,
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final Favourite favourite = items[index];
          return FavouriteTile(
            favourite,
            key: ValueKey<String>(favourite.id),
            onTap: () => _open(favourite),
            onRemove: () => _remove(viewModel, favourite),
          );
        },
      ),
    );
  }
}

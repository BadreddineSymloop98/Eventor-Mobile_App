import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/catalog/service_query.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/atoms/app_chip.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/selection_sheet.dart';
import '../../../core/widgets/organisms/service_result_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../filters/view/filters_drawer.dart';
import '../view_model/results_view_model.dart';

/// S2 / S2a / S2b — search results, inside the tab they were opened from:
/// Search, or Home (so Back returns to Home).
///
/// The header names what was asked for (the search, or the category for
/// S2a). "Sort" and "Filters" open a new results page for the changed query.
/// With nothing found (S2b) the active filters are listed as chips to take
/// off, one at a time or all at once.
class ResultsView extends StatefulWidget {
  const ResultsView({super.key});

  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Asks for the next page a screen before the end.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final ScrollPosition position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - position.viewportDimension) {
      context.read<ResultsViewModel>().loadMore();
    }
  }

  /// Where these results live — under Search or under Home — so a new sort
  /// or filter stays in the same tab.
  String get _base => GoRouterState.of(context).uri.path;

  void _open(ServiceQuery query) =>
      context.go(AppRoutes.resultsFor(query, base: _base));

  /// Back to the screen these results were opened from.
  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_base == AppRoutes.homeResults ? AppRoutes.home : AppRoutes.search);
    }
  }

  String _orderLabel(AppLocalizations l10n, ServiceOrder order) => switch (order) {
        ServiceOrder.relevance => l10n.sortRelevance,
        ServiceOrder.priceAsc => l10n.sortPriceLow,
        ServiceOrder.priceDesc => l10n.sortPriceHigh,
        ServiceOrder.rating => l10n.sortRating,
        ServiceOrder.popular => l10n.sortPopular,
        ServiceOrder.newest => l10n.sortNewest,
      };

  Future<void> _sort(ResultsViewModel viewModel) async {
    final AppLocalizations l10n = context.l10n;
    final Set<ServiceOrder>? picked = await showSelectionSheet<ServiceOrder>(
      context,
      title: l10n.filtersSortBy,
      selected: <ServiceOrder>{viewModel.query.order},
      options: <SelectionOption<ServiceOrder>>[
        for (final ServiceOrder order in ServiceOrder.values)
          SelectionOption<ServiceOrder>(value: order, label: _orderLabel(l10n, order)),
      ],
    );
    if (picked == null || picked.isEmpty || picked.first == viewModel.query.order) return;
    _open(viewModel.query.copyWith(order: picked.first));
  }

  Future<void> _filters(ResultsViewModel viewModel) async {
    final ServiceQuery? query = await showFiltersDrawer(
      context,
      initial: viewModel.query,
      homeWilaya: context.read<SessionController>().user?.wilaya?.code,
    );
    if (query != null && query != viewModel.query && mounted) _open(query);
  }

  Future<void> _refresh(ResultsViewModel viewModel) async {
    final Failure? failure = await viewModel.refresh();
    if (failure != null && mounted) {
      showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
    }
  }

  String _title(AppLocalizations l10n, ResultsViewModel viewModel, String language) {
    final String? q = viewModel.query.q?.trim();
    if (q != null && q.isNotEmpty) return q;
    final String? categories = categoryNames(viewModel.categories, language);
    return categories ?? l10n.resultsAllServices;
  }

  @override
  Widget build(BuildContext context) {
    final ResultsViewModel viewModel = context.watch<ResultsViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              color: AppColors.bgSurface,
              padding: EdgeInsetsDirectional.fromSTEB(
                AppSpacing.xs.dw,
                AppSpacing.xs.dh,
                AppSpacing.md.dw,
                AppSpacing.sm.dh,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Semantics(
                        button: true,
                        label: l10n.backLabel,
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: _back,
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox.square(
                            dimension: AppSizes.touchTarget.dw,
                            child: Center(
                              child: AppIcon(AppIcons.chevronLeft, color: AppColors.iconBrand),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _title(l10n, viewModel, language),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: AppSpacing.sm.dw),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            viewModel.isFirstLoad ? '' : l10n.resultsCount(viewModel.total),
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        AppChip(
                          label: l10n.resultsSortChip(_orderLabel(l10n, viewModel.query.order)),
                          isSelected: false,
                          onTap: () => _sort(viewModel),
                        ),
                        SizedBox(width: AppSpacing.xs.dw),
                        AppChip(
                          label: l10n.resultsFiltersChip(viewModel.query.filterCount),
                          isSelected: viewModel.query.filterCount > 0,
                          onTap: () => _filters(viewModel),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
            Expanded(child: _body(context, viewModel)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ResultsViewModel viewModel) {
    if (viewModel.isFirstLoad) {
      return ListView(
        padding: AppSpacing.screenPaddingAll,
        children: <Widget>[
          for (int i = 0; i < 4; i++)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm.dh),
              child: Skeleton(height: 150.dh),
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
    if (viewModel.isEmpty) return _Empty(viewModel: viewModel, onOpen: _open);

    final List<ServiceCard> items = viewModel.items;
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () => _refresh(viewModel),
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPaddingAll,
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm.dh),
        itemBuilder: (BuildContext context, int index) {
          if (index == items.length) return _Footer(viewModel: viewModel);
          final ServiceCard service = items[index];
          return ServiceResultCard(
            service,
            onTap: () => context.push(AppRoutes.serviceFor(service.id)),
          );
        },
      ),
    );
  }
}

/// The end of the list: a spinner while the next page loads, or a retry if
/// it failed.
class _Footer extends StatelessWidget {
  const _Footer({required this.viewModel});

  final ResultsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md.dh),
        child: const Center(child: CircularProgressIndicator(color: AppColors.brand)),
      );
    }
    if (viewModel.loadMoreFailed) {
      return Column(
        children: <Widget>[
          Text(
            context.l10n.resultsLoadMoreFailed,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          MainButton(
            label: context.l10n.stateRetry,
            style: MainButtonStyle.ghost,
            onPressed: viewModel.loadMore,
          ),
        ],
      );
    }
    return SizedBox(height: AppSpacing.md.dh);
  }
}

/// S2b: nothing found. Says what was asked for, lists the filters that are
/// on as chips to take off, and offers to clear them all.
class _Empty extends StatelessWidget {
  const _Empty({required this.viewModel, required this.onOpen});

  final ResultsViewModel viewModel;
  final ValueChanged<ServiceQuery> onOpen;

  String _label(BuildContext context, FilterChipKind kind) {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    final ServiceQuery query = viewModel.query;
    return switch (kind) {
      FilterChipKind.category =>
        categoryNames(viewModel.categories, language) ?? l10n.filtersCategory,
      FilterChipKind.wilaya => l10n.filtersWilaya,
      FilterChipKind.price => l10n.filtersBudget,
      FilterChipKind.rating => '${query.minRating}+',
      FilterChipKind.eventDate =>
        query.eventDate == null ? l10n.filtersEventDate : shortDate(query.eventDate!, language),
      FilterChipKind.favourites => l10n.filterChipFavourites,
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<FilterChipKind> active = viewModel.activeFilters;
    final String? q = viewModel.query.q?.trim();

    return ListView(
      padding: AppSpacing.screenPaddingAll,
      children: <Widget>[
        StateCard.empty(
          icon: AppIcons.search,
          title: l10n.resultsEmptyTitle,
          body: q != null && q.isNotEmpty
              ? '${l10n.resultsEmptySearch(q)} ${l10n.resultsEmptyBody}'
              : l10n.resultsEmptyBody,
        ),
        if (active.isNotEmpty) ...<Widget>[
          SizedBox(height: AppSpacing.md.dh),
          Wrap(
            spacing: AppSpacing.xs.dw,
            runSpacing: AppSpacing.xs.dh,
            children: <Widget>[
              for (final FilterChipKind kind in active)
                Semantics(
                  button: true,
                  label: l10n.resultsRemoveFilter(_label(context, kind)),
                  excludeSemantics: true,
                  child: AppChip(
                    label: '${_label(context, kind)}  ×',
                    isSelected: true,
                    onTap: () => onOpen(viewModel.without(kind)),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md.dh),
          MainButton(
            label: l10n.resultsClearFilters,
            style: MainButtonStyle.secondary,
            onPressed: () => onOpen(viewModel.query.clearFilters()),
          ),
        ],
      ],
    );
  }
}

/// "Photography · Catering" — the chosen categories, as the design writes a
/// pack's categories. `null` until they are known.
@visibleForTesting
String? categoryNames(List<CategoryWithCount> categories, String language) =>
    categories.isEmpty
        ? null
        : categories.map((CategoryWithCount c) => c.name.of(language)).join(' · ');

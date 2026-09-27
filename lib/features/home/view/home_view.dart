import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/catalog/service_query.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/back_to_exit.dart';
import '../../../core/widgets/molecules/section_header.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/category_rail.dart';
import '../../../core/widgets/organisms/pack_cards.dart';
import '../../../core/widgets/organisms/selection_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../filters/view/filters_drawer.dart';
import '../../shell/shell_badges.dart';
import '../../shell/view/client_shell.dart';
import '../view_model/home_view_model.dart';
import 'widgets/home_header.dart';
import 'widgets/home_sections.dart';
import 'widgets/home_skeleton.dart';

/// Screen 11 — the client's Home, the first tab.
///
/// Sections the API has nothing for are left out rather than drawn empty
/// (spec D2); the budget card always shows, as an invitation when there is
/// no budget yet (11c). Links to screens not built yet say "Coming soon".
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _comingSoon() => showComingSoon(context, context.l10n.comingSoon);

  Future<void> _refresh(HomeViewModel viewModel) async {
    final Failure? failure = await viewModel.refresh();
    if (failure != null && mounted) {
      showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
    }
  }

  Future<void> _chooseCity(HomeViewModel viewModel) async {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    final List<Wilaya> wilayas;
    try {
      wilayas = await viewModel.wilayas();
    } on Failure catch (failure) {
      if (mounted) showAppToast(context, l10n.forFailure(failure), tone: AppToastTone.error);
      return;
    }
    if (!mounted) return;

    final Set<int>? picked = await showSelectionSheet<int>(
      context,
      title: l10n.chooseCity,
      subtitle: l10n.chooseCitySubtitle,
      searchHint: l10n.wilayaSearchHint,
      selected: <int>{?viewModel.city?.code},
      options: <SelectionOption<int>>[
        for (final Wilaya wilaya in wilayas)
          SelectionOption<int>(value: wilaya.code, label: wilaya.nameFor(language)),
      ],
    );
    if (picked == null || picked.isEmpty || picked.first == viewModel.city?.code) return;

    final Failure? failure = await viewModel.changeCity(picked.first);
    if (failure != null && mounted) {
      showAppToast(context, l10n.cityChangeFailed, tone: AppToastTone.error);
    }
  }

  Future<void> _openFilters(HomeViewModel viewModel) async {
    final int? city = viewModel.city?.code;
    final ServiceQuery? query = await showFiltersDrawer(
      context,
      initial: const ServiceQuery(),
      homeWilaya: city,
    );
    if (query != null && mounted) {
      context.go(AppRoutes.resultsFor(query, base: AppRoutes.homeResults));
    }
  }

  @override
  Widget build(BuildContext context) {
    final HomeViewModel viewModel = context.watch<HomeViewModel>();
    final HomeFeed? feed = viewModel.feed;
    final bool hasUnread = context.watch<ShellBadges>().unreadNotifications > 0;

    final Widget body;
    if (feed != null) {
      body = _HomeContent(
        feed: feed,
        onComingSoon: _comingSoon,
      );
    } else if (viewModel.isFirstLoad || !viewModel.hasError) {
      body = const HomeSkeleton();
    } else {
      body = Padding(
        padding: AppSpacing.screenPaddingAll,
        child: StateCard.error(onRetry: viewModel.load),
      );
    }

    // Home is the bottom of the client's stack: Back here would close the app.
    return BackToExit(
      child: Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: ScrollToTopOnReselect(
          branch: 0,
          controller: _scroll,
          child: RefreshIndicator(
            color: AppColors.brand,
            onRefresh: () => _refresh(viewModel),
            child: ListView(
              controller: _scroll,
              // Pull to refresh works even when the content is short.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: AppSpacing.xl.dh),
              children: <Widget>[
                HomeHeader(
                  greeting: viewModel.greeting,
                  fullName: viewModel.fullName,
                  city: viewModel.city,
                  hasUnread: hasUnread,
                  isChangingCity: viewModel.isChangingCity,
                  onBell: () => context.push(AppRoutes.notifications),
                  onCity: () => _chooseCity(viewModel),
                  onSearch: () => context.go(AppRoutes.search),
                  onFilters: () => _openFilters(viewModel),
                ),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.feed, required this.onComingSoon});

  final HomeFeed feed;
  final VoidCallback onComingSoon;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Wilaya? city = feed.wilaya;

    Widget section({
      required String title,
      required Widget child,
      String? action,
      VoidCallback? onAction,
      bool bleed = false,
    }) =>
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.xl.dh),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
                child: SectionHeader(title: title, actionLabel: action, onAction: onAction),
              ),
              SizedBox(height: AppSpacing.xs.dh),
              // A rail runs to the screen edges; everything else sits in the gutter.
              if (bleed)
                child
              else
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
                  child: child,
                ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (feed.categories.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.md.dh),
            child: CategoryRail(
              categories: feed.categories,
              onTap: (CategoryRef category) => context.go(
                AppRoutes.resultsFor(
                  ServiceQuery(categoryIds: <String>{category.id}),
                  base: AppRoutes.homeResults,
                ),
              ),
            ),
          ),
        if (feed.upcomingBookings.isNotEmpty)
          section(
            title: l10n.homeYourBookings,
            action: l10n.seeAll,
            onAction: () => context.go(AppRoutes.bookings),
            child: UpcomingBookingsList(
              bookings: feed.upcomingBookings,
              onOpen: (_) => onComingSoon(),
            ),
          ),
        section(
          title: l10n.homeYourBudget,
          action: feed.budget.exists ? l10n.budgetDetails : null,
          onAction: feed.budget.exists ? onComingSoon : null,
          child: BudgetCard(budget: feed.budget, onOpen: onComingSoon),
        ),
        if (feed.packs.isNotEmpty)
          section(
            title: l10n.homeReadyPacks,
            action: l10n.seeAll,
            onAction: () => context.push(AppRoutes.packs),
            bleed: true,
            child: PacksRail(
              packs: feed.packs,
              onOpen: (PackCard pack) => context.push(AppRoutes.packFor(pack.id)),
            ),
          ),
        if (feed.nearbyServices.isNotEmpty)
          section(
            title: l10n.homeServicesNearYou,
            action: l10n.seeAll,
            onAction: () => context.go(
              AppRoutes.resultsFor(
                ServiceQuery(wilayaCodes: <int>{?city?.code}),
                base: AppRoutes.homeResults,
              ),
            ),
            child: NearbyServicesList(
              services: feed.nearbyServices,
              onOpen: (ServiceCard service) =>
                  context.push(AppRoutes.serviceFor(service.id)),
            ),
          ),
      ],
    );
  }
}

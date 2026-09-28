import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/provider_catalog/provider_catalog_repository.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_chip.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/confirm_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../shell/view/client_shell.dart' show ScrollToTopOnReselect;
import '../view_model/catalog_outcomes.dart';
import '../view_model/provider_services_view_model.dart';
import 'catalog_wording.dart';
import 'widgets/catalog_cards.dart';
import 'widgets/catalog_form_parts.dart';
import 'widgets/catalog_sheets.dart';

/// P6 My services and P10 My packs — the provider's third tab, one chip each.
///
/// `?view=packs` opens it on the Packs chip ([AppRoutes.providerPacksTab]);
/// a later link with it switches the chip on the screen already built.
class ProviderServicesView extends StatefulWidget {
  const ProviderServicesView({this.openPacks = false, super.key});

  /// Its index in the provider shell.
  static const int branch = 2;

  final bool openPacks;

  @override
  State<ProviderServicesView> createState() => _ProviderServicesViewState();
}

class _ProviderServicesViewState extends State<ProviderServicesView> {
  final ScrollController _scroll = ScrollController();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<ProviderServicesViewModel>().refresh(),
    );
  }

  @override
  void didUpdateWidget(ProviderServicesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openPacks && !oldWidget.openPacks) {
      context.read<ProviderServicesViewModel>().setTab(CatalogTab.packs);
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _scroll.dispose();
    super.dispose();
  }

  ProviderServicesViewModel get _viewModel => context.read<ProviderServicesViewModel>();

  Future<void> _refresh() async {
    final Failure? failure = await _viewModel.refresh();
    if (failure != null && mounted) _error(failure);
  }

  void _error(Failure failure) =>
      showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);

  /// Opens a form or a gallery, then shows what it changed.
  Future<void> _open(String location, {Object? extra}) async {
    await context.push(location, extra: extra);
    if (mounted) await _viewModel.refresh();
  }

  // ------------------------------------------------------------ services

  Future<void> _publishService(ProviderServiceSummary service) async {
    final AppLocalizations l10n = context.l10n;
    final PublishOutcome<ServiceMissing>? outcome = await _viewModel.publishService(service);
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case PublishDone<ServiceMissing>():
        showAppToast(context, l10n.providerServicePublished);
      case PublishChecklist<ServiceMissing>(:final List<ServiceMissing> missing):
        final bool fix = await showServiceChecklistSheet(context, missing: missing);
        if (!fix || !mounted) return;
        ServiceChecklistItem? first;
        for (final ServiceChecklistItem item in ServiceChecklistItem.values) {
          if (first == null && item.isMissingIn(missing)) first = item;
        }
        await _open(AppRoutes.providerEditServiceFor(service.id), extra: first);
      case PublishNotVerified<ServiceMissing>():
        await showNotVerifiedSheet(context);
      case PublishInvalid<ServiceMissing>():
        break;
      case PublishFailed<ServiceMissing>(:final Failure failure):
        _error(failure);
    }
  }

  Future<void> _unpublishService(ProviderServiceSummary service) async {
    final AppLocalizations l10n = context.l10n;
    final bool confirmed = await showConfirmSheet(
      context,
      title: l10n.providerServiceUnpublishTitle,
      message: l10n.providerServiceUnpublishBody,
      confirmLabel: l10n.providerServiceUnpublish,
      cancelLabel: l10n.providerServiceKeepPublished,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final Failure? failure = await _viewModel.unpublishService(service);
    if (!mounted) return;
    if (failure == null) {
      showAppToast(context, l10n.providerServiceUnpublished, tone: AppToastTone.info);
    } else {
      _error(failure);
    }
  }

  /// P6b's "Contact support": the support address when the server gives
  /// one, else its phone.
  Future<void> _contactSupport(AppConfig config) async {
    final String? email = config.supportEmail;
    final String? phone = config.supportPhone;
    final Uri target = email != null
        ? Uri(
            scheme: 'mailto',
            path: email,
            queryParameters: <String, String>{'subject': context.l10n.supportEmailSubject},
          )
        : Uri(scheme: 'tel', path: phone!.replaceAll(' ', ''));
    await launchUrl(target);
  }

  // --------------------------------------------------------------- packs

  Future<void> _publishPack(ProviderPackSummary pack) async {
    final AppLocalizations l10n = context.l10n;
    final PublishOutcome<PackMissing>? outcome = await _viewModel.publishPack(pack);
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case PublishDone<PackMissing>():
        showAppToast(context, l10n.providerPackPublished);
      case PublishChecklist<PackMissing>(:final List<PackMissing> missing):
        final bool fix = await showPackChecklistSheet(context, missing: missing);
        if (!fix || !mounted) return;
        PackChecklistItem? first;
        for (final PackChecklistItem item in PackChecklistItem.values) {
          if (first == null && item != PackChecklistItem.profile && item.isMissingIn(missing)) {
            first = item;
          }
        }
        await _open(AppRoutes.providerEditPackFor(pack.id), extra: first);
      case PublishNotVerified<PackMissing>():
        await showNotVerifiedSheet(context);
      case PublishInvalid<PackMissing>():
        break;
      case PublishFailed<PackMissing>(:final Failure failure):
        _error(failure);
    }
  }

  Future<void> _unpublishPack(ProviderPackSummary pack) async {
    final AppLocalizations l10n = context.l10n;
    final bool confirmed = await showConfirmSheet(
      context,
      title: l10n.providerPackUnpublishTitle,
      message: l10n.providerPackUnpublishBody,
      confirmLabel: l10n.providerServiceUnpublish,
      cancelLabel: l10n.providerServiceKeepPublished,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final Failure? failure = await _viewModel.unpublishPack(pack);
    if (!mounted) return;
    if (failure == null) {
      showAppToast(context, l10n.providerPackUnpublished, tone: AppToastTone.info);
    } else {
      _error(failure);
    }
  }

  void _add(ProviderServicesViewModel viewModel) {
    if (viewModel.tab == CatalogTab.packs) {
      _open(AppRoutes.providerNewPack);
    } else {
      _open(AppRoutes.providerNewService);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProviderServicesViewModel viewModel = context.watch<ProviderServicesViewModel>();
    final AppLocalizations l10n = context.l10n;
    final bool onPacks = viewModel.tab == CatalogTab.packs;
    // On the Packs chip, + makes a pack — which needs two published services.
    final bool canAdd = !onPacks || viewModel.canBuildPack;

    final Widget content;
    if (viewModel.isFirstLoad) {
      content = const CatalogListSkeleton();
    } else if (viewModel.loadFailed) {
      content = StateCard.error(onRetry: viewModel.load);
    } else if (onPacks) {
      content = _packsContent(viewModel);
    } else {
      content = _servicesContent(viewModel);
    }
    final bool centred = !viewModel.isFirstLoad &&
        !viewModel.loadFailed &&
        (onPacks ? viewModel.packs.isEmpty : viewModel.services.isEmpty);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Header(
            title: onPacks ? l10n.providerPackTabTitle : l10n.providerServiceTabTitle,
            tab: viewModel.tab,
            addLabel: onPacks ? l10n.providerPackCreate : l10n.providerAddService,
            onAdd: canAdd ? () => _add(viewModel) : null,
            onTab: viewModel.setTab,
          ),
          Expanded(
            child: ScrollToTopOnReselect(
              branch: ProviderServicesView.branch,
              controller: _scroll,
              child: RefreshIndicator(
                color: AppColors.brand,
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverPadding(
                      padding: AppSpacing.screenPaddingAll,
                      sliver: centred
                          ? SliverFillRemaining(hasScrollBody: false, child: content)
                          : SliverToBoxAdapter(child: content),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _servicesContent(ProviderServicesViewModel viewModel) {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    final AppConfig config = context.read<AppConfigRepository>().current;
    final bool hasSupport = config.supportEmail != null || config.supportPhone != null;
    if (viewModel.services.isEmpty) {
      return CatalogEmptyState(
        icon: AppIcons.briefcase,
        title: l10n.providerServiceEmptyTitle,
        body: l10n.providerServiceEmptyBody,
        action: MainButton(
          label: l10n.providerAddService,
          onPressed: () => _open(AppRoutes.providerNewService),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ProviderServiceSummary service in viewModel.services) ...<Widget>[
          if (service != viewModel.services.first) SizedBox(height: AppSpacing.md.dh),
          ServiceCatalogCard(
            key: ValueKey<String>(service.id),
            service: service,
            note: l10n.serviceNote(viewModel.noteFor(service), language),
            hiddenAt: viewModel.hiddenAt(service),
            onTap: () => _open(AppRoutes.providerEditServiceFor(service.id)),
            actions: _serviceActions(viewModel, service, hasSupport, config),
          ),
        ],
      ],
    );
  }

  Widget _serviceActions(
    ProviderServicesViewModel viewModel,
    ProviderServiceSummary service,
    bool hasSupport,
    AppConfig config,
  ) {
    final AppLocalizations l10n = context.l10n;
    final bool busy = viewModel.busyId != null;
    final bool mine = viewModel.busyId == service.id;
    void edit() => _open(AppRoutes.providerEditServiceFor(service.id));
    return switch (service.status) {
      ProviderServiceStatus.published => FormActionRow(
          secondary: MainButton(
            label: l10n.providerServiceUnpublish,
            style: MainButtonStyle.secondary,
            isLoading: mine,
            canBeTapped: !busy,
            onPressed: () => _unpublishService(service),
          ),
          primary: MainButton(label: l10n.providerServiceEdit, canBeTapped: !mine, onPressed: edit),
        ),
      ProviderServiceStatus.draft => FormActionRow(
          secondary: MainButton(
            label: l10n.providerServiceEdit,
            style: MainButtonStyle.secondary,
            canBeTapped: !mine,
            onPressed: edit,
          ),
          primary: MainButton(
            label: l10n.providerServicePublish,
            isLoading: mine,
            canBeTapped: !busy,
            onPressed: () => _publishService(service),
          ),
        ),
      ProviderServiceStatus.hidden => FormActionRow(
          secondary: hasSupport
              ? MainButton(
                  label: l10n.contactSupport,
                  style: MainButtonStyle.secondary,
                  onPressed: () => _contactSupport(config),
                )
              : null,
          primary: MainButton(label: l10n.providerServiceEdit, onPressed: edit),
        ),
    };
  }

  Widget _packsContent(ProviderServicesViewModel viewModel) {
    final AppLocalizations l10n = context.l10n;
    if (viewModel.packs.isEmpty) {
      final bool canBuild = viewModel.canBuildPack;
      final bool hasDrafts =
          viewModel.services.any((ProviderServiceSummary s) => !s.isPublished && !s.isHidden);
      return CatalogEmptyState(
        icon: AppIcons.layers,
        title: l10n.providerPackEmptyTitle,
        body: canBuild
            ? l10n.providerPackEmptyBody
            : l10n.providerPackEmptyNeedsServices(viewModel.publishedServicesCount),
        action: canBuild
            ? MainButton(label: l10n.providerPackCreate, onPressed: () => _open(AppRoutes.providerNewPack))
            : hasDrafts
                // A draft is one Publish away: back to the services.
                ? MainButton(
                    label: l10n.providerPackPublishAnother,
                    onPressed: () => viewModel.setTab(CatalogTab.services),
                  )
                : MainButton(
                    label: l10n.providerAddService,
                    onPressed: () => _open(AppRoutes.providerNewService),
                  ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ProviderPackSummary pack in viewModel.packs) ...<Widget>[
          if (pack != viewModel.packs.first) SizedBox(height: AppSpacing.md.dh),
          PackCatalogCard(
            key: ValueKey<String>(pack.id),
            pack: pack,
            note: _packNote(viewModel, pack),
            onTap: () => _open(AppRoutes.providerEditPackFor(pack.id)),
            actions: _packActions(viewModel, pack),
          ),
        ],
      ],
    );
  }

  /// "Needs attention — …" on a published pack; the price rule on one that
  /// is not.
  String? _packNote(ProviderServicesViewModel viewModel, ProviderPackSummary pack) {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    if (pack.needsAttention) {
      for (final PackAttention reason in pack.attention) {
        switch (reason.code) {
          case PackAttentionCode.itemNotPublished:
            for (final ProviderServiceSummary s in viewModel.services) {
              if (s.id == reason.serviceId) return l10n.providerPackAttentionItem(s.title.of(language));
            }
          case PackAttentionCode.itemDeleted:
            return l10n.providerPackAttentionDeleted;
          case PackAttentionCode.providerNotVerified || PackAttentionCode.providerBlocked:
            return l10n.providerPackAttentionProfile;
          case PackAttentionCode.providerDeleted || PackAttentionCode.unknown:
            break;
        }
      }
      return l10n.providerPackAttentionDeleted;
    }
    if (!pack.isPublished && !amountIsPositive(pack.savings)) return l10n.providerPackPriceRule;
    return null;
  }

  Widget _packActions(ProviderServicesViewModel viewModel, ProviderPackSummary pack) {
    final AppLocalizations l10n = context.l10n;
    final bool busy = viewModel.busyId != null;
    final bool mine = viewModel.busyId == pack.id;
    void edit() => _open(AppRoutes.providerEditPackFor(pack.id));
    if (pack.isPublished) {
      return FormActionRow(
        secondary: MainButton(
          label: l10n.providerServiceUnpublish,
          style: MainButtonStyle.secondary,
          isLoading: mine,
          canBeTapped: !busy,
          onPressed: () => _unpublishPack(pack),
        ),
        primary: MainButton(label: l10n.providerServiceEdit, canBeTapped: !mine, onPressed: edit),
      );
    }
    return FormActionRow(
      secondary: MainButton(
        label: l10n.providerServiceEdit,
        style: MainButtonStyle.secondary,
        canBeTapped: !mine,
        onPressed: edit,
      ),
      primary: MainButton(
        label: l10n.providerServicePublish,
        isLoading: mine,
        canBeTapped: !busy,
        onPressed: () => _publishPack(pack),
      ),
    );
  }
}

/// The tab-root header (§1.1): title and +, then the two chips.
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.tab,
    required this.addLabel,
    required this.onAdd,
    required this.onTab,
  });

  final String title;
  final CatalogTab tab;
  final String addLabel;
  final VoidCallback? onAdd;
  final ValueChanged<CatalogTab> onTab;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md.dw,
        MediaQuery.paddingOf(context).top + AppSpacing.xl.dh,
        AppSpacing.md.dw,
        AppSpacing.sm.dh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                enabled: onAdd != null,
                label: addLabel,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onAdd,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox.square(
                    dimension: AppSizes.touchTarget.dw,
                    child: Center(
                      child: AppIcon(
                        AppIcons.plus,
                        color: onAdd == null ? AppColors.textDisabled : AppColors.iconBrand,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs.dh),
          Row(
            children: <Widget>[
              AppChip(
                label: l10n.providerServiceChipServices,
                isSelected: tab == CatalogTab.services,
                onTap: () => onTab(CatalogTab.services),
              ),
              SizedBox(width: 6.dw),
              AppChip(
                label: l10n.providerServiceChipPacks,
                isSelected: tab == CatalogTab.packs,
                onTap: () => onTab(CatalogTab.packs),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

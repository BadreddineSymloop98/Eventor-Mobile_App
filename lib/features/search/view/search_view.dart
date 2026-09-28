import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/catalog/service_query.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/category_icon.dart';
import '../../../core/widgets/atoms/icon_tile.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/layout/content_container.dart';
import '../../../core/widgets/molecules/section_header.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../shell/view/client_shell.dart';
import '../view_model/search_view_model.dart';

/// S1 — Search, before anything is typed.
class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _field = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _field.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submit(SearchViewModel viewModel, String text) async {
    final ServiceQuery? query = await viewModel.submit(text);
    if (query == null || !mounted) return;
    context.go(AppRoutes.resultsFor(query));
  }

  @override
  Widget build(BuildContext context) {
    final SearchViewModel viewModel = context.watch<SearchViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SafeArea(
        child: ScrollToTopOnReselect(
          branch: 1,
          controller: _scroll,
          child: ListView(
            controller: _scroll,
            padding: AppSpacing.screenPaddingAll,
            children: <Widget>[
              ContentContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextField(
                      controller: _field,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (String text) => _submit(viewModel, text),
                      decoration: InputDecoration(
                        hintText: l10n.homeSearchHint,
                        prefixIcon: Padding(
                          padding: EdgeInsetsDirectional.all(AppSpacing.sm.dw),
                          child: AppIcon(AppIcons.search, size: AppSizes.iconMd, color: AppColors.iconDefault),
                        ),
                        filled: true,
                        fillColor: AppColors.bgSurface,
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: AppRadii.mdAll,
                          borderSide: BorderSide(color: AppColors.borderDefault),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: AppRadii.mdAll,
                          borderSide: BorderSide(color: AppColors.borderBrand, width: 1.5),
                        ),
                      ),
                    ),
                    if (viewModel.recents.isNotEmpty) ...<Widget>[
                      SizedBox(height: AppSpacing.xl.dh),
                      SectionHeader(
                        title: l10n.searchRecent,
                        actionLabel: l10n.searchClear,
                        onAction: viewModel.clearRecents,
                      ),
                      for (final String recent in viewModel.recents)
                        _RecentRow(
                          text: recent,
                          onOpen: () => _submit(viewModel, recent),
                          onRemove: () => viewModel.removeRecent(recent),
                        ),
                    ],
                    SizedBox(height: AppSpacing.xl.dh),
                    SectionHeader(title: l10n.searchBrowseCategories),
                    SizedBox(height: AppSpacing.xs.dh),
                    if (viewModel.isLoadingCategories && viewModel.categories.isEmpty)
                      for (int i = 0; i < 5; i++)
                        Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.xs.dh),
                          child: Skeleton(height: 56.dh),
                        )
                    else if (viewModel.hasError && viewModel.categories.isEmpty)
                      StateCard.error(onRetry: viewModel.loadCategories)
                    else
                      for (final CategoryWithCount category in viewModel.categories)
                        _CategoryRow(
                          icon: categoryIcon(category.icon),
                          name: category.name.of(language),
                          count: l10n.servicesCount(category.servicesCount),
                          textTheme: textTheme,
                          onTap: () => context.go(
                            AppRoutes.resultsFor(ServiceQuery(categoryIds: <String>{category.id})),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.text, required this.onOpen, required this.onRemove});

  final String text;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: onOpen,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.dh),
              child: Row(
                children: <Widget>[
                  AppIcon(AppIcons.search, size: AppSizes.iconMd, color: AppColors.iconDefault),
                  SizedBox(width: AppSpacing.sm.dw),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: context.l10n.searchRemoveRecent(text),
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: SizedBox.square(
              dimension: AppSizes.touchTarget.dw,
              child: Center(
                child: AppIcon(AppIcons.close, size: AppSizes.iconMd, color: AppColors.iconDefault),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.icon,
    required this.name,
    required this.count,
    required this.textTheme,
    required this.onTap,
  });

  final AppIcons icon;
  final String name;
  final String count;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.dh),
          child: Row(
            children: <Widget>[
              IconTile(icon),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(name, style: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary)),
                    Text(count, style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              AppIcon(AppIcons.chevronRight, size: AppSizes.iconMd, color: AppColors.iconDefault),
            ],
          ),
        ),
      ),
    );
  }
}

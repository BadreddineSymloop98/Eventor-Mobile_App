import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/catalog/service_query.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/reference/reference_repository.dart';
import '../../../core/widgets/atoms/app_chip.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/app_switch.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/organisms/app_bottom_sheet.dart';
import '../../../core/widgets/organisms/month_calendar.dart';
import '../../../core/widgets/organisms/range_slider_field.dart';
import '../../../core/widgets/organisms/side_drawer.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/filters_view_model.dart';
import 'wilaya_drill_in.dart';

/// Opens 11a over the current screen and returns the query to show, or
/// `null` if it was closed without "Show".
Future<ServiceQuery?> showFiltersDrawer(
  BuildContext context, {
  required ServiceQuery initial,
  required int? homeWilaya,
}) {
  final CatalogRepository catalog = context.read<CatalogRepository>();
  final ReferenceRepository reference = context.read<ReferenceRepository>();
  return showSideDrawer<ServiceQuery>(
    context,
    barrierLabel: context.l10n.filtersClose,
    builder: (_) => ChangeNotifierProvider<FiltersViewModel>(
      create: (_) => FiltersViewModel(
        initial: initial,
        catalog: catalog,
        reference: reference,
        homeWilaya: homeWilaya,
      ),
      child: const FiltersPanel(),
    ),
  );
}

/// The drawer's content: the groups, or the wilaya drill-in in their place.
class FiltersPanel extends StatefulWidget {
  const FiltersPanel({super.key});

  @override
  State<FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  bool _choosingWilayas = false;

  @override
  Widget build(BuildContext context) {
    final FiltersViewModel viewModel = context.watch<FiltersViewModel>();

    // A cross-fade between the two pages of the drawer; Back returns to the
    // groups with the selection kept.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _choosingWilayas
          ? WilayaDrillIn(
              key: const ValueKey<String>('wilayas'),
              wilayas: viewModel.allWilayas,
              selected: viewModel.query.wilayaCodes,
              onBack: () => setState(() => _choosingWilayas = false),
              onDone: (Set<int> codes) {
                viewModel.setWilayas(codes);
                setState(() => _choosingWilayas = false);
              },
            )
          : _FilterGroups(
              key: const ValueKey<String>('groups'),
              viewModel: viewModel,
              onAllWilayas: () => setState(() => _choosingWilayas = true),
            ),
    );
  }
}

class _FilterGroups extends StatelessWidget {
  const _FilterGroups({
    required this.viewModel,
    required this.onAllWilayas,
    super.key,
  });

  final FiltersViewModel viewModel;
  final VoidCallback onAllWilayas;

  static const List<num> _ratings = <num>[4.5, 4, 3.5];

  String _orderLabel(AppLocalizations l10n, ServiceOrder order) => switch (order) {
        ServiceOrder.relevance => l10n.sortRelevance,
        ServiceOrder.priceAsc => l10n.sortPriceLow,
        ServiceOrder.priceDesc => l10n.sortPriceHigh,
        ServiceOrder.rating => l10n.sortRating,
        ServiceOrder.popular => l10n.sortPopular,
        ServiceOrder.newest => l10n.sortNewest,
      };

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showEventDateSheet(
      context,
      selected: viewModel.query.eventDate,
    );
    if (picked != null) viewModel.setEventDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final ServiceQuery query = viewModel.query;
    final TextStyle overline = AppTextStyles.overlineForLocale(
      Localizations.localeOf(context),
    ).copyWith(color: AppColors.textSecondary);
    final DateTime? date = query.eventDate;
    final int? count = viewModel.resultCount;

    Widget group(String label, Widget child) => Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.xl.dh),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label.toUpperCase(), style: overline),
              SizedBox(height: AppSpacing.xs.dh),
              child,
            ],
          ),
        );

    Widget chips(List<Widget> children) => Wrap(
          spacing: AppSpacing.xs.dw,
          runSpacing: AppSpacing.xs.dh,
          children: children,
        );

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md.dw,
            AppSpacing.md.dh,
            AppSpacing.xs.dw,
            AppSpacing.xs.dh,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.filtersTitle,
                  style: textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
                ),
              ),
              Semantics(
                button: true,
                label: l10n.filtersClose,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox.square(
                    dimension: AppSizes.touchTarget.dw,
                    child: Center(
                      child: AppIcon(AppIcons.close, color: AppColors.iconDefault),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
            children: <Widget>[
              group(
                l10n.filtersSortBy,
                chips(<Widget>[
                  for (final ServiceOrder order in ServiceOrder.values)
                    AppChip(
                      label: _orderLabel(l10n, order),
                      isSelected: query.order == order,
                      onTap: () => viewModel.setOrder(order),
                    ),
                ]),
              ),
              if (viewModel.categories.isNotEmpty)
                group(
                  l10n.filtersCategory,
                  chips(<Widget>[
                    for (final CategoryWithCount category in viewModel.categories)
                      AppChip(
                        label: category.name.of(language),
                        isSelected: query.categoryIds.contains(category.id),
                        onTap: () => viewModel.toggleCategory(category.id),
                      ),
                  ]),
                ),
              group(
                l10n.filtersWilaya,
                chips(<Widget>[
                  for (final Wilaya wilaya in viewModel.wilayaChips)
                    AppChip(
                      label: wilaya.nameFor(language),
                      isSelected: query.wilayaCodes.contains(wilaya.code),
                      onTap: () => viewModel.toggleWilaya(wilaya.code),
                    ),
                  AppChip(
                    label: l10n.filtersAllWilayas,
                    isSelected: false,
                    onTap: viewModel.allWilayas.isEmpty ? null : onAllWilayas,
                  ),
                ]),
              ),
              group(
                l10n.filtersBudget,
                RangeSliderField(
                  values: RangeValues(
                    (query.priceMin ?? 0).toDouble(),
                    (query.priceMax ?? ServiceQuery.priceCeiling).toDouble(),
                  ),
                  max: ServiceQuery.priceCeiling.toDouble(),
                  onChanged: (RangeValues values) =>
                      viewModel.setPrice(values.start, values.end),
                ),
              ),
              group(
                l10n.filtersEventDate,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => _pickDate(context),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: AppSizes.controlMd.dh,
                        padding: EdgeInsetsDirectional.only(
                          start: AppSpacing.sm.dw,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: AppRadii.mdAll,
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Row(
                          children: <Widget>[
                            AppIcon(AppIcons.calendar, size: AppSizes.iconMd, color: AppColors.iconBrand),
                            SizedBox(width: AppSpacing.xs.dw),
                            Expanded(
                              child: Text(
                                date == null ? l10n.filtersEventDateAny : shortDate(date, language),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: date == null ? AppColors.textSecondary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (date != null)
                              Semantics(
                                button: true,
                                label: l10n.filtersEventDateClear,
                                excludeSemantics: true,
                                child: GestureDetector(
                                  onTap: () => viewModel.setEventDate(null),
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
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs.dh),
                    Text(
                      l10n.filtersEventDateHint,
                      style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              group(
                l10n.filtersRating,
                chips(<Widget>[
                  for (final num rating in _ratings)
                    AppChip(
                      label: '$rating+',
                      isSelected: query.minRating == rating,
                      onTap: () => viewModel.setMinRating(rating),
                    ),
                  AppChip(
                    label: l10n.filtersRatingAny,
                    isSelected: query.minRating == null,
                    onTap: () => viewModel.setMinRating(null),
                  ),
                ]),
              ),
              group(
                l10n.filtersSaved,
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.filtersFavouritesOnly,
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    AppSwitch(
                      value: query.favouritesOnly,
                      onChanged: viewModel.setFavouritesOnly,
                      semanticLabel: l10n.filtersFavouritesOnly,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md.dw,
            AppSpacing.sm.dh,
            AppSpacing.md.dw,
            AppSpacing.md.dh,
          ),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderDefault)),
          ),
          child: Row(
            children: <Widget>[
              MainButton(
                label: l10n.filtersClearAll,
                style: MainButtonStyle.ghost,
                onPressed: query.filterCount == 0 && query.order == ServiceOrder.relevance
                    ? null
                    : viewModel.clearAll,
              ),
              SizedBox(width: AppSpacing.xs.dw),
              Expanded(
                child: MainButton(
                  label: count == null ? l10n.filtersShow : l10n.filtersShowCount(count),
                  isLoading: viewModel.isCounting,
                  onPressed: () => Navigator.of(context).pop(query),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A calendar in a sheet for the filters' event date: any day from today on.
Future<DateTime?> showEventDateSheet(
  BuildContext context, {
  required DateTime? selected,
}) {
  return showAppBottomSheet<DateTime>(
    context,
    builder: (BuildContext sheetContext) => _EventDateSheet(selected: selected),
  );
}

class _EventDateSheet extends StatefulWidget {
  const _EventDateSheet({required this.selected});

  final DateTime? selected;

  @override
  State<_EventDateSheet> createState() => _EventDateSheetState();
}

class _EventDateSheetState extends State<_EventDateSheet> {
  late DateTime _month = widget.selected ?? DateTime.now();

  /// Every day from today on can be chosen; the filter itself narrows to
  /// providers free that day.
  Availability _open(DateTime month) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int days = DateTime(month.year, month.month + 1, 0).day;
    return Availability(
      month: '${month.year}-${month.month}',
      minNoticeDays: 0,
      firstBookableDate: today,
      days: <AvailabilityDay>[
        for (int d = 1; d <= days; d++)
          AvailabilityDay(
            date: DateTime(month.year, month.month, d),
            state: DateTime(month.year, month.month, d).isBefore(today)
                ? DayState.blocked
                : DayState.available,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: context.l10n.eventDateSheetTitle,
      body: MonthCalendar(
        month: _month,
        availability: _open(_month),
        selected: widget.selected,
        firstMonth: DateTime.now(),
        onMonthChanged: (DateTime month) => setState(() => _month = month),
        onSelect: (DateTime day) => Navigator.of(context).pop(day),
      ),
    );
  }
}

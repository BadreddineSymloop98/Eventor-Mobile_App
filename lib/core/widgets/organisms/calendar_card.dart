import 'package:flutter/material.dart';

import '../../catalog/models/availability.dart';
import '../../constants/ui_helpers.dart';
import '../../formatting/date_format.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';
import '../molecules/main_button.dart';
import 'month_calendar.dart';

/// "Pick a date" on 12 and 20: the calendar in a card, what was picked, and
/// the notes beneath it. A month that failed to load shows a retry in place
/// of the grid.
class CalendarCard extends StatelessWidget {
  const CalendarCard({
    required this.month,
    required this.firstMonth,
    required this.availability,
    required this.monthFailed,
    required this.selected,
    required this.onSelect,
    required this.onMonthChanged,
    required this.onRetry,
    required this.notes,
    this.marked,
    this.legend = const CalendarLegendLabels(),
    this.footer,
    super.key,
  });

  /// The booking's current day, outlined (B6).
  final DateTime? marked;
  final CalendarLegendLabels legend;

  /// Replaces the "Selected: …" line under the grid — the time block and
  /// the date-and-time summary of B1, B6 and B9.
  final Widget? footer;

  final DateTime month;
  final DateTime firstMonth;
  final Availability? availability;
  final bool monthFailed;
  final DateTime? selected;

  /// `null` makes the calendar read-only.
  final ValueChanged<DateTime>? onSelect;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onRetry;

  /// Lines under the card — the notice period, how the time is confirmed.
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final DateTime? picked = selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: EdgeInsetsDirectional.all(AppSpacing.sm.dw),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: AppElevation.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (monthFailed)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md.dh),
                  child: Column(
                    children: <Widget>[
                      Text(
                        context.l10n.monthLoadFailed,
                        style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      MainButton(
                        label: context.l10n.stateRetry,
                        style: MainButtonStyle.ghost,
                        onPressed: onRetry,
                      ),
                    ],
                  ),
                )
              else
                MonthCalendar(
                  month: month,
                  availability: availability,
                  selected: selected,
                  onSelect: onSelect,
                  onMonthChanged: onMonthChanged,
                  firstMonth: firstMonth,
                  marked: marked,
                  legend: legend,
                ),
              if (footer case final Widget below) ...<Widget>[
                SizedBox(height: AppSpacing.sm.dh),
                below,
              ] else if (picked != null) ...<Widget>[
                SizedBox(height: AppSpacing.sm.dh),
                Container(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.sm.dw,
                    vertical: AppSpacing.xs.dh,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgBrandSubtle,
                    borderRadius: AppRadii.smAll,
                  ),
                  child: Row(
                    children: <Widget>[
                      AppIcon(AppIcons.check, size: AppSizes.iconMd, color: AppColors.iconBrand),
                      SizedBox(width: AppSpacing.xs.dw),
                      Text(
                        context.l10n.selectedDateLabel,
                        style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      SizedBox(width: AppSpacing.xs.dw),
                      Text(
                        shortDate(picked, language),
                        style: textTheme.titleSmall?.copyWith(color: AppColors.textBrand),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        for (final String note in notes) ...<Widget>[
          SizedBox(height: AppSpacing.xs.dh),
          Text(
            note,
            style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

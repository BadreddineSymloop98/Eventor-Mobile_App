import 'package:flutter/material.dart';
// Only DateFormat: intl's own TextDirection would shadow Flutter's.
import 'package:intl/intl.dart' show DateFormat;

import '../../catalog/models/availability.dart';
import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';
import '../atoms/skeleton.dart';

/// A month of a service's or a pack's availability — "Pick a date" on 12 and
/// 20.
///
/// Weeks start on Sunday, as drawn, and the columns follow the reading
/// direction, so in Arabic Sunday is on the right. Day states come from the
/// API: available days are tinted and can be picked, fully booked ones are
/// struck through, and everything else — blocked, or too soon — is greyed
/// out. Numbers stay Western digits in both languages.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    required this.month,
    required this.availability,
    required this.selected,
    required this.onSelect,
    required this.onMonthChanged,
    this.firstMonth,
    this.showLegend = true,
    super.key,
  });

  /// Any day in the month shown.
  final DateTime month;

  /// `null` while the month loads — the grid shows skeletons.
  final Availability? availability;
  final DateTime? selected;

  /// `null` makes the calendar read-only: states show, nothing can be
  /// picked (a provider who paused bookings).
  final ValueChanged<DateTime>? onSelect;
  final ValueChanged<DateTime> onMonthChanged;

  /// The earliest month the back arrow reaches — the current one.
  final DateTime? firstMonth;

  /// The availability key under the grid. Off for a plain date picker,
  /// where there is nothing booked to explain.
  final bool showLegend;

  static const double _cellHeight = 40;

  DateTime get _first => DateTime(month.year, month.month);

  bool get _canGoBack {
    final DateTime? floor = firstMonth;
    if (floor == null) return true;
    return _first.isAfter(DateTime(floor.year, floor.month));
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).languageCode;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MonthBar(
          title: DateFormat.MMMM(locale).format(_first),
          year: '${_first.year}',
          canGoBack: _canGoBack,
          onBack: () => onMonthChanged(DateTime(_first.year, _first.month - 1)),
          onForward: () =>
              onMonthChanged(DateTime(_first.year, _first.month + 1)),
        ),
        SizedBox(height: AppSpacing.sm.dh),
        Row(
          children: <Widget>[
            for (int i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  _weekday(locale, i),
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.xs.dh),
        _grid(context),
        if (showLegend) ...<Widget>[
          SizedBox(height: AppSpacing.sm.dh),
          const _Legend(),
        ],
      ],
    );
  }

  /// Short weekday names from a known Sunday (1 March 2026). Arabic uses the
  /// one-letter form, which fits a 41pt column.
  static String _weekday(String locale, int fromSunday) {
    final DateTime day = DateTime(2026, 3, 1 + fromSunday);
    if (locale == 'ar') return DateFormat('EEEEE', locale).format(day);
    final String short = DateFormat.E(locale).format(day);
    return short.length > 2 ? short.substring(0, 2) : short;
  }

  Widget _grid(BuildContext context) {
    final int daysInMonth = DateTime(_first.year, _first.month + 1, 0).day;
    // DateTime.weekday is 1 (Monday) to 7 (Sunday); Sunday leads.
    final int leading = _first.weekday % 7;
    final int cells = ((leading + daysInMonth) / 7).ceil() * 7;
    final Availability? states = availability;

    return Column(
      children: <Widget>[
        for (int row = 0; row < cells / 7; row++)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xs2.dh),
            child: Row(
              children: <Widget>[
                for (int col = 0; col < 7; col++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.xs2.dw / 2,
                      ),
                      child: _cell(
                        context,
                        row * 7 + col - leading + 1,
                        daysInMonth,
                        states,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(
    BuildContext context,
    int day,
    int daysInMonth,
    Availability? states,
  ) {
    final double height = _cellHeight.dh;
    if (day < 1 || day > daysInMonth) return SizedBox(height: height);
    if (states == null) {
      return Skeleton(height: height, radius: AppRadii.smAll);
    }

    final DateTime date = DateTime(_first.year, _first.month, day);
    final DayState state = states.stateOf(date);
    final DateTime? chosen = selected;
    final bool isSelected = chosen != null && _sameDay(chosen, date);
    final ValueChanged<DateTime>? pick = onSelect;
    final bool canPick = pick != null && state == DayState.available;
    final TextStyle? base = Theme.of(context).textTheme.bodyMedium;

    final (Color? fill, Color text) = switch (state) {
      _ when isSelected => (AppColors.bgBrand, AppColors.textOnBrand),
      DayState.available => (AppColors.bgBrandSubtle, AppColors.textPrimary),
      DayState.busy => (null, AppColors.textSecondary),
      DayState.blocked => (null, AppColors.textDisabled),
    };

    return Semantics(
      button: canPick,
      selected: isSelected,
      enabled: canPick,
      child: GestureDetector(
        onTap: canPick ? () => pick(date) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadii.smAll,
          ),
          child: Text(
            '$day',
            textDirection: TextDirection.ltr,
            style: base?.copyWith(
              color: text,
              decoration: state == DayState.busy && !isSelected
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.title,
    required this.year,
    required this.canGoBack,
    required this.onBack,
    required this.onForward,
  });

  final String title;
  final String year;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
        );

    return Row(
      children: <Widget>[
        _Arrow(
          icon: AppIcons.chevronLeft,
          label: context.l10n.calendarPreviousMonth,
          onTap: canGoBack ? onBack : null,
        ),
        Expanded(
          // Month and year as separate runs, so the year keeps Western digits
          // and its place in Arabic.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(title, style: style),
              SizedBox(width: AppSpacing.xs2.dw),
              Text(year, textDirection: TextDirection.ltr, style: style),
            ],
          ),
        ),
        _Arrow(
          icon: AppIcons.chevronRight,
          label: context.l10n.calendarNextMonth,
          onTap: onForward,
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.label, required this.onTap});

  final AppIcons icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: AppSizes.touchTarget.dw,
          child: Center(
            // Directional glyphs: "previous" points back in either language.
            child: AppIcon(
              icon,
              color: enabled ? AppColors.iconBrand : AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
        );

    Widget item(Widget swatch, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            swatch,
            SizedBox(width: AppSpacing.xs2.dw),
            Text(label, style: style),
          ],
        );

    Widget box(Color? fill, {bool outlined = false}) => Container(
          width: AppSpacing.sm.dw,
          height: AppSpacing.sm.dw,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadii.xsAll,
            border: outlined ? Border.all(color: AppColors.borderDefault) : null,
          ),
        );

    return Wrap(
      spacing: AppSpacing.md.dw,
      runSpacing: AppSpacing.xs.dh,
      children: <Widget>[
        item(box(AppColors.bgBrand), context.l10n.calendarSelected),
        item(box(AppColors.bgBrandSubtle), context.l10n.calendarAvailable),
        item(
          Text(
            '—',
            style: style?.copyWith(decoration: TextDecoration.lineThrough),
          ),
          context.l10n.calendarBooked,
        ),
        item(box(null, outlined: true), context.l10n.calendarUnavailable),
      ],
    );
  }
}

import 'package:flutter/material.dart';
// Only DateFormat: intl's own TextDirection would shadow Flutter's.
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/availability/availability_repository.dart';
import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/formatting/booking_format.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/atoms/skeleton.dart';
import '../../../../l10n/app_localizations.dart';

/// How a day of the provider's calendar is painted — the P15 legend's
/// swatches. The design copied its cells from the client date picker and
/// used none of them; the cells follow the legend instead (known defect).
class ProviderDayStyle {
  const ProviderDayStyle._(this.fill, this.border, this.text, {this.struck = false});

  /// The tint over a cell, so the number stays readable on every state.
  static const double _wash = 0.14;

  static ProviderDayStyle of(ProviderDayStatus status) => switch (status) {
        ProviderDayStatus.free => const ProviderDayStyle._(
            AppColors.bgSurface,
            AppColors.borderDefault,
            AppColors.textPrimary,
          ),
        ProviderDayStatus.partial => _tinted(AppColors.borderBrandSubtle),
        // The legend draws Blocked grey with a strike line.
        ProviderDayStatus.blocked => ProviderDayStyle._(
            AppColors.statusCompleted.withValues(alpha: _wash),
            AppColors.statusCompleted,
            AppColors.textSecondary,
            struck: true,
          ),
        ProviderDayStatus.held => _tinted(AppColors.statusPending),
        ProviderDayStatus.booked => _tinted(AppColors.statusAccepted),
      };

  static ProviderDayStyle _tinted(Color color) =>
      ProviderDayStyle._(color.withValues(alpha: _wash), color, AppColors.textPrimary);

  final Color fill;
  final Color border;
  final Color text;
  final bool struck;
}

/// What the legend and screen readers call [status].
String providerDayStatusLabel(AppLocalizations l10n, ProviderDayStatus status) => switch (status) {
      ProviderDayStatus.free => l10n.availabilityLegendFree,
      ProviderDayStatus.partial => l10n.availabilityLegendPartial,
      ProviderDayStatus.blocked => l10n.availabilityLegendBlocked,
      ProviderDayStatus.held => l10n.availabilityLegendHeld,
      ProviderDayStatus.booked => l10n.availabilityLegendBooked,
    };

/// P15's month: the provider's own days, painted by what is on them.
///
/// Built for the provider rather than on the client's `MonthCalendar`,
/// which only lets available days be picked: here every day can be opened.
/// Weeks start on Sunday like the client calendar, and the columns follow
/// the reading direction — in Arabic Sunday is on the right, and every
/// number sits under its own weekday (the Arabic frame's grid did not).
/// Past days are faded and open only when something was on them; today
/// carries a dot under its number.
class ProviderMonthCalendar extends StatelessWidget {
  const ProviderMonthCalendar({
    required this.month,
    required this.data,
    required this.today,
    required this.selected,
    required this.canGoBack,
    required this.onDayTap,
    required this.onMonthChanged,
    this.failure,
    super.key,
  });

  /// Any day in the month shown.
  final DateTime month;

  /// `null` while the month loads — skeleton cells.
  final AvailabilityMonth? data;

  /// Shown instead of the grid when the month could not load: the message
  /// and a retry.
  final Widget? failure;
  final DateTime today;
  final DateTime? selected;
  final bool canGoBack;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<DateTime> onMonthChanged;

  static const double _cellHeight = 40;

  DateTime get _first => DateTime(month.year, month.month);

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).languageCode;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget? problem = failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MonthBar(
          title: DateFormat.MMMM(locale).format(_first),
          year: '${_first.year}',
          onBack: canGoBack ? () => onMonthChanged(DateTime(_first.year, _first.month - 1)) : null,
          onForward: () => onMonthChanged(DateTime(_first.year, _first.month + 1)),
        ),
        SizedBox(height: AppSpacing.sm.dh),
        Row(
          children: <Widget>[
            for (int i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  _weekday(locale, i),
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.sm.dh),
        problem ?? _grid(context),
        SizedBox(height: AppSpacing.sm.dh),
        const ProviderCalendarLegend(),
      ],
    );
  }

  /// Short weekday names from a known Sunday (1 March 2026) — the client
  /// calendar's: Arabic takes the one-letter form, which fits the column.
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
    final int rows = ((leading + daysInMonth) / 7).ceil();

    return Column(
      children: <Widget>[
        for (int row = 0; row < rows; row++)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xs2.dh),
            child: Row(
              children: <Widget>[
                for (int col = 0; col < 7; col++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.xs2.dw / 2),
                      child: _cell(context, row * 7 + col - leading + 1, daysInMonth),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, int number, int daysInMonth) {
    final double height = _cellHeight.dh;
    if (number < 1 || number > daysInMonth) return SizedBox(height: height);
    final AvailabilityMonth? loaded = data;
    if (loaded == null) return Skeleton(height: height, radius: AppRadii.smAll);

    final DateTime date = DateTime(_first.year, _first.month, number);
    return _DayCell(
      key: ValueKey<DateTime>(date),
      day: loaded.dayOf(date),
      isPast: date.isBefore(today),
      isToday: date == today,
      isSelected: selected == date,
      height: height,
      onTap: () => onDayTap(date),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isPast,
    required this.isToday,
    required this.isSelected,
    required this.height,
    required this.onTap,
    super.key,
  });

  /// How faded a past day is — still readable, as history.
  static const double _pastOpacity = 0.4;
  static const double _todayDot = 4;

  final ProviderDay day;
  final bool isPast;
  final bool isToday;
  final bool isSelected;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String locale = Localizations.localeOf(context).languageCode;
    final ProviderDayStyle style = ProviderDayStyle.of(day.status);
    // A past day opens only to show what was on it.
    final bool canOpen = !isPast || day.items.isNotEmpty;
    final Color text = isSelected ? AppColors.textOnBrand : style.text;
    final TextStyle? number = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: text,
          fontWeight: isToday || isSelected ? FontWeight.w700 : null,
          decoration: style.struck && !isSelected ? TextDecoration.lineThrough : null,
          decorationColor: text,
        );

    final Widget cell = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: height,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.bgBrand : style.fill,
        borderRadius: AppRadii.smAll,
        border: Border.all(color: isSelected ? AppColors.borderBrand : style.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('${day.date.day}', textDirection: TextDirection.ltr, style: number),
          if (isToday)
            Container(
              width: _todayDot,
              height: _todayDot,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textOnBrand : AppColors.iconBrand,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );

    return Semantics(
      button: canOpen,
      enabled: canOpen,
      selected: isSelected,
      label: <String>[
        weekdayDayMonth(day.date, locale),
        providerDayStatusLabel(l10n, day.status),
        if (isToday) l10n.availabilityToday,
      ].join(', '),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: canOpen ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: isPast ? Opacity(opacity: _pastOpacity, child: cell) : cell,
      ),
    );
  }
}

/// The key under the grid: the five day states with their swatches, and
/// today's dot.
class ProviderCalendarLegend extends StatelessWidget {
  const ProviderCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextStyle? style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
        );
    final double side = 14.dw;

    Widget item(Widget swatch, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            swatch,
            SizedBox(width: AppSpacing.xs2.dw),
            Text(label, style: style),
          ],
        );

    Widget swatch(ProviderDayStatus status) {
      final ProviderDayStyle look = ProviderDayStyle.of(status);
      return Container(
        width: side,
        height: side,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: look.fill,
          borderRadius: AppRadii.xsAll,
          border: Border.all(color: look.border),
        ),
        // The legend's strike line on Blocked.
        child: look.struck ? Container(height: 1, color: look.border) : null,
      );
    }

    return Wrap(
      spacing: AppSpacing.sm.dw,
      runSpacing: AppSpacing.xs.dh,
      children: <Widget>[
        for (final ProviderDayStatus status in ProviderDayStatus.values)
          item(swatch(status), providerDayStatusLabel(l10n, status)),
        item(
          SizedBox(
            width: side,
            height: side,
            child: Center(
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(color: AppColors.iconBrand, shape: BoxShape.circle),
              ),
            ),
          ),
          l10n.availabilityToday,
        ),
      ],
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.title,
    required this.year,
    required this.onBack,
    required this.onForward,
  });

  final String title;
  final String year;
  final VoidCallback? onBack;
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
          onTap: onBack,
        ),
        Expanded(
          // Month and year as separate runs, so the year keeps Western digits
          // and its place in Arabic.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(child: Text(title, style: style, overflow: TextOverflow.ellipsis)),
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

/// The 44×44 round month buttons on the canvas grey, as drawn.
class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.label, required this.onTap});

  final AppIcons icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    final double side = AppSizes.controlMd.dw;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: side,
          height: side,
          decoration: const BoxDecoration(color: AppColors.bgCanvas, shape: BoxShape.circle),
          alignment: Alignment.center,
          // Directional glyphs: "previous" points back in either language.
          child: AppIcon(
            icon,
            size: AppSizes.iconMd,
            color: enabled ? AppColors.iconBrand : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}

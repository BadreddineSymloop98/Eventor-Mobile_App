import 'package:flutter/material.dart';

import '../../catalog/models/availability.dart';
import '../../constants/ui_helpers.dart';
import '../molecules/main_button.dart';
import 'app_bottom_sheet.dart';
import 'month_calendar.dart';

/// What [showDatePickerSheet] came back with. A `null` [date] means the date
/// was cleared; a `null` [DateChoice] means the sheet was dismissed.
class DateChoice {
  const DateChoice(this.date);

  final DateTime? date;
}

/// Picks a day from today on, on the app's own month grid (the one 12 and 20
/// book on) rather than the platform picker. Tapping a day picks it and
/// closes; [clearLabel], when given and a date is set, offers to remove it.
Future<DateChoice?> showDatePickerSheet(
  BuildContext context, {
  required String title,
  DateTime? selected,
  String? clearLabel,
  DateTime Function() now = DateTime.now,
}) {
  return showAppBottomSheet<DateChoice>(
    context,
    builder: (BuildContext sheetContext) => _DatePickerSheet(
      title: title,
      selected: selected,
      clearLabel: selected == null ? null : clearLabel,
      today: now(),
    ),
  );
}

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({
    required this.title,
    required this.selected,
    required this.clearLabel,
    required this.today,
  });

  final String title;
  final DateTime? selected;
  final String? clearLabel;
  final DateTime today;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late DateTime _month = widget.selected ?? widget.today;

  DateTime get _today =>
      DateTime(widget.today.year, widget.today.month, widget.today.day);

  /// Every day from today on is open; the past is greyed out. A date already
  /// in the past (an event that has happened) still shows as chosen.
  Availability _open(DateTime month) {
    final int days = DateTime(month.year, month.month + 1, 0).day;
    return Availability(
      month: '',
      minNoticeDays: 0,
      firstBookableDate: _today,
      days: <AvailabilityDay>[
        for (int day = 1; day <= days; day++)
          if (!DateTime(month.year, month.month, day).isBefore(_today))
            AvailabilityDay(
              date: DateTime(month.year, month.month, day),
              state: DayState.available,
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? selected = widget.selected;
    final String? clear = widget.clearLabel;
    // The arrows stop at this month — or at the chosen one, if it is earlier.
    final DateTime floor =
        selected != null && selected.isBefore(_today) ? selected : _today;

    return AppSheetScaffold(
      title: widget.title,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.xs.dh),
          child: MonthCalendar(
            month: _month,
            availability: _open(_month),
            selected: selected,
            firstMonth: floor,
            showLegend: false,
            onSelect: (DateTime day) => Navigator.pop(context, DateChoice(day)),
            onMonthChanged: (DateTime month) => setState(() => _month = month),
          ),
        ),
      ),
      actions: <Widget>[
        if (clear != null)
          MainButton(
            label: clear,
            style: MainButtonStyle.ghost,
            onPressed: () => Navigator.pop(context, const DateChoice(null)),
          ),
      ],
    );
  }
}

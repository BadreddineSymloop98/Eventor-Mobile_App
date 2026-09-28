import 'package:flutter/material.dart';

import '../../bookings/models/booking_detail.dart';
import '../../constants/ui_helpers.dart';
import '../../formatting/money_format.dart';
import '../../localization/app_localizations_x.dart';
import '../molecules/meta_line.dart';
import 'divided_card.dart';

/// A label and its value on one row of a [DividedCard] — B4's "Your event"
/// and "Where", B9a's "Date and place". [stacked] puts a long value (an
/// address) under its label instead.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    required this.label,
    required this.value,
    this.stacked = false,
    this.isLtr = false,
    super.key,
  });

  final String label;
  final String value;
  final bool stacked;

  /// A time, a count, a reference — kept left to right in Arabic.
  final bool isLtr;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Text key = Text(
      label,
      style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
    );
    final Text shown = Text(
      value,
      textAlign: stacked ? TextAlign.start : TextAlign.end,
      textDirection: isLtr ? TextDirection.ltr : null,
      style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
    );
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md.dw,
        vertical: AppSpacing.sm.dh,
      ),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                key,
                SizedBox(height: AppSpacing.xs2.dh),
                shown,
              ],
            )
          : Row(
              children: <Widget>[
                key,
                SizedBox(width: AppSpacing.md.dw),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: shown,
                  ),
                ),
              ],
            ),
    );
  }
}

/// A section of a booking screen: its heading, then its card.
class BookingSection extends StatelessWidget {
  const BookingSection({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        SizedBox(height: AppSpacing.xs.dh),
        child,
      ],
    );
  }
}

/// The priced lines and the total — B1's "Price", B4's, B8's lines and
/// B9a's pack items. A line bought more than once says "2 × 4 000 DA" under
/// its label; a discount line shows its minus.
class PriceLinesCard extends StatelessWidget {
  const PriceLinesCard({
    required this.lines,
    required this.totalLabel,
    required this.total,
    this.leading,
    this.unitOf,
    this.highlightTotal = true,
    super.key,
  });

  final List<BookingLine> lines;
  final String totalLabel;
  final String total;

  /// Rows before the lines — B9a's "Sum of the services".
  final List<Widget>? leading;

  /// "per day" under a line bought once, when the screen knows its unit.
  final String? Function(BookingLine line)? unitOf;

  /// The total on the pale purple band (B1) rather than plain (B4).
  final bool highlightTotal;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? amountStyle =
        textTheme.labelLarge?.copyWith(color: AppColors.textPrimary);
    final TextStyle? totalStyle = textTheme.titleMedium?.copyWith(
      color: AppColors.textBrand,
    );

    Widget amount(String value, TextStyle? style) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(formatAmount(value), textDirection: TextDirection.ltr, style: style),
            SizedBox(width: AppSpacing.xs2.dw),
            Text(context.l10n.currencyDzd, style: style),
          ],
        );

    Widget line(BookingLine l) {
      final String? unit = unitOf?.call(l);
      return Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md.dw,
          vertical: AppSpacing.sm.dh,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l.label,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                  ),
                  if (l.quantity > 1) ...<Widget>[
                    SizedBox(height: AppSpacing.xs2.dh / 2),
                    MetaLine(
                      parts: <MetaPart>[
                        MetaPart('${l.quantity} ×', isLtr: true),
                        MetaPart.amount(l.unitAmount),
                      ],
                    ),
                  ] else if (unit != null) ...<Widget>[
                    SizedBox(height: AppSpacing.xs2.dh / 2),
                    Text(
                      unit,
                      style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm.dw),
            amount(
              l.amount,
              l.kind == BookingLineKind.discount
                  ? amountStyle?.copyWith(color: AppColors.textBrand)
                  : amountStyle,
            ),
          ],
        ),
      );
    }

    return DividedCard(
      children: <Widget>[
        ...?leading,
        for (final BookingLine l in lines) line(l),
        Container(
          color: highlightTotal ? AppColors.bgBrandSubtle : null,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md.dw,
            vertical: AppSpacing.sm.dh,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  totalLabel,
                  style: textTheme.labelLarge?.copyWith(color: AppColors.textBrand),
                ),
              ),
              amount(total, totalStyle),
            ],
          ),
        ),
      ],
    );
  }
}

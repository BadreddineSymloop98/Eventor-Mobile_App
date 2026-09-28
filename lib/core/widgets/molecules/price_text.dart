import 'package:flutter/material.dart';

import '../../catalog/models/price_type.dart';
import '../../constants/ui_helpers.dart';
import '../../formatting/money_format.dart';
import '../../localization/app_localizations_x.dart';
import '../../localization/catalog_labels.dart';

/// A service's price with its unit — or "On quote" for a quote-only service,
/// whose base price is not a promise and is not shown (spec D4).
class ServicePrice extends StatelessWidget {
  const ServicePrice({
    required this.amount,
    required this.type,
    this.showFrom = true,
    this.fromOnOwnLine = false,
    this.amountStyle,
    this.labelStyle,
    super.key,
  });

  final String amount;
  final PriceType type;

  /// "From 45 000 DA" rather than "45 000 DA".
  final bool showFrom;

  /// "From" on a line of its own, with the amount and unit below it — 12's
  /// action bar, where the price shares its width with two buttons and
  /// reads best as a short caption over the figure.
  final bool fromOnOwnLine;
  final TextStyle? amountStyle;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    if (type == PriceType.onQuote) {
      return Text(
        context.l10n.priceOnQuote,
        style: amountStyle ??
            Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
      );
    }
    if (showFrom && fromOnOwnLine) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.l10n.priceFrom,
            style: labelStyle ??
                Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
          ),
          PriceText(
            amount: amount,
            unit: context.l10n.priceUnit(type),
            amountStyle: amountStyle,
            labelStyle: labelStyle,
          ),
        ],
      );
    }
    return PriceText(
      amount: amount,
      prefix: showFrom ? context.l10n.priceFrom : null,
      unit: context.l10n.priceUnit(type),
      amountStyle: amountStyle,
      labelStyle: labelStyle,
    );
  }
}

/// A price as the design sets it: "From 45 000 DA per day".
///
/// Each part is its own text, in reading order, inside a row that follows the
/// app's direction. That is the number-token rule: an amount interpolated
/// into an Arabic sentence has its digit groups reversed by the bidi
/// algorithm (`000 45`), so the amount is kept apart and set left to right,
/// and the row puts the words around it in the right order for either
/// language — in Arabic the leading word ends up furthest right.
class PriceText extends StatelessWidget {
  const PriceText({
    required this.amount,
    this.prefix,
    this.unit,
    this.amountStyle,
    this.labelStyle,
    super.key,
  });

  /// The API's amount string, such as `"45000.00"`.
  final String amount;

  /// Before the amount — usually `l10n.priceFrom`.
  final String? prefix;

  /// After the currency — usually the service's `priceTypeLabel`.
  final String? unit;

  /// Defaults to `Label/L` in the primary text colour.
  final TextStyle? amountStyle;

  /// For the prefix, currency and unit. Defaults to `Caption` in secondary.
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? amountText = amountStyle ??
        textTheme.labelLarge?.copyWith(color: AppColors.textPrimary);
    final TextStyle? labelText = labelStyle ??
        textTheme.labelSmall?.copyWith(color: AppColors.textSecondary);
    final String? before = prefix;
    final String? after = unit;
    final SizedBox gap = SizedBox(width: AppSpacing.xs2.dw);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        if (before != null) ...<Widget>[
          Text(before, style: labelText),
          gap,
        ],
        Text(
          formatAmount(amount),
          textDirection: TextDirection.ltr,
          style: amountText,
        ),
        gap,
        Text(context.l10n.currencyDzd, style: amountText),
        if (after != null) ...<Widget>[
          gap,
          Flexible(
            child: Text(
              after,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelText,
            ),
          ),
        ],
      ],
    );
  }
}

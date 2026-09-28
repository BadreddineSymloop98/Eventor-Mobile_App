import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../formatting/money_format.dart';
import '../../localization/app_localizations_x.dart';

/// One run of a [MetaLine].
class MetaPart {
  const MetaPart(this.text, {this.isLtr = false}) : amount = null;

  /// An amount with its currency — digits kept left to right, the currency
  /// after them in either language.
  const MetaPart.amount(String this.amount)
      : text = '',
        isLtr = true;

  final String text;
  final String? amount;

  /// Times, references, numbers: set left to right so Arabic does not
  /// reverse their digits (the number-token rule).
  final bool isLtr;
}

/// "Sat 14 Mar · 13:00 → 23:00 · 71 000 DA", as separate runs so every
/// number keeps its order in Arabic — the recap lines of B2, B3, B5, B7.
class MetaLine extends StatelessWidget {
  const MetaLine({required this.parts, this.style, super.key});

  final List<MetaPart> parts;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final TextStyle? text = style ??
        Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            );
    final List<MetaPart> shown =
        parts.where((MetaPart p) => p.amount != null || p.text.isNotEmpty).toList();

    Widget run(MetaPart part) {
      final String? amount = part.amount;
      if (amount == null) {
        return Text(
          part.text,
          textDirection: part.isLtr ? TextDirection.ltr : null,
          style: text,
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(formatAmount(amount), textDirection: TextDirection.ltr, style: text),
          SizedBox(width: AppSpacing.xs2.dw / 2),
          Text(context.l10n.currencyDzd, style: text),
        ],
      );
    }

    return Wrap(
      spacing: AppSpacing.xs2.dw,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (int i = 0; i < shown.length; i++) ...<Widget>[
          if (i > 0) Text('·', style: text),
          run(shown[i]),
        ],
      ],
    );
  }
}

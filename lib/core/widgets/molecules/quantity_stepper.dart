import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';

/// `−  2  +` — B1's extras. Holds to [min]…[max]; a button
/// that cannot move the value any further is greyed out.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.step = 1,
    this.label,
    super.key,
  });

  final int value;

  /// `null` disables both buttons.
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;

  /// How far one tap moves.
  final int step;

  /// What is being counted, for screen readers — "Guests".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ValueChanged<int>? change = onChanged;

    Widget button(String glyph, String semantics, int? next) {
      final bool enabled = change != null && next != null;
      return Semantics(
        button: true,
        enabled: enabled,
        label: semantics,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: enabled ? () => change(next) : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: AppSizes.touchTarget.dw,
            height: AppSizes.touchTarget.dw,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: AppRadii.lgAll,
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Text(
              glyph,
              style: textTheme.titleMedium?.copyWith(
                color: enabled ? AppColors.textBrand : AppColors.textDisabled,
              ),
            ),
          ),
        ),
      );
    }

    final int down = (value - step).clamp(min, max);
    final int up = (value + step).clamp(min, max);

    return Semantics(
      label: label,
      value: '$value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          button('−', context.l10n.stepperLess, value > min ? down : null),
          SizedBox(width: AppSpacing.sm.dw),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: AppSpacing.xl.dw),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: textTheme.labelLarge?.copyWith(color: AppColors.textBrand),
            ),
          ),
          SizedBox(width: AppSpacing.sm.dw),
          button('+', context.l10n.stepperMore, value < max ? up : null),
        ],
      ),
    );
  }
}

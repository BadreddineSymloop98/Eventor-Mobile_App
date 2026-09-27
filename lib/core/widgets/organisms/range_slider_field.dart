import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../molecules/price_text.dart';

/// The BUDGET range on 11a: two thumbs over 0 → [max], in steps of [step],
/// with both ends written out. At [max] the upper label reads "500 000+ DA",
/// because the top of the slider means "no ceiling".
class RangeSliderField extends StatelessWidget {
  const RangeSliderField({
    required this.values,
    required this.max,
    required this.onChanged,
    this.step = 5000,
    super.key,
  });

  final RangeValues values;
  final double max;
  final double step;
  final ValueChanged<RangeValues> onChanged;

  String _amount(double value) => '${value.round()}.00';

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? style = textTheme.labelMedium?.copyWith(color: AppColors.textPrimary);
    final bool atCeiling = values.end >= max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.bgBrand,
            inactiveTrackColor: AppColors.bgDisabled,
            thumbColor: AppColors.bgBrand,
            overlayColor: AppColors.bgBrand.withValues(alpha: 0.12),
            trackHeight: 4,
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: RangeSlider(
            values: values,
            max: max,
            divisions: (max / step).round(),
            onChanged: onChanged,
          ),
        ),
        Row(
          children: <Widget>[
            PriceText(amount: _amount(values.start), amountStyle: style, labelStyle: style),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                PriceText(amount: _amount(values.end), amountStyle: style, labelStyle: style),
                if (atCeiling)
                  Text('+', textDirection: TextDirection.ltr, style: style),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

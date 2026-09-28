import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';

/// A white card whose children are stacked with a full-bleed hairline
/// between each pair — the shell used by 14's conversation rows and 16's
/// notification rows, distinct from [InfoCard] only in taking arbitrary
/// children rather than icon-and-text rows.
class DividedCard extends StatelessWidget {
  const DividedCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = children;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: AppElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.borderDefault,
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

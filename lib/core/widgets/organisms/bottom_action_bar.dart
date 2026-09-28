import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';

/// A form's one button, pinned under the content — the design's
/// `Action bar (sticky)`: white, a hairline on top, 12/16/24/16, the bottom
/// system inset added to the 24. The chrome [StickyActionBar] uses, with one
/// full-width child.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: const Border(top: BorderSide(color: AppColors.borderDefault)),
        boxShadow: AppElevation.md,
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md.dw,
        AppSpacing.sm.dh,
        AppSpacing.md.dw,
        AppSpacing.xl.dh + MediaQuery.paddingOf(context).bottom,
      ),
      child: child,
    );
  }
}

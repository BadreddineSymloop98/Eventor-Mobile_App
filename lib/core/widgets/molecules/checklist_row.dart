import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../atoms/app_icon.dart';

/// Where a checklist line stands.
enum ChecklistState {
  /// A green tick, the label quiet — P9's and P14's met items.
  done,

  /// An amber cross, the label emphasised — something still to do.
  missing,

  /// A red cross — a hard refusal, P7b's "cannot be deleted" reasons.
  blocked,
}

/// One line of a checklist card: the icon, a 12pt gap, then the label
/// filling the rest, so in Arabic the text sits right against its icon (the
/// standing RTL tick-row rule — never space-between).
class ChecklistRow extends StatelessWidget {
  const ChecklistRow({
    required this.label,
    required this.state,
    this.stateLabel,
    super.key,
  });

  final String label;
  final ChecklistState state;

  /// "Done" / "Missing", read after the label by screen readers.
  final String? stateLabel;

  @override
  Widget build(BuildContext context) {
    final (AppIcons icon, Color iconColor, Color textColor) = switch (state) {
      ChecklistState.done => (AppIcons.check, AppColors.statusAccepted, AppColors.textSecondary),
      ChecklistState.missing => (AppIcons.close, AppColors.statusPending, AppColors.textPrimary),
      ChecklistState.blocked => (AppIcons.close, AppColors.statusDeclined, AppColors.textPrimary),
    };
    final String? spoken = stateLabel;
    return Semantics(
      label: spoken == null ? label : '$label, $spoken',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md.dw,
          vertical: AppSpacing.sm.dh,
        ),
        child: Row(
          children: <Widget>[
            AppIcon(icon, size: AppSizes.iconMd, color: iconColor),
            SizedBox(width: AppSpacing.sm.dw),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The white list card a sheet's rows sit in — 1pt border, 12pt corners,
/// hairlines between the rows, no shadow (it is already on a raised sheet).
class ChecklistCard extends StatelessWidget {
  const ChecklistCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
            children[i],
          ],
        ],
      ),
    );
  }
}

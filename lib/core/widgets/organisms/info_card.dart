import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../atoms/app_icon.dart';

/// One line of an [InfoCard]: a glyph, the text, and optionally something on
/// the far side (a chevron, a "10 h" pill).
class InfoRow {
  const InfoRow({required this.icon, required this.text, this.trailing, this.onTap});

  final AppIcons icon;
  final String text;
  final Widget? trailing;
  final VoidCallback? onTap;
}

/// The design's fact-list card — Key facts on 12, Good to know, Where they
/// work on 13.
///
/// Anatomy per §4.7: the card has no horizontal padding, each row carries
/// 12/16, and the dividers run full-bleed between rows.
class InfoCard extends StatelessWidget {
  const InfoCard({required this.rows, this.title, super.key});

  final List<InfoRow> rows;

  /// A small heading inside the card — "Good to know".
  final String? title;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? heading = title;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: AppElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (heading != null)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md.dw,
                AppSpacing.sm.dh,
                AppSpacing.md.dw,
                0,
              ),
              child: Text(
                heading,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
            _row(textTheme, rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(TextTheme textTheme, InfoRow row) {
    final Widget? trailing = row.trailing;
    final Widget content = Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md.dw,
        vertical: AppSpacing.sm.dh,
      ),
      child: Row(
        children: <Widget>[
          AppIcon(row.icon, size: AppSizes.iconMd, color: AppColors.iconBrand),
          SizedBox(width: AppSpacing.sm.dw),
          Expanded(
            child: Text(
              row.text,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ),
          if (trailing != null) ...<Widget>[
            SizedBox(width: AppSpacing.xs.dw),
            trailing,
          ],
        ],
      ),
    );
    final VoidCallback? tap = row.onTap;
    return tap == null
        ? content
        : GestureDetector(onTap: tap, behavior: HitTestBehavior.opaque, child: content);
  }
}

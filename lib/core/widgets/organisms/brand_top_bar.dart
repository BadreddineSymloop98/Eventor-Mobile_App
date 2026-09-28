import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_spinner.dart';

/// The purple header of a pushed screen — Back, a large title and, at the
/// end, one text action in gold ("Edit", "Delete", "Mark all as read").
///
/// The same geometry 16 draws by hand; kept in one place for section 7.
class BrandTopBar extends StatelessWidget {
  const BrandTopBar({
    required this.title,
    this.onBack,
    this.actionLabel,
    this.onAction,
    this.isActionLoading = false,
    super.key,
  });

  final String title;

  /// Defaults to [Navigator.maybePop], so a screen's `PopScope` — a "discard
  /// changes?" guard — hears the tap like it hears the system Back.
  final VoidCallback? onBack;

  final String? actionLabel;

  /// `null` with a label shows the action greyed out, while it cannot run.
  final VoidCallback? onAction;

  /// The action is running — a spinner replaces its label until it ends.
  final bool isActionLoading;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? action = actionLabel;

    return Container(
      color: AppColors.bgBrand,
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xs2.dw,
        MediaQuery.paddingOf(context).top + AppSpacing.md.dh,
        AppSpacing.md.dw,
        AppSpacing.lg.dh,
      ),
      child: Row(
        children: <Widget>[
          Semantics(
            button: true,
            label: context.l10n.backLabel,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onBack ?? () => Navigator.maybePop(context),
              behavior: HitTestBehavior.opaque,
              child: SizedBox.square(
                dimension: AppSizes.touchTarget.dw,
                child: const Center(
                  child: AppIcon(
                    AppIcons.chevronLeft,
                    color: AppColors.iconOnBrand,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.textOnBrand,
                ),
              ),
            ),
          ),
          if (action != null)
            Semantics(
              button: true,
              enabled: onAction != null,
              child: GestureDetector(
                onTap: onAction,
                behavior: HitTestBehavior.opaque,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: AppSizes.touchTarget.dh,
                    minWidth: AppSizes.touchTarget.dw,
                  ),
                  child: Center(
                    child: isActionLoading
                        ? const AppSpinner(
                            size: AppSizes.iconMd,
                            color: AppColors.iconOnBrandAccent,
                          )
                        : Text(
                            action,
                            style: textTheme.labelMedium?.copyWith(
                              color: onAction == null
                                  ? AppColors.textOnBrand.withValues(alpha: 0.5)
                                  : AppColors.textOnBrandAccent,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

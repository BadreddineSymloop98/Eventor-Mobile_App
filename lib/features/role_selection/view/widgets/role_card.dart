import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../model/user_role.dart';

/// One selectable role in the sign-up fork.
///
/// The design is deliberate about the selected state: a 2px brand border
/// **and** a check, because "colour alone should never carry a selection
/// state". Both are kept.
///
/// The row mirrors in Arabic on its own — the design needed a separate
/// right-to-left component only because Figma instances cannot reorder their
/// children, which is not a constraint here.
class RoleCard extends StatelessWidget {
  const RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  /// The tile behind the glyph.
  static const double _tileSize = 48;

  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md.dw,
            vertical: AppSpacing.md.dh,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadii.mdAll,
            border: Border.all(
              color: isSelected
                  ? AppColors.borderBrand
                  : AppColors.borderDefault,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              _IconTile(icon: role.icon),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      role.title(l10n),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textBrand,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs2.dh),
                    Text(
                      role.description(l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm.dw),
              // The space is held whether or not the check is showing, so the
              // text does not reflow as the user moves between options.
              SizedBox(
                width: AppSizes.iconLg.dw,
                height: AppSizes.iconLg.dw,
                child: isSelected
                    ? SvgPicture.asset(
                        'assets/icons/check.svg',
                        colorFilter: const ColorFilter.mode(
                          AppColors.iconBrand,
                          BlendMode.srcIn,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rounded tile the role's glyph sits in.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: RoleCard._tileSize.dw,
      height: RoleCard._tileSize.dw,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.bgCanvas,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.borderBrandSubtle),
      ),
      child: SvgPicture.asset(
        icon,
        width: AppSizes.iconLg.dw,
        height: AppSizes.iconLg.dw,
        colorFilter: const ColorFilter.mode(
          AppColors.iconBrand,
          BlendMode.srcIn,
        ),
        // The glyph is decorative: the card's own title names the role.
        excludeFromSemantics: true,
      ),
    );
  }
}

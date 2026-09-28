import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../atoms/app_icon.dart';

/// One selectable option in a fork, with a glyph, a title and a line of
/// description — the design's `Role Card`.
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
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  /// The tile behind the glyph.
  static const double _tileSize = 48;

  final AppIcons icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
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
              Container(
                width: _tileSize.dw,
                height: _tileSize.dw,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgCanvas,
                  borderRadius: AppRadii.mdAll,
                  border: Border.all(color: AppColors.borderBrandSubtle),
                ),
                // Decorative: the card's own title names the option.
                child: AppIcon(icon, color: AppColors.iconBrand),
              ),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textBrand,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs2.dh),
                    Text(
                      description,
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
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isSelected ? 1 : 0,
                child: const AppIcon(AppIcons.check, color: AppColors.iconBrand),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

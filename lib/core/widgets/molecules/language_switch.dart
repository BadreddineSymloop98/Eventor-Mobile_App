import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../../localization/locale_controller.dart';

/// The EN / عربي segmented control that sits top-right on every pre-auth
/// screen.
///
/// A white pill regardless of what is behind it, so the same component works
/// on the navy splash and on a white form. The design keeps it available right
/// through the auth flow — the user can change language at any point before an
/// account exists to store the preference against.
///
/// Each label is written in its own script and set in its own typeface, not in
/// the app's current one: "عربي" is always Cairo and "EN" is always Figtree, so
/// a reader who cannot read the current language can still find their own.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});

  static const Locale _english = Locale('en');
  static const Locale _arabic = Locale('ar');

  @override
  Widget build(BuildContext context) {
    final LocaleController controller = context.watch<LocaleController>();

    // A null locale means "follow the device", which the switch has to render
    // as one of the two. The app resolves it the same way the theme does.
    final bool isArabic =
        (controller.locale ?? Localizations.localeOf(context)).languageCode ==
            _arabic.languageCode;

    return Semantics(
      container: true,
      label: context.l10n.languageSwitchLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppRadii.fullAll,
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xs2.dw,
            vertical: AppSpacing.xs2.dh,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Segment(
                label: 'EN',
                fontFamily: AppFontFamilies.latin,
                isSelected: !isArabic,
                onTap: () => controller.setLocale(_english),
              ),
              SizedBox(width: _Segment.gap.dw),
              _Segment(
                label: 'عربي',
                fontFamily: AppFontFamilies.arabic,
                isSelected: isArabic,
                onTap: () => controller.setLocale(_arabic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One half of the switch.
class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.fontFamily,
    required this.isSelected,
    required this.onTap,
  });

  /// Space between the two halves, in design pixels. Tighter than any spacing
  /// token, because the two read as one control rather than as two.
  static const double gap = 2;

  final String label;
  final String fontFamily;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: isSelected ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.bgBrand : Colors.transparent,
            borderRadius: AppRadii.fullAll,
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm.dw,
              vertical: AppSpacing.xs2.dh,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 18 / 13,
                // Gold on the brand fill, not white: the accent is what marks
                // the active half.
                color: isSelected
                    ? AppColors.textOnBrandAccent
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

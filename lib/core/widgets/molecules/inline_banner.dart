import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';

/// What a banner is reporting.
enum InlineBannerTone {
  /// Something went wrong and the user has to act — the red callout on
  /// `07b`, `07c`, `07d`, `08b`, `10c`, `10g`.
  danger,

  /// A neutral note — the pale purple callout used for policies and
  /// reassurance.
  info,
}

/// A callout that sits in the flow of a form, above the fields it concerns —
/// the design's hand-built `Banner · …` frames, given one implementation.
///
/// Used instead of a toast whenever the message needs to stay put while the
/// user fixes the problem: a wrong password, an email already taken, a code
/// that expired. Announced to screen readers as a live region so it is heard
/// the moment it appears.
///
/// Text is `Label/M` for the title and `Body/S` for the body — the design's
/// banners carry an unbound 12pt style, mapped onto the ramp so Arabic gets
/// its own sizes (user decision, 2026-09-23).
class InlineBanner extends StatelessWidget {
  const InlineBanner({
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.tone = InlineBannerTone.danger,
    super.key,
  });

  final String title;
  final String? message;

  /// An optional follow-up link under the text — "Send a new code" on `07c`.
  final String? actionLabel;
  final VoidCallback? onAction;

  final InlineBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDanger = tone == InlineBannerTone.danger;
    final String? body = message;
    final String? action = actionLabel;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md.dw,
          vertical: AppSpacing.sm.dh,
        ),
        decoration: BoxDecoration(
          color: isDanger ? AppColors.bgDangerSubtle : AppColors.bgBrandSubtle,
          borderRadius: AppRadii.mdAll,
          border: isDanger ? Border.all(color: AppColors.borderDanger) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: textTheme.labelMedium?.copyWith(
                color: isDanger ? AppColors.textDanger : AppColors.textBrand,
              ),
            ),
            if (body != null) ...<Widget>[
              SizedBox(height: AppSpacing.xs2.dh),
              Text(
                body,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
            if (action != null) ...<Widget>[
              SizedBox(height: AppSpacing.xs2.dh),
              Semantics(
                button: onAction != null,
                child: GestureDetector(
                  onTap: onAction,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    // Stretches the tap area to a finger's height without
                    // moving the link off the banner's text column.
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.xs2.dh,
                    ),
                    child: Text(
                      action,
                      style: textTheme.labelMedium?.copyWith(
                        color: onAction == null
                            ? AppColors.textSecondary
                            : AppColors.textBrand,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

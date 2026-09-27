import 'package:flutter/material.dart';

import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/formatting/date_format.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/messaging/models/conversation.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/atoms/status_badge.dart';
import '../../../../l10n/app_localizations.dart';

/// 15's top bar: back, who you are talking to, and ⋯.
class ChatTopBar extends StatelessWidget {
  const ChatTopBar({
    required this.avatar,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.onPeerTap,
    this.onMore,
    super.key,
  });

  static const double _more = 22;

  final Widget avatar;
  final String title;
  final String? subtitle;

  /// Opens 13 for a provider; `null` for anyone else.
  final VoidCallback? onPeerTap;

  /// `null` hides ⋯ (support and dispute chats).
  final VoidCallback? onMore;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? line = subtitle;
    final VoidCallback? more = onMore;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        // The 48pt targets carry most of the design's 16 inset.
        AppSpacing.xs2.dw,
        MediaQuery.paddingOf(context).top + AppSpacing.sm.dh,
        AppSpacing.xs2.dw,
        AppSpacing.sm.dh,
      ),
      child: Row(
        children: <Widget>[
          _Target(
            label: l10n.backLabel,
            onTap: onBack,
            child: const AppIcon(
              AppIcons.chevronLeft,
              color: AppColors.iconBrand,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onPeerTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: <Widget>[
                  avatar,
                  SizedBox(width: AppSpacing.sm.dw),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (line != null)
                          Text(
                            line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (more != null)
            _Target(
              label: l10n.chatMore,
              onTap: more,
              child: const AppIcon(
                AppIcons.moreHorizontal,
                size: _more,
                color: AppColors.iconBrand,
              ),
            ),
        ],
      ),
    );
  }
}

class _Target extends StatelessWidget {
  const _Target({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: AppSizes.touchTarget.dw,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// The booking the chat is about, under the top bar. Its tap goes to the
/// booking, which is not built yet.
class BookingContextCard extends StatelessWidget {
  const BookingContextCard({
    required this.booking,
    required this.onTap,
    super.key,
  });

  final ChatBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String locale = Localizations.localeOf(context).languageCode;
    final DateTime? date = booking.eventDate;
    final TextStyle? meta = textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
    );

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md.dw,
        AppSpacing.sm.dh,
        AppSpacing.md.dw,
        AppSpacing.xs2.dh,
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm.dw,
            vertical: 10.dh,
          ),
          decoration: const BoxDecoration(
            color: AppColors.bgBrandSubtle,
            borderRadius: AppRadii.mdAll,
          ),
          child: Row(
            children: <Widget>[
              const AppIcon(AppIcons.camera, color: AppColors.iconBrand),
              SizedBox(width: 10.dw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      booking.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.textBrand,
                      ),
                    ),
                    // Separate runs, so the reference keeps its own order in
                    // an Arabic line.
                    Wrap(
                      children: <Widget>[
                        if (date != null)
                          Text('${shortDate(date, locale)} · ', style: meta),
                        Text(
                          booking.reference,
                          textDirection: TextDirection.ltr,
                          style: meta,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.dw),
              StatusBadge(BookingStatusKind.fromApi(booking.status)),
              SizedBox(width: AppSpacing.xs2.dw),
              const AppIcon(
                AppIcons.chevronRight,
                size: AppSizes.iconSm,
                color: AppColors.iconBrand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

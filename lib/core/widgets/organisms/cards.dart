import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../molecules/price_text.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_avatar.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_network_image.dart';
import '../atoms/icon_tile.dart';
import '../atoms/rating_line.dart';
import '../atoms/rating_view.dart';
import '../atoms/status_badge.dart';
import '../molecules/main_button.dart';

/// The design's four list cards, each a white rounded box with a hairline:
/// [ProviderCard], [BookingCard], [RequestCard] and [ServiceItem].
///
/// They take already-formatted strings rather than models, so the card never
/// decides how a price or a date is written — and prices always arrive as a
/// separate amount and unit, which keeps numbers out of interpolated Arabic
/// strings (the standing rule on number tokens).

/// A provider in a discovery list — avatar, name, meta line, rating, and
/// "From … per …" at the end. `radius/lg` and `elevation/sm`, the only card of
/// the four that floats.
class ProviderCard extends StatelessWidget {
  const ProviderCard({
    required this.name,
    required this.meta,
    required this.amount,
    required this.unit,
    this.photoUrl,
    this.score,
    this.reviewCount,
    this.isNew = false,
    this.quoteLabel,
    this.onTap,
    super.key,
  });

  final String name;

  /// "Photographer · Alger".
  final String meta;

  /// The API's amount — `"45000.00"`. Drawn by [PriceText], so the number
  /// and the currency keep their order in Arabic.
  final String amount;

  /// "per day".
  final String unit;

  final String? photoUrl;
  final String? score;
  final int? reviewCount;

  /// Nobody has reviewed it yet: "New" instead of a score.
  final bool isNew;

  /// Replaces the whole "From … per …" column — a service priced on quote
  /// has no price to show ("On quote").
  final String? quoteLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? rating = score;
    final String? quote = quoteLabel;

    return _CardShell(
      onTap: onTap,
      radius: AppRadii.lg,
      shadow: AppElevation.sm,
      padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppAvatar(name: name, photoUrl: photoUrl, size: AppAvatarSize.large),
          SizedBox(width: AppSpacing.sm.dw),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.xs2.dh),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (rating != null) ...<Widget>[
                  SizedBox(height: AppSpacing.xs2.dh),
                  RatingView(score: rating, count: reviewCount),
                ] else if (isNew) ...<Widget>[
                  SizedBox(height: AppSpacing.xs2.dh),
                  const RatingLine(avgRating: '0.00', ratingCount: 0),
                ],
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.dw),
          if (quote != null)
            Text(
              quote,
              style: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
            )
          else
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                context.l10n.priceFrom,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.xs2.dh),
              PriceText(
                amount: amount,
                amountStyle: textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.xs2.dh),
              Text(
                unit,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A booking in a short list — avatar, counterpart name, meta line and the
/// status badge. The name is whoever the booking is *with*: the provider on
/// the client's side, the client on the provider's.
class BookingCard extends StatelessWidget {
  const BookingCard({
    required this.counterpartName,
    required this.meta,
    required this.status,
    this.photoUrl,
    this.onTap,
    super.key,
  });

  final String counterpartName;

  /// "Photography · Sat 14 Mar".
  final String meta;
  final BookingStatusKind status;
  final String? photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: onTap,
      padding: EdgeInsetsDirectional.all(AppSpacing.sm.dw),
      child: Row(
        children: <Widget>[
          AppAvatar(name: counterpartName, photoUrl: photoUrl),
          SizedBox(width: AppSpacing.sm.dw),
          Expanded(
            child: _TitleAndMeta(title: counterpartName, meta: meta),
          ),
          SizedBox(width: AppSpacing.sm.dw),
          StatusBadge(status),
        ],
      ),
    );
  }
}

/// A new booking request on the provider's side, with Decline and Accept
/// underneath.
class RequestCard extends StatelessWidget {
  const RequestCard({
    required this.clientName,
    required this.meta,
    required this.onAccept,
    required this.onDecline,
    this.status = BookingStatusKind.pending,
    this.photoUrl,
    this.onTap,
    this.isBusy = false,
    this.isAccepting = false,
    super.key,
  });

  final String clientName;

  /// "Wedding photography · Sat 14 Mar · 150 guests" — may run to two lines.
  final String meta;
  final BookingStatusKind status;
  final String? photoUrl;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onTap;

  /// Disables both actions while one of them is being sent.
  final bool isBusy;

  /// Accept is the one being sent — its button shows the spinner.
  final bool isAccepting;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: onTap,
      padding: EdgeInsetsDirectional.all(AppSpacing.sm.dw),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(name: clientName, photoUrl: photoUrl),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: _TitleAndMeta(
                  title: clientName,
                  meta: meta,
                  metaLines: 2,
                ),
              ),
              SizedBox(width: AppSpacing.sm.dw),
              StatusBadge(status),
            ],
          ),
          SizedBox(height: AppSpacing.sm.dh),
          Row(
            children: <Widget>[
              Expanded(
                child: MainButton(
                  label: context.l10n.requestDecline,
                  style: MainButtonStyle.secondary,
                  onPressed: onDecline,
                  canBeTapped: !isBusy,
                ),
              ),
              SizedBox(width: AppSpacing.xs.dw),
              Expanded(
                child: MainButton(
                  label: context.l10n.requestAccept,
                  onPressed: onAccept,
                  isLoading: isAccepting,
                  canBeTapped: !isBusy || isAccepting,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of a provider's services — thumb, title, "price · unit", and whether
/// it is taking bookings.
class ServiceItem extends StatelessWidget {
  const ServiceItem({
    required this.title,
    required this.price,
    this.unit,
    this.isAvailable = true,
    this.badge,
    this.photoUrl,
    this.icon = AppIcons.camera,
    this.onTap,
    super.key,
  });

  final String title;

  /// The amount, grouped — "45 000". The currency is added as its own
  /// token, so the digits keep their order in Arabic.
  final String price;

  /// "per day" — `null` when the price has no unit to show.
  final String? unit;
  final bool isAvailable;

  /// Stands in for the availability badge — a service's publishing status on
  /// the provider's own home (21).
  final Widget? badge;

  /// The service's cover; the category glyph stands in until it has one.
  final String? photoUrl;

  /// The category glyph on the thumb, until the service has a photo.
  final AppIcons icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return _CardShell(
      onTap: onTap,
      padding: EdgeInsetsDirectional.all(AppSpacing.sm.dw),
      child: Row(
        children: <Widget>[
          if (photoUrl case final String url)
            AppNetworkImage(
              url: url,
              width: IconTile.thumbSize.dw,
              height: IconTile.thumbSize.dw,
              radius: AppRadii.mdAll,
            )
          else
            IconTile.serviceThumb(icon),
          SizedBox(width: AppSpacing.sm.dw),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.xs2.dh),
                // Price and unit as separate runs: the amount keeps its own
                // left-to-right order inside Arabic copy.
                Row(
                  children: <Widget>[
                    Text(
                      price,
                      textDirection: TextDirection.ltr,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs2.dw),
                    Text(
                      context.l10n.currencyDzd,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (unit case final String perUnit) ...<Widget>[
                      Text(
                        ' · ',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          perUnit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.dw),
          badge ?? AvailabilityBadge(isAvailable: isAvailable),
        ],
      ),
    );
  }
}

class _TitleAndMeta extends StatelessWidget {
  const _TitleAndMeta({
    required this.title,
    required this.meta,
    this.metaLines = 1,
  });

  final String title;
  final String meta;
  final int metaLines;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
        ),
        SizedBox(height: AppSpacing.xs2.dh),
        Text(
          meta,
          maxLines: metaLines,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// White box, hairline, rounded — pressable when [onTap] is set, turning
/// `bg/surface-pressed` under the finger.
class _CardShell extends StatefulWidget {
  const _CardShell({
    required this.child,
    required this.padding,
    this.onTap,
    this.radius = AppRadii.md,
    this.shadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final List<BoxShadow>? shadow;

  @override
  State<_CardShell> createState() => _CardShellState();
}

class _CardShellState extends State<_CardShell> {
  bool _isPressed = false;

  void _set(bool value) {
    if (widget.onTap == null || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _isPressed ? AppColors.bgSurfacePressed : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: widget.shadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

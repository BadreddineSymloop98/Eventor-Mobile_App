import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';

/// Where a booking stands, as the design's `Status Badge` names it.
enum BookingStatusKind {
  pending,
  accepted,
  declined,
  completed,
  cancelled;

  /// The API's status string as this enum, defaulting an unknown value to
  /// [pending] — a status the server adds later must not crash a screen
  /// that was already shipped.
  static BookingStatusKind fromApi(String api) => switch (api) {
        'accepted' => BookingStatusKind.accepted,
        'declined' => BookingStatusKind.declined,
        'cancelled' => BookingStatusKind.cancelled,
        'completed' => BookingStatusKind.completed,
        _ => BookingStatusKind.pending,
      };
}

/// A small outlined pill carrying a coloured dot and the status name.
///
/// The colour comes from `status/*` and is used for the outline, the dot and
/// the label together, on a white ground — the design never fills a badge.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  static const double _dotSize = 6;

  final BookingStatusKind status;

  Color get _color => switch (status) {
        BookingStatusKind.pending => AppColors.statusPending,
        BookingStatusKind.accepted => AppColors.statusAccepted,
        BookingStatusKind.declined => AppColors.statusDeclined,
        BookingStatusKind.completed => AppColors.statusCompleted,
        BookingStatusKind.cancelled => AppColors.statusCancelled,
      };

  @override
  Widget build(BuildContext context) {
    final String label = switch (status) {
      BookingStatusKind.pending => context.l10n.statusPending,
      BookingStatusKind.accepted => context.l10n.statusAccepted,
      BookingStatusKind.declined => context.l10n.statusDeclined,
      BookingStatusKind.completed => context.l10n.statusCompleted,
      BookingStatusKind.cancelled => context.l10n.statusCancelled,
    };

    return _OutlinedPill(
      color: _color,
      label: label,
      radius: AppRadii.md,
      dotSize: _dotSize,
    );
  }
}

/// Whether a service is taking bookings — the design's `Availability Badge`.
///
/// Same anatomy as [StatusBadge] but fully rounded, which is how the design
/// tells a property of a *service* apart from the state of a *booking*.
class AvailabilityBadge extends StatelessWidget {
  const AvailabilityBadge({required this.isAvailable, super.key});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return _OutlinedPill(
      color: isAvailable ? AppColors.statusAccepted : AppColors.statusCompleted,
      label: isAvailable
          ? context.l10n.availabilityAvailable
          : context.l10n.availabilityUnavailable,
      radius: AppRadii.full,
      dotSize: StatusBadge._dotSize,
    );
  }
}

class _OutlinedPill extends StatelessWidget {
  const _OutlinedPill({
    required this.color,
    required this.label,
    required this.radius,
    required this.dotSize,
  });

  final Color color;
  final String label;
  final double radius;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm.dw,
        vertical: AppSpacing.xs2.dh,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: dotSize.dw,
            height: dotSize.dw,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: AppSpacing.xs2.dw),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

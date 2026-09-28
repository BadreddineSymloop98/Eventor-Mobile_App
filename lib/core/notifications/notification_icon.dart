import '../widgets/atoms/app_icon.dart';

/// The icon a notification row shows, from its `type` (`"area.event"`).
///
/// Checked in order — the two exact `booking.*` cases first, then by area,
/// then by event — because `booking.accepted` must not fall into the
/// `booking` area's default before it is even considered, and an unknown
/// `booking.*` event (`booking.created`) should still land on the bell,
/// not on some other area's icon.
AppIcons notificationIcon(String type) {
  final int dot = type.indexOf('.');
  final String area = dot == -1 ? type : type.substring(0, dot);
  final String event = dot == -1 ? '' : type.substring(dot + 1);

  if (type == 'booking.accepted') return AppIcons.check;
  if (type == 'booking.declined' || type == 'booking.cancelled') {
    return AppIcons.close;
  }
  if (area == 'message' || area == 'dispute') return AppIcons.message;
  if (event == 'reminder' ||
      event == 'waiting' ||
      event.startsWith('reschedule')) {
    return AppIcons.calendar;
  }
  if (area == 'review' || area == 'review_reply') return AppIcons.starFilled;
  if (type == 'verification.approved') return AppIcons.check;
  if (type == 'verification.rejected' || type == 'academic_request.cancelled') {
    return AppIcons.close;
  }
  if (area == 'report') return AppIcons.alertTriangle;

  return AppIcons.bell;
}

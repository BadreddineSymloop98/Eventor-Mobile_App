import 'package:flutter/material.dart';

import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/formatting/chat_time_format.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/messaging/models/chat_message.dart';
import '../../../../core/messaging/picked_image.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/atoms/app_network_image.dart';
import '../../../../core/widgets/atoms/skeleton.dart';
import '../../../../l10n/app_localizations.dart';
import '../../view_model/chat_thread.dart';

/// One message on 15, as Figma draws it: received on the reading start,
/// sent on the end in the brand colour, the time inside at the end.
///
/// A removed message is always drawn received-style, with the app's own
/// words (decision 7). A pending one fades with a clock; a failed one says
/// "Not sent · Tap to retry" and a tap sends it again (D8).
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.entry,
    this.senderName,
    this.onLongPress,
    this.onRetry,
    this.onPhotoTap,
    this.onPhotoReload,
    super.key,
  });

  static const double maxWidth = 268;
  static const double photoWidth = 244;
  static const double photoHeight = 180;
  static const double _tail = 4;
  static const double _round = 16;
  static const double _clock = 12;
  static const double _sendingOpacity = 0.6;
  static const double _removedOpacity = 0.55;

  final ChatEntry entry;

  /// The sender, above the first bubble of their run in a group chat.
  final String? senderName;
  final VoidCallback? onLongPress;
  final VoidCallback? onRetry;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onPhotoReload;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ChatMessage message = entry.message;
    final bool removed = message.isRemoved;
    final bool sentStyle = message.mine && !removed;
    final bool failed = entry.state == EntryState.failed;
    final bool sending = entry.state == EntryState.sending;

    final Color textColor = sentStyle
        ? AppColors.textOnBrand
        : AppColors.textPrimary;
    final Color secondary = sentStyle
        ? AppColors.textOnBrand.withValues(alpha: 0.8)
        : AppColors.textSecondary;
    final BorderRadiusDirectional corners = sentStyle
        ? const BorderRadiusDirectional.only(
            topStart: Radius.circular(_round),
            topEnd: Radius.circular(_round),
            bottomEnd: Radius.circular(_tail),
            bottomStart: Radius.circular(_round),
          )
        : const BorderRadiusDirectional.only(
            topStart: Radius.circular(_round),
            topEnd: Radius.circular(_round),
            bottomEnd: Radius.circular(_round),
            bottomStart: Radius.circular(_tail),
          );

    final bool hasPhoto =
        !removed && (entry.localImage != null || message.hasImage);
    final String body = message.body.trim();

    final Widget footer = failed
        ? Text(
            l10n.chatNotSent,
            style: textTheme.labelSmall?.copyWith(color: AppColors.textDanger),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (sending) ...<Widget>[
                Semantics(
                  label: l10n.chatSending,
                  child: AppIcon(
                    AppIcons.clock,
                    size: _clock,
                    color: secondary,
                  ),
                ),
                SizedBox(width: AppSpacing.xs2.dw),
              ],
              Text(
                clockTime(message.createdAt),
                textDirection: TextDirection.ltr,
                style: textTheme.labelSmall?.copyWith(color: secondary),
              ),
            ],
          );

    final Widget bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth.dw),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.sm.dw,
        9.dh,
        AppSpacing.sm.dw,
        7.dh,
      ),
      decoration: BoxDecoration(
        color: sentStyle ? AppColors.bgBrand : AppColors.bgSurface,
        border: sentStyle ? null : Border.all(color: AppColors.borderDefault),
        borderRadius: corners,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (hasPhoto) ...<Widget>[
            _Photo(entry: entry, onTap: onPhotoTap, onReload: onPhotoReload),
            if (body.isNotEmpty) SizedBox(height: AppSpacing.xs.dh),
          ],
          if (removed)
            Opacity(
              opacity: _removedOpacity,
              child: Text(
                l10n.chatRemoved,
                style: textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            )
          else if (body.isNotEmpty)
            Text(
              message.body,
              style: textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          if (message.masked && !removed) ...<Widget>[
            SizedBox(height: 2.dh),
            Text(
              l10n.chatMaskedNote,
              style: textTheme.labelSmall?.copyWith(color: secondary),
            ),
          ],
          SizedBox(height: 2.dh),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            widthFactor: 1,
            child: footer,
          ),
        ],
      ),
    );

    final String? label = senderName;
    return Align(
      alignment: message.mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (label != null)
            Padding(
              padding: EdgeInsetsDirectional.only(bottom: AppSpacing.xs2.dh),
              child: Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          GestureDetector(
            onLongPress: removed ? null : onLongPress,
            onTap: failed ? onRetry : null,
            behavior: HitTestBehavior.opaque,
            child: Opacity(
              opacity: sending ? _sendingOpacity : 1,
              child: bubble,
            ),
          ),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.entry, this.onTap, this.onReload});

  final ChatEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onReload;

  @override
  Widget build(BuildContext context) {
    final double width = MessageBubble.photoWidth.dw;
    final double height = MessageBubble.photoHeight.dh;
    final PickedImage? local = entry.localImage;
    if (local != null) {
      return ClipRRect(
        borderRadius: AppRadii.smAll,
        child: Image.memory(
          local.bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: AppNetworkImage(
        url: entry.message.imageUrl,
        width: width,
        height: height,
        radius: AppRadii.smAll,
        placeholderIcon: AppIcons.image,
        // Signed URLs expire after about 15 minutes (D15).
        errorBuilder: () =>
            _ReloadTile(width: width, height: height, onTap: onReload),
      ),
    );
  }
}

class _ReloadTile extends StatelessWidget {
  const _ReloadTile({required this.width, required this.height, this.onTap});

  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.bgDisabled,
          borderRadius: AppRadii.smAll,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const AppIcon(AppIcons.image, color: AppColors.iconDefault),
            SizedBox(height: AppSpacing.xs2.dh),
            Text(
              context.l10n.photoReload,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The pill above a day's messages.
class DayPill extends StatelessWidget {
  const DayPill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: _Pill(child: _pillText(context, label)));
  }
}

/// A line from Eventor itself — "Booking requested · …". Full width, and it
/// wraps rather than truncating.
class SystemPill extends StatelessWidget {
  const SystemPill(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: _Pill(child: _pillText(context, text, center: true)),
    );
  }
}

Widget _pillText(BuildContext context, String text, {bool center = false}) =>
    Text(
      text,
      textAlign: center ? TextAlign.center : null,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: AppColors.textSecondary),
    );

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm.dw,
        vertical: AppSpacing.xs2.dh,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgDisabled,
        borderRadius: AppRadii.fullAll,
      ),
      child: child,
    );
  }
}

/// "New messages ↓" — shown when a poll brings messages while the user reads
/// further up (D9).
class NewMessagesPill extends StatelessWidget {
  const NewMessagesPill({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm.dw,
            vertical: AppSpacing.xs.dh,
          ),
          decoration: const BoxDecoration(
            color: AppColors.bgBrand,
            borderRadius: AppRadii.fullAll,
            boxShadow: AppElevation.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                context.l10n.chatNewMessages,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: AppColors.textOnBrand),
              ),
              SizedBox(width: AppSpacing.xs2.dw),
              const AppIcon(
                AppIcons.chevronDown,
                size: AppSizes.iconSm,
                color: AppColors.iconOnBrand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton bubbles for a chat's first load (G1).
class ChatSkeleton extends StatelessWidget {
  const ChatSkeleton({super.key});

  static const List<double> _widths = <double>[200, 240, 180, 220, 190, 240];

  @override
  Widget build(BuildContext context) {
    return ListView(
      reverse: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md.dw,
        vertical: AppSpacing.sm.dh,
      ),
      children: <Widget>[
        for (final (int i, double width) in _widths.indexed)
          Padding(
            padding: EdgeInsets.only(bottom: 10.dh),
            child: Align(
              alignment: i.isEven
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Skeleton(
                height: 44.dh,
                width: width.dw,
                radius: AppRadii.lgAll,
              ),
            ),
          ),
      ],
    );
  }
}

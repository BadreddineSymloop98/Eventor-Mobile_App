import 'package:flutter/material.dart';

import '../../../../core/bookings/bookings_repository.dart';
import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/formatting/booking_format.dart';
import '../../../../core/formatting/date_format.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/widgets/atoms/app_chip.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/molecules/app_text_area.dart';
import '../../../../core/widgets/molecules/inline_banner.dart';
import '../../../../core/widgets/molecules/main_button.dart';
import '../../../../core/widgets/molecules/meta_line.dart';
import '../../../../core/widgets/molecules/note_callout.dart';
import '../../../../core/widgets/organisms/app_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';

/// B5 Cancel booking — and, while the reason is being typed, B5a: the recap
/// and the note step aside so the field and the buttons stay above the
/// keyboard. `true` once cancelled.
Future<bool> showCancelBookingSheet(
  BuildContext context, {
  required BookingDetail booking,
  required int daysToEvent,
  required int maxReason,
  required Future<Failure?> Function(String reason) onCancel,
}) async {
  final bool? cancelled = await showAppBottomSheet<bool>(
    context,
    builder: (_) => _CancelSheet(
      booking: booking,
      daysToEvent: daysToEvent,
      maxReason: maxReason,
      onCancel: onCancel,
    ),
  );
  return cancelled ?? false;
}

class _CancelSheet extends StatefulWidget {
  const _CancelSheet({
    required this.booking,
    required this.daysToEvent,
    required this.maxReason,
    required this.onCancel,
  });

  final BookingDetail booking;
  final int daysToEvent;
  final int maxReason;
  final Future<Failure?> Function(String reason) onCancel;

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  final TextEditingController _reason = TextEditingController();
  bool _isSending = false;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _reason.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _isSending = true;
      _failure = null;
    });
    final Failure? failure = await widget.onCancel(_reason.text.trim());
    if (!mounted) return;
    if (failure == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _isSending = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final BookingDetail booking = widget.booking;
    final BookingCard card = booking.card;
    final String provider = card.providerName;
    final bool isRequest = card.status == 'pending';
    // B5a: the keyboard is up.
    final bool typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    final Failure? failure = _failure;
    final String? policy = booking.cancellationPolicy;

    return AppSheetScaffold(
      title: isRequest ? l10n.cancelRequestTitle : l10n.cancelBookingTitle,
      subtitle: typing
          ? l10n.cancelBodyShort(provider)
          : isRequest
              ? l10n.cancelRequestBody(provider)
              : l10n.cancelBookingBody(provider),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (failure != null) ...<Widget>[
              InlineBanner(title: l10n.forFailure(failure)),
              SizedBox(height: AppSpacing.sm.dh),
            ],
            if (!typing) ...<Widget>[
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md.dw,
                  vertical: AppSpacing.sm.dh,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.bgCanvas,
                  borderRadius: AppRadii.mdAll,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      card.title.of(language),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
                    ),
                    SizedBox(height: AppSpacing.xs2.dh / 2),
                    MetaLine(
                      parts: <MetaPart>[
                        MetaPart(shortDate(card.eventDate, language)),
                        MetaPart(timeRange(card.startTime, card.endTime, nextDay: context.l10n.bookingNextDayMark), isLtr: true),
                        MetaPart.amount(card.total),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md.dh),
            ],
            AppTextArea(
              // B5a removes the recap above this field the moment the
              // keyboard rises. Unkeyed, the field would move to another slot
              // in this Column and be rebuilt from scratch — a new focus
              // node, so the keyboard dropped straight away and the recap
              // came back. The key carries its state across the change.
              key: const ValueKey<String>('cancel-reason'),
              controller: _reason,
              label: l10n.cancelReasonLabel,
              hintText: l10n.cancelReasonHint,
              helperText: l10n.cancelReasonHelper(provider),
              maxLength: widget.maxReason,
              enabled: !_isSending,
              maxLines: 3,
            ),
            if (!typing) ...<Widget>[
              SizedBox(height: AppSpacing.md.dh),
              NoteCallout(
                text: <String>[
                  l10n.cancelDaysBefore(widget.daysToEvent),
                  if (policy == null) l10n.cancelNothingPaid else l10n.cancelPolicyQuote(provider, policy),
                ].join(' '),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        MainButton(
          label: isRequest ? l10n.cancelRequestConfirm : l10n.cancelBookingConfirm,
          tone: MainButtonTone.danger,
          isLoading: _isSending,
          canBeTapped: _reason.text.trim().isNotEmpty,
          onPressed: _send,
        ),
        MainButton(
          label: isRequest ? l10n.cancelRequestKeep : l10n.cancelBookingKeep,
          style: MainButtonStyle.ghost,
          onPressed: _isSending ? null : () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}

/// "Leave a review": 1–5 stars and a comment of 10 to 2000 characters.
/// `true` once published.
Future<bool> showReviewSheet(
  BuildContext context, {
  required String providerName,
  required Future<Failure?> Function(int rating, String comment) onSubmit,
}) async {
  final bool? sent = await showAppBottomSheet<bool>(
    context,
    builder: (_) => _ReviewSheet(providerName: providerName, onSubmit: onSubmit),
  );
  return sent ?? false;
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.providerName, required this.onSubmit});

  final String providerName;
  final Future<Failure?> Function(int rating, String comment) onSubmit;

  static const int minComment = 10;
  static const int maxComment = 2000;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final TextEditingController _comment = TextEditingController();
  int _rating = 0;
  bool _isSending = false;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _comment.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _valid =>
      _rating > 0 && _comment.text.trim().length >= _ReviewSheet.minComment;

  Future<void> _send() async {
    setState(() {
      _isSending = true;
      _failure = null;
    });
    final Failure? failure = await widget.onSubmit(_rating, _comment.text.trim());
    if (!mounted) return;
    if (failure == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _isSending = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Failure? failure = _failure;
    final int length = _comment.text.trim().length;

    return AppSheetScaffold(
      title: l10n.reviewTitle(widget.providerName),
      subtitle: l10n.reviewBody,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (failure != null) ...<Widget>[
              InlineBanner(title: l10n.forFailure(failure)),
              SizedBox(height: AppSpacing.sm.dh),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int star = 1; star <= 5; star++)
                  Semantics(
                    button: true,
                    selected: star <= _rating,
                    label: l10n.reviewStars(star),
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: _isSending ? null : () => setState(() => _rating = star),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsetsDirectional.all(AppSpacing.xs2.dw),
                        child: AppIcon(
                          star <= _rating ? AppIcons.starFilled : AppIcons.star,
                          size: 40,
                          color: star <= _rating ? AppColors.ratingFilled : AppColors.ratingEmpty,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.md.dh),
            AppTextArea(
              controller: _comment,
              label: l10n.reviewCommentLabel,
              hintText: l10n.reviewCommentHint,
              helperText: length > 0 && length < _ReviewSheet.minComment
                  ? l10n.reviewCommentTooShort(_ReviewSheet.minComment)
                  : l10n.reviewCommentHelper,
              maxLength: _ReviewSheet.maxComment,
              enabled: !_isSending,
              minLines: 3,
              maxLines: 6,
              showCounter: false,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        MainButton(
          label: l10n.reviewSubmit,
          isLoading: _isSending,
          canBeTapped: _valid,
          onPressed: _send,
        ),
        MainButton(
          label: l10n.reviewLater,
          style: MainButtonStyle.ghost,
          onPressed: _isSending ? null : () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}

/// "There was a problem": what went wrong and what happened, 30 to 5000
/// characters. It opens a dispute; Eventor support steps in. `true` once
/// reported.
Future<bool> showProblemSheet(
  BuildContext context, {
  required String providerName,
  required Future<Failure?> Function(DisputeType type, String description) onSubmit,
}) async {
  final bool? sent = await showAppBottomSheet<bool>(
    context,
    builder: (_) => _ProblemSheet(providerName: providerName, onSubmit: onSubmit),
  );
  return sent ?? false;
}

class _ProblemSheet extends StatefulWidget {
  const _ProblemSheet({required this.providerName, required this.onSubmit});

  final String providerName;
  final Future<Failure?> Function(DisputeType type, String description) onSubmit;

  static const int minDescription = 30;
  static const int maxDescription = 5000;

  @override
  State<_ProblemSheet> createState() => _ProblemSheetState();
}

class _ProblemSheetState extends State<_ProblemSheet> {
  final TextEditingController _description = TextEditingController();
  DisputeType? _type;
  bool _isSending = false;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _description.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  bool get _valid =>
      _type != null &&
      _description.text.trim().length >= _ProblemSheet.minDescription;

  Future<void> _send() async {
    final DisputeType? type = _type;
    if (type == null) return;
    setState(() {
      _isSending = true;
      _failure = null;
    });
    final Failure? failure = await widget.onSubmit(type, _description.text.trim());
    if (!mounted) return;
    if (failure == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _isSending = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Failure? failure = _failure;
    final int length = _description.text.trim().length;

    String label(DisputeType type) => switch (type) {
          DisputeType.providerNoShow => l10n.problemNoShow,
          DisputeType.serviceNotAsDescribed => l10n.problemNotAsDescribed,
          DisputeType.incompleteOrLate => l10n.problemLate,
          DisputeType.priceDisagreement => l10n.problemPrice,
          DisputeType.damageOrSafety => l10n.problemDamage,
          DisputeType.behaviour => l10n.problemBehaviour,
          DisputeType.other => l10n.problemOther,
        };

    return AppSheetScaffold(
      title: l10n.problemTitle,
      subtitle: l10n.problemBody(widget.providerName),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (failure != null) ...<Widget>[
              InlineBanner(title: l10n.forFailure(failure)),
              SizedBox(height: AppSpacing.sm.dh),
            ],
            Text(
              l10n.problemTypeLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
            ),
            SizedBox(height: AppSpacing.xs.dh),
            Wrap(
              spacing: AppSpacing.xs.dw,
              runSpacing: AppSpacing.xs.dh,
              children: <Widget>[
                for (final DisputeType type in DisputeType.values)
                  AppChip(
                    label: label(type),
                    isSelected: _type == type,
                    onTap: () => setState(() => _type = type),
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.md.dh),
            AppTextArea(
              controller: _description,
              label: l10n.problemDescriptionLabel,
              hintText: l10n.problemDescriptionHint,
              helperText: length > 0 && length < _ProblemSheet.minDescription
                  ? l10n.problemDescriptionTooShort(_ProblemSheet.minDescription - length)
                  : l10n.problemDescriptionHelper,
              maxLength: _ProblemSheet.maxDescription,
              enabled: !_isSending,
              minLines: 4,
              maxLines: 8,
              showCounter: false,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        MainButton(
          label: l10n.problemSubmit,
          tone: MainButtonTone.danger,
          isLoading: _isSending,
          canBeTapped: _valid,
          onPressed: _send,
        ),
        MainButton(
          label: l10n.problemCancel,
          style: MainButtonStyle.ghost,
          onPressed: _isSending ? null : () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}

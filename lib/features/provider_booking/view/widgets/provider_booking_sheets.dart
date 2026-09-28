import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/bookings/models/booking_card.dart';
import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/formatting/date_format.dart';
import '../../../../core/formatting/money_format.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/provider/provider_repository.dart';
import '../../../../core/widgets/atoms/app_chip.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/molecules/app_text_area.dart';
import '../../../../core/widgets/molecules/inline_banner.dart';
import '../../../../core/widgets/molecules/main_button.dart';
import '../../../../core/widgets/organisms/app_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';

/// The API's cap on a decline or cancel reason.
const int providerReasonMaxLength = 60;

/// P3 — declining a request, which cannot be undone, with the reason the
/// client will read. The sheet stays up while the decline is sent and shows
/// a refusal in place; `true` once it went through. Shared by 21, P1 and P2.
Future<bool> showDeclineSheet(
  BuildContext context, {
  required BookingCard request,
  required Future<Failure?> Function(String reason) onDecline,
}) async {
  final AppLocalizations l10n = context.l10n;
  final String client = request.counterpartyName;
  final bool? declined = await showAppBottomSheet<bool>(
    context,
    builder: (BuildContext sheetContext) => _ReasonSheet(
      booking: request,
      title: l10n.providerBookingDeclineTitle,
      body: l10n.declineBody(client),
      label: l10n.providerBookingDeclineReasonLabel,
      hint: l10n.declineReasonHint,
      helper: l10n.declineReasonHelper(client),
      note: l10n.declineNote,
      confirmLabel: l10n.declineConfirm,
      keepLabel: l10n.declineGoBack,
      onSubmit: onDecline,
    ),
  );
  return declined ?? false;
}

/// P2a's "Cancel booking": the provider cancels an accepted booking, with a
/// reason (required, 1–60) the client reads — the same P3 treatment as the
/// decline, since it cannot be undone either. `true` once cancelled.
Future<bool> showProviderCancelSheet(
  BuildContext context, {
  required BookingCard booking,
  required Future<Failure?> Function(String reason) onCancel,
}) async {
  final AppLocalizations l10n = context.l10n;
  final String client = booking.counterpartyName;
  final bool? cancelled = await showAppBottomSheet<bool>(
    context,
    builder: (BuildContext sheetContext) => _ReasonSheet(
      booking: booking,
      title: l10n.cancelBookingTitle,
      body: l10n.providerBookingCancelBody(client),
      label: l10n.cancelReasonLabel,
      hint: l10n.providerBookingCancelReasonHint,
      helper: l10n.declineReasonHelper(client),
      note: l10n.providerBookingCancelNote,
      confirmLabel: l10n.cancelBookingConfirm,
      keepLabel: l10n.providerBookingCancelKeep,
      onSubmit: onCancel,
    ),
  );
  return cancelled ?? false;
}

/// A sheet that ends something with a short reason the client reads: the
/// booking recap, the reason with its live counter, a note, and the red
/// confirm over the way back.
class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({
    required this.booking,
    required this.title,
    required this.body,
    required this.label,
    required this.hint,
    required this.helper,
    required this.note,
    required this.confirmLabel,
    required this.keepLabel,
    required this.onSubmit,
  });

  final BookingCard booking;
  final String title;
  final String body;
  final String label;
  final String hint;
  final String helper;
  final String note;
  final String confirmLabel;
  final String keepLabel;
  final Future<Failure?> Function(String reason) onSubmit;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final TextEditingController _reason = TextEditingController();
  bool _isSending = false;
  Failure? _failure;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    // The button is busy already; a second tap must not send twice.
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _failure = null;
    });
    final Failure? failure = await widget.onSubmit(_reason.text.trim());
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
    final BookingCard booking = widget.booking;
    final Failure? failure = _failure;
    final TextStyle? recapMeta = textTheme.labelSmall?.copyWith(color: AppColors.textSecondary);
    final String? start = booking.startTime;
    final String? end = booking.endTime;

    return AppSheetScaffold(
      title: widget.title,
      subtitle: widget.body,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (failure != null) ...<Widget>[
              InlineBanner(title: l10n.forFailure(failure)),
              SizedBox(height: AppSpacing.sm.dh),
            ],
            Container(
              padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
              decoration: const BoxDecoration(
                color: AppColors.bgCanvas,
                borderRadius: AppRadii.mdAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    booking.title.of(language),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
                  ),
                  SizedBox(height: AppSpacing.xs2.dh),
                  // Date, times and amount as separate runs, so the digits
                  // keep their order in Arabic.
                  Wrap(
                    spacing: AppSpacing.xs2.dw,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(shortDate(booking.eventDate, language), style: recapMeta),
                      if (start != null) ...<Widget>[
                        Text('·', style: recapMeta),
                        Text(
                          end == null ? start : '$start → $end',
                          textDirection: TextDirection.ltr,
                          style: recapMeta,
                        ),
                      ],
                      Text('·', style: recapMeta),
                      Text(formatAmount(booking.total), textDirection: TextDirection.ltr, style: recapMeta),
                      Text(l10n.currencyDzd, style: recapMeta),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md.dh),
            Text(
              widget.label,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppSpacing.xs2.dh),
            Container(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md.dw,
                vertical: AppSpacing.sm.dh,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppRadii.mdAll,
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: TextField(
                controller: _reason,
                enabled: !_isSending,
                minLines: 2,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(providerReasonMaxLength),
                ],
                onChanged: (_) => setState(() {}),
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                cursorColor: AppColors.borderBrand,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: widget.hint,
                  hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.xs2.dh),
            Row(
              children: <Widget>[
                Expanded(child: Text(widget.helper, style: recapMeta)),
                Text(
                  '${_reason.text.length}/$providerReasonMaxLength',
                  textDirection: TextDirection.ltr,
                  style: recapMeta,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md.dh),
            Container(
              padding: EdgeInsetsDirectional.all(AppSpacing.sm.dw),
              decoration: const BoxDecoration(
                color: AppColors.bgBrandSubtle,
                borderRadius: AppRadii.mdAll,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const AppIcon(AppIcons.check, size: AppSizes.iconMd, color: AppColors.iconDefault),
                  SizedBox(width: AppSpacing.xs.dw),
                  Expanded(
                    child: Text(
                      widget.note,
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        MainButton(
          label: widget.confirmLabel,
          tone: MainButtonTone.danger,
          isLoading: _isSending,
          canBeTapped: _reason.text.trim().isNotEmpty,
          onPressed: _send,
        ),
        MainButton(
          label: widget.keepLabel,
          style: MainButtonStyle.secondary,
          onPressed: _isSending ? null : () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}

/// "Report a problem" (P2b / P2e) and P5's "There was a problem", from the
/// provider's side: what went wrong with the client and what happened, 30
/// to 5000 characters. It opens a dispute; Eventor support steps in. `true`
/// once reported.
Future<bool> showProviderProblemSheet(
  BuildContext context, {
  required String clientName,
  required Future<Failure?> Function(ProviderDisputeType type, String description) onSubmit,
}) async {
  final bool? sent = await showAppBottomSheet<bool>(
    context,
    builder: (_) => _ProblemSheet(clientName: clientName, onSubmit: onSubmit),
  );
  return sent ?? false;
}

class _ProblemSheet extends StatefulWidget {
  const _ProblemSheet({required this.clientName, required this.onSubmit});

  final String clientName;
  final Future<Failure?> Function(ProviderDisputeType type, String description) onSubmit;

  static const int minDescription = 30;
  static const int maxDescription = 5000;

  @override
  State<_ProblemSheet> createState() => _ProblemSheetState();
}

class _ProblemSheetState extends State<_ProblemSheet> {
  final TextEditingController _description = TextEditingController();
  ProviderDisputeType? _type;
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
      _type != null && _description.text.trim().length >= _ProblemSheet.minDescription;

  Future<void> _send() async {
    final ProviderDisputeType? type = _type;
    if (type == null || _isSending) return;
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

    String label(ProviderDisputeType type) => switch (type) {
          ProviderDisputeType.clientNoShow => l10n.providerBookingProblemClientNoShow,
          ProviderDisputeType.priceDisagreement => l10n.problemPrice,
          ProviderDisputeType.cancellationDisagreement => l10n.providerBookingProblemCancellation,
          ProviderDisputeType.damageOrSafety => l10n.problemDamage,
          ProviderDisputeType.behaviour => l10n.problemBehaviour,
          ProviderDisputeType.other => l10n.problemOther,
        };

    return AppSheetScaffold(
      title: l10n.problemTitle,
      subtitle: l10n.problemBody(widget.clientName),
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
                for (final ProviderDisputeType type in ProviderDisputeType.values)
                  AppChip(
                    label: label(type),
                    isSelected: _type == type,
                    onTap: _isSending ? null : () => setState(() => _type = type),
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

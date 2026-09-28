import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/availability/availability_repository.dart';
import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/formatting/booking_format.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/provider/models/provider_home.dart' show ProviderServiceRow, ProviderServiceStatus;
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/atoms/app_spinner.dart';
import '../../../../core/widgets/molecules/app_text_field.dart';
import '../../../../core/widgets/molecules/inline_banner.dart';
import '../../../../core/widgets/molecules/main_button.dart';
import '../../../../core/widgets/organisms/app_bottom_sheet.dart';
import '../../../../core/widgets/organisms/discard_guard.dart';
import '../../../../core/widgets/organisms/selection_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../booking_request/view/widgets/booking_form_sections.dart' show TimeBlock;
import '../../view_model/availability_view_model.dart';

/// What P15c's day sheet was closed with — the screen then acts on it.
sealed class DaySheetAction {
  const DaySheetAction();
}

/// "Remove" on one of the provider's own blocks.
class RemoveBlock extends DaySheetAction {
  const RemoveBlock(this.item);

  final ProviderDayItem item;
}

/// "Block the whole day" (P15a) or "Block a time slot" (P15b).
class BlockDay extends DaySheetAction {
  const BlockDay(this.mode);

  final BlockMode mode;
}

/// A booking or a request row — P2 opens.
class OpenBooking extends DaySheetAction {
  const OpenBooking(this.bookingId);

  final String bookingId;
}

/// P15a blocks the whole day, P15b a time slot of it.
enum BlockMode { wholeDay, slot }

/// P15c — what is on [day], with its removals and the ways to block it.
///
/// Remove closes the sheet and the screen removes at once with an Undo
/// toast (decision 6): a toast under an open sheet would be hidden by it.
/// A past day's sheet only shows; [refusal] explains why a day takes no
/// more blocks.
Future<DaySheetAction?> showDaySheet(
  BuildContext context, {
  required ProviderDay day,
  required bool isPast,
  required BlockRefusal? refusal,
}) {
  return showAppBottomSheet<DaySheetAction>(
    context,
    builder: (BuildContext sheetContext) => _DaySheet(day: day, isPast: isPast, refusal: refusal),
  );
}

class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.day, required this.isPast, required this.refusal});

  final ProviderDay day;
  final bool isPast;
  final BlockRefusal? refusal;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final List<ProviderDayItem> items = day.items;
    final bool canBlock = !isPast && refusal == null;
    final bool hasSlot = items.any(
      (ProviderDayItem i) => i.kind == ProviderDayItemKind.blocked && !i.isWholeDay,
    );
    final String? why = switch (refusal) {
      BlockRefusal.alreadyBlocked => l10n.availabilityAlreadyBlocked,
      BlockRefusal.fullyBooked => l10n.availabilityFullyBooked,
      BlockRefusal.past || null => null,
    };

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: AppSheetScaffold(
        title: weekdayDayMonth(day.date, language),
        subtitle: isPast
            ? l10n.availabilityDayPast
            : <String>[
                l10n.availabilityDaySummary(items.length),
                if (items.any((ProviderDayItem i) => !i.removable)) l10n.availabilityDayRemoveHint,
              ].join(' '),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (items.isNotEmpty)
                _GroupedCard(
                  children: <Widget>[
                    for (final ProviderDayItem item in items)
                      _DayItemRow(
                        item: item,
                        canRemove: !isPast && item.removable && item.id != null,
                        onRemove: () => Navigator.of(context).pop(RemoveBlock(item)),
                        onOpen: item.booking == null
                            ? null
                            : () => Navigator.of(context).pop(OpenBooking(item.booking!.id)),
                      ),
                  ],
                ),
              if (why != null) ...<Widget>[
                if (items.isNotEmpty) SizedBox(height: AppSpacing.sm.dh),
                Text(why, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          if (canBlock) ...<Widget>[
            MainButton(
              label: l10n.availabilityBlockWholeDay,
              onPressed: () => Navigator.of(context).pop(const BlockDay(BlockMode.wholeDay)),
            ),
            MainButton(
              label: hasSlot ? l10n.availabilityBlockAnotherSlot : l10n.availabilityBlockSlot,
              style: MainButtonStyle.secondary,
              onPressed: () => Navigator.of(context).pop(const BlockDay(BlockMode.slot)),
            ),
          ],
          MainButton(
            label: l10n.availabilityClose,
            style: canBlock ? MainButtonStyle.ghost : MainButtonStyle.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// The sheet's grouped list: white, hairline border, 12pt corners, a hairline
/// between rows.
class _GroupedCard extends StatelessWidget {
  const _GroupedCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// [text] as a left-to-right island inside a sentence: `EVT-2026-0142`'s
/// hyphens and digits would otherwise be reordered in Arabic ("2026-0142-EVT").
String _isolated(String text) => '\u2066$text\u2069';

/// One thing on the day. A block says when and for which services, with its
/// note and "Remove"; a booking or request says its reference and times,
/// why it cannot be removed here, and opens P2.
class _DayItemRow extends StatelessWidget {
  const _DayItemRow({
    required this.item,
    required this.canRemove,
    required this.onRemove,
    required this.onOpen,
  });

  final ProviderDayItem item;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final TextStyle? titleStyle = textTheme.labelLarge?.copyWith(color: AppColors.textPrimary);
    final TextStyle? meta = textTheme.labelSmall?.copyWith(color: AppColors.textSecondary);
    final String times = timeRange(item.startTime, item.endTime, nextDay: l10n.bookingNextDayMark);
    final DayBooking? booking = item.booking;
    final String? note = item.note;
    final String service = item.service?.title.of(language) ?? l10n.availabilityAllServices;

    // Label, times and name as separate runs, so each keeps its own
    // direction in Arabic; the reference sits inside its sentence, isolated.
    final List<Widget> title = <Widget>[
      switch (item.kind) {
        ProviderDayItemKind.booked => Text(l10n.availabilityItemBooked(_isolated(booking?.reference ?? '')), style: titleStyle),
        ProviderDayItemKind.held => Text(l10n.availabilityItemHeld(_isolated(booking?.reference ?? '')), style: titleStyle),
        ProviderDayItemKind.blocked => Text(
            item.isWholeDay ? l10n.availabilityItemBlockedAllDay : l10n.availabilityItemBlockedSlot,
            style: titleStyle,
          ),
      },
      if (item.kind == ProviderDayItemKind.blocked && times.isNotEmpty)
        Text(times, textDirection: TextDirection.ltr, style: titleStyle),
      if (booking?.clientName case final String client) ...<Widget>[
        Text('·', style: titleStyle),
        Text(client, style: titleStyle),
      ],
    ];

    final Widget trailing = canRemove
        ? Semantics(
            button: true,
            child: GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: AppSizes.controlSm.dh),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    l10n.availabilityRemove,
                    style: textTheme.labelLarge?.copyWith(color: AppColors.statusDeclined),
                  ),
                ),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(l10n.availabilityCannotRemove, style: meta),
              if (onOpen != null) ...<Widget>[
                SizedBox(width: AppSpacing.xs2.dw),
                const AppIcon(AppIcons.chevronRight, size: AppSizes.iconSm, color: AppColors.iconDefault),
              ],
            ],
          );

    final Widget row = Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md.dw,
        vertical: AppSpacing.sm.dh,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(spacing: AppSpacing.xs2.dw, children: title),
                SizedBox(height: AppSpacing.xs2.dh),
                Wrap(
                  spacing: AppSpacing.xs2.dw,
                  children: <Widget>[
                    if (item.isBooking && times.isNotEmpty) ...<Widget>[
                      Text(times, textDirection: TextDirection.ltr, style: meta),
                      Text('·', style: meta),
                    ],
                    // A pack booking has no single service to name.
                    if (!item.isBooking || item.service != null) Text(service, style: meta),
                  ],
                ),
                if (note != null)
                  Text(
                    l10n.availabilityItemNote(note),
                    style: meta?.copyWith(color: AppColors.textPrimary),
                  ),
                if (item.kind == ProviderDayItemKind.booked)
                  Text(l10n.availabilityWhyBooked, style: meta)
                else if (item.kind == ProviderDayItemKind.held)
                  Text(l10n.availabilityWhyHeld, style: meta),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.dw),
          trailing,
        ],
      ),
    );

    final VoidCallback? open = onOpen;
    if (open == null) return row;
    return Semantics(
      button: true,
      child: GestureDetector(onTap: open, behavior: HitTestBehavior.opaque, child: row),
    );
  }
}

/// P15a / P15b — block [day] whole or in part, for every service or one,
/// with a private note (decision 3: both sheets take both). Answers with
/// the mode blocked, or `null` when left.
///
/// The server's refusals show inside the sheet, which stays open: a past
/// day, a service that is no longer the provider's, a field it refused.
Future<BlockMode?> showBlockSheet(
  BuildContext context, {
  required AvailabilityViewModel viewModel,
  required ProviderDay day,
  required BlockMode mode,
}) {
  return showAppBottomSheet<BlockMode>(
    context,
    builder: (BuildContext sheetContext) => _BlockSheet(viewModel: viewModel, day: day, initialMode: mode),
  );
}

class _BlockSheet extends StatefulWidget {
  const _BlockSheet({required this.viewModel, required this.day, required this.initialMode});

  final AvailabilityViewModel viewModel;
  final ProviderDay day;
  final BlockMode initialMode;

  @override
  State<_BlockSheet> createState() => _BlockSheetState();
}

class _BlockSheetState extends State<_BlockSheet> {
  final TextEditingController _note = TextEditingController();
  late BlockMode _mode = widget.initialMode;
  String? _serviceId;
  String? _start;
  String? _end;
  bool _isSending = false;
  bool _isLoadingServices = false;
  bool _servicesFailed = false;
  bool _timesMissing = false;
  Failure? _failure;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _isDirty => _note.text.trim().isNotEmpty || _start != null || _end != null || _serviceId != null;

  /// The server's own words for one field of a `VALIDATION_FAILED`.
  String? _fieldError(Set<String> fields) {
    final Failure? failure = _failure;
    if (failure is! ApiFailure) return null;
    for (final FieldError error in failure.fieldErrors) {
      if (fields.contains(error.field)) return error.message;
    }
    return null;
  }

  /// The failure for the banner — `null` when every refused field already
  /// shows its own message.
  String? _bannerText(AppLocalizations l10n) {
    final Failure? failure = _failure;
    if (failure == null) return null;
    if (failure is ApiFailure) {
      switch (failure.code) {
        case ApiErrorCode.availabilityDatePast:
          return l10n.availabilityErrorDatePast;
        case ApiErrorCode.availabilityServiceInvalid:
          return l10n.availabilityErrorServiceInvalid;
        case ApiErrorCode.validationFailed:
          // The note shows its own error; the times do on the slot sheet.
          final bool isSlot = _mode == BlockMode.slot;
          final bool allShown = failure.fieldErrors.isNotEmpty &&
              failure.fieldErrors.every(
                (FieldError e) =>
                    e.field == 'note' || (isSlot && (e.field == 'startTime' || e.field == 'endTime')),
              );
          if (allShown) return null;
      }
    }
    return l10n.forFailure(failure);
  }

  /// The picked service's name, kept from the pick: a refused service drops
  /// the view model's list, and the row must still say what was refused.
  String? _serviceTitle;

  String _serviceName(AppLocalizations l10n) =>
      _serviceId == null ? l10n.availabilityAllServices : _serviceTitle ?? l10n.availabilityAllServices;

  Future<void> _pickService() async {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    if (widget.viewModel.services == null) {
      setState(() {
        _isLoadingServices = true;
        _servicesFailed = false;
      });
      final Failure? failure = await widget.viewModel.loadServices();
      if (!mounted) return;
      setState(() {
        _isLoadingServices = false;
        _servicesFailed = failure != null;
      });
      if (failure != null) return;
    }
    final List<ProviderServiceRow> services = widget.viewModel.services ?? const <ProviderServiceRow>[];
    // '' stands for every service — the picker's values cannot be null.
    const String all = '';
    final Set<String>? picked = await showSelectionSheet<String>(
      context,
      title: l10n.availabilityServicesLabel,
      subtitle: l10n.availabilityServicesSubtitle,
      selected: <String>{_serviceId ?? all},
      options: <SelectionOption<String>>[
        SelectionOption<String>(value: all, label: l10n.availabilityAllServices),
        for (final ProviderServiceRow service in services)
          SelectionOption<String>(
            value: service.id,
            label: service.title.of(language),
            detail: switch (service.status) {
              ProviderServiceStatus.published => null,
              ProviderServiceStatus.draft => l10n.serviceStatusDraft,
              ProviderServiceStatus.hidden => l10n.serviceStatusHidden,
            },
          ),
      ],
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    setState(() {
      _serviceId = picked.first == all ? null : picked.first;
      _serviceTitle = null;
      for (final ProviderServiceRow service in services) {
        if (service.id == _serviceId) _serviceTitle = service.title.of(language);
      }
      if (_failure case ApiFailure(code: ApiErrorCode.availabilityServiceInvalid)) _failure = null;
    });
  }

  void _setMode(BlockMode mode) {
    if (_isSending || mode == _mode) return;
    setState(() {
      _mode = mode;
      _timesMissing = false;
      _failure = null;
    });
  }

  Future<void> _submit() async {
    if (_isSending) return;
    final bool isSlot = _mode == BlockMode.slot;
    if (isSlot && (_start == null || _end == null)) {
      setState(() => _timesMissing = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSending = true;
      _failure = null;
    });
    final String note = _note.text.trim();
    final Failure? failure = await widget.viewModel.block(
      BlockRequest(
        date: widget.day.date,
        startTime: isSlot ? _start : null,
        endTime: isSlot ? _end : null,
        serviceId: _serviceId,
        note: note.isEmpty ? null : note,
      ),
    );
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(_mode);
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
    final String language = Localizations.localeOf(context).languageCode;
    final bool isSlot = _mode == BlockMode.slot;
    final String dayLabel = weekdayDayMonth(widget.day.date, language);
    final String? banner = _bannerText(l10n);
    final String? timesError = isSlot ? _fieldError(<String>{'startTime', 'endTime'}) : null;
    final List<ProviderDayItem> items = widget.day.items;
    final bool held = items.any((ProviderDayItem i) => i.kind == ProviderDayItemKind.held);
    final bool booked = items.any((ProviderDayItem i) => i.kind == ProviderDayItemKind.booked);
    final bool serviceRefused = switch (_failure) {
      ApiFailure(code: ApiErrorCode.availabilityServiceInvalid) => true,
      _ => false,
    };

    return DiscardGuard(
      isDirty: _isDirty && !_isSending,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        child: AppSheetScaffold(
          title: isSlot ? l10n.availabilityBlockSlotTitle(dayLabel) : l10n.availabilityBlockDayTitle(dayLabel),
          subtitle: isSlot ? l10n.availabilityBlockSlotBody : l10n.availabilityBlockDayBody,
          body: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (banner != null) ...<Widget>[
                  InlineBanner(title: banner),
                  SizedBox(height: AppSpacing.sm.dh),
                ],
                if (_servicesFailed) ...<Widget>[
                  InlineBanner(title: l10n.availabilityServicesFailed),
                  SizedBox(height: AppSpacing.sm.dh),
                ],
                if (held || booked) ...<Widget>[
                  InlineBanner(
                    tone: InlineBannerTone.info,
                    title: booked ? l10n.availabilityBookedWarning : l10n.availabilityHeldWarning,
                  ),
                  SizedBox(height: AppSpacing.sm.dh),
                ],
                _GroupedCard(
                  children: <Widget>[
                    _OptionRow(
                      label: l10n.availabilityModeWholeDay,
                      value: isSlot ? null : l10n.availabilityModeSelected,
                      isChosen: !isSlot,
                      onTap: _isSending ? null : () => _setMode(BlockMode.wholeDay),
                    ),
                    _OptionRow(
                      label: l10n.availabilityModeSlot,
                      value: isSlot ? l10n.availabilityModeSelected : null,
                      isChosen: isSlot,
                      onTap: _isSending ? null : () => _setMode(BlockMode.slot),
                    ),
                    _OptionRow(
                      label: l10n.availabilityServicesLabel,
                      value: _serviceName(l10n),
                      hasError: serviceRefused,
                      isLoading: _isLoadingServices,
                      opensPicker: true,
                      onTap: _isSending || _isLoadingServices ? null : _pickService,
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md.dh),
                if (isSlot) ...<Widget>[
                  TimeBlock(
                    date: widget.day.date,
                    start: _start,
                    end: _end,
                    enabled: !_isSending,
                    helper: timesError ??
                        (_timesMissing ? l10n.availabilityTimesMissing : l10n.availabilitySlotHelper),
                    hasError: timesError != null || _timesMissing,
                    onStart: (String? value) => setState(() {
                      _start = value;
                      // As on B1: an end equal to the new start is not a slot.
                      if (value == null || value == _end) _end = null;
                      if (_start != null && _end != null) _timesMissing = false;
                    }),
                    onEnd: (String? value) => setState(() {
                      _end = value;
                      if (_start != null && _end != null) _timesMissing = false;
                    }),
                  ),
                  SizedBox(height: AppSpacing.md.dh),
                ],
                AppTextField(
                  controller: _note,
                  label: l10n.availabilityNoteLabel,
                  hintText: l10n.availabilityNoteHint,
                  enabled: !_isSending,
                  errorText: _fieldError(<String>{'note'}),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(BlockRequest.maxNote),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            MainButton(
              label: isSlot ? l10n.availabilityConfirmSlot : l10n.availabilityConfirmDay,
              isLoading: _isSending,
              onPressed: _submit,
            ),
            MainButton(
              label: l10n.availabilityCancel,
              style: MainButtonStyle.secondary,
              onPressed: _isSending ? null : () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// A label / value row of the options card, as drawn: label at the start,
/// value at the end in grey. The chosen mode carries a check.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.isChosen = false,
    this.hasError = false,
    this.isLoading = false,
    this.opensPicker = false,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool isChosen;
  final bool hasError;
  final bool isLoading;

  /// A chevron: the row opens a list rather than choosing itself.
  final bool opensPicker;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? shown = value;

    return Semantics(
      button: true,
      selected: isChosen,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: BoxConstraints(minHeight: AppSizes.controlMd.dh),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md.dw,
            vertical: AppSpacing.sm.dh,
          ),
          color: isChosen ? AppColors.bgBrandSubtle : null,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
                ),
              ),
              if (shown != null) ...<Widget>[
                SizedBox(width: AppSpacing.sm.dw),
                Flexible(
                  child: Text(
                    shown,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: hasError ? AppColors.textDanger : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              if (isChosen) ...<Widget>[
                SizedBox(width: AppSpacing.xs.dw),
                const AppIcon(AppIcons.check, size: AppSizes.iconMd, color: AppColors.iconBrand),
              ] else if (isLoading) ...<Widget>[
                SizedBox(width: AppSpacing.xs.dw),
                const AppSpinner(size: AppSizes.iconMd),
              ] else if (opensPicker) ...<Widget>[
                SizedBox(width: AppSpacing.xs.dw),
                const AppIcon(AppIcons.chevronRight, size: AppSizes.iconSm, color: AppColors.iconDefault),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/messaging/models/report_reason.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/atoms/app_network_image.dart';
import '../../../../core/widgets/molecules/main_button.dart';
import '../../../../core/widgets/organisms/app_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../view_model/chat_view_model.dart';

/// What a long-press on a message offers (decision 5).
enum MessageAction { copy, report }

/// What ⋯ offers (decision 6).
enum PeerAction { viewProfile, report }

Future<MessageAction?> showMessageActions(
  BuildContext context, {
  required bool canCopy,
  required bool canReport,
}) {
  final AppLocalizations l10n = context.l10n;
  return showAppBottomSheet<MessageAction>(
    context,
    builder: (BuildContext sheet) => AppSheetScaffold(
      title: l10n.chatMore,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (canCopy)
            _ActionRow(
              label: l10n.chatCopy,
              onTap: () => Navigator.of(sheet).pop(MessageAction.copy),
            ),
          if (canReport)
            _ActionRow(
              label: l10n.chatReportMessage,
              onTap: () => Navigator.of(sheet).pop(MessageAction.report),
            ),
        ],
      ),
    ),
  );
}

Future<PeerAction?> showPeerActions(
  BuildContext context, {
  required String name,
  required bool canViewProfile,
}) {
  final AppLocalizations l10n = context.l10n;
  return showAppBottomSheet<PeerAction>(
    context,
    builder: (BuildContext sheet) => AppSheetScaffold(
      title: l10n.chatMore,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (canViewProfile)
            _ActionRow(
              label: l10n.chatViewProfile,
              onTap: () => Navigator.of(sheet).pop(PeerAction.viewProfile),
            ),
          _ActionRow(
            label: l10n.chatReportUser(name),
            onTap: () => Navigator.of(sheet).pop(PeerAction.report),
          ),
        ],
      ),
    ),
  );
}

/// D16: the reason, an optional note, and Send.
Future<({ReportReason reason, String? note})?> showReportSheet(
  BuildContext context,
) {
  return showAppBottomSheet<({ReportReason reason, String? note})>(
    context,
    builder: (BuildContext sheet) => const _ReportSheet(),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.sm.dh),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final TextEditingController _note = TextEditingController();
  ReportReason? _reason;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ReportReason? reason = _reason;
    String label(ReportReason r) => switch (r) {
      ReportReason.inappropriate => l10n.reportReasonInappropriate,
      ReportReason.spam => l10n.reportReasonSpam,
      ReportReason.contactOutside => l10n.reportReasonContact,
      ReportReason.harassment => l10n.reportReasonHarassment,
      ReportReason.fake => l10n.reportReasonFake,
      ReportReason.other => l10n.reportReasonOther,
    };

    return AppSheetScaffold(
      title: l10n.reportTitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final ReportReason r in ReportReason.values)
            _ReasonRow(
              label: label(r),
              isSelected: r == reason,
              onTap: () => setState(() => _reason = r),
            ),
          SizedBox(height: AppSpacing.sm.dh),
          TextField(
            controller: _note,
            minLines: 3,
            maxLines: 3,
            maxLength: ChatViewModel.maxNoteLength,
            decoration: InputDecoration(hintText: l10n.reportNoteHint),
          ),
        ],
      ),
      actions: <Widget>[
        MainButton(
          label: l10n.reportSend,
          onPressed: reason == null
              ? null
              : () =>
                    Navigator.of(context)
                        .pop((reason: reason, note: _note.text)),
        ),
      ],
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  static const double _outer = 20;
  static const double _inner = 10;

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.sm.dh),
          child: Row(
            children: <Widget>[
              Container(
                width: _outer.dw,
                height: _outer.dw,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.borderBrand
                        : AppColors.borderDefault,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Container(
                        width: _inner.dw,
                        height: _inner.dw,
                        decoration: const BoxDecoration(
                          color: AppColors.bgBrand,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full screen, black, pinch or double-tap to zoom; ✕ or a swipe down
/// closes it.
Future<void> showPhotoViewer(BuildContext context, {required String url}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (BuildContext route, _, _) => _PhotoViewer(url: url),
      transitionsBuilder: (_, Animation<double> animation, _, Widget child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.url});

  final String url;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  final TransformationController _zoom = TransformationController();

  static const double _doubleTapScale = 2.5;
  static const double _dismissVelocity = 300;

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    _zoom.value = _zoom.value.getMaxScaleOnAxis() > 1
        ? Matrix4.identity()
        : Matrix4.diagonal3Values(_doubleTapScale, _doubleTapScale, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: _toggleZoom,
              onVerticalDragEnd: (DragEndDetails details) {
                final bool zoomed = _zoom.value.getMaxScaleOnAxis() > 1;
                if (!zoomed &&
                    (details.primaryVelocity ?? 0) > _dismissVelocity) {
                  Navigator.of(context).pop();
                }
              },
              child: InteractiveViewer(
                transformationController: _zoom,
                maxScale: 4,
                child: Center(child: _ViewerImage(url: widget.url)),
              ),
            ),
          ),
          PositionedDirectional(
            top: MediaQuery.paddingOf(context).top + AppSpacing.xs.dh,
            end: AppSpacing.xs.dw,
            child: Semantics(
              button: true,
              label: context.l10n.photoViewerClose,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: SizedBox.square(
                  dimension: AppSizes.touchTarget.dw,
                  child: const Center(
                    child: AppIcon(
                      AppIcons.close,
                      color: AppColors.iconOnBrand,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerImage extends StatelessWidget {
  const _ViewerImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return AppNetworkImage(
      url: url,
      width: MediaQuery.sizeOf(context).width,
      fit: BoxFit.contain,
      placeholderIcon: AppIcons.image,
    );
  }
}

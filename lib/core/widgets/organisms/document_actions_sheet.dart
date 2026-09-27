import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../../../l10n/app_localizations.dart';
import '../atoms/app_icon.dart';
import 'app_bottom_sheet.dart';

/// What the user chose to do with a document that already has a file.
enum DocumentAction { replace, remove }

/// Asks what to do with an attached document.
///
/// A field that already holds a file has two useful gestures and only one tap
/// to spend, so the tap opens this rather than guessing. Returns `null` when
/// the sheet is dismissed without choosing, which is the common case and not
/// an answer.
Future<DocumentAction?> showDocumentActionsSheet(
  BuildContext context, {
  required String fileName,
}) {
  return showAppBottomSheet<DocumentAction>(
    context,
    builder: (BuildContext sheetContext) =>
        _DocumentActionsSheet(fileName: fileName),
  );
}

class _DocumentActionsSheet extends StatelessWidget {
  const _DocumentActionsSheet({required this.fileName});

  /// Named at the top so it is obvious which of several fields is being
  /// acted on — they all look alike once attached.
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return AppSheetScaffold(
      title: fileName,
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppRadii.mdAll,
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _SheetAction(
              icon: AppIcons.upload,
              label: l10n.documentReplace,
              onTap: () => Navigator.of(context).pop(DocumentAction.replace),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
            _SheetAction(
              icon: AppIcons.trash,
              label: l10n.documentRemove,
              // The one destructive choice on the sheet, so it is the only one
              // that carries the danger colour.
              tone: AppColors.textDanger,
              onTap: () => Navigator.of(context).pop(DocumentAction.remove),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row of the sheet: a glyph, a label, and a full-width tap target.
class _SheetAction extends StatefulWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone = AppColors.textPrimary,
  });

  final AppIcons icon;
  final String label;
  final VoidCallback onTap;

  /// Colours both the glyph and the label, so the two never disagree about
  /// how serious the action is.
  final Color tone;

  @override
  State<_SheetAction> createState() => _SheetActionState();
}

class _SheetActionState extends State<_SheetAction> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: _isPressed ? AppColors.bgSurfacePressed : null,
          constraints: BoxConstraints(minHeight: AppSizes.touchTarget.dh),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md.dw,
            vertical: AppSpacing.sm.dh,
          ),
          child: Row(
            children: <Widget>[
              AppIcon(widget.icon, size: AppSizes.iconMd, color: widget.tone),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: widget.tone,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

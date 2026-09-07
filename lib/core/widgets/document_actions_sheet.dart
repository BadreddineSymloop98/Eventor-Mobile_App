import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/ui_helpers.dart';
import '../localization/app_localizations_x.dart';
import '../../l10n/app_localizations.dart';

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
  return showModalBottomSheet<DocumentAction>(
    context: context,
    backgroundColor: AppColors.bgSurface,
    // The design rounds every surface; a sheet is the top two corners of one.
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.only(
        topStart: Radius.circular(AppRadii.xl),
        topEnd: Radius.circular(AppRadii.xl),
      ),
    ),
    builder: (BuildContext sheetContext) =>
        _DocumentActionsSheet(fileName: fileName),
  );
}

class _DocumentActionsSheet extends StatelessWidget {
  const _DocumentActionsSheet({required this.fileName});

  /// Named at the top so it is obvious which of several fields is being
  /// acted on — they all look alike once attached.
  final String fileName;

  static const double _grabberWidth = 40;
  static const double _grabberHeight = 4;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(height: AppSpacing.sm.dh),
          Center(
            child: Container(
              width: _grabberWidth.dw,
              height: _grabberHeight.dh,
              decoration: BoxDecoration(
                color: AppColors.borderDefault,
                borderRadius: AppRadii.fullAll,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md.dh),
          Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md.dw,
            ),
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xs.dh),
          _SheetAction(
            icon: 'assets/icons/upload.svg',
            label: l10n.documentReplace,
            onTap: () => Navigator.of(context).pop(DocumentAction.replace),
          ),
          _SheetAction(
            icon: 'assets/icons/trash.svg',
            label: l10n.documentRemove,
            // The one destructive choice on the sheet, so it is the only one
            // that carries the app's red.
            tone: AppColors.statusDeclined,
            onTap: () => Navigator.of(context).pop(DocumentAction.remove),
          ),
          SizedBox(height: AppSpacing.sm.dh),
        ],
      ),
    );
  }
}

/// One row of the sheet: a glyph, a label, and a full-width tap target.
class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone = AppColors.textPrimary,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  /// Colours both the glyph and the label, so the two never disagree about
  /// how serious the action is.
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md.dw,
            vertical: AppSpacing.sm.dh,
          ),
          child: Row(
            children: <Widget>[
              SvgPicture.asset(
                icon,
                width: AppSizes.iconMd.dw,
                height: AppSizes.iconMd.dw,
                colorFilter: ColorFilter.mode(tone, BlendMode.srcIn),
              ),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(color: tone),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

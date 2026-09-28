import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_spinner.dart';

/// The four states the design draws a document field in.
enum DocumentUploadState {
  /// Nothing attached yet.
  empty,

  /// A file is on its way to the server.
  uploading,

  /// The file is attached (and, for a submitted document, received).
  uploaded,

  /// The file was refused — by validation here, or by a reviewer.
  rejected,
}

/// The app's file field — the design's `Document Upload`.
///
/// It deliberately borrows the text field's anatomy — label above the box, a
/// 52pt rounded rectangle, one line underneath — so a form that mixes typed
/// fields and documents reads as one form rather than two.
///
/// The state is worked out from what is passed in: [isUploading] wins, then
/// [errorText] (rejected), then [fileName] (uploaded), else empty.
class DocumentUploadField extends StatelessWidget {
  const DocumentUploadField({
    required this.label,
    required this.onTap,
    this.fileName,
    this.helperText,
    this.errorText,
    this.isUploading = false,
    super.key,
  });

  /// Sits above the box, always visible. Names the document, not the action.
  final String label;

  /// Opens whatever picks the file. `null` while uploading or when the field
  /// cannot be changed.
  final VoidCallback? onTap;

  /// What is currently attached, or `null` while the field is empty.
  final String? fileName;

  /// Says which paper is meant, or the accepted formats. Grey.
  final String? helperText;

  /// Why the file was refused. Turns the field to its Rejected state and
  /// replaces [helperText].
  final String? errorText;

  final bool isUploading;

  DocumentUploadState get state {
    if (isUploading) return DocumentUploadState.uploading;
    if (errorText != null) return DocumentUploadState.rejected;
    if (fileName != null) return DocumentUploadState.uploaded;
    return DocumentUploadState.empty;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DocumentUploadState current = state;
    final String? message = errorText ?? helperText;
    final String placeholder = context.l10n.documentUploadAction;
    final bool hasFile = fileName != null;

    final (Color border, double width) = switch (current) {
      DocumentUploadState.empty => (AppColors.borderDefault, 1.0),
      DocumentUploadState.uploading => (AppColors.borderBrand, 1.0),
      DocumentUploadState.uploaded => (AppColors.borderBrandSubtle, 1.0),
      DocumentUploadState.rejected => (AppColors.borderDanger, 1.5),
    };

    final Color messageColor = switch (current) {
      DocumentUploadState.uploading => AppColors.textBrand,
      DocumentUploadState.rejected => AppColors.textDanger,
      _ => AppColors.textSecondary,
    };

    final Widget trailing = switch (current) {
      DocumentUploadState.empty => const AppIcon(
          AppIcons.plus,
          size: AppSizes.iconMd,
          color: AppColors.iconBrand,
        ),
      DocumentUploadState.uploading => const AppSpinner(size: AppSizes.iconMd),
      DocumentUploadState.uploaded => const AppIcon(
          AppIcons.check,
          size: AppSizes.iconMd,
          color: AppColors.statusAccepted,
        ),
      DocumentUploadState.rejected => const AppIcon(
          AppIcons.close,
          size: AppSizes.iconMd,
          color: AppColors.iconDanger,
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.xs2.dh),
        Semantics(
          button: onTap != null,
          label: label,
          value: fileName ?? placeholder,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: AppSizes.controlLg.dh,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md.dw,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppRadii.mdAll,
                border: Border.all(color: border, width: width),
              ),
              child: Row(
                children: <Widget>[
                  AppIcon(
                    hasFile ? AppIcons.fileText : AppIcons.upload,
                    size: AppSizes.iconMd,
                    color: hasFile ? AppColors.iconBrand : AppColors.iconDefault,
                  ),
                  SizedBox(width: AppSpacing.xs.dw),
                  Expanded(
                    child: Text(
                      fileName ?? placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: hasFile
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs.dw),
                  trailing,
                ],
              ),
            ),
          ),
        ),
        if (message != null) ...<Widget>[
          SizedBox(height: AppSpacing.xs2.dh),
          Text(
            message,
            style: theme.textTheme.labelSmall?.copyWith(color: messageColor),
          ),
        ],
      ],
    );
  }
}

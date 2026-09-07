import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/ui_helpers.dart';
import '../localization/app_localizations_x.dart';

/// The app's file field, for the papers a reviewed account has to attach.
///
/// It deliberately borrows the text field's anatomy — label above the box, a
/// 52pt rounded rectangle, one line of red underneath — so a form that mixes
/// typed fields and documents reads as one form rather than two.
///
/// The box is dashed while empty and solid once something is attached. That is
/// the only structural difference from a text field: a text field is always
/// somewhere you may type, whereas an empty document field is an invitation.
class DocumentUploadField extends StatelessWidget {
  const DocumentUploadField({
    required this.label,
    required this.onTap,
    this.fileName,
    this.helperText,
    this.errorText,
    super.key,
  });

  /// Height of the box the file name sits in. Shared with the text field so
  /// the two line up when they are stacked in one form.
  static const double _fieldHeight = 52;

  static const String _uploadIcon = 'assets/icons/upload.svg';
  static const String _documentIcon = 'assets/icons/document.svg';
  static const String _addIcon = 'assets/icons/plus.svg';
  static const String _attachedIcon = 'assets/icons/check.svg';

  /// Sits above the box, always visible. Names the document, not the action.
  final String label;

  /// Opens whatever picks the file. Tapping an already-attached field replaces
  /// what is there, so there is one gesture rather than remove-then-add.
  final VoidCallback onTap;

  /// What is currently attached, or `null` while the field is empty.
  final String? fileName;

  /// Says which paper is meant. Shown only while nothing is attached — once a
  /// file is there the instruction has been followed and has nothing left to
  /// say, which is the rule the typed fields follow too.
  final String? helperText;

  /// Validation message, or `null` when the field is acceptable.
  final String? errorText;

  bool get _hasFile => fileName != null;
  bool get _hasError => errorText != null;

  /// The single line under the box, or `null` when there is nothing to say.
  ///
  /// An error is a verdict and outranks the instruction, exactly as in the
  /// text field.
  String? get _message => errorText ?? (_hasFile ? null : helperText);

  Color get _borderColor {
    if (_hasError) return AppColors.statusDeclined;
    if (_hasFile) return AppColors.borderBrandSubtle;
    return AppColors.borderDefault;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? message = _message;
    final String placeholder = context.l10n.documentUploadAction;

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
          button: true,
          label: label,
          value: fileName ?? placeholder,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: CustomPaint(
              painter: _FieldBorderPainter(
                color: _borderColor,
                // Thickens once it carries a value or an error, matching the
                // way a text field thickens when it holds the caret.
                strokeWidth: _hasFile || _hasError ? 2 : 1,
                isDashed: !_hasFile && !_hasError,
                radius: AppRadii.md,
              ),
              child: SizedBox(
                height: _fieldHeight.dh,
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md.dw,
                  ),
                  child: Row(
                    children: <Widget>[
                      SvgPicture.asset(
                        _hasFile ? _documentIcon : _uploadIcon,
                        width: AppSizes.iconMd.dw,
                        height: AppSizes.iconMd.dw,
                        colorFilter: ColorFilter.mode(
                          _hasFile
                              ? AppColors.iconBrand
                              : AppColors.iconDefault,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs.dw),
                      Expanded(
                        child: Text(
                          fileName ?? placeholder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _hasFile
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs.dw),
                      SvgPicture.asset(
                        _hasFile ? _attachedIcon : _addIcon,
                        width: AppSizes.iconMd.dw,
                        height: AppSizes.iconMd.dw,
                        colorFilter: ColorFilter.mode(
                          _hasFile
                              ? AppColors.statusAccepted
                              : AppColors.iconBrand,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (message != null) ...<Widget>[
          SizedBox(height: AppSpacing.xs2.dh),
          Text(
            message,
            // Red whether it is an error or an instruction — the same call the
            // text fields make: the instruction states the rule the field has
            // to meet, so it is the same sentence the error will be.
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.statusDeclined,
            ),
          ),
        ],
      ],
    );
  }
}

/// Draws the box's outline, dashed or solid.
///
/// Flutter's [Border] cannot dash, and a dashed rectangle is how the design
/// says "there is nothing here yet" — so the outline is painted rather than
/// decorated.
class _FieldBorderPainter extends CustomPainter {
  const _FieldBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.isDashed,
    required this.radius,
  });

  /// Length of one dash, and of the gap after it, in logical pixels.
  static const double _dashLength = 5;
  static const double _gapLength = 4;

  final Color color;
  final double strokeWidth;
  final bool isDashed;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Inset by half the stroke so the outline sits inside the box rather than
    // straddling its edge, which would clip against the field below.
    final double inset = strokeWidth / 2;
    final RRect box = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    if (!isDashed) {
      canvas.drawRRect(box, paint);
      return;
    }

    final Path outline = Path()..addRRect(box);
    for (final PathMetric metric in outline.computeMetrics()) {
      double start = 0;
      while (start < metric.length) {
        final double end = start + _dashLength;
        canvas.drawPath(
          metric.extractPath(start, end.clamp(0, metric.length)),
          paint,
        );
        start = end + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_FieldBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.isDashed != isDashed ||
      oldDelegate.radius != radius;
}

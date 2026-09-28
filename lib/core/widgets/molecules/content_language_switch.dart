import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../provider_catalog/models/content_language.dart';
import '../atoms/app_chip.dart';

/// P7's and P11's `English | عربي` control: which language's copy the form
/// below is showing, and a caption saying what that language still lacks.
///
/// Two chips, as the design draws it, not a Material segmented button. The
/// labels are each language's own name and are never translated — pass the
/// same two strings in both app languages. In an Arabic app the row mirrors
/// by itself, so English ends up on the right.
class ContentLanguageSwitch extends StatelessWidget {
  const ContentLanguageSwitch({
    required this.value,
    required this.onChanged,
    required this.englishLabel,
    required this.arabicLabel,
    this.caption,
    super.key,
  });

  final ContentLanguage value;

  /// `null` locks the control — while the form is saving.
  final ValueChanged<ContentLanguage>? onChanged;
  final String englishLabel;
  final String arabicLabel;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final String? line = caption;
    final ValueChanged<ContentLanguage>? change = onChanged;

    Widget chip(ContentLanguage language, String label) => AppChip(
          label: label,
          isSelected: value == language,
          onTap: change == null ? null : () => change(language),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          container: true,
          child: Row(
            children: <Widget>[
              chip(ContentLanguage.english, englishLabel),
              SizedBox(width: AppSpacing.xs.dw),
              chip(ContentLanguage.arabic, arabicLabel),
            ],
          ),
        ),
        if (line != null) ...<Widget>[
          SizedBox(height: AppSpacing.xs2.dh),
          Text(
            line,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}

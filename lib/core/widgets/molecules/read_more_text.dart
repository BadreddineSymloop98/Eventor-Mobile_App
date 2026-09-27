import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';

/// A long description cut to a few lines, with "Read more" when — and only
/// when — there is more to read.
class ReadMoreText extends StatefulWidget {
  const ReadMoreText(this.text, {this.trimLines = 4, this.style, super.key});

  final String text;
  final int trimLines;

  /// Defaults to `Body/M` in the primary text colour.
  final TextStyle? style;

  @override
  State<ReadMoreText> createState() => _ReadMoreTextState();
}

class _ReadMoreTextState extends State<ReadMoreText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? style = widget.style ??
        textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.trimLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final bool overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.text,
              style: style,
              maxLines: _isExpanded ? null : widget.trimLines,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
            if (overflows)
              Semantics(
                button: true,
                child: GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.dh),
                    child: Text(
                      _isExpanded ? context.l10n.readLess : context.l10n.readMore,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.textBrand,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

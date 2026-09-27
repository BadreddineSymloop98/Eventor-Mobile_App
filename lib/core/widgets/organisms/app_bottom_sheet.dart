import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';

/// Shows [builder] as a bottom sheet with the design's sheet treatment.
///
/// The standing rule for every sheet in the app (`P3 Decline sheet`):
/// a neutral scrim at 50%, 24pt top corners, `elevation/lg`, a 36×4 grabber.
/// The scrim and the corners come from the theme's `bottomSheetTheme`; this
/// adds the parts a theme cannot — keyboard avoidance and a height cap — so
/// no screen calls `showModalBottomSheet` directly and drifts from the rule.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    // Lets the sheet grow past half the screen (a long list) and lift above
    // the keyboard (a search field inside it).
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    useSafeArea: true,
    // [AppSheetScaffold] paints the surface, the corners and the shadow
    // itself — a Material sheet behind it would clip the shadow away.
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (BuildContext sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: builder(sheetContext),
    ),
  );
}

/// The inside of a bottom sheet, laid out as the design draws it: grabber,
/// heading, optional supporting line, the body, and the actions pinned under
/// it.
///
/// 12/16/24/16 padding and a 16pt gap between the blocks — the sheet anatomy
/// shared by `P3`, `B5` and `S3`.
class AppSheetScaffold extends StatelessWidget {
  const AppSheetScaffold({
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const <Widget>[],
    this.expandBody = false,
    super.key,
  });

  static const double _grabberWidth = 36;
  static const double _grabberHeight = 4;

  final String title;
  final String? subtitle;
  final Widget body;

  /// Buttons stacked under the body, full width, 8pt apart.
  final List<Widget> actions;

  /// Whether [body] should take the space left over — for a scrolling list
  /// that should fill the sheet rather than hug its first few rows.
  final bool expandBody;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? line = subtitle;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
        boxShadow: AppElevation.lg,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md.dw,
            AppSpacing.sm.dh,
            AppSpacing.md.dw,
            AppSpacing.xl.dh,
          ),
          child: Column(
            mainAxisSize: expandBody ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: _grabberWidth.dw,
                  height: _grabberHeight,
                  decoration: BoxDecoration(
                    color: AppColors.bgDisabled,
                    borderRadius: BorderRadius.circular(_grabberHeight / 2),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md.dh),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (line != null) ...<Widget>[
                SizedBox(height: AppSpacing.xs.dh),
                Text(
                  line,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.md.dh),
              // Flexible either way, so a long body (a list) is given the
              // height that is left rather than an unbounded one it cannot
              // lay out in.
              if (expandBody) Expanded(child: body) else Flexible(child: body),
              for (int i = 0; i < actions.length; i++) ...<Widget>[
                SizedBox(height: (i == 0 ? AppSpacing.md : AppSpacing.xs).dh),
                actions[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

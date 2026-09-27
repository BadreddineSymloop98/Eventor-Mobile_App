import 'package:flutter/widgets.dart';

import '../../constants/ui_helpers.dart';

/// Centres its child and stops it from growing past [AppSizes.maxContentWidth].
///
/// The design is drawn for phones, where this does nothing at all. It earns
/// its place on a tablet, which is not a designed case but is a reachable one:
/// without it a login form would stretch the full width of the screen and read
/// as broken rather than as unstyled.
///
/// Wrap the content column of a screen, not individual controls.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    required this.child,
    this.maxWidth = AppSizes.maxContentWidth,
    super.key,
  });

  final Widget child;

  /// Deliberately a fixed number of logical pixels rather than a share of the
  /// window, unlike everything else in the app.
  ///
  /// It exists to *stop* the content growing with the screen, so expressing it
  /// as a percentage of that screen would cancel out the only thing it does.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

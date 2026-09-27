import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';

/// Opens [builder] as a drawer from the trailing edge — 11a Filters.
///
/// 320 wide and full height, rounded 24 on the corners facing the screen,
/// over the design's neutral scrim at 50%. The trailing edge is the right in
/// English and the left in Arabic. Returns what the drawer pops with.
Future<T?> showSideDrawer<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  required String barrierLabel,
}) {
  final bool rtl = Directionality.of(context) == TextDirection.rtl;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: AppColors.bgScrim.withValues(alpha: AppColors.scrimOpacity),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (BuildContext context, _, _) => Align(
      alignment: AlignmentDirectional.centerEnd,
      child: _DrawerPanel(child: Builder(builder: builder)),
    ),
    transitionBuilder: (
      BuildContext context,
      Animation<double> animation,
      _,
      Widget child,
    ) =>
        SlideTransition(
      position: Tween<Offset>(
        begin: Offset(rtl ? -1 : 1, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      ),
      child: child,
    ),
  );
}

class _DrawerPanel extends StatelessWidget {
  const _DrawerPanel({required this.child});

  final Widget child;

  static const double _width = 320;
  static const Radius _corner = Radius.circular(AppRadii.xl);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgSurface,
      elevation: 0,
      borderRadius: const BorderRadiusDirectional.horizontal(start: _corner)
          .resolve(Directionality.of(context)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: _width.dw,
        height: double.infinity,
        child: SafeArea(child: child),
      ),
    );
  }
}

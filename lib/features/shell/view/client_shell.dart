import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations_x.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/organisms/app_bottom_nav.dart';
import '../../../l10n/app_localizations.dart';
import '../shell_badges.dart';

/// The five-tab frame around a client's screens — the design's `Bottom Nav`
/// with its animated tabs.
///
/// Each tab keeps its own stack and scroll position (go_router's
/// `StatefulShellRoute`). Tapping the tab already open takes it back to its
/// first screen and, through [TabReselect], scrolls that screen to the top —
/// what every well-known app does with its tab bar.
class ClientShell extends StatefulWidget {
  const ClientShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  final TabReselect _reselect = TabReselect();

  @override
  void dispose() {
    _reselect.dispose();
    super.dispose();
  }

  void _select(int index) {
    final StatefulNavigationShell shell = widget.navigationShell;
    final bool again = index == shell.currentIndex;
    if (again) _reselect.fire(index);
    shell.goBranch(index, initialLocation: again);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final int unread = context.watch<ShellBadges>().unreadConversations;

    return ChangeNotifierProvider<TabReselect>.value(
      value: _reselect,
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: AppBottomNav(
          currentIndex: widget.navigationShell.currentIndex,
          onSelected: _select,
          destinations: <AppNavDestination>[
            AppNavDestination(
              icon: AppIcons.home,
              activeIcon: AppIcons.homeFilled,
              label: l10n.navHome,
            ),
            AppNavDestination(
              icon: AppIcons.search,
              activeIcon: AppIcons.searchFilled,
              label: l10n.navSearch,
            ),
            AppNavDestination(
              icon: AppIcons.calendar,
              activeIcon: AppIcons.calendarFilled,
              label: l10n.navBookings,
            ),
            AppNavDestination(
              icon: AppIcons.message,
              activeIcon: AppIcons.messageFilled,
              label: l10n.navMessages,
              badgeCount: unread,
            ),
            AppNavDestination(
              icon: AppIcons.user,
              activeIcon: AppIcons.userFilled,
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}

/// Says "the tab already open was tapped again". A tab's first screen
/// listens and scrolls itself back to the top.
class TabReselect extends ChangeNotifier {
  int? _branch;

  /// The tab that was tapped again last.
  int? get branch => _branch;

  void fire(int branch) {
    _branch = branch;
    notifyListeners();
  }
}

/// Scrolls [controller] to the top when the tab at [branch] is tapped again.
///
/// Wrap a tab's first screen in it. Harmless outside the shell — without a
/// [TabReselect] above it, it does nothing.
class ScrollToTopOnReselect extends StatefulWidget {
  const ScrollToTopOnReselect({
    required this.branch,
    required this.controller,
    required this.child,
    super.key,
  });

  final int branch;
  final ScrollController controller;
  final Widget child;

  @override
  State<ScrollToTopOnReselect> createState() => _ScrollToTopOnReselectState();
}

class _ScrollToTopOnReselectState extends State<ScrollToTopOnReselect> {
  TabReselect? _reselect;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TabReselect? reselect =
        Provider.of<TabReselect?>(context, listen: false);
    if (reselect == _reselect) return;
    _reselect?.removeListener(_onReselect);
    _reselect = reselect?..addListener(_onReselect);
  }

  void _onReselect() {
    if (_reselect?.branch != widget.branch) return;
    final ScrollController controller = widget.controller;
    if (!controller.hasClients) return;
    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _reselect?.removeListener(_onReselect);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

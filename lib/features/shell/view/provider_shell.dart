import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations_x.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/organisms/app_bottom_nav.dart';
import '../../../l10n/app_localizations.dart';
import '../shell_badges.dart';
import 'client_shell.dart' show TabReselect;

/// The provider's five tabs — Home · Requests · Services · Messages ·
/// Profile, as screen 21 draws them.
///
/// The same frame as [ClientShell]: each tab keeps its own stack, a re-tap
/// returns to its first screen and scrolls it to the top, and the Messages
/// badge counts unread conversations. Messages sits at the same index in both
/// shells, so its screen is shared as it is.
class ProviderShell extends StatefulWidget {
  const ProviderShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends State<ProviderShell> {
  final TabReselect _reselect = TabReselect();
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: () => context.read<ShellBadges>().refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
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
              icon: AppIcons.calendar,
              activeIcon: AppIcons.calendarFilled,
              label: l10n.navRequests,
            ),
            AppNavDestination(icon: AppIcons.briefcase, label: l10n.navServices),
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

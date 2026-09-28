import 'package:flutter/material.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/layout/content_container.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/app_top_bar.dart';

/// A tab whose screens are not built yet — Bookings, Messages.
///
/// A titled page with the G2 empty card, so the tab bar works end to end and
/// each tab can be swapped for its real screen without touching the shell.
class PlaceholderTabView extends StatelessWidget {
  const PlaceholderTabView({required this.title, required this.icon, super.key});

  final String title;
  final AppIcons icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppTopBar(title: title, showBack: false),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPaddingAll,
        child: ContentContainer(
          child: StateCard.empty(
            icon: icon,
            title: context.l10n.tabComingSoonTitle,
            body: context.l10n.tabComingSoonBody,
          ),
        ),
      ),
    );
  }
}

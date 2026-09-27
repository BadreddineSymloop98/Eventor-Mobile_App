import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';
import '../atoms/skeleton.dart';
import '../molecules/state_card.dart';
import 'app_top_bar.dart';

/// A detail screen (12, 13, 20) whose subject was removed: says so, with a
/// way back. Not an error — retrying would not bring it back.
class DetailGoneView extends StatelessWidget {
  const DetailGoneView({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppTopBar(title: '', onBack: onBack),
      body: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: StateCard.empty(
          icon: AppIcons.alertTriangle,
          title: context.l10n.detailGoneTitle,
          body: context.l10n.detailGoneBody,
          actionLabel: context.l10n.detailGoneBack,
          onAction: onBack,
        ),
      ),
    );
  }
}

/// A detail screen that failed to load: the G2 error card under a bar with
/// Back.
class DetailErrorView extends StatelessWidget {
  const DetailErrorView({required this.onRetry, required this.onBack, super.key});

  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppTopBar(title: '', onBack: onBack),
      body: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: StateCard.error(onRetry: onRetry),
      ),
    );
  }
}

/// G1's detail-header shape: the photo, then a few blocks where the head and
/// the first cards will be.
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({required this.photoHeight, super.key});

  /// Logical pixels.
  final double photoHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          Skeleton(height: photoHeight, radius: BorderRadius.zero),
          Padding(
            padding: AppSpacing.screenPaddingAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Skeleton(height: 24.dh, width: 220.dw),
                SizedBox(height: AppSpacing.xs.dh),
                Skeleton(height: 16.dh, width: 140.dw),
                SizedBox(height: AppSpacing.xl.dh),
                Skeleton(height: 72.dh),
                SizedBox(height: AppSpacing.md.dh),
                Skeleton(height: 180.dh),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

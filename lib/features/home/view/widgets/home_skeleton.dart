import 'package:flutter/material.dart';

import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/widgets/atoms/skeleton.dart';
import '../../../../core/widgets/molecules/section_header.dart';
import '../../../../l10n/app_localizations.dart';

/// `11 · State · loading`: the header stays live, each section keeps its
/// title, and its body is one grey block the height of what is coming. No
/// spinner (G1).
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    Widget section(String? title, double height) => Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md.dw,
            AppSpacing.xl.dh,
            AppSpacing.md.dw,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (title != null) ...<Widget>[
                SectionHeader(title: title),
                SizedBox(height: AppSpacing.xs.dh),
              ],
              Skeleton(height: height.dh),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        section(null, 76),
        section(l10n.homeYourBookings, 180),
        section(l10n.homeYourBudget, 108),
        section(l10n.homeReadyPacks, 210),
        section(l10n.homeServicesNearYou, 224),
      ],
    );
  }
}

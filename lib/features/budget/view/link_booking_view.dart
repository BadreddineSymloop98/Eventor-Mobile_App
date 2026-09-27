import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/bookings/bookings_repository.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/bottom_action_bar.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../core/widgets/organisms/divided_card.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/link_booking_view_model.dart';

/// 18h — picks the booking a line stands for, or none. Closes with a
/// [BookingLinkChoice]; Back leaves the line as it was.
class LinkBookingView extends StatelessWidget {
  const LinkBookingView({super.key});

  @override
  Widget build(BuildContext context) {
    final LinkBookingViewModel viewModel = context.watch<LinkBookingViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<BookingCard>? items = viewModel.items;

    final List<Widget> list;
    if (items == null && viewModel.hasError) {
      list = <Widget>[StateCard.error(onRetry: viewModel.load)];
    } else if (items == null) {
      list = <Widget>[
        for (int i = 0; i < 3; i++) ...<Widget>[
          Skeleton(height: 64.dh, radius: AppRadii.mdAll),
          SizedBox(height: AppSpacing.xs.dh),
        ],
      ];
    } else if (items.isEmpty && viewModel.orphan == null) {
      list = <Widget>[
        StateCard.empty(
          icon: AppIcons.calendar,
          title: l10n.linkBookingEmptyTitle,
          body: l10n.linkBookingEmptyBody,
        ),
      ];
    } else {
      list = <Widget>[
        DividedCard(
          children: <Widget>[
            if (viewModel.orphan case final LinkedBooking orphan)
              _ChoiceRow(
                title: orphan.providerName,
                subtitle: orphan.reference,
                isSelected: viewModel.selectedId == orphan.id,
                onTap: () => viewModel.select(orphan.id),
              ),
            for (final BookingCard booking in items)
              _BookingRow(booking: booking, viewModel: viewModel),
          ],
        ),
        if (viewModel.usedBy.isNotEmpty) ...<Widget>[
          SizedBox(height: AppSpacing.sm.dh),
          Text(
            l10n.linkBookingNote,
            style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ];
    }

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BrandTopBar(title: l10n.linkBookingTitle),
          Expanded(
            child: ListView(
              padding: EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md.dw,
                AppSpacing.md.dh,
                AppSpacing.md.dw,
                AppSpacing.xl.dh,
              ),
              children: <Widget>[
                Text(
                  l10n.linkBookingIntro,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: AppSpacing.sm.dh),
                DividedCard(
                  children: <Widget>[
                    _ChoiceRow(
                      title: l10n.expenseNotLinked,
                      subtitle: l10n.linkBookingNoneBody,
                      isSelected: viewModel.selectedId == null,
                      onTap: () => viewModel.select(null),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm.dh),
                ...list,
              ],
            ),
          ),
          BottomActionBar(
            child: MainButton(
              label: l10n.linkBookingAction,
              canBeTapped: viewModel.hasChanged,
              onPressed: () => Navigator.of(context).pop(viewModel.choice),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking, required this.viewModel});

  final BookingCard booking;
  final LinkBookingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;
    final String? usedOn = viewModel.usedBy[booking.id];
    return _ChoiceRow(
      title: booking.providerName,
      subtitle: <String>[
        booking.title.of(language),
        shortDate(booking.eventDate, language),
        booking.reference,
      ].where((String part) => part.isNotEmpty).join(' · '),
      isSelected: viewModel.selectedId == booking.id,
      usedOn: usedOn == null ? null : context.l10n.linkBookingUsedOn(usedOn),
      onTap: usedOn == null ? () => viewModel.select(booking.id) : null,
    );
  }
}

/// One radio-style row: selected shows a tick on a pale purple wash; a row
/// already used elsewhere is greyed out with where it is used.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.usedOn,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final String? usedOn;

  /// `null` for a row that cannot be picked.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool enabled = onTap != null;
    final String? note = usedOn;

    return Semantics(
      button: enabled,
      enabled: enabled,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          color: isSelected ? AppColors.bgBrandSubtle : AppColors.bgSurface,
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md.dw,
              vertical: AppSpacing.sm.dh,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs2.dh),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (isSelected) ...<Widget>[
                  SizedBox(width: AppSpacing.sm.dw),
                  const AppIcon(AppIcons.check, color: AppColors.iconBrand),
                ] else if (note != null) ...<Widget>[
                  SizedBox(width: AppSpacing.sm.dw),
                  Text(
                    note,
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

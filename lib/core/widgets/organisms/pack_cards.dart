import 'package:flutter/material.dart';

import '../../catalog/models/catalog_models.dart';
import '../../constants/ui_helpers.dart';
import '../../formatting/money_format.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_avatar.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_network_image.dart';
import '../molecules/favourite_button.dart';
import '../molecules/price_text.dart';

/// Shared pressed-state shell for the pack cards: white, hairline, radius
/// 16, a light shadow, and a darker fill while held.
class _PackShell extends StatefulWidget {
  const _PackShell({
    required this.child,
    this.onTap,
    this.width,
    this.radius = AppRadii.lgAll,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final BorderRadius radius;

  @override
  State<_PackShell> createState() => _PackShellState();
}

class _PackShellState extends State<_PackShell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? tap = widget.onTap;
    return Semantics(
      button: tap != null,
      child: GestureDetector(
        onTap: tap,
        onTapDown: tap == null ? null : (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: widget.width,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _pressed ? AppColors.bgSurfacePressed : AppColors.bgSurface,
            borderRadius: widget.radius,
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: AppElevation.sm,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A pack on Home's Ready Packs rail — 240 wide, photo, name, what is in it,
/// and the price in brand.
///
/// Spaced as Figma draws it: a 120 photo, then a text block padded 8/12 with
/// 4 between its lines, then the card's own 12 at the bottom — 20 under the
/// price in all. Corners are 12, not the list card's 16.
class PackRailCard extends StatelessWidget {
  const PackRailCard(this.pack, {this.onTap, super.key});

  final PackCard pack;
  final VoidCallback? onTap;

  static const double width = 240;
  static const double _photoHeight = 120;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;

    return _PackShell(
      onTap: onTap,
      width: width.dw,
      radius: AppRadii.mdAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppNetworkImage(
            url: pack.coverUrl,
            height: _photoHeight.dh,
            placeholderIcon: AppIcons.layers,
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.sm.dw,
              AppSpacing.xs.dh,
              AppSpacing.sm.dw,
              // The block's own 8, plus the card's 12.
              (AppSpacing.xs + AppSpacing.sm).dh,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pack.name.of(language),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
                ),
                SizedBox(height: AppSpacing.xs2.dh),
                Text(
                  pack.categoryNames.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: AppSpacing.xs2.dh),
                // Body/M Strong in brand, prefix and amount alike.
                PriceText(
                  amount: pack.price,
                  prefix: context.l10n.priceFrom,
                  amountStyle: textTheme.titleSmall?.copyWith(color: AppColors.textBrand),
                  labelStyle: textTheme.titleSmall?.copyWith(color: AppColors.textBrand),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Save 45 000 DA · 12%" — each number its own left-to-right run.
class SavingsPill extends StatelessWidget {
  const SavingsPill({required this.savings, required this.percent, super.key});

  final String savings;
  final num percent;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textAccent,
        );
    final String pct = percent == percent.roundToDouble()
        ? '${percent.round()}%'
        : '$percent%';

    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xs.dw,
        vertical: AppSpacing.xs2.dh,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PriceText(
            amount: savings,
            prefix: context.l10n.packSave,
            amountStyle: style,
            labelStyle: style,
          ),
          SizedBox(width: AppSpacing.xs2.dw),
          Text('·', style: style),
          SizedBox(width: AppSpacing.xs2.dw),
          Text(pct, textDirection: TextDirection.ltr, style: style),
        ],
      ),
    );
  }
}

/// A pack on 19 — the large card: photo with its saving and a heart, name,
/// how many services and which, then who makes it and the price.
class PackListCard extends StatelessWidget {
  const PackListCard(this.pack, {this.onTap, super.key});

  final PackCard pack;
  final VoidCallback? onTap;

  static const double _photoHeight = 150;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final bool hasSaving = amountIsPositive(pack.savings);

    return _PackShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: _photoHeight.dh,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                AppNetworkImage(
                  url: pack.coverUrl,
                  height: _photoHeight.dh,
                  placeholderIcon: AppIcons.layers,
                ),
                if (hasSaving)
                  PositionedDirectional(
                    top: AppSpacing.sm.dh,
                    start: AppSpacing.sm.dw,
                    child: SavingsPill(
                      savings: pack.savings,
                      percent: pack.savingsPercent,
                    ),
                  ),
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: FavouriteButton(
                    target: FavouriteTarget.pack(pack.id),
                    initial: pack.isFavourite,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pack.name.of(language),
                  style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                ),
                SizedBox(height: AppSpacing.xs.dh),
                Row(
                  children: <Widget>[
                    AppIcon(AppIcons.layers, size: AppSizes.iconSm, color: AppColors.iconBrand),
                    SizedBox(width: AppSpacing.xs.dw),
                    Expanded(
                      child: Text(
                        <String>[
                          context.l10n.servicesCount(pack.itemsCount),
                          ...pack.categoryNames,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.dh),
                  child: const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
                ),
                Row(
                  children: <Widget>[
                    AppAvatar(
                      name: pack.provider.businessName,
                      photoUrl: pack.provider.avatarUrl,
                      size: AppAvatarSize.small,
                    ),
                    SizedBox(width: AppSpacing.xs.dw),
                    Expanded(
                      child: Text(
                        context.l10n.packBy(pack.provider.businessName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    PriceText(
                      amount: pack.price,
                      amountStyle: textTheme.titleMedium?.copyWith(color: AppColors.textBrand),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The Ready Packs rail — runs off the trailing edge, as drawn.
class PacksRail extends StatelessWidget {
  const PacksRail({required this.packs, required this.onOpen, super.key});

  final List<PackCard> packs;
  final ValueChanged<PackCard> onOpen;

  @override
  Widget build(BuildContext context) {
    // Takes the height of its cards rather than a fixed one: the cards'
    // spacing scales with the screen but their text does not, so any fixed
    // height would clip on some phone or text size. A handful of packs, so
    // building them all at once costs nothing.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < packs.length; i++) ...<Widget>[
            if (i > 0) SizedBox(width: AppSpacing.sm.dw),
            PackRailCard(packs[i], onTap: () => onOpen(packs[i])),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/bookings/bookings_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/formatting/booking_format.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/localization/catalog_labels.dart';
import '../../../core/widgets/molecules/inline_banner.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/price_text.dart';
import '../../../core/widgets/organisms/booking_cards.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../core/widgets/organisms/divided_card.dart';
import '../../../core/widgets/organisms/sticky_action_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/booking_request_view_model.dart';
import 'pack_booking_view.dart' show PackItemRow;
import 'widgets/booking_form_sections.dart';

/// B9a Review your pack: each service at its own price, the date and place,
/// the pack price against the sum — then one request for all of it.
///
/// Shares B9's view model. A day taken meanwhile sends the client back to
/// B9, where B1b's banner explains; anything else stays here (B1a).
class PackReviewView extends StatefulWidget {
  const PackReviewView({super.key});

  @override
  State<PackReviewView> createState() => _PackReviewViewState();
}

class _PackReviewViewState extends State<PackReviewView> {
  Future<void> _send() async {
    final BookingRequestViewModel viewModel = context.read<BookingRequestViewModel>();
    final BookingDetail? created = await viewModel.send();
    if (!mounted) return;
    if (created != null) {
      Navigator.of(context).pop(created);
    } else if (viewModel.problem != null && viewModel.problem != SendProblem.failed) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final BookingRequestViewModel viewModel = context.watch<BookingRequestViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final PackDetail pack = viewModel.pack!;
    final BookingQuote? quote = viewModel.quote;
    final DateTime? date = viewModel.selectedDate;
    final int count = pack.items.length;
    final String total = quote?.total ?? pack.price;
    final String subtotal = quote?.subtotal ?? pack.sumOfItems;
    final String saving = quote?.discountTotal ?? pack.savings;
    final List<BookingLine> itemLines = <BookingLine>[
      for (final BookingLine line in quote?.lines ?? const <BookingLine>[])
        if (line.kind == BookingLineKind.packService) line,
    ];
    final String place = <String>[
      ?viewModel.commune?.nameFor(language),
      ?viewModel.wilaya?.nameFor(language),
    ].join(', ');
    final String times = timeRange(viewModel.startTime, viewModel.endTime, nextDay: l10n.bookingNextDayMark);

    Widget priceRow(String label, Widget value, {bool strong = false, bool brand = false}) =>
        Container(
          color: brand ? AppColors.bgBrandSubtle : null,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md.dw,
            vertical: AppSpacing.sm.dh,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: (strong ? textTheme.labelLarge : textTheme.bodyMedium)?.copyWith(
                    color: brand
                        ? AppColors.textBrand
                        : strong
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                  ),
                ),
              ),
              value,
            ],
          ),
        );
    PriceText money(String amount, {bool brand = false, bool strong = false}) => PriceText(
          amount: amount,
          amountStyle: (strong ? textTheme.titleMedium : textTheme.labelLarge)?.copyWith(
            color: brand ? AppColors.textBrand : AppColors.textPrimary,
          ),
          labelStyle: textTheme.labelLarge?.copyWith(
            color: brand ? AppColors.textBrand : AppColors.textPrimary,
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BrandTopBar(title: l10n.packReviewTitle),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (viewModel.problem == SendProblem.failed) ...<Widget>[
                    SendProblemBanner(viewModel: viewModel),
                    SizedBox(height: AppSpacing.md.dh),
                  ],
                  BookingSection(
                    title: pack.name.of(language),
                    child: DividedCard(
                      children: <Widget>[
                        for (final (int i, PackItem item) in pack.items.indexed)
                          PackItemRow(
                            title: item.title.of(language),
                            icon: subjectIcon(item.category),
                            caption: l10n.priceUnit(item.priceType),
                            trailing: PriceText(
                              amount: i < itemLines.length ? itemLines[i].amount : item.price,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs.dh),
                  Text(
                    l10n.packReviewOneRequest(count, pack.provider.businessName),
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: AppSpacing.lg.dh),
                  BookingSection(
                    title: l10n.packReviewDatePlace,
                    child: DividedCard(
                      children: <Widget>[
                        if (date != null)
                          KeyValueRow(label: l10n.bookingDate, value: fullDate(date, language)),
                        if (times.isNotEmpty)
                          KeyValueRow(label: l10n.bookingTime, value: times, isLtr: true),
                        if (viewModel.eventType case final EventType type)
                          KeyValueRow(label: l10n.bookingEventType, value: l10n.eventTypeLabel(type)),
                        if (viewModel.guests case final int guests)
                          KeyValueRow(label: l10n.bookingGuests, value: '$guests', isLtr: true),
                        if (place.isNotEmpty) KeyValueRow(label: l10n.bookingWhere, value: place),
                        if (viewModel.address.trim().isNotEmpty)
                          KeyValueRow(
                            label: l10n.bookingAddressLabel,
                            value: viewModel.address.trim(),
                            stacked: true,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg.dh),
                  BookingSection(
                    title: l10n.bookingPrice,
                    child: DividedCard(
                      children: <Widget>[
                        priceRow(l10n.packReviewSum(count), money(subtotal)),
                        priceRow(l10n.packReviewPackPrice, money(total, strong: true), strong: true),
                        if (amountCents(saving) > 0)
                          priceRow(
                            l10n.packReviewYouSave,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                money(saving, brand: true),
                                Text(
                                  ' · ${formatPercent(pack.savingsPercent)}%',
                                  textDirection: TextDirection.ltr,
                                  style: textTheme.labelLarge?.copyWith(color: AppColors.textBrand),
                                ),
                              ],
                            ),
                            brand: true,
                          ),
                        priceRow(
                          l10n.bookingTotalOnSite,
                          money(total, brand: true, strong: true),
                          strong: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs.dh),
                  Text(
                    l10n.bookingCashFootnote(pack.provider.businessName),
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  if (quote != null && !quote.available) ...<Widget>[
                    SizedBox(height: AppSpacing.md.dh),
                    InlineBanner(title: l10n.bookingDateRefused),
                  ],
                ],
              ),
            ),
          ),
          StickyActionBar(
            leading: BookingBarTotal(total: total, caption: l10n.bookingTotalCaption),
            actions: <Widget>[
              MainButton(
                label: viewModel.problem == SendProblem.failed
                    ? l10n.bookingTryAgain
                    : l10n.packReviewSend,
                isLoading: viewModel.isSending,
                canBeTapped: viewModel.canSend,
                onPressed: _send,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "14" for 14, "15.3" for 15.3 — the server's saving percent.
String formatPercent(num value) =>
    value == value.roundToDouble() ? '${value.round()}' : value.toStringAsFixed(1);

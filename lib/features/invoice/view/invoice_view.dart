import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/bookings/bookings_repository.dart';
import '../../../core/catalog/models/pack.dart' show EventType;
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/booking_format.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/localization/catalog_labels.dart';
import '../../../core/services/device_files.dart';
import '../../../core/widgets/atoms/app_spinner.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/inline_banner.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/meta_line.dart';
import '../../../core/widgets/molecules/price_text.dart';
import '../../../core/widgets/organisms/bottom_action_bar.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../core/widgets/organisms/detail_states.dart';
import '../../../core/widgets/organisms/divided_card.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/invoice_view_model.dart';
import 'invoice_pdf.dart';

/// B8 Invoice. Issued by Eventor on acceptance (section 9 decision 4): the
/// issuer block is Eventor's, the provider is who delivers the service, and
/// the stamp says "Paid in cash" only once the booking is completed.
class InvoiceView extends StatelessWidget {
  const InvoiceView({super.key});

  /// Draws B8 as a PDF in the language on screen.
  InvoicePdfRenderer _renderer(BuildContext context, InvoiceViewModel viewModel) {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    return () => buildInvoicePdf(
          invoice: viewModel.invoice!,
          booking: viewModel.booking!,
          isPaid: viewModel.isPaid,
          l10n: l10n,
          language: language,
        );
  }

  /// Saves the PDF onto the device, then says where — with Open, as a
  /// browser does for a finished download.
  Future<void> _download(BuildContext context, InvoiceViewModel viewModel) async {
    final SavedFile? saved = await viewModel.download(
      _renderer(context, viewModel),
      notice: DownloadNotice(
        channelName: context.l10n.downloadsChannelName,
        text: context.l10n.invoiceDownloadNoticeText,
      ),
    );
    if (!context.mounted) return;
    final AppLocalizations l10n = context.l10n;
    if (saved == null) {
      final Failure? failure = viewModel.failure;
      if (viewModel.saveDenied) {
        showAppToast(context, l10n.invoiceSaveDenied, tone: AppToastTone.error);
      } else if (failure != null) {
        showAppToast(
          context,
          failure is StorageFailure ? l10n.invoiceSaveFailed : l10n.forFailure(failure),
          tone: AppToastTone.error,
        );
      }
      return;
    }
    showAppToast(
      context,
      defaultTargetPlatform == TargetPlatform.iOS
          ? l10n.invoiceSavedToFiles
          : l10n.invoiceSavedToDownloads,
      actionLabel: saved.uri == null ? null : l10n.invoiceOpen,
      onAction: () async {
        final bool opened = await viewModel.open(saved);
        if (!opened && context.mounted) {
          showAppToast(context, l10n.invoiceNoPdfApp, tone: AppToastTone.info);
        }
      },
      // Long enough to reach Open.
      duration: const Duration(seconds: 6),
    );
  }

  /// Hands the PDF to another app — WhatsApp, email — through the system
  /// share sheet.
  Future<void> _share(BuildContext context, InvoiceViewModel viewModel) async {
    final Invoice? invoice = viewModel.invoice;
    if (invoice == null) return;
    final Uint8List? bytes = await viewModel.pdf(_renderer(context, viewModel));
    if (!context.mounted) return;
    if (bytes == null) {
      final Failure? failure = viewModel.failure;
      if (failure != null) {
        showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
      }
      return;
    }
    final String name = viewModel.fileName;
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile.fromData(bytes, mimeType: 'application/pdf', name: name)],
        fileNameOverrides: <String>[name],
        subject: context.l10n.invoiceShareSubject(invoice.number),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final InvoiceViewModel viewModel = context.watch<InvoiceViewModel>();
    final AppLocalizations l10n = context.l10n;
    final Invoice? invoice = viewModel.invoice;
    final BookingDetail? booking = viewModel.booking;

    if (invoice == null || booking == null) {
      return Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            BrandTopBar(title: l10n.invoiceTitle),
            Expanded(
              child: viewModel.isGone
                  ? DetailGoneView(onBack: () => context.pop())
                  : viewModel.hasError
                      ? DetailErrorView(onRetry: viewModel.load, onBack: () => context.pop())
                      : const Center(child: AppSpinner()),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BrandTopBar(
            title: l10n.invoiceTitle,
            actionLabel: l10n.invoiceShare,
            isActionLoading: viewModel.isSharing,
            onAction: viewModel.isDownloading ? null : () => _share(context, viewModel),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (viewModel.isVoided) ...<Widget>[
                    InlineBanner(title: l10n.invoiceVoidedTitle, message: l10n.invoiceVoidedBody),
                    SizedBox(height: AppSpacing.md.dh),
                  ],
                  _InvoiceCard(invoice: invoice, booking: booking, isPaid: viewModel.isPaid),
                  SizedBox(height: AppSpacing.xs.dh),
                  Text(
                    l10n.invoiceFootnote(booking.card.providerName),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          BottomActionBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                MainButton(
                  label: l10n.invoiceDownload,
                  isLoading: viewModel.isDownloading,
                  canBeTapped: !viewModel.isSharing,
                  onPressed: () => _download(context, viewModel),
                ),
                SizedBox(height: AppSpacing.xs.dh),
                MainButton(
                  label: l10n.invoiceBackToBooking,
                  style: MainButtonStyle.ghost,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.booking, required this.isPaid});

  final Invoice invoice;
  final BookingDetail booking;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final TextStyle? overline = textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.66,
    );
    final TextStyle? name = textTheme.labelLarge?.copyWith(color: AppColors.textPrimary);
    final TextStyle? detail = textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);
    final String provider = invoice.provider.displayName;

    Widget block(List<Widget> children) => Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md.dw,
            vertical: AppSpacing.sm.dh,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        );
    Widget ltr(String text, TextStyle? style) =>
        Text(text, textDirection: TextDirection.ltr, style: style);
    Widget money(String amount, TextStyle? style) => PriceText(
          amount: amount,
          amountStyle: style,
          labelStyle: style,
        );

    final String place = <String>[
      ?booking.locationText,
      ?booking.communeName,
      ?booking.wilaya?.nameFor(language),
    ].where((String s) => s.isNotEmpty).join(', ');
    final String providerMeta = <String>[
      ?booking.card.category?.name.of(language),
      ?booking.wilaya?.nameFor(language),
    ].join(' · ');

    return DividedCard(
      children: <Widget>[
        block(<Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l10n.invoiceOverline, style: overline),
                    ltr(invoice.number, textTheme.titleMedium?.copyWith(color: AppColors.textPrimary)),
                    Text(l10n.invoiceIssued(dayMonthYear(invoice.issuedAt.toLocal(), language)), style: detail),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.xs.dw,
                  vertical: AppSpacing.xs2.dh,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgBrandSubtle,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isPaid ? l10n.invoicePaidInCash : l10n.invoicePayOnTheDay,
                  style: textTheme.labelMedium?.copyWith(color: AppColors.textBrand),
                ),
              ),
            ],
          ),
        ]),
        block(<Widget>[
          Text(l10n.invoiceFrom, style: overline),
          Text(invoice.issuer.name, style: name),
          Text(invoice.issuer.address, style: detail),
          MetaLine(
            style: detail,
            parts: <MetaPart>[
              MetaPart('NIF ${invoice.issuer.nif}', isLtr: true),
              MetaPart('RC ${invoice.issuer.rc}', isLtr: true),
            ],
          ),
          ltr(invoice.issuer.email, detail),
        ]),
        block(<Widget>[
          Text(l10n.invoiceServiceBy, style: overline),
          Text(provider, style: name),
          if (providerMeta.isNotEmpty) Text(providerMeta, style: detail),
          if (invoice.provider.phone case final String phone) ltr(phone, detail),
        ]),
        block(<Widget>[
          Text(l10n.invoiceBilledTo, style: overline),
          Text(invoice.client.displayName, style: name),
          if (invoice.client.phone case final String phone) ltr(phone, detail),
        ]),
        block(<Widget>[
          Text(l10n.invoiceBooking, style: overline),
          ltr(invoice.bookingReference, name),
          Text(
            <String>[
              if (invoice.eventType case final EventType type) l10n.eventTypeLabel(type),
              fullDate(invoice.eventDate, language),
            ].join(' · '),
            style: detail,
          ),
          if (place.isNotEmpty || booking.guests != null)
            MetaLine(
              style: detail,
              parts: <MetaPart>[
                if (place.isNotEmpty) MetaPart(place),
                if (booking.guests case final int guests) MetaPart(l10n.bookingGuestsCount(guests)),
              ],
            ),
        ]),
        for (final BookingLine line in invoice.lines)
          block(<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(line.label, style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
                      MetaLine(
                        parts: <MetaPart>[
                          MetaPart('${line.quantity} ×', isLtr: true),
                          MetaPart.amount(line.unitAmount),
                        ],
                      ),
                    ],
                  ),
                ),
                money(line.amount, name),
              ],
            ),
          ]),
        if (amountCents(invoice.discountTotal) > 0)
          block(<Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(l10n.invoiceSubtotal, style: detail)),
                money(invoice.subtotal, name),
              ],
            ),
            SizedBox(height: AppSpacing.xs2.dh),
            Row(
              children: <Widget>[
                Expanded(child: Text(l10n.invoiceDiscount, style: detail)),
                money('-${invoice.discountTotal}', name),
              ],
            ),
          ]),
        block(<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  isPaid ? l10n.invoiceTotalPaid : l10n.invoiceTotalToPay,
                  style: textTheme.labelLarge?.copyWith(color: AppColors.textBrand),
                ),
              ),
              money(invoice.total, textTheme.headlineMedium?.copyWith(color: AppColors.textBrand)),
            ],
          ),
          SizedBox(height: AppSpacing.xs2.dh),
          Text(
            isPaid
                ? l10n.invoicePaidNote(provider, dayMonthYear(invoice.eventDate, language))
                : l10n.invoiceToPayNote(provider, dayMonthYear(invoice.eventDate, language)),
            style: detail,
          ),
        ]),
      ],
    );
  }
}

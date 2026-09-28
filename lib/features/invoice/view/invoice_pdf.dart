import 'package:flutter/services.dart' show Uint8List, rootBundle;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/widgets.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/bookings/bookings_repository.dart';
import '../../../core/catalog/models/pack.dart' show EventType;
import '../../../core/constants/ui_helpers.dart' show AppColors;
import '../../../core/formatting/booking_format.dart' show fullDate;
import '../../../core/formatting/date_format.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/localization/catalog_labels.dart';
import '../../../l10n/app_localizations.dart';

/// B8 as a document: the same blocks as the screen's invoice card — number
/// and status, From, Service by, Billed to, Booking, the lines, the total —
/// on one A4 page, in the app's language (Arabic right to left).
///
/// Drawn in the app rather than taken from `/invoice.pdf`, so what is saved
/// or shared matches what the client was looking at, on live and mock alike.
Future<Uint8List> buildInvoicePdf({
  required Invoice invoice,
  required BookingDetail booking,
  required bool isPaid,
  required AppLocalizations l10n,
  required String language,
}) async =>
    (await buildInvoiceDocument(
      invoice: invoice,
      booking: booking,
      isPaid: isPaid,
      l10n: l10n,
      language: language,
    ))
        .save();

/// The document behind [buildInvoicePdf], before it is written out — so a
/// test can count its pages after `save`.
@visibleForTesting
Future<pw.Document> buildInvoiceDocument({
  required Invoice invoice,
  required BookingDetail booking,
  required bool isPaid,
  required AppLocalizations l10n,
  required String language,
}) async {
  final _Fonts fonts = await _Fonts.load();
  final bool arabic = language == 'ar';
  final pw.Document document = pw.Document(
    title: '${l10n.invoiceTitle} ${invoice.number}',
    author: invoice.issuer.name,
    creator: 'Eventor',
    theme: pw.ThemeData.withFont(
      base: arabic ? fonts.cairo : fonts.figtree,
      bold: arabic ? fonts.cairoBold : fonts.figtreeBold,
      // A client's or provider's name can be in the other script.
      fontFallback: <pw.Font>[if (arabic) fonts.figtree else fonts.cairo],
    ),
  );
  final _InvoicePage page = _InvoicePage(
    invoice: invoice,
    booking: booking,
    isPaid: isPaid,
    l10n: l10n,
    language: language,
    wordmark: fonts.figtreeBold,
  );
  final pw.TextDirection direction = arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  document.addPage(
    page.fitsOnePage
        // The usual invoice: B8's card fills the page, the total at its foot.
        ? pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            textDirection: direction,
            build: (pw.Context context) => page.onePage(),
          )
        // Too many lines for one page: the same blocks flow on, numbered,
        // rather than being cut off.
        : pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            textDirection: direction,
            header: page.header,
            footer: page.footer,
            build: (pw.Context context) => page.flow(),
          ),
  );
  return document;
}

/// Static cuts of the app's two typefaces (see pubspec: a PDF cannot pick a
/// weight from the variable files). Loaded once per run.
class _Fonts {
  const _Fonts(this.figtree, this.figtreeBold, this.cairo, this.cairoBold);

  final pw.Font figtree;
  final pw.Font figtreeBold;
  final pw.Font cairo;
  final pw.Font cairoBold;

  static _Fonts? _loaded;

  static Future<_Fonts> load() async {
    final _Fonts? cached = _loaded;
    if (cached != null) return cached;
    Future<pw.Font> font(String name) async =>
        pw.Font.ttf(await rootBundle.load('assets/fonts/pdf/$name.ttf'));
    final List<pw.Font> all = await Future.wait(<Future<pw.Font>>[
      font('Figtree-Regular'),
      font('Figtree-SemiBold'),
      font('Cairo-Regular'),
      font('Cairo-SemiBold'),
    ]);
    return _loaded = _Fonts(all[0], all[1], all[2], all[3]);
  }
}

PdfColor _pdf(Color color) => PdfColor.fromInt(color.toARGB32());

class _InvoicePage {
  _InvoicePage({
    required this.invoice,
    required this.booking,
    required this.isPaid,
    required this.l10n,
    required this.language,
    required this.wordmark,
  });

  final Invoice invoice;
  final BookingDetail booking;
  final bool isPaid;
  final AppLocalizations l10n;
  final String language;
  final pw.Font wordmark;

  // The screen's type ramp, scaled for paper.
  static final PdfColor _primary = _pdf(AppColors.textPrimary);
  static final PdfColor _secondary = _pdf(AppColors.textSecondary);
  static final PdfColor _brand = _pdf(AppColors.textBrand);
  static final PdfColor _brandSubtle = _pdf(AppColors.bgBrandSubtle);
  static final PdfColor _brandBand = _pdf(AppColors.bgBrand);
  static final PdfColor _onBrand = _pdf(AppColors.textOnBrand);
  static final PdfColor _onBrandAccent = _pdf(AppColors.textOnBrandAccent);
  static final PdfColor _border = _pdf(AppColors.borderDefault);

  late final pw.TextStyle _overline = pw.TextStyle(
    fontSize: 8.5,
    fontWeight: pw.FontWeight.bold,
    letterSpacing: 0.8,
    color: _secondary,
  );
  late final pw.TextStyle _name = pw.TextStyle(
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
    color: _primary,
  );
  late final pw.TextStyle _detail = pw.TextStyle(fontSize: 10, color: _secondary, lineSpacing: 2);
  late final pw.TextStyle _body = pw.TextStyle(fontSize: 11, color: _primary);

  /// Rows below the booking block: a line each, and the subtotal/discount.
  int get _rows => invoice.lines.length + (_hasDiscount ? 1 : 0);

  bool get _hasDiscount => amountCents(invoice.discountTotal) > 0;

  /// What A4 holds with B8's blocks above and the total below — measured
  /// from the type sizes here, with room left for a wrapped label.
  bool get fitsOnePage => _rows <= 4;

  /// From three rows the blocks tighten, so four still fit.
  bool get _compact => _rows >= 3;

  static const double _side = 32;

  pw.Widget onePage() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        _band(),
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(_side, 24, _side, 28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: <pw.Widget>[
                pw.Expanded(child: _card()),
                pw.SizedBox(height: 10),
                _footnote(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The multi-page layout: the band on the first page, the blocks flowing
  /// with their dividers (a bordered card cannot break across pages), the
  /// total and the footnote at the end.
  List<pw.Widget> flow() {
    pw.Widget side(pw.Widget child) =>
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: _side), child: child);
    return <pw.Widget>[
      for (final pw.Widget block in _blocks()) ...<pw.Widget>[
        side(block),
        side(_divider()),
      ],
      side(_total()),
      pw.SizedBox(height: 10),
      side(_footnote()),
    ];
  }

  pw.Widget header(pw.Context context) => context.pageNumber == 1
      ? pw.Padding(padding: const pw.EdgeInsets.only(bottom: 16), child: _band())
      : pw.SizedBox(height: _side);

  pw.Widget footer(pw.Context context) => pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(_side, 8, _side, 20),
        child: pw.Row(
          children: <pw.Widget>[
            _ltr(invoice.number, pw.TextStyle(fontSize: 9, color: _secondary)),
            pw.Spacer(),
            _ltr('${context.pageNumber} / ${context.pagesCount}', pw.TextStyle(fontSize: 9, color: _secondary)),
          ],
        ),
      );

  pw.Widget _footnote() => pw.Text(
        l10n.invoiceFootnote(invoice.provider.displayName),
        style: pw.TextStyle(fontSize: 9, color: _secondary),
      );

  /// The screen's purple top bar: the brand, and what this is.
  pw.Widget _band() {
    return pw.Container(
      color: _brandBand,
      padding: const pw.EdgeInsets.symmetric(horizontal: _side, vertical: 22),
      child: pw.Row(
        children: <pw.Widget>[
          pw.Text(
            'Eventor',
            textDirection: pw.TextDirection.ltr,
            style: pw.TextStyle(font: wordmark, fontSize: 24, color: _onBrand),
          ),
          pw.Spacer(),
          pw.Text(
            l10n.invoiceTitle,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _onBrandAccent),
          ),
        ],
      ),
    );
  }

  /// B8's divided card, stretched to the page: the blocks from the top, the
  /// total at the foot.
  pw.Widget _card() {
    final List<pw.Widget> top = _blocks();

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          for (int i = 0; i < top.length; i++) ...<pw.Widget>[
            if (i > 0) _divider(),
            top[i],
          ],
          pw.Spacer(),
          _divider(),
          _total(),
        ],
      ),
    );
  }

  /// B8's blocks, top to bottom, down to the last line.
  List<pw.Widget> _blocks() => <pw.Widget>[
        _heading(),
        _block(<pw.Widget>[_from()]),
        _serviceBy(),
        _block(<pw.Widget>[_billedTo()]),
        _bookingBlock(),
        for (final BookingLine line in invoice.lines) _line(line),
        if (_hasDiscount) _discount(),
      ];

  pw.Widget _divider() => pw.Divider(height: 1, thickness: 1, color: _border);

  pw.Widget _block(List<pw.Widget> children) => pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: 20, vertical: _compact ? 8 : 14),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children),
      );

  pw.Widget _ltr(String text, pw.TextStyle style) =>
      pw.Text(text, textDirection: pw.TextDirection.ltr, style: style);

  pw.Widget _gap() => pw.SizedBox(height: 3);

  /// `45 000 DA` — the amount left to right, the currency after it, as
  /// `PriceText` sets it.
  pw.Widget _money(String amount, pw.TextStyle style) => pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: <pw.Widget>[
          _ltr(formatAmount(amount), style),
          pw.SizedBox(width: 3),
          pw.Text(l10n.currencyDzd, style: style),
        ],
      );

  pw.Widget _heading() => _block(<pw.Widget>[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text(l10n.invoiceOverline, style: _overline),
                  _gap(),
                  _ltr(
                    invoice.number,
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _primary),
                  ),
                  _gap(),
                  pw.Text(
                    l10n.invoiceIssued(dayMonthYear(invoice.issuedAt.toLocal(), language)),
                    style: _detail,
                  ),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _brandSubtle,
                borderRadius: pw.BorderRadius.circular(999),
              ),
              child: pw.Text(
                isPaid ? l10n.invoicePaidInCash : l10n.invoicePayOnTheDay,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _brand),
              ),
            ),
          ],
        ),
      ]);

  pw.Widget _from() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(l10n.invoiceFrom, style: _overline),
          _gap(),
          pw.Text(invoice.issuer.name, style: _name),
          _gap(),
          pw.Text(invoice.issuer.address, style: _detail),
          _ltr('NIF ${invoice.issuer.nif} · RC ${invoice.issuer.rc}', _detail),
          _ltr(invoice.issuer.email, _detail),
        ],
      );

  pw.Widget _billedTo() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(l10n.invoiceBilledTo, style: _overline),
          _gap(),
          pw.Text(invoice.client.displayName, style: _name),
          if (invoice.client.phone case final String phone) ...<pw.Widget>[
            _gap(),
            _ltr(phone, _detail),
          ],
        ],
      );

  pw.Widget _serviceBy() {
    final String meta = <String>[
      ?booking.card.category?.name.of(language),
      ?booking.wilaya?.nameFor(language),
    ].join(' · ');
    return _block(<pw.Widget>[
      pw.Text(l10n.invoiceServiceBy, style: _overline),
      _gap(),
      pw.Text(invoice.provider.displayName, style: _name),
      if (meta.isNotEmpty) ...<pw.Widget>[_gap(), pw.Text(meta, style: _detail)],
      if (invoice.provider.phone case final String phone) _ltr(phone, _detail),
    ]);
  }

  pw.Widget _bookingBlock() {
    final String place = <String>[
      ?booking.locationText,
      ?booking.communeName,
      ?booking.wilaya?.nameFor(language),
    ].where((String s) => s.isNotEmpty).join(', ');
    return _block(<pw.Widget>[
      pw.Text(l10n.invoiceBooking, style: _overline),
      _gap(),
      _ltr(invoice.bookingReference, _name),
      _gap(),
      pw.Text(
        <String>[
          if (invoice.eventType case final EventType type) l10n.eventTypeLabel(type),
          fullDate(invoice.eventDate, language),
        ].join(' · '),
        style: _detail,
      ),
      if (place.isNotEmpty || booking.guests != null)
        pw.Text(
          <String>[
            if (place.isNotEmpty) place,
            if (booking.guests case final int guests) l10n.bookingGuestsCount(guests),
          ].join(' · '),
          style: _detail,
        ),
    ]);
  }

  pw.Widget _line(BookingLine line) => _block(<pw.Widget>[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text(line.label, style: _body),
                  _gap(),
                  pw.Row(
                    children: <pw.Widget>[
                      _ltr('${line.quantity} ×', _detail),
                      pw.SizedBox(width: 4),
                      _money(line.unitAmount, _detail),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            _money(line.amount, _name),
          ],
        ),
      ]);

  pw.Widget _discount() => _block(<pw.Widget>[
        pw.Row(
          children: <pw.Widget>[
            pw.Expanded(child: pw.Text(l10n.invoiceSubtotal, style: _detail)),
            _money(invoice.subtotal, _name),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: <pw.Widget>[
            pw.Expanded(child: pw.Text(l10n.invoiceDiscount, style: _detail)),
            _money('-${invoice.discountTotal}', _name),
          ],
        ),
      ]);

  pw.Widget _total() {
    final String provider = invoice.provider.displayName;
    final String day = dayMonthYear(invoice.eventDate, language);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Row(
            children: <pw.Widget>[
              pw.Expanded(
                child: pw.Text(
                  isPaid ? l10n.invoiceTotalPaid : l10n.invoiceTotalToPay,
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _brand),
                ),
              ),
              _money(
                invoice.total,
                pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _brand),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            isPaid ? l10n.invoicePaidNote(provider, day) : l10n.invoiceToPayNote(provider, day),
            style: _detail,
          ),
        ],
      ),
    );
  }
}

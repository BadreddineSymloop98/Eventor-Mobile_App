import 'dart:convert';
import 'dart:typed_data';

import 'package:eventor/core/bookings/bookings_repository.dart';
import 'package:eventor/features/invoice/view/invoice_pdf.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../support/booking_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Draws the invoice and writes it out: the bytes, and how many pages.
  Future<({Uint8List bytes, int pages})> draw(String language, {Invoice? invoice}) async {
    final pw.Document document = await buildInvoiceDocument(
      invoice: invoice ?? Invoice.fromJson(invoiceJson()),
      booking: testBooking(),
      isPaid: false,
      l10n: lookupAppLocalizations(Locale(language)),
      language: language,
    );
    final Uint8List bytes = await document.save();
    return (bytes: bytes, pages: document.document.pdfPageList.pages.length);
  }

  Invoice withLines(int count) {
    final Map<String, Object?> json = invoiceJson();
    json['lines'] = <Map<String, Object?>>[
      for (int i = 0; i < count; i++)
        <String, Object?>{
          'kind': 'extra',
          'label': 'Extra $i',
          'quantity': 2,
          'unitAmount': '1500.00',
          'amount': '3000.00',
        },
    ];
    return Invoice.fromJson(json);
  }

  test('draws one A4 page in English', () async {
    final ({Uint8List bytes, int pages}) pdf = await draw('en');

    expect(latin1.decode(pdf.bytes.sublist(0, 5)), '%PDF-');
    expect(pdf.pages, 1);
  });

  test('draws one page in Arabic, right to left', () async {
    final ({Uint8List bytes, int pages}) pdf = await draw('ar');

    expect(latin1.decode(pdf.bytes.sublist(0, 5)), '%PDF-');
    expect(pdf.pages, 1);
  });

  test('four lines still fit the one page', () async {
    expect((await draw('en', invoice: withLines(4))).pages, 1);
    expect((await draw('ar', invoice: withLines(4))).pages, 1);
  });

  test('a long invoice flows onto more pages rather than being cut', () async {
    expect((await draw('en', invoice: withLines(12))).pages, greaterThan(1));
  });
}

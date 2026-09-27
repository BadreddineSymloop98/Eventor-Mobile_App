/// How a service is priced.
///
/// The API also sends a translated `priceTypeLabel`; the app words it itself
/// instead, so the label follows the app's language without a reload and the
/// mock backend needs no translations of its own.
enum PriceType {
  perEvent('per_event'),
  perHour('per_hour'),
  perPerson('per_person'),
  perDay('per_day'),
  onQuote('on_quote');

  const PriceType(this.apiValue);

  final String apiValue;

  /// An unknown value reads as per event — a price that still shows, rather
  /// than a row that cannot be drawn.
  static PriceType fromApi(String? value) {
    for (final PriceType type in values) {
      if (type.apiValue == value) return type;
    }
    return perEvent;
  }
}

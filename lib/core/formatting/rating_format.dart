/// A rating as the design writes it: `"4.80"` → `"4.8"`, `"5.00"` → `"5.0"`.
///
/// One decimal, always — "5" beside "4.8" in a list reads as a different
/// kind of number. Anything unreadable is handed back unchanged.
String formatRating(String apiRating) {
  final double? value = double.tryParse(apiRating);
  return value == null ? apiRating : value.toStringAsFixed(1);
}

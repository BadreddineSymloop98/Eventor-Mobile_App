/// Why a conversation is being reported — the report sheet's radio list.
enum ReportReason {
  inappropriate('inappropriate'),
  spam('spam'),
  contactOutside('contact_outside'),
  harassment('harassment'),
  fake('fake'),
  other('other');

  const ReportReason(this.apiValue);

  final String apiValue;
}

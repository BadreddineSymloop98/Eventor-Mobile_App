/// The conversation list's tab bar — which threads a query asks for.
enum ConversationFilter {
  all('all'),
  unread('unread'),
  booking('booking');

  const ConversationFilter(this.apiValue);

  final String apiValue;
}

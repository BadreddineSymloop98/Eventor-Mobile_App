import '../network/api_client.dart';
import 'models/booking_card.dart';

export 'models/booking_card.dart';

/// The client's bookings.
abstract interface class BookingsRepository {
  /// One tab of the client Bookings list. [limit] goes up to the API's 100.
  Future<ApiPage<BookingCard>> list({
    required BookingTab tab,
    int page = 1,
    int limit = 20,
  });
}

/// [BookingsRepository] against the live API.
class ApiBookingsRepository implements BookingsRepository {
  ApiBookingsRepository(this._api);

  final ApiClient _api;

  @override
  Future<ApiPage<BookingCard>> list({
    required BookingTab tab,
    int page = 1,
    int limit = 20,
  }) async {
    final ApiPage<Map<String, Object?>> result = await _api.getPage(
      '/app/bookings',
      query: <String, Object?>{
        'tab': tab.apiValue,
        'page': page,
        'limit': limit,
      },
    );
    return result.map(BookingCard.fromJson);
  }
}

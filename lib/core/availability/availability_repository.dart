import '../network/api_client.dart';
import 'models/provider_availability.dart';

export 'models/provider_availability.dart';

/// The provider's own calendar (P15–P15c): a month at a time, the blocks
/// they add, and their removal. Bookings and requests show on it but are
/// changed from the booking, never from here.
abstract interface class AvailabilityRepository {
  /// Every day of the month containing [month], with what is on it.
  Future<AvailabilityMonth> month(DateTime month);

  /// Adds a block and answers with it. A past date is refused
  /// (`AVAILABILITY_DATE_PAST`), so is a service that is not the
  /// provider's (`AVAILABILITY_SERVICE_INVALID`).
  Future<ProviderDayItem> block(BlockRequest request);

  /// Removes a block the provider added. A booking's row answers
  /// `AVAILABILITY_BLOCK_NOT_REMOVABLE`; one already gone,
  /// `AVAILABILITY_BLOCK_NOT_FOUND`.
  Future<void> unblock(String id);
}

/// [AvailabilityRepository] against the live API.
class ApiAvailabilityRepository implements AvailabilityRepository {
  ApiAvailabilityRepository(this._api);

  final ApiClient _api;

  @override
  Future<AvailabilityMonth> month(DateTime month) async {
    final Object? data = await _api.get(
      '/app/provider/availability',
      query: <String, Object?>{'month': apiMonth(month)},
    );
    return AvailabilityMonth.fromJson(
      data is Map<String, Object?> ? data : const <String, Object?>{},
    );
  }

  @override
  Future<ProviderDayItem> block(BlockRequest request) async {
    final Object? data = await _api.post(
      '/app/provider/availability/blocks',
      body: request.toJson(),
    );
    return ProviderDayItem.fromJson(
      data is Map<String, Object?> ? data : const <String, Object?>{},
    );
  }

  @override
  Future<void> unblock(String id) =>
      _api.delete('/app/provider/availability/blocks/$id');
}

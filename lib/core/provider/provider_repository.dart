import '../network/api_client.dart';
import 'models/provider_home.dart';

export 'models/provider_home.dart';

/// The provider's own side of the app: their home, their availability, and
/// their answers to requests.
abstract interface class ProviderRepository {
  /// 21 / 21a / 21b in one call.
  Future<ProviderHome> home();

  /// 21's "Accepting bookings" choice. Paused keeps the services visible
  /// and refuses new requests. Returns what the server now holds.
  Future<bool> setAcceptingBookings(bool accepting);

  /// Accepts a pending request — the date is re-checked on the server.
  Future<void> accept(String bookingId);

  /// Declines a pending request; the client reads [reason].
  Future<void> decline(String bookingId, {required String reason});
}

/// [ProviderRepository] against the live API.
class ApiProviderRepository implements ProviderRepository {
  ApiProviderRepository(this._api);

  final ApiClient _api;

  @override
  Future<ProviderHome> home() async {
    final Object? data = await _api.get('/app/provider/home');
    return ProviderHome.fromJson(
      data is Map<String, Object?> ? data : const <String, Object?>{},
    );
  }

  @override
  Future<bool> setAcceptingBookings(bool accepting) async {
    final Object? data = await _api.patch(
      '/app/provider/profile',
      body: <String, Object?>{'acceptingBookings': accepting},
    );
    // Answers with the whole account; the toggle lives on its provider part.
    final Object? provider = data is Map<String, Object?> ? data['provider'] : null;
    final Object? value =
        provider is Map<String, Object?> ? provider['acceptingBookings'] : null;
    return value is bool ? value : accepting;
  }

  @override
  Future<void> accept(String bookingId) =>
      _api.post('/app/provider/bookings/$bookingId/accept');

  @override
  Future<void> decline(String bookingId, {required String reason}) => _api.post(
        '/app/provider/bookings/$bookingId/decline',
        body: <String, Object?>{'reason': reason},
      );
}

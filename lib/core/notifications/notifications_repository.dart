import '../catalog/models/json_read.dart';
import '../errors/failure.dart';
import '../network/api_client.dart';
import 'models/app_notification.dart';

/// The bell — screen 15's list and the badge counts screens elsewhere poll
/// for.
abstract interface class NotificationsRepository {
  /// Newest first, 20 to a page.
  Future<ApiPage<AppNotification>> list({int page = 1});

  /// Marks [ids] read. Returns the new unread total, so the badge updates
  /// without a second request.
  Future<int> markRead(List<String> ids);

  /// Marks every notification read. Returns the new unread total.
  Future<int> markAllRead();

  /// Removes one for good. One that is already gone counts as removed.
  Future<void> delete(String id);

  /// `GET /app/me`'s two badge counts. A field the server omits reads as 0.
  Future<({int notifications, int conversations})> counts();
}

/// [NotificationsRepository] against the live API.
class ApiNotificationsRepository implements NotificationsRepository {
  ApiNotificationsRepository(this._api);

  final ApiClient _api;
  static const int _pageSize = 20;

  @override
  Future<ApiPage<AppNotification>> list({int page = 1}) async {
    final ApiPage<Map<String, Object?>> result = await _api.getPage(
      '/app/me/notifications',
      query: <String, Object?>{'page': page, 'limit': _pageSize},
    );
    return result.map(AppNotification.fromJson);
  }

  @override
  Future<int> markRead(List<String> ids) async {
    final Object? data = await _api.post(
      '/app/me/notifications/read',
      body: <String, Object?>{'ids': ids},
    );
    return _unread(data);
  }

  @override
  Future<int> markAllRead() async {
    final Object? data = await _api.post(
      '/app/me/notifications/read',
      body: <String, Object?>{'all': true},
    );
    return _unread(data);
  }

  @override
  Future<({int notifications, int conversations})> counts() async {
    final Object? data = await _api.get('/app/me');
    final Map<String, Object?> object =
        data is Map<String, Object?> ? data : const <String, Object?>{};
    return (
      notifications: readInt(object, 'unreadNotifications'),
      conversations: readInt(object, 'unreadConversations'),
    );
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _api.delete('/app/me/notifications/$id');
    } on ApiFailure catch (failure) {
      if (failure.code != ApiErrorCode.notificationNotFound) rethrow;
    }
  }

  static int _unread(Object? data) =>
      data is Map<String, Object?> ? readInt(data, 'unread') : 0;
}

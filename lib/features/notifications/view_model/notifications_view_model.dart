import 'dart:async';

import '../../../core/base/base_view_model.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/api_page.dart';
import '../../../core/notifications/models/app_notification.dart';
import '../../../core/notifications/notifications_repository.dart';
import '../../shell/shell_badges.dart';

/// One of 16's sections — Today, This week, Earlier — as the API groups it.
class NotificationSection {
  const NotificationSection(this.group, this.items);

  final NotificationGroup group;
  final List<AppNotification> items;
}

/// Screen 16. Opening it marks nothing read (D1): only a tap or "Mark all
/// read" does, and both flip the dots at once and put them back if the
/// server refuses.
class NotificationsViewModel extends BaseViewModel {
  NotificationsViewModel({
    required this._notifications,
    required this._badges,
  }) {
    load();
  }

  final NotificationsRepository _notifications;
  final ShellBadges _badges;

  final List<AppNotification> _items = <AppNotification>[];
  int _page = 0;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isOffline = false;

  bool get isFirstLoad => _isLoading && _items.isEmpty;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  /// The last reload found no connection while rows were showing.
  bool get isOffline => _isOffline;
  bool get isEmpty => !_isLoading && !hasError && _items.isEmpty;

  bool get canMarkAll =>
      _badges.unreadNotifications > 0 ||
      _items.any((AppNotification n) => !n.read);

  /// The API's order, each group once, where its first row falls.
  List<NotificationSection> get sections {
    final Map<NotificationGroup, List<AppNotification>> groups =
        <NotificationGroup, List<AppNotification>>{};
    for (final AppNotification n in _items) {
      groups.putIfAbsent(n.group, () => <AppNotification>[]).add(n);
    }
    return <NotificationSection>[
      for (final MapEntry<NotificationGroup, List<AppNotification>> entry
          in groups.entries)
        NotificationSection(entry.key, entry.value),
    ];
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final ApiPage<AppNotification>? page = await runGuarded(
      () => _notifications.list(),
    );
    if (page != null) _replace(page);
    _isLoading = false;
    notifyListeners();
    unawaited(_badges.refresh());
  }

  /// Pull to refresh. The list stays on failure; no connection shows the
  /// offline banner, anything else is returned for a toast.
  Future<Failure?> refresh() async {
    try {
      _replace(await _notifications.list());
      _isOffline = false;
      notifyListeners();
      unawaited(_badges.refresh());
      return null;
    } on NetworkFailure catch (failure) {
      _isOffline = _items.isNotEmpty;
      notifyListeners();
      return failure;
    } on Failure catch (failure) {
      return failure;
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final ApiPage<AppNotification> page = await _notifications.list(
        page: _page + 1,
      );
      _items.addAll(page.items);
      _page = page.page;
      _hasMore = page.hasMore;
    } on Failure {
      // The next scroll to the end asks again.
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<Failure?> markRead(String id) async {
    final int index = _items.indexWhere((AppNotification n) => n.id == id);
    if (index < 0 || _items[index].read) return null;
    _items[index] = _items[index].copyWith(read: true);
    notifyListeners();
    try {
      _badges.update(
        unreadNotifications: await _notifications.markRead(<String>[id]),
      );
      return null;
    } on Failure catch (failure) {
      final int again = _items.indexWhere((AppNotification n) => n.id == id);
      if (again >= 0) _items[again] = _items[again].copyWith(read: false);
      notifyListeners();
      return failure;
    }
  }

  Future<Failure?> markAllRead() async {
    final List<AppNotification> before = List<AppNotification>.of(_items);
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
    notifyListeners();
    try {
      _badges.update(unreadNotifications: await _notifications.markAllRead());
      notifyListeners();
      return null;
    } on Failure catch (failure) {
      _items
        ..clear()
        ..addAll(before);
      notifyListeners();
      return failure;
    }
  }

  void _replace(ApiPage<AppNotification> page) {
    _items
      ..clear()
      ..addAll(page.items);
    _page = page.page;
    _hasMore = page.hasMore;
  }
}

import '../../../core/base/base_view_model.dart';
import '../../../core/bookings/bookings_repository.dart';
import '../../../core/network/api_page.dart';
import '../../../core/routing/app_routes.dart';

/// 18h: the client's bookings that a line can stand for — upcoming, pending
/// and past; never cancelled or declined, which cost nothing (user decision,
/// 2026-09-27). A booking already on another line is shown but cannot be
/// picked.
class LinkBookingViewModel extends BaseViewModel {
  LinkBookingViewModel({
    required this._bookings,
    required LinkBookingArgs args,
  })  : current = args.current,
        usedBy = args.usedBy,
        _selectedId = args.current?.id {
    load();
  }

  final BookingsRepository _bookings;

  /// The line's booking when the screen opened.
  final LinkedBooking? current;
  final Map<String, String> usedBy;

  /// The API's largest page — one call per tab covers any real client.
  static const int _pageSize = 100;

  List<BookingCard>? _items;
  String? _selectedId;

  List<BookingCard>? get items => _items;
  bool get isFirstLoad => _items == null && !hasError;
  String? get selectedId => _selectedId;

  /// The line's current booking when it is no longer in any of the three
  /// lists (it was cancelled since) — still shown, so it can be kept or
  /// dropped knowingly.
  LinkedBooking? get orphan {
    final LinkedBooking? linked = current;
    final List<BookingCard>? loaded = _items;
    if (linked == null || loaded == null) return null;
    return loaded.any((BookingCard b) => b.id == linked.id) ? null : linked;
  }

  bool get hasChanged => _selectedId != current?.id;

  Future<void> load() async {
    final List<BookingCard>? loaded = await runGuarded(() async {
      final List<List<BookingCard>> tabs = await Future.wait(
        <Future<List<BookingCard>>>[
          for (final BookingTab tab in const <BookingTab>[
            BookingTab.upcoming,
            BookingTab.pending,
            BookingTab.past,
          ])
            _bookings
                .list(tab: tab, limit: _pageSize)
                .then((ApiPage<BookingCard> page) => page.items),
        ],
      );
      // Soonest first, then waiting, then what already happened.
      final Set<String> seen = <String>{};
      return <BookingCard>[
        for (final List<BookingCard> tab in tabs)
          for (final BookingCard booking in tab)
            if (seen.add(booking.id)) booking,
      ];
    });
    if (loaded != null) _items = loaded;
    notifyListeners();
  }

  bool isInUse(String bookingId) => usedBy.containsKey(bookingId);

  void select(String? bookingId) {
    if (bookingId != null && isInUse(bookingId)) return;
    _selectedId = bookingId;
    notifyListeners();
  }

  /// The choice to hand back to the line.
  BookingLinkChoice get choice {
    final String? id = _selectedId;
    if (id == null) return const BookingLinkChoice(null);
    for (final BookingCard booking in _items ?? const <BookingCard>[]) {
      if (booking.id == id) {
        return BookingLinkChoice(
          LinkedBooking(
            id: booking.id,
            reference: booking.reference,
            providerName: booking.providerName,
          ),
        );
      }
    }
    return BookingLinkChoice(current);
  }
}

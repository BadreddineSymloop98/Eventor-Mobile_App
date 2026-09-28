import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/bookings/bookings_repository.dart';
import '../core/budget/budget_repository.dart' show apiDate;
import '../core/catalog/catalog_repository.dart';
import '../core/catalog/favourites_repository.dart';
import '../core/catalog/models/catalog_models.dart';
import '../core/catalog/service_query.dart';
import '../core/errors/failure.dart';
import '../core/models/account.dart' show UserRole;
import '../core/network/api_page.dart';
import 'mock_backend.dart';
import 'mock_budget.dart';
import 'mock_catalog_data.dart';
import 'mock_communes_data.dart';
import 'mock_messaging.dart';
import 'mock_reference_data.dart';

part 'mock_bookings.dart';

/// Where a mock photo lives. `AppNetworkImage` loads `asset:` URLs from the
/// bundle instead of the network.
String _photoUrl(String file) => 'asset:assets/mock/photos/$file';

/// Cents from an amount string, for sorting and filtering — never through a
/// double.
int _cents(String amount) {
  final List<String> parts = amount.split('.');
  final int whole = int.tryParse(parts.first) ?? 0;
  final int fraction =
      parts.length > 1 ? int.tryParse(parts[1].padRight(2, '0')) ?? 0 : 0;
  return whole * 100 + fraction;
}

ApiFailure _notFound(String code, String what) => ApiFailure(
      statusCode: 404,
      code: code,
      message: '$what not found.',
    );

/// Builds API-shaped JSON from `mock_catalog_data.dart`, so the mock goes
/// through the same `fromJson` as a live response. Shared by both mock
/// repositories.
class _MockCatalog {
  _MockCatalog(this._backend, this._languageCode);

  final MockBackend _backend;
  final String Function() _languageCode;

  static final Map<String, Map<String, Object?>> _categories =
      <String, Map<String, Object?>>{
    for (final Map<String, Object?> c in mockCatalogCategories)
      c['id']! as String: c,
  };
  static final Map<String, Map<String, Object?>> _providers =
      <String, Map<String, Object?>>{
    for (final Map<String, Object?> p in mockCatalogProviders)
      p['id']! as String: p,
  };
  static final Map<String, Map<String, Object?>> _services =
      <String, Map<String, Object?>>{
    for (final Map<String, Object?> s in mockCatalogServices)
      s['id']! as String: s,
  };
  static final Map<String, Map<String, Object?>> _packs =
      <String, Map<String, Object?>>{
    for (final Map<String, Object?> p in mockCatalogPacks) p['id']! as String: p,
  };

  bool get _isArabic => _languageCode() == 'ar';

  Map<String, Object?>? _categoryRef(Object? id) {
    final Map<String, Object?>? c = _categories[id];
    if (c == null) return null;
    return <String, Object?>{
      'id': c['id'],
      'slug': c['slug'],
      'name': _isArabic && (c['nameAr'] as String).isNotEmpty
          ? c['nameAr']
          : c['nameEn'],
      'nameEn': c['nameEn'],
      'nameAr': c['nameAr'],
      'icon': c['icon'],
    };
  }

  static Map<String, Object?> _wilayaRef(int code) {
    final Wilaya wilaya = mockWilayas.firstWhere(
      (Wilaya w) => w.code == code,
      orElse: () => Wilaya(code: code, nameEn: '$code', nameAr: '$code'),
    );
    return <String, Object?>{
      'code': wilaya.code,
      'name': wilaya.nameEn,
      'nameEn': wilaya.nameEn,
      'nameAr': wilaya.nameAr,
    };
  }

  static List<int> _codes(Map<String, Object?> json, String key) =>
      (json[key]! as List<Object?>).cast<int>();

  static List<String> _files(Map<String, Object?> json) =>
      (json['photos']! as List<Object?>).cast<String>();

  static Map<String, Object?> _photo(String file) => <String, Object?>{
        'id': file,
        'thumbUrl': _photoUrl(file),
        'mediumUrl': _photoUrl(file),
        'largeUrl': _photoUrl(file),
        'width': 1200,
        'height': 800,
      };

  // ------------------------------------------------------------- ratings

  /// A provider's rating: the review-weighted mean of their services.
  static ({String avg, int count}) _providerRating(String providerId) {
    int count = 0;
    double total = 0;
    for (final Map<String, Object?> s in _services.values) {
      if (s['providerId'] != providerId) continue;
      final int n = (s['ratingCount']! as num).toInt();
      count += n;
      total += n * double.parse(s['avgRating']! as String);
    }
    return (avg: count == 0 ? '0.00' : (total / count).toStringAsFixed(2), count: count);
  }

  static List<Map<String, Object?>> _breakdown(List<int> counts) {
    final int total = counts.fold(0, (int a, int b) => a + b);
    return <Map<String, Object?>>[
      for (int i = 0; i < 5; i++)
        <String, Object?>{
          'stars': 5 - i,
          'count': counts[i],
          'percent': total == 0 ? 0 : (counts[i] * 100 / total).round(),
        },
    ];
  }

  List<Map<String, Object?>> _reviews(bool Function(Map<String, Object?>) where) {
    final DateTime now = _backend.now;
    final List<Map<String, Object?>> rows =
        mockCatalogReviews.where(where).toList()
          ..sort(
            (Map<String, Object?> a, Map<String, Object?> b) =>
                (a['daysAgo']! as num).compareTo(b['daysAgo']! as num),
          );
    return <Map<String, Object?>>[
      for (final Map<String, Object?> r in rows.take(3))
        <String, Object?>{
          'id': r['id'],
          'authorName': r['authorName'],
          'authorAvatarUrl': null,
          'rating': r['rating'],
          'comment': r['comment'],
          'redacted': false,
          'reply': r['reply'],
          'repliedAt': null,
          'createdAt': now
              .subtract(Duration(days: (r['daysAgo']! as num).toInt()))
              .toUtc()
              .toIso8601String(),
        },
    ];
  }

  // ------------------------------------------------------------ providers

  Map<String, Object?> providerSummary(String id) {
    final Map<String, Object?> p = _providers[id]!;
    final ({String avg, int count}) rating = _providerRating(id);
    return <String, Object?>{
      'id': p['id'],
      'businessName': p['businessName'],
      'category': _categoryRef(p['categoryId']),
      'avatarUrl': null,
      'verified': p['verified'],
      'avgRating': rating.avg,
      'ratingCount': rating.count,
      'completedBookingsCount': p['completedBookingsCount'],
      'yearsActive': p['yearsActive'],
      'avgReplyMinutes': null,
      'replyTime': p['replyTime'],
      'acceptingBookings': p['acceptingBookings'],
    };
  }

  Map<String, Object?> providerDetail(String id) {
    final Map<String, Object?>? p = _providers[id];
    if (p == null) throw _notFound(ApiErrorCode.providerNotFound, 'Provider');
    final List<Map<String, Object?>> own = _services.values
        .where((Map<String, Object?> s) => s['providerId'] == id)
        .toList();
    final List<int> counts = List<int>.filled(5, 0);
    for (final Map<String, Object?> s in own) {
      final List<int> c = (s['ratingCounts']! as List<Object?>).cast<int>();
      for (int i = 0; i < 5; i++) {
        counts[i] += c[i];
      }
    }
    return <String, Object?>{
      ...providerSummary(id),
      'bio': p['bioEn'],
      'bioEn': p['bioEn'],
      'bioAr': p['bioAr'],
      'languagesSpoken': p['languagesSpoken'],
      'wilayas': _codes(p, 'wilayas').map(_wilayaRef).toList(),
      // English, like a server answering in English; the view words the
      // checks it knows by their code.
      'checks': <Map<String, Object?>>[
        <String, Object?>{
          'code': 'identity',
          'title': 'Identity verified',
          'detail': 'National ID checked by Eventor',
          'passed': p['identityPassed'],
        },
        <String, Object?>{
          'code': 'registration',
          'title': 'Registered activity',
          'detail': 'Commercial register or artisan card verified',
          'passed': p['registrationPassed'],
        },
        <String, Object?>{
          'code': 'reply_time',
          'title': 'Reply time',
          'detail': 'Measured over the last 30 days',
          'passed': p['replyPassed'],
        },
      ],
      'servicesCount': own.length,
      // The live profile lists at most ten.
      'services': own.take(10).map(serviceCard).toList(),
      'packs': _packs.values
          .where((Map<String, Object?> k) => k['providerId'] == id)
          .map(packCard)
          .toList(),
      'ratingBreakdown': _breakdown(counts),
      'recentReviews':
          _reviews((Map<String, Object?> r) => r['providerId'] == id),
      'memberSince': p['memberSince'],
    };
  }

  // ------------------------------------------------------------- services

  Map<String, Object?> serviceCard(Map<String, Object?> s) {
    final List<String> photos = _files(s);
    return <String, Object?>{
      'id': s['id'],
      'title': _isArabic ? s['titleAr'] : s['titleEn'],
      'titleEn': s['titleEn'],
      'titleAr': s['titleAr'],
      'category': _categoryRef(s['categoryId']),
      'basePrice': s['basePrice'],
      'priceType': s['priceType'],
      'priceTypeLabel': '',
      'avgRating': s['avgRating'],
      'ratingCount': s['ratingCount'],
      'bookingsCount': s['bookingsCount'],
      'coverUrl': photos.isEmpty ? null : _photoUrl(photos.first),
      'wilayas': _codes(s, 'wilayas').map(_wilayaRef).toList(),
      'provider': providerSummary(s['providerId']! as String),
      'isFavourite': _isSaved('service', s['id']! as String),
    };
  }

  Map<String, Object?> serviceDetail(String id) {
    final Map<String, Object?>? s = _services[id];
    if (s == null) throw _notFound(ApiErrorCode.serviceNotFound, 'Service');
    return <String, Object?>{
      ...serviceCard(s),
      'description': s['descriptionEn'],
      'descriptionEn': s['descriptionEn'],
      'descriptionAr': s['descriptionAr'],
      'cancellationPolicy': s['cancellationEn'],
      'cancellationPolicyEn': s['cancellationEn'],
      'cancellationPolicyAr': s['cancellationAr'],
      'facts': s['facts'],
      'extras': s['extras'],
      'photos': _files(s).map(_photo).toList(),
      'maxGuests': s['maxGuests'],
      'maxEventsPerDay': s['maxEventsPerDay'],
      'ratingBreakdown':
          _breakdown((s['ratingCounts']! as List<Object?>).cast<int>()),
      'recentReviews': _reviews((Map<String, Object?> r) => r['serviceId'] == id),
      'providerPacks': _packs.values
          .where((Map<String, Object?> k) => k['providerId'] == s['providerId'])
          .map(packCard)
          .toList(),
      'updatedAt': _backend.now.toUtc().toIso8601String(),
    };
  }

  /// Screen 12's list after search, filters and sort.
  List<Map<String, Object?>> findServices(ServiceQuery query) {
    final String? text = query.q?.trim().toLowerCase();
    final Map<String, Object?> filters = query.toQuery();
    final DateTime? date = query.eventDate;
    final List<Map<String, Object?>> found = _services.values.where(
      (Map<String, Object?> s) {
        if (text != null && text.isNotEmpty) {
          final String provider =
              (_providers[s['providerId']]!['businessName']! as String)
                  .toLowerCase();
          final bool matches =
              (s['titleEn']! as String).toLowerCase().contains(text) ||
                  (s['titleAr']! as String).contains(text) ||
                  provider.contains(text);
          if (!matches) return false;
        }
        if (query.categoryIds.isNotEmpty &&
            !query.categoryIds.contains(s['categoryId'])) {
          return false;
        }
        if (query.wilayaCodes.isNotEmpty &&
            !_codes(s, 'wilayas').any(query.wilayaCodes.contains)) {
          return false;
        }
        final int price = _cents(s['basePrice']! as String);
        final Object? min = filters['priceMin'];
        final Object? max = filters['priceMax'];
        if (min is num && price < min * 100) return false;
        if (max is num && price > max * 100) return false;
        final num? rating = query.minRating;
        if (rating != null &&
            double.parse(s['avgRating']! as String) < rating) {
          return false;
        }
        if (date != null &&
            _dayState(s['id']! as String, date) != DayState.available) {
          return false;
        }
        if (query.favouritesOnly && !_isSaved('service', s['id']! as String)) {
          return false;
        }
        return true;
      },
    ).toList();

    int byOrder(Map<String, Object?> a, Map<String, Object?> b) =>
        (a['order']! as num).compareTo(b['order']! as num);
    int byPrice(Map<String, Object?> a, Map<String, Object?> b) =>
        _cents(a['basePrice']! as String)
            .compareTo(_cents(b['basePrice']! as String));
    int byRating(Map<String, Object?> a, Map<String, Object?> b) {
      final int score = double.parse(b['avgRating']! as String)
          .compareTo(double.parse(a['avgRating']! as String));
      return score != 0
          ? score
          : (b['ratingCount']! as num).compareTo(a['ratingCount']! as num);
    }

    switch (query.order) {
      case ServiceOrder.relevance:
        found.sort(byOrder);
      case ServiceOrder.priceAsc:
        found.sort((Map<String, Object?> a, Map<String, Object?> b) {
          final int price = byPrice(a, b);
          return price != 0 ? price : byOrder(a, b);
        });
      case ServiceOrder.priceDesc:
        found.sort((Map<String, Object?> a, Map<String, Object?> b) {
          final int price = byPrice(b, a);
          return price != 0 ? price : byOrder(b, a);
        });
      case ServiceOrder.rating:
        found.sort(byRating);
      case ServiceOrder.popular:
        found.sort(
          (Map<String, Object?> a, Map<String, Object?> b) =>
              (b['bookingsCount']! as num).compareTo(a['bookingsCount']! as num),
        );
      case ServiceOrder.newest:
        found.sort((Map<String, Object?> a, Map<String, Object?> b) => byOrder(b, a));
    }
    return found;
  }

  // ---------------------------------------------------------------- packs

  Map<String, Object?> packCard(Map<String, Object?> k) {
    final List<String> photos = _files(k);
    final List<String> items = (k['items']! as List<Object?>).cast<String>();
    return <String, Object?>{
      'id': k['id'],
      'name': _isArabic ? k['nameAr'] : k['nameEn'],
      'nameEn': k['nameEn'],
      'nameAr': k['nameAr'],
      'eventType': k['eventType'],
      'wilaya': _wilayaRef((k['wilayaCode']! as num).toInt()),
      'price': k['price'],
      'sumOfItems': k['sumOfItems'],
      'savings': k['savings'],
      'savingsPercent': k['savingsPercent'],
      'itemsCount': items.length,
      'categoryNames': <String>[
        for (final String id in items)
          ?(_categoryRef(_services[id]?['categoryId'])?['name'] as String?),
      ],
      'coverUrl': photos.isEmpty ? null : _photoUrl(photos.first),
      // A number since 2026-09-27, like every pack rating on the live API.
      'avgRating': double.parse(k['avgRating']! as String),
      'ratingCount': k['ratingCount'],
      'bookingsCount': k['bookingsCount'],
      'provider': providerSummary(k['providerId']! as String),
      'isFavourite': _isSaved('pack', k['id']! as String),
    };
  }

  Map<String, Object?> packDetail(String id) {
    final Map<String, Object?>? k = _packs[id];
    if (k == null) throw _notFound(ApiErrorCode.packNotFound, 'Pack');
    final List<String> items = (k['items']! as List<Object?>).cast<String>();
    return <String, Object?>{
      ...packCard(k),
      'description': k['descriptionEn'],
      'descriptionEn': k['descriptionEn'],
      'descriptionAr': k['descriptionAr'],
      'maxGuests': k['maxGuests'],
      'photos': _files(k).map(_photo).toList(),
      'items': <Map<String, Object?>>[
        for (final (int i, String serviceId) in items.indexed)
          <String, Object?>{
            'serviceId': serviceId,
            'title': _isArabic
                ? _services[serviceId]!['titleAr']
                : _services[serviceId]!['titleEn'],
            'titleEn': _services[serviceId]!['titleEn'],
            'titleAr': _services[serviceId]!['titleAr'],
            'category': _categoryRef(_services[serviceId]!['categoryId']),
            'price': _services[serviceId]!['basePrice'],
            'priceType': _services[serviceId]!['priceType'],
            'coverUrl': _files(_services[serviceId]!).isEmpty
                ? null
                : _photoUrl(_files(_services[serviceId]!).first),
            'position': i,
          },
      ],
      'wilayas': _codes(k, 'wilayas').map(_wilayaRef).toList(),
      'recentReviews': _reviews(
        (Map<String, Object?> r) => items.contains(r['serviceId']),
      ),
    };
  }

  List<Map<String, Object?>> findPacks(EventType? eventType, PackOrder order) {
    final List<Map<String, Object?>> found = _packs.values
        .where(
          (Map<String, Object?> k) =>
              eventType == null || k['eventType'] == eventType.apiValue,
        )
        .toList();
    int count(Map<String, Object?> json, String key) =>
        (json[key]! as num).toInt();
    switch (order) {
      case PackOrder.savings:
        found.sort(
          (Map<String, Object?> a, Map<String, Object?> b) =>
              (b['savingsPercent']! as num).compareTo(a['savingsPercent']! as num),
        );
      case PackOrder.priceAsc:
        found.sort(
          (Map<String, Object?> a, Map<String, Object?> b) =>
              _cents(a['price']! as String).compareTo(_cents(b['price']! as String)),
        );
      case PackOrder.priceDesc:
        found.sort(
          (Map<String, Object?> a, Map<String, Object?> b) =>
              _cents(b['price']! as String).compareTo(_cents(a['price']! as String)),
        );
      case PackOrder.rating:
        found.sort(
          (Map<String, Object?> a, Map<String, Object?> b) =>
              double.parse(b['avgRating']! as String)
                  .compareTo(double.parse(a['avgRating']! as String)),
        );
      case PackOrder.popular:
        found.sort(
          (Map<String, Object?> a, Map<String, Object?> b) =>
              count(b, 'bookingsCount').compareTo(count(a, 'bookingsCount')),
        );
    }
    return found;
  }

  // --------------------------------------------------------- availability

  static const int minNoticeDays = 1;

  DateTime get _firstBookable {
    final DateTime now = _backend.now;
    return DateTime(now.year, now.month, now.day + minNoticeDays);
  }

  static int _seed(String id) =>
      id.codeUnits.fold(17, (int a, int c) => (a * 31 + c) & 0x7fffffff);

  /// A stable, believable calendar: roughly one day in five fully booked and
  /// one in eleven blocked, the same on every run.
  DayState _dayState(String serviceId, DateTime day) {
    final DateTime date = DateTime(day.year, day.month, day.day);
    if (date.isBefore(_firstBookable)) return DayState.blocked;
    if (_MockBookings(this).heldByMe(serviceId, date)) return DayState.busy;
    final int h =
        (_seed(serviceId) + date.day * 7 + date.month * 13 + date.year) % 11;
    if (h == 0 || h == 3) return DayState.busy;
    if (h == 5) return DayState.blocked;
    return DayState.available;
  }

  /// A pack's day is free only when every item is; busy when any item is.
  DayState _packDayState(Map<String, Object?> pack, DateTime day) {
    final List<DayState> states = <DayState>[
      for (final Object? id in pack['items']! as List<Object?>)
        _dayState(id! as String, day),
    ];
    if (states.every((DayState s) => s == DayState.available)) {
      return DayState.available;
    }
    return states.contains(DayState.busy) ? DayState.busy : DayState.blocked;
  }

  Map<String, Object?> availability(
    DateTime month,
    DayState Function(DateTime day) stateOf,
  ) {
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    String day(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return <String, Object?>{
      'month': monthParam(month),
      'maxEventsPerDay': 1,
      'minNoticeDays': minNoticeDays,
      'firstBookableDate': day(_firstBookable),
      'days': <Map<String, Object?>>[
        for (int d = 1; d <= daysInMonth; d++)
          <String, Object?>{
            'date': day(DateTime(month.year, month.month, d)),
            'state': stateOf(DateTime(month.year, month.month, d)).name,
          },
      ],
    };
  }

  Map<String, Object?> serviceAvailability(String id, DateTime month) {
    if (!_services.containsKey(id)) {
      throw _notFound(ApiErrorCode.serviceNotFound, 'Service');
    }
    return availability(month, (DateTime d) => _dayState(id, d));
  }

  Map<String, Object?> packAvailability(String id, DateTime month) {
    final Map<String, Object?>? pack = _packs[id];
    if (pack == null) throw _notFound(ApiErrorCode.packNotFound, 'Pack');
    return availability(month, (DateTime d) => _packDayState(pack, d));
  }

  // ------------------------------------------------------------ favourites

  bool _isSaved(String kind, String id) {
    final MockAccount? account = _backend.sessionAccount;
    if (account == null || account.role.apiValue != 'client') return false;
    return _backend.favouriteRows().any(
          (Map<String, Object?> row) =>
              row['kind'] == kind && row['targetId'] == id,
        );
  }

  /// A saved row as `GET /app/me/favourites` returns it, or `null` when its
  /// target left no trace at all.
  Map<String, Object?>? favourite(Map<String, Object?> row) {
    final String kind = row['kind']! as String;
    final String targetId = row['targetId']! as String;
    final String createdAt = DateTime.fromMillisecondsSinceEpoch(
      (row['createdAt']! as num).toInt(),
    ).toUtc().toIso8601String();
    final Map<String, Object?> base = <String, Object?>{
      'id': row['id'],
      'kind': kind,
      'targetId': targetId,
      'createdAt': createdAt,
    };

    if (kind == 'service' && _services[targetId] != null) {
      final Map<String, Object?> s = _services[targetId]!;
      final List<String> photos = _files(s);
      return <String, Object?>{
        ...base,
        'title': _isArabic ? s['titleAr'] : s['titleEn'],
        'titleEn': s['titleEn'],
        'titleAr': s['titleAr'],
        'providerName': _providers[s['providerId']]!['businessName'],
        'category': _categoryRef(s['categoryId']),
        'fromPrice': s['basePrice'],
        'coverUrl': photos.isEmpty ? null : _photoUrl(photos.first),
        'avgRating': s['avgRating'],
        'ratingCount': s['ratingCount'],
        'available': true,
      };
    }
    if (kind == 'pack' && _packs[targetId] != null) {
      final Map<String, Object?> k = _packs[targetId]!;
      final List<String> photos = _files(k);
      return <String, Object?>{
        ...base,
        'title': _isArabic ? k['nameAr'] : k['nameEn'],
        'titleEn': k['nameEn'],
        'titleAr': k['nameAr'],
        'providerName': _providers[k['providerId']]!['businessName'],
        'category': null,
        'fromPrice': k['price'],
        'coverUrl': photos.isEmpty ? null : _photoUrl(photos.first),
        'avgRating': k['avgRating'],
        'ratingCount': k['ratingCount'],
        'available': true,
      };
    }
    for (final Map<String, Object?> gone in mockRetiredFavourites) {
      if (gone['id'] != targetId) continue;
      return <String, Object?>{
        ...base,
        'title': _isArabic ? gone['titleAr'] : gone['titleEn'],
        'titleEn': gone['titleEn'],
        'titleAr': gone['titleAr'],
        'providerName': gone['providerName'],
        'category': _categoryRef(gone['categoryId']),
        'fromPrice': gone['fromPrice'],
        'coverUrl': null,
        'avgRating': gone['avgRating'],
        'ratingCount': gone['ratingCount'],
        'available': false,
      };
    }
    return null;
  }

  bool targetExists(FavouriteTarget target) => target.kind == FavouriteKind.pack
      ? _packs.containsKey(target.id)
      : _services.containsKey(target.id);

  // ------------------------------------------------------------------ home

  Map<String, Object?> home() {
    final MockAccount account = _backend.requireSession();
    final int? wilaya = account.wilayaCode;
    final bool seeded = account.email == 'client@eventor.test';
    final DateTime now = _backend.now;
    String day(int fromToday) {
      final DateTime d = DateTime(now.year, now.month, now.day + fromToday);
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    final List<Map<String, Object?>> nearby = findServices(
      ServiceQuery(
        wilayaCodes: wilaya == null ? const <int>{} : <int>{wilaya},
        order: ServiceOrder.rating,
      ),
    );
    // The next two, as `/app/home` lists them: confirmed or waiting, still
    // ahead.
    final String today = day(0);
    final List<Map<String, Object?>> upcoming = bookings()
        .where(
          (Map<String, Object?> b) =>
              (b['status'] == 'accepted' || b['status'] == 'pending') &&
              (b['eventDate']! as String).compareTo(today) >= 0,
        )
        .toList()
      ..sort(
        (Map<String, Object?> a, Map<String, Object?> b) =>
            (a['eventDate']! as String).compareTo(b['eventDate']! as String),
      );
    // Only a client has a budget; the backend refuses anyone else.
    final Map<String, Object?>? budget =
        account.role == UserRole.client ? _backend.budget() : null;
    final Map<String, Object?>? summary = budget == null
        ? null
        : mockBudgetJson(budget, MockCatalogLookups._(this));

    return <String, Object?>{
      'fullName': account.fullName,
      'avatarUrl': null,
      'wilaya': wilaya == null ? null : _wilayaRef(wilaya),
      'unreadNotifications': seeded ? 2 : 0,
      'unreadConversations': seeded ? 3 : 0,
      'categories': categories(),
      'upcomingBookings': <Map<String, Object?>>[
        for (final Map<String, Object?> b in upcoming.take(2))
          <String, Object?>{
            'id': b['id'],
            'reference': b['reference'],
            'providerName':
                (b['counterparty']! as Map<String, Object?>)['businessName'],
            'providerAvatarUrl': null,
            'title': b['title'],
            'category': _categoryRef(_services[b['serviceId']]?['categoryId']),
            'eventDate': b['eventDate'],
            'startTime': b['startTime'],
            'status': b['status'],
            'coverUrl': null,
          },
      ],
      'budget': summary != null
          ? <String, Object?>{
              'exists': true,
              'spentTotal': summary['spentTotal'],
              'totalAmount': summary['totalAmount'],
              'spentPercent': summary['spentPercent'],
              'bookedCount': summary['bookedCount'],
              'itemsCount': summary['itemsCount'],
            }
          : <String, Object?>{
              'exists': false,
              'spentTotal': '0.00',
              'totalAmount': '0.00',
              'spentPercent': 0,
              'bookedCount': 0,
              'itemsCount': 0,
            },
      'packs': findPacks(null, PackOrder.savings).take(5).map(packCard).toList(),
      'nearbyServices': nearby.take(6).map(serviceCard).toList(),
    };
  }

  // -------------------------------------------------------------- bookings

  /// The signed-in client's bookings, rendered from the store in
  /// `mock_bookings.dart`. Empty for anyone but a client.
  List<Map<String, Object?>> bookings() => _MockBookings(this).rendered();


  List<Map<String, Object?>> categories() => <Map<String, Object?>>[
        for (final Map<String, Object?> c in mockCatalogCategories)
          if (c['listed'] == true)
            <String, Object?>{
              ..._categoryRef(c['id'])!,
              'position': c['position'],
              'servicesCount': _services.values
                  .where((Map<String, Object?> s) => s['categoryId'] == c['id'])
                  .length,
            },
      ];
}

/// One page of [items], as the API pages: from 1, 20 by default.
ApiPage<T> _page<T>(List<T> items, int page, int limit) {
  final int start = (page - 1) * limit;
  return ApiPage<T>(
    items: start >= items.length
        ? <T>[]
        : items.sublist(start, (start + limit).clamp(0, items.length)),
    page: page,
    totalPages: (items.length / limit).ceil(),
    total: items.length,
  );
}

/// [CatalogRepository] on the in-app [MockBackend] and the catalog snapshot.
///
/// Behaves like the live API — same filters, orders, paging and error codes —
/// with one kindness: search matches Arabic titles too, which live does not
/// index yet (a backend ask).
class MockCatalogRepository implements CatalogRepository {
  MockCatalogRepository(
    this._backend, {
    required String Function() languageCode,
    this._messaging,
  }) : _catalog = _MockCatalog(_backend, languageCode);

  final MockBackend _backend;
  final _MockCatalog _catalog;

  /// Where the home feed's two unread counts come from, when given — so the
  /// bell dot and the Messages badge agree with screens 14 and 16. Without
  /// it the feed keeps its fixed seeded counts.
  final MockMessagingStore? _messaging;

  @override
  Future<HomeFeed> home() async {
    await _backend.delay();
    final Map<String, Object?> json = _catalog.home();
    final MockMessagingStore? messaging = _messaging;
    if (messaging != null) {
      json['unreadNotifications'] = messaging.unreadNotifications();
      json['unreadConversations'] = messaging.unreadConversations();
    }
    return HomeFeed.fromJson(json);
  }

  @override
  Future<List<CategoryWithCount>> categories() async {
    await _backend.delay();
    return _catalog.categories().map(CategoryWithCount.fromJson).toList();
  }

  @override
  Future<ApiPage<ServiceCard>> services(
    ServiceQuery query, {
    int page = 1,
    int limit = 20,
  }) async {
    await _backend.delay();
    if (query.favouritesOnly) _backend.requireSession();
    final List<ServiceCard> found = _catalog
        .findServices(query)
        .map((Map<String, Object?> s) => ServiceCard.fromJson(_catalog.serviceCard(s)))
        .toList();
    return _page(found, page, limit);
  }

  @override
  Future<ServiceDetail> service(String id) async {
    await _backend.delay();
    return ServiceDetail.fromJson(_catalog.serviceDetail(id));
  }

  @override
  Future<Availability> serviceAvailability(String id, DateTime month) async {
    await _backend.delay();
    return Availability.fromJson(_catalog.serviceAvailability(id, month));
  }

  @override
  Future<ProviderDetail> provider(String id) async {
    await _backend.delay();
    return ProviderDetail.fromJson(_catalog.providerDetail(id));
  }

  @override
  Future<ApiPage<PackCard>> packs({
    EventType? eventType,
    PackOrder order = PackOrder.savings,
    int page = 1,
  }) async {
    await _backend.delay();
    final List<PackCard> found = _catalog
        .findPacks(eventType, order)
        .map((Map<String, Object?> k) => PackCard.fromJson(_catalog.packCard(k)))
        .toList();
    return _page(found, page, 20);
  }

  @override
  Future<PackDetail> pack(String id) async {
    await _backend.delay();
    return PackDetail.fromJson(_catalog.packDetail(id));
  }

  @override
  Future<Availability> packAvailability(String id, DateTime month) async {
    await _backend.delay();
    return Availability.fromJson(_catalog.packAvailability(id, month));
  }
}

/// [FavouritesRepository] on the in-app [MockBackend].
class MockFavouritesRepository implements FavouritesRepository {
  MockFavouritesRepository(this._backend, {String Function()? languageCode})
      : _catalog = _MockCatalog(_backend, languageCode ?? () => 'en');

  final MockBackend _backend;
  final _MockCatalog _catalog;

  @override
  Future<ApiPage<Favourite>> list({
    FavouriteKind? kind,
    String? categoryId,
    int page = 1,
  }) async {
    await _backend.delay();
    final List<Favourite> rows = <Favourite>[
      for (final Map<String, Object?> row in _backend.favouriteRows())
        if (kind == null || row['kind'] == kind.apiValue)
          if (_catalog.favourite(row) case final Map<String, Object?> json)
            Favourite.fromJson(json),
    ];
    final List<Favourite> filtered = categoryId == null
        ? rows
        : rows
            .where(
              (Favourite f) =>
                  f.kind == FavouriteKind.service && f.category?.id == categoryId,
            )
            .toList();
    return _page(filtered, page, 20);
  }

  @override
  Future<Favourite> add(FavouriteTarget target) async {
    await _backend.delay();
    _backend.favouriteRows(); // The role check comes before the lookup.
    if (!_catalog.targetExists(target)) {
      throw _notFound(
        target.kind == FavouriteKind.pack
            ? ApiErrorCode.packNotFound
            : ApiErrorCode.serviceNotFound,
        target.kind == FavouriteKind.pack ? 'Pack' : 'Service',
      );
    }
    final Map<String, Object?> row =
        await _backend.addFavourite(target.kind.apiValue, target.id);
    return Favourite.fromJson(_catalog.favourite(row)!);
  }

  @override
  Future<void> remove(FavouriteTarget target) async {
    await _backend.delay();
    await _backend.removeFavouriteByTarget(target.kind.apiValue, target.id);
  }

  @override
  Future<void> removeById(String favouriteId) async {
    await _backend.delay();
    try {
      await _backend.removeFavourite(favouriteId);
    } on ApiFailure catch (failure) {
      if (failure.code != ApiErrorCode.favouriteNotFound) rethrow;
    }
  }
}

/// What the mock budget needs from the catalog — a category's ref and one
/// of the client's bookings — without reaching into its private builder.
class MockCatalogLookups {
  MockCatalogLookups(
    MockBackend backend, {
    required String Function() languageCode,
  }) : _catalog = _MockCatalog(backend, languageCode);

  MockCatalogLookups._(this._catalog);

  final _MockCatalog _catalog;

  Map<String, Object?>? category(String? id) => _catalog._categoryRef(id);

  /// The services of the catalog provider trading as [businessName], as
  /// `AppProviderServiceRowDto`s — what a mock provider's 21 lists. Reads no
  /// favourites, so it works for a provider's session.
  List<Map<String, Object?>> providerServices(String? businessName) {
    String? providerId;
    for (final Map<String, Object?> p in _MockCatalog._providers.values) {
      if (p['businessName'] == businessName) providerId = p['id'] as String?;
    }
    if (providerId == null) return <Map<String, Object?>>[];
    return <Map<String, Object?>>[
      for (final Map<String, Object?> s in _MockCatalog._services.values)
        if (s['providerId'] == providerId)
          <String, Object?>{
            'id': s['id'],
            'title': _catalog._isArabic ? s['titleAr'] : s['titleEn'],
            'titleEn': s['titleEn'],
            'titleAr': s['titleAr'],
            'status': 'published',
            'visibleInApp': true,
            'basePrice': s['basePrice'],
            'priceType': s['priceType'],
            'avgRating': s['avgRating'],
            'ratingCount': s['ratingCount'],
            'bookingsCount': s['bookingsCount'],
            'photosCount': _MockCatalog._files(s).length,
            'coverUrl': _MockCatalog._files(s).isEmpty
                ? null
                : _photoUrl(_MockCatalog._files(s).first),
            'wilayas': <Object?>[],
          },
    ];
  }

  /// One of the signed-in client's bookings, or `null` — someone else's
  /// reads as missing, as live.
  Map<String, Object?>? booking(String id) {
    for (final Map<String, Object?> b in _catalog.bookings()) {
      if (b['id'] == id) return b;
    }
    return null;
  }
}


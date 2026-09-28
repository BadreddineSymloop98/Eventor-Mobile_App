import 'dart:async';

import 'package:eventor/core/availability/availability_repository.dart';
import 'package:eventor/core/catalog/models/json_read.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/provider/models/provider_home.dart';

/// `2026-03-14`.
String dayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// A block row as the API sends it (`AvailabilityBlockDto`, kind blocked).
Map<String, Object?> blockItemJson({
  required String id,
  required DateTime date,
  String? startTime,
  String? endTime,
  String? serviceId,
  String serviceTitle = 'Grande salle',
  String? note,
  bool removable = true,
}) =>
    <String, Object?>{
      'id': id,
      'kind': 'blocked',
      'date': dayKey(date),
      'startTime': startTime,
      'endTime': endTime,
      'service': serviceId == null
          ? null
          : <String, Object?>{'id': serviceId, 'titleEn': serviceTitle, 'titleAr': serviceTitle},
      'booking': null,
      'note': note,
      'removable': removable,
    };

/// A booking's row (`held` while pending, `booked` once accepted).
Map<String, Object?> bookingItemJson({
  required String bookingId,
  required DateTime date,
  bool accepted = true,
  String reference = 'EVT-2026-0142',
  String? startTime = '13:00',
  String? endTime = '23:00',
  String? clientName,
}) =>
    <String, Object?>{
      'id': 'slot-$bookingId',
      'kind': accepted ? 'booked' : 'held',
      'date': dayKey(date),
      'startTime': startTime,
      'endTime': endTime,
      'service': <String, Object?>{'id': 'svc-1', 'titleEn': 'Grande salle', 'titleAr': 'القاعة الكبرى'},
      'booking': <String, Object?>{
        'id': bookingId,
        'reference': reference,
        'status': accepted ? 'accepted' : 'pending',
        'clientName': ?clientName,
      },
      'note': null,
      'removable': false,
    };

/// A provider service row for the "Which services" picker.
ProviderServiceRow testServiceRow(String id, String title, {ProviderServiceStatus status = ProviderServiceStatus.published}) =>
    ProviderServiceRow(
      id: id,
      title: LocalizedText(en: title, ar: title),
      status: status,
      basePrice: '45000.00',
      coverUrl: null,
    );

/// [AvailabilityRepository] as a small in-memory server: rows per day, the
/// status worked out like the API's, blocks added and removed for real — so
/// a view model's reloads see its own writes.
class FakeAvailabilityRepository implements AvailabilityRepository {
  FakeAvailabilityRepository({List<Map<String, Object?>> items = const <Map<String, Object?>>[]})
      : _items = <Map<String, Object?>>[...items];

  final List<Map<String, Object?>> _items;

  /// `month:2026-03`, `block`, `unblock:<id>` — in order.
  final List<String> calls = <String>[];

  /// Every block asked for.
  final List<BlockRequest> blocks = <BlockRequest>[];

  /// The next call of that name (`month`, `block`, `unblock`) throws this.
  final Map<String, Failure> failNext = <String, Failure>{};

  /// Month loads wait on this while set — to see the skeleton, or to answer
  /// out of order.
  Completer<void>? monthGate;

  int maxEventsPerDay = 1;
  int _nextId = 1;

  List<Map<String, Object?>> get items => List<Map<String, Object?>>.unmodifiable(_items);

  void _maybeFail(String name) {
    final Failure? failure = failNext.remove(name);
    if (failure != null) throw failure;
  }

  @override
  Future<AvailabilityMonth> month(DateTime month) async {
    final String key = apiMonth(month);
    calls.add('month:$key');
    final int length = DateTime(month.year, month.month + 1, 0).day;
    // Read before the gate: a held answer is the month as it was asked.
    final AvailabilityMonth answer = AvailabilityMonth.fromJson(<String, Object?>{
      'providerId': 'provider-1',
      'month': key,
      'maxEventsPerDay': maxEventsPerDay,
      'days': <Map<String, Object?>>[
        for (int d = 1; d <= length; d++) _dayJson(DateTime(month.year, month.month, d)),
      ],
    });
    final Completer<void>? gate = monthGate;
    if (gate != null) await gate.future;
    _maybeFail('month');
    return answer;
  }

  Map<String, Object?> _dayJson(DateTime date) {
    final String key = dayKey(date);
    final List<Map<String, Object?>> rows =
        _items.where((Map<String, Object?> i) => i['date'] == key).toList();
    final List<ProviderDayItem> parsed = rows.map(ProviderDayItem.fromJson).toList();
    return <String, Object?>{
      'date': key,
      'status': ProviderDayStatus.of(parsed).name,
      'items': rows,
    };
  }

  @override
  Future<ProviderDayItem> block(BlockRequest request) async {
    calls.add('block');
    blocks.add(request);
    await Future<void>.value();
    _maybeFail('block');
    final Map<String, Object?> row = blockItemJson(
      id: 'block-${_nextId++}',
      date: request.date,
      startTime: request.startTime,
      endTime: request.endTime,
      serviceId: request.serviceId,
      note: request.note,
    );
    _items.add(row);
    return ProviderDayItem.fromJson(row);
  }

  @override
  Future<void> unblock(String id) async {
    calls.add('unblock:$id');
    await Future<void>.value();
    _maybeFail('unblock');
    final int index = _items.indexWhere((Map<String, Object?> i) => i['id'] == id);
    if (index < 0) {
      throw const ApiFailure(
        statusCode: 404,
        code: ApiErrorCode.availabilityBlockNotFound,
        message: 'The availability block was not found.',
      );
    }
    if (_items[index]['removable'] != true) {
      throw const ApiFailure(
        statusCode: 409,
        code: ApiErrorCode.availabilityBlockNotRemovable,
        message: 'Only manual blocks can be removed.',
      );
    }
    _items.removeAt(index);
  }

  /// The row with [id] disappears server-side — someone removed it
  /// elsewhere.
  void dropRow(String id) => _items.removeWhere((Map<String, Object?> i) => i['id'] == id);
}

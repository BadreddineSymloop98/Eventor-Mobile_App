import 'dart:async';

import '../../../core/base/base_view_model.dart';
import '../../../core/bookings/bookings_repository.dart';
import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/catalog/month_availability.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/booking_format.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/models/account.dart';
import '../../../core/reference/reference_repository.dart';
import '../../../core/session/session_controller.dart';

/// A field B1 / B9 cannot send without, in the order the form shows them —
/// the view scrolls to the first one missing.
enum BookingField { date, time, eventType, guests, wilaya }

/// Why the last send did not go through, when the form has to say so.
enum SendProblem {
  /// B1b: someone else took the date meanwhile.
  dateTaken,

  /// The date is now too soon (the notice period moved past it).
  tooSoon,

  /// The provider paused bookings while the form was open.
  notAccepting,

  /// B1a: offline, or the server refused for a reason the form cannot fix.
  failed,
}

/// B1 Request booking (a service) and B9 / B9a (a pack): one form, one
/// request. The price comes from `/bookings/quote` once a date is picked —
/// the server's own lines — and from the listed prices before that.
///
/// Nothing picked is lost on a failed send: B1a keeps the form and offers
/// Try again; B1b strikes the taken day through and asks for another.
class BookingRequestViewModel extends BaseViewModel with MonthAvailability {
  BookingRequestViewModel({
    required this._catalog,
    required this._bookings,
    required this._reference,
    required this._session,
    this.serviceId,
    this.packId,
    this._initialDate,
    this._today = DateTime.now,
    this._quoteDelay = const Duration(milliseconds: 350),
  }) : assert((serviceId == null) != (packId == null)) {
    load();
  }

  final CatalogRepository _catalog;
  final BookingsRepository _bookings;
  final ReferenceRepository _reference;
  final SessionController _session;
  final DateTime Function() _today;
  final Duration _quoteDelay;
  final DateTime? _initialDate;

  final String? serviceId;
  final String? packId;

  /// The note's cap and the address's, from the API.
  static const int maxNote = 2000;
  static const int maxAddress = 255;

  /// The guest cap when the service or pack sets none.
  static const int defaultMaxGuests = 5000;

  ServiceDetail? _service;
  PackDetail? _pack;
  bool _isLoading = false;
  bool _isGone = false;

  String? _startTime;
  String? _endTime;
  EventType? _eventType;

  /// `null` until a count is typed or stepped to.
  int? _guests;
  Wilaya? _wilaya;
  Commune? _commune;
  List<Commune>? _communes;
  bool _isLoadingCommunes = false;
  final Map<String, int> _extras = <String, int>{};
  String _address = '';
  String _note = '';

  BookingQuote? _quote;
  bool _isQuoting = false;
  Timer? _quoteTimer;
  int _quoteRequest = 0;

  Set<BookingField> _missing = <BookingField>{};
  bool _isSending = false;
  SendProblem? _problem;
  DateTime? _takenDate;
  bool _isSent = false;

  bool get isPack => packId != null;
  ServiceDetail? get service => _service;
  PackDetail? get pack => _pack;
  bool get isFirstLoad => _isLoading && _service == null && _pack == null;
  bool get isGone => _isGone;

  String? get startTime => _startTime;
  String? get endTime => _endTime;
  EventType? get eventType => _eventType;
  int? get guests => _guests;
  Wilaya? get wilaya => _wilaya;
  Commune? get commune => _commune;
  bool get isLoadingCommunes => _isLoadingCommunes;
  String get address => _address;
  String get note => _note;
  int extraCount(String extraId) => _extras[extraId] ?? 0;

  /// The communes of the chosen wilaya; empty hides the field.
  List<Commune> get communes => _communes ?? const <Commune>[];

  BookingQuote? get quote => _quote;
  bool get isQuoting => _isQuoting;
  Set<BookingField> get missing => _missing;
  bool get isSending => _isSending;
  SendProblem? get problem => _problem;

  /// The day B1b reports as just taken.
  DateTime? get takenDate => _takenDate;

  /// The provider's name, for the copy.
  String get providerName =>
      _service?.provider.businessName ?? _pack?.provider.businessName ?? '';

  ProviderSummary? get provider => _service?.provider ?? _pack?.provider;

  /// The wilayas the event can be in: those the service covers — for a
  /// pack, those every item covers.
  List<Wilaya> get wilayaOptions => _service?.wilayas ?? _pack?.wilayas ?? const <Wilaya>[];

  PriceType get priceType => _service?.priceType ?? PriceType.perEvent;

  /// Guests are asked for when they set the price, or when the service
  /// caps them; everywhere else they are still worth telling the provider.
  int? get maxGuests => _service?.maxGuests ?? _pack?.maxGuests;

  /// The most guests the field takes.
  int get guestLimit => maxGuests ?? defaultMaxGuests;

  /// More guests than the service or pack takes: shown as soon as it is
  /// typed, and Send stops on it.
  bool get guestsOverLimit => (_guests ?? 0) > guestLimit;

  bool get needsTimes => priceType == PriceType.perHour;
  bool get needsGuests => priceType == PriceType.perPerson;

  /// The picked date can be sent: the quote has not refused it.
  bool get dateRefused => _quote != null && !_quote!.available;

  bool get isDirty =>
      !_isSent &&
      (selectedDate != null ||
          _eventType != null ||
          _guests != null ||
          _extras.values.any((int n) => n > 0) ||
          _address.trim().isNotEmpty ||
          _note.trim().isNotEmpty);

  /// Whether Send can be tapped at all; what is missing is reported when it
  /// is tapped, not by greying the button out.
  bool get canSend =>
      !_isSending &&
      selectedDate != null &&
      !dateRefused &&
      _problem != SendProblem.notAccepting;

  @override
  bool get canPickDates =>
      provider?.acceptingBookings ?? false;

  @override
  DateTime today() => _today();

  @override
  Future<Availability> fetchMonth(DateTime month) => isPack
      ? _catalog.packAvailability(packId!, month)
      : _catalog.serviceAvailability(serviceId!, month);

  Future<void> load() async {
    _isLoading = true;
    _isGone = false;
    notifyListeners();
    final bool loaded = await runGuarded(() async {
          if (isPack) {
            _pack = await _catalog.pack(packId!);
          } else {
            _service = await _catalog.service(serviceId!);
          }
          return true;
        }) ??
        false;
    final Failure? failure = this.failure;
    if (!loaded &&
        failure is ApiFailure &&
        (failure.statusCode == 404 ||
            failure.code == ApiErrorCode.serviceNotFound ||
            failure.code == ApiErrorCode.packNotFound)) {
      _isGone = true;
      clearFailure();
    }
    _isLoading = false;
    if (loaded) _applyDefaults();
    notifyListeners();
    if (loaded) {
      await openOn(_initialDate);
      _scheduleQuote();
    }
  }

  void _applyDefaults() {
    final PackDetail? pack = _pack;
    if (pack != null) _eventType = pack.eventType;
    final List<Wilaya> options = wilayaOptions;
    final Wilaya? home = _session.user?.wilaya;
    Wilaya? chosen;
    for (final Wilaya w in options) {
      if (w.code == home?.code) chosen = w;
    }
    chosen ??= options.length == 1 ? options.single : null;
    if (chosen != null) unawaited(setWilaya(chosen));
  }

  // ---------------------------------------------------------------- edits

  @override
  void selectDate(DateTime day) {
    final DateTime? before = selectedDate;
    super.selectDate(day);
    if (selectedDate != before) {
      _missing = _missing.difference(<BookingField>{BookingField.date});
      if (_problem == SendProblem.dateTaken || _problem == SendProblem.tooSoon) {
        _problem = null;
      }
      _scheduleQuote();
    }
  }

  void setStartTime(String? value) {
    _startTime = value;
    // No start, no end; and an end equal to the new start would read as a
    // 24-hour event, which the To list never offers — so it goes.
    if (value == null || value == _endTime) _endTime = null;
    _missing = _missing.difference(<BookingField>{BookingField.time});
    _changed(requote: true);
  }

  void setEndTime(String? value) {
    _endTime = value;
    _missing = _missing.difference(<BookingField>{BookingField.time});
    _changed(requote: true);
  }

  void setEventType(EventType type) {
    _eventType = type;
    _missing = _missing.difference(<BookingField>{BookingField.eventType});
    _changed();
  }

  /// [value] is what the field holds: `null` when it is empty.
  void setGuests(int? value) {
    if (value == _guests) return;
    _guests = value;
    // A count that is still over the cap keeps its error.
    if (!guestsOverLimit) {
      _missing = _missing.difference(<BookingField>{BookingField.guests});
    }
    _changed(requote: needsGuests);
  }

  void setExtra(String extraId, int count) {
    _extras[extraId] = count;
    _changed(requote: true);
  }

  void setAddress(String value) {
    _address = value;
    _changed();
  }

  void setNote(String value) {
    _note = value;
    _changed();
  }

  Future<void> setWilaya(Wilaya wilaya) async {
    if (_wilaya?.code == wilaya.code) return;
    _wilaya = wilaya;
    _commune = null;
    _communes = null;
    _missing = _missing.difference(<BookingField>{BookingField.wilaya});
    _isLoadingCommunes = true;
    notifyListeners();
    try {
      final List<Commune> loaded = await _reference.communes(wilaya.code);
      // Only if the wilaya is still the chosen one.
      if (_wilaya?.code == wilaya.code) _communes = loaded;
    } catch (_) {
      // No list: the commune is optional, the address says the rest.
      _communes = const <Commune>[];
    }
    _isLoadingCommunes = false;
    notifyListeners();
  }

  void setCommune(Commune? commune) {
    _commune = commune;
    notifyListeners();
  }

  void _changed({bool requote = false}) {
    if (_problem == SendProblem.failed) _problem = null;
    notifyListeners();
    if (requote) _scheduleQuote();
  }

  // ---------------------------------------------------------------- price

  void _scheduleQuote() {
    _quoteTimer?.cancel();
    if (selectedDate == null) {
      _quote = null;
      notifyListeners();
      return;
    }
    _quoteTimer = Timer(_quoteDelay, _runQuote);
  }

  Future<void> _runQuote() async {
    final BookingRequest? request = _request(forQuote: true);
    if (request == null) return;
    final int ticket = ++_quoteRequest;
    _isQuoting = true;
    notifyListeners();
    try {
      final BookingQuote result = await _bookings.quote(request);
      if (ticket != _quoteRequest) return;
      _quote = result;
      if (!result.available && selectedDate != null) {
        // The day went between loading and picking: strike it through.
        if (result.refusal == QuoteRefusal.dateUnavailable) {
          markTaken(selectedDate!);
        }
      }
    } catch (_) {
      // The listed prices stand in; Send still asks the server.
    }
    if (ticket == _quoteRequest) {
      _isQuoting = false;
      notifyListeners();
    }
  }

  /// The lines to show: the quote's once there is one, else the listed
  /// prices — the service at its unit and the extras picked, or the pack's
  /// services and its saving. [language] names them.
  List<BookingLine> lines(String language, {required String packSavingLabel}) {
    final BookingQuote? quoted = _quote;
    if (quoted != null && quoted.lines.isNotEmpty) return quoted.lines;
    final List<BookingLine> result = <BookingLine>[];
    final ServiceDetail? service = _service;
    final PackDetail? pack = _pack;
    if (service != null) {
      final int quantity = _quantity;
      final int unit = amountCents(service.basePrice);
      result.add(BookingLine(
        kind: BookingLineKind.service,
        label: service.title.of(language),
        quantity: quantity,
        unitAmount: service.basePrice,
        amount: _money(unit * quantity),
      ));
      for (final ServiceExtra extra in service.extras) {
        final int count = extraCount(extra.id);
        if (count == 0) continue;
        result.add(BookingLine(
          kind: BookingLineKind.extra,
          label: extra.name.of(language),
          quantity: count,
          unitAmount: extra.price,
          amount: _money(amountCents(extra.price) * count),
        ));
      }
    } else if (pack != null) {
      for (final PackItem item in pack.items) {
        result.add(BookingLine(
          kind: BookingLineKind.packService,
          label: item.title.of(language),
          quantity: 1,
          unitAmount: item.price,
          amount: item.price,
        ));
      }
      if (amountCents(pack.savings) > 0) {
        result.add(BookingLine(
          kind: BookingLineKind.discount,
          label: packSavingLabel,
          quantity: 1,
          unitAmount: '-${pack.savings}',
          amount: '-${pack.savings}',
        ));
      }
    }
    return result;
  }

  /// The total to pay: the quote's, else the listed prices'.
  String get total {
    final BookingQuote? quoted = _quote;
    if (quoted != null) return quoted.total;
    final PackDetail? pack = _pack;
    if (pack != null) return pack.price;
    final ServiceDetail? service = _service;
    if (service == null) return '0.00';
    int cents = amountCents(service.basePrice) * _quantity;
    for (final ServiceExtra extra in service.extras) {
      cents += amountCents(extra.price) * extraCount(extra.id);
    }
    return _money(cents);
  }

  /// The service's quantity at its price type, as the server counts it.
  int get _quantity => switch (priceType) {
        PriceType.perHour => _hours ?? 1,
        PriceType.perPerson => (_guests ?? 0) < 1 ? 1 : _guests!,
        _ => 1,
      };

  /// Whole hours from start to end, an end past midnight counting on.
  int? get _hours {
    final String? start = _startTime;
    final String? end = _endTime;
    if (start == null || end == null) return null;
    return (spanMinutes(start, end) / 60).ceil();
  }

  static String _money(int cents) {
    final String sign = cents < 0 ? '-' : '';
    final int abs = cents.abs();
    return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }

  // ------------------------------------------------------------------ send

  /// The fields still missing, in form order — empty when the request can
  /// go. Marks them so the form shows why.
  List<BookingField> validate() {
    final List<BookingField> missing = <BookingField>[
      if (selectedDate == null) BookingField.date,
      if ((needsTimes && (_startTime == null || _endTime == null)) ||
          (_endTime != null && _startTime == null))
        BookingField.time,
      if (_eventType == null) BookingField.eventType,
      if ((needsGuests && _guests == null) || guestsOverLimit)
        BookingField.guests,
      if (_wilaya == null) BookingField.wilaya,
    ];
    _missing = missing.toSet();
    notifyListeners();
    return missing;
  }

  BookingRequest? _request({bool forQuote = false}) {
    final DateTime? date = selectedDate;
    final EventType? type = _eventType;
    final Wilaya? place = _wilaya;
    if (date == null) return null;
    if (!forQuote && (type == null || place == null)) return null;
    return BookingRequest(
      serviceId: serviceId,
      packId: packId,
      eventDate: date,
      startTime: _startTime,
      endTime: _startTime == null ? null : _endTime,
      guests: _guests,
      extras: Map<String, int>.of(_extras)..removeWhere((_, int n) => n == 0),
      // The quote only prices; these two are placeholders it ignores.
      wilayaCode: place?.code ?? 16,
      eventType: type ?? EventType.other,
      communeId: _commune?.id,
      locationText: _address,
      clientNote: _note,
    );
  }

  /// Prices the request for B9a — the server's lines and saving. `null`
  /// with [failure] when it could not.
  Future<BookingQuote?> review() async {
    if (validate().isNotEmpty) return null;
    _quoteTimer?.cancel();
    final BookingRequest? request = _request();
    if (request == null) return null;
    final BookingQuote? result = await runGuarded(() => _bookings.quote(request));
    if (result != null) {
      _quote = result;
      if (!result.available && result.refusal == QuoteRefusal.dateUnavailable) {
        _takenDate = selectedDate;
        markTaken(selectedDate!);
        _problem = SendProblem.dateTaken;
        notifyListeners();
        return null;
      }
      notifyListeners();
    }
    return result;
  }

  /// Sends the request. The new booking, or `null` with [problem] set (or
  /// [missing], when the form is incomplete).
  Future<BookingDetail?> send() async {
    if (_isSending) return null;
    if (validate().isNotEmpty) return null;
    final BookingRequest? request = _request();
    if (request == null) return null;
    _isSending = true;
    _problem = null;
    notifyListeners();
    BookingDetail? created;
    try {
      created = await _bookings.create(request);
      _isSent = true;
    } on ApiFailure catch (failure) {
      _problem = switch (failure.code) {
        ApiErrorCode.dateUnavailable => SendProblem.dateTaken,
        ApiErrorCode.minNotice => SendProblem.tooSoon,
        ApiErrorCode.providerNotAccepting => SendProblem.notAccepting,
        _ => SendProblem.failed,
      };
      if (_problem != SendProblem.failed) {
        final DateTime? taken = selectedDate;
        _takenDate = taken;
        if (taken != null) markTaken(taken);
        clearSelection();
        _quote = null;
      } else {
        setFailure(failure);
      }
    } on Failure catch (failure) {
      _problem = SendProblem.failed;
      setFailure(failure);
    } catch (error) {
      _problem = SendProblem.failed;
      setFailure(UnexpectedFailure(cause: error));
    }
    _isSending = false;
    notifyListeners();
    return created;
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }
}

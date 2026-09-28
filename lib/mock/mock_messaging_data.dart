/// The seed the mock messaging backend starts every account on: the
/// conversations Figma 14 draws, the threads inside them (Figma 15), the
/// notifications Figma 16 draws, and enough filler to page past 20.
///
/// Everything is built relative to `MockBackend.now`, so the D6 time ladder
/// shows Today, Yesterday, a weekday and plain dates whatever day the app
/// runs on. The other side of a direct chat is a **catalog provider id**
/// wherever one fits, so "View profile", the D4 reply-time line and
/// `findWith` from screens 12 and 13 all resolve.
///
/// Thread content is what people typed, so it stays in the language it was
/// written in; only the server's own words — booking titles and
/// notifications — carry both languages (`…En` / `…Ar`) for the store to
/// resolve per request, as the live server does by `Accept-Language`.
library;

/// The support agent every support and dispute thread holds.
const String mockSupportId = 'mock-support';
const String mockSupportName = 'Eventor support';

/// Catalog provider ids the seed talks to (`mock_catalog_data.dart`).
const String mockLumiereId = '3552815d-6aca-43fc-ace8-0409ee3a762e';
const String mockYasmineId = 'c62532f4-6fa9-4752-9f82-cdbea4b0dd07';
const String mockDjazairId = '6db77516-86a1-49ef-8b57-2c610c4e90ca';
const String mockOliviersId = 'fe9734e0-24c4-4640-ae2a-d07220ed3f5a';
const String mockBahiaId = '94305376-287a-4966-9546-8c3afd247e88';

/// A deleted account's leftover messages keep its old id as their sender.
const String mockDeletedUserId = 'mock-deleted-user';

/// One seeded conversation: its detail JSON (with the booking title in both
/// languages) and its thread, oldest first.
typedef MockThreadSeed = ({
  Map<String, Object?> conversation,
  List<Map<String, Object?>> messages,
});

String _iso(DateTime time) => time.toUtc().toIso8601String();

String _date(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

String _photo(String file) => 'asset:assets/mock/photos/$file';

Map<String, Object?> _person(
  String id,
  String name, {
  String role = 'provider',
  String? avatarUrl,
  bool blocked = false,
}) => <String, Object?>{
  'id': id,
  'name': name,
  'avatarUrl': avatarUrl,
  'role': role,
  'blocked': blocked,
};

/// Builds one thread's messages with ids `<conversationId>-m<n>`, so every
/// seeded message id is unique across the whole inbox.
class _ThreadBuilder {
  _ThreadBuilder(this.conversationId, this.meId);

  final String conversationId;
  final String meId;
  final List<Map<String, Object?>> messages = <Map<String, Object?>>[];

  void add(
    String? senderId,
    String body,
    DateTime at, {
    String kind = 'text',
    bool masked = false,
    String? imageUrl,
  }) {
    messages.add(<String, Object?>{
      'id': '$conversationId-m${messages.length + 1}',
      'conversationId': conversationId,
      'kind': kind,
      'senderId': senderId,
      'mine': senderId != null && senderId == meId,
      'body': body,
      'masked': masked,
      'imageUrl': imageUrl,
      'imageLargeUrl': imageUrl,
      'createdAt': _iso(at),
    });
  }

  void system(String body, DateTime at) => add(null, body, at, kind: 'system');
}

Map<String, Object?> _conversation({
  required String id,
  required String kind,
  required Map<String, Object?>? other,
  required List<Map<String, Object?>> participants,
  required List<Map<String, Object?>> messages,
  required String lastMessage,
  required DateTime createdAt,
  String status = 'open',
  int unreadCount = 0,
  Map<String, Object?>? booking,
  bool canWrite = true,
  bool contactUnmasked = false,
  String? disputeId,
  String? closedReason,
}) => <String, Object?>{
  'id': id,
  'kind': kind,
  'status': status,
  'other': other,
  'lastMessage': lastMessage,
  'lastMessageAt': messages.isEmpty ? null : messages.last['createdAt'],
  'unreadCount': unreadCount,
  'booking': booking,
  'canWrite': canWrite,
  'participants': participants,
  'contactUnmasked': contactUnmasked,
  'disputeId': disputeId,
  'closedReason': closedReason,
  'createdAt': _iso(createdAt),
};

/// Lumière's history before today — alternating turns, enough of it (40
/// lines) that the newest page of 30 leaves older ones to scroll up to.
const List<String> _lumiereHistoryMine = <String>[
  'Hello, are you free for a wedding in the spring?',
  'It would be in Algiers, around 250 guests.',
  'Do you also do the engagement session?',
  'Could you send me a few examples of your albums?',
  'What is included in the full-day pack?',
  'Is the drone footage an extra?',
  'How long until we receive the photos?',
  'Can we meet at your studio next week?',
  'Tuesday afternoon works for me.',
  'Great, I will send the booking request soon.',
  'Do you travel to Blida as well?',
  'We would like a short highlights video too.',
  'Is a second photographer possible?',
  'How many edited photos do we get?',
  'Can you shoot the henna evening too?',
  'Thank you, that is very clear.',
  'My fiancé agrees with the full-day pack.',
  'Is a deposit needed to hold the date?',
  'Perfect, we will decide this week.',
  'We just sent the request for 14 March.',
];

const List<String> _lumiereHistoryTheirs = <String>[
  'Hello! Yes, the spring is still quite open.',
  'That size is no problem for our team.',
  'Yes, we can add it to the same booking.',
  'Of course — here is our portfolio link in the profile.',
  'Ceremony, reception and a printed album.',
  'It is included in the full-day pack.',
  'Usually three weeks after the event.',
  'Yes, we are open Tuesday to Saturday.',
  'Tuesday at 15:00 it is.',
  'Looking forward to it.',
  'Yes, Blida and Tipaza at no extra cost.',
  'A 3-minute highlights film is included.',
  'Yes, for larger weddings we always send two.',
  'Around 400, all colour-graded.',
  'Yes, it can be added as a half-day.',
  'You are welcome — ask anything anytime.',
  'Wonderful news!',
  'The deposit is handled with the booking.',
  'Take your time, the date is not taken yet.',
  'Received, thank you — I will look at it tomorrow.',
];

/// The made-up businesses that pad the list past two pages. None of them
/// is in the catalog, so their profile shows "no longer available" — fine
/// for filler. No name contains "yasm", so a search for Salle Yasmine
/// still finds only her.
const List<String> _fillerBusinesses = <String>[
  'Salle Le Palmier',
  'Traiteur Dar Diaf',
  'Studio Nour',
  'DJ Amine',
  'Fleurs de Tlemcen',
  'Pâtisserie Lalla',
  'Salle Essaada',
  'Orchestre El Anka',
  'Déco Mille et Une Nuits',
  'Traiteur Bab El Oued',
  'Henné Chez Zineb',
  'Photo Kasbah',
];

/// The catalog providers left over once the drawn rows are placed. Douceurs
/// d'Oran is kept out on purpose so `start` with it opens a brand-new chat,
/// and Studio Yasmine Photo so a search for "yasm" finds only Salle Yasmine.
const List<({String id, String name})> _fillerCatalogProviders =
    <({String id, String name})>[
      (id: '874ec054-c8d1-4c70-810c-52c9debac14f', name: 'Orchestre Andalou'),
      (id: 'aebed654-e28b-4191-8ec2-531031ca3314', name: 'Pâtisserie Meriem'),
      (id: '96a1f496-ffee-4a92-8204-76f8066a62e4', name: 'Flora Design'),
      (id: '94991c78-a5b7-4c3d-8aa6-a7fefcb75d64', name: 'Rym Events Déco'),
      (id: 'a08cde8f-1369-492a-8dd3-8187341af983', name: 'Limousine Prestige'),
    ];

const List<(String, String)> _fillerExchanges = <(String, String)>[
  (
    'Hello, are you available in July?',
    'Hello! Yes, send us your date and we will confirm.',
  ),
  (
    'Could you send me your prices for 200 guests?',
    'Of course, the quote is on its way.',
  ),
  ('Do you work on Fridays?', 'Yes, every day except Mondays.'),
  (
    'Thank you for the quick answer!',
    'With pleasure — congratulations on the event.',
  ),
];

/// The 25 conversations every account starts with, newest first.
List<MockThreadSeed> mockConversationSeeds({
  required DateTime now,
  required String meId,
  required String meName,
}) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  DateTime dayAt(int daysAgo, int hour, int minute) =>
      DateTime(today.year, today.month, today.day - daysAgo, hour, minute);
  final String firstName = meName.trim().split(' ').first;
  final Map<String, Object?> me = _person(meId, meName, role: 'client');
  final Map<String, Object?> support = _person(
    mockSupportId,
    mockSupportName,
    role: 'support',
  );

  final List<MockThreadSeed> seeds = <MockThreadSeed>[];

  // ------------------------------------------------ Studio Lumière (Figma 15)
  {
    const String id = 'mock-chat-lumiere';
    final Map<String, Object?> lumiere = _person(
      mockLumiereId,
      'Studio Lumière',
      avatarUrl: _photo('pexels-photographie-1.webp'),
    );
    final _ThreadBuilder thread = _ThreadBuilder(id, meId);
    final DateTime historyStart = today.subtract(const Duration(days: 20));
    for (int i = 0; i < 40; i++) {
      final bool mine = i.isEven;
      final List<String> lines = mine
          ? _lumiereHistoryMine
          : _lumiereHistoryTheirs;
      thread.add(
        mine ? meId : mockLumiereId,
        lines[i ~/ 2],
        historyStart.add(Duration(hours: 9 + i * 12)),
      );
    }
    final DateTime latest = now.subtract(const Duration(minutes: 20));
    thread
      ..system(
        'Booking requested · phone numbers stay hidden until the provider accepts.',
        latest.subtract(const Duration(minutes: 30)),
      )
      ..add(
        mockLumiereId,
        'Good morning — I saw your request for 14 March.',
        latest.subtract(const Duration(minutes: 22)),
      )
      ..add(
        mockLumiereId,
        "Perfect, I'm free that day. Do you want the full-day pack or just the ceremony ?",
        latest.subtract(const Duration(minutes: 13)),
      )
      ..add(
        meId,
        'Full day please. My number is [phone hidden]',
        latest.subtract(const Duration(minutes: 4)),
        masked: true,
      )
      ..add(
        mockLumiereId,
        'Last month at Salle Yasmine',
        latest.subtract(const Duration(minutes: 1)),
        kind: 'attachment',
        imageUrl: _photo('pexels-salles-des-fetes-2.webp'),
      )
      ..add(mockLumiereId, "Perfect — I'll hold Sat 14 Mar for you.", latest);
    seeds.add((
      conversation: _conversation(
        id: id,
        kind: 'direct',
        other: lumiere,
        participants: <Map<String, Object?>>[me, lumiere],
        messages: thread.messages,
        lastMessage: "Perfect — I'll hold Sat 14 Mar for you.",
        unreadCount: 2,
        booking: <String, Object?>{
          'id': 'mock-booking-lumiere',
          'reference': 'EVT-000123',
          'status': 'pending',
          'eventDate': _date(today.add(const Duration(days: 50))),
          'titleEn': 'Wedding photo & video coverage',
          'titleAr': 'تغطية الزفاف بالصور والفيديو',
          'total': '57000.00',
        },
        createdAt: historyStart.add(const Duration(hours: 9)),
      ),
      messages: thread.messages,
    ));
  }

  // --------------------------------------------- Salle Yasmine (removed line)
  {
    const String id = 'mock-chat-yasmine';
    final Map<String, Object?> yasmine = _person(
      mockYasmineId,
      'Salle Yasmine',
      avatarUrl: _photo('pexels-salles-des-fetes-1.webp'),
    );
    final _ThreadBuilder thread = _ThreadBuilder(id, meId)
      ..add(
        meId,
        'Hello, is the hall available for about 250 guests in April?',
        dayAt(2, 17, 5),
      )
      ..add(
        mockYasmineId,
        'Hello! Let me check the calendar.',
        dayAt(2, 17, 30),
      )
      // An admin hid this one; the live API sends the placeholder in its place.
      ..add(mockYasmineId, '[removed by Eventor]', dayAt(1, 10, 12))
      ..add(meId, 'Is the weekend of the 18th still open?', dayAt(1, 18, 2))
      ..add(
        mockYasmineId,
        'Yes, the hall is free that weekend.',
        dayAt(1, 18, 40),
      );
    seeds.add((
      conversation: _conversation(
        id: id,
        kind: 'direct',
        other: yasmine,
        participants: <Map<String, Object?>>[me, yasmine],
        messages: thread.messages,
        lastMessage: 'Yes, the hall is free that weekend.',
        createdAt: dayAt(2, 17, 5),
      ),
      messages: thread.messages,
    ));
  }

  // ----------------------------------------------- Traiteur El Djazair
  // Figma draws "Traiteur El Baraka"; the catalog provider stands in so 13
  // opens from this chat.
  {
    const String id = 'mock-chat-djazair';
    final Map<String, Object?> djazair = _person(
      mockDjazairId,
      'Traiteur El Djazair',
    );
    final _ThreadBuilder thread = _ThreadBuilder(id, meId)
      ..add(
        meId,
        'Hello, do you cater for weddings in Blida?',
        dayAt(3, 10, 20),
      )
      ..add(
        mockDjazairId,
        'Can you confirm the guest count ?',
        dayAt(3, 11, 5),
      );
    seeds.add((
      conversation: _conversation(
        id: id,
        kind: 'direct',
        other: djazair,
        participants: <Map<String, Object?>>[me, djazair],
        messages: thread.messages,
        lastMessage: 'Can you confirm the guest count ?',
        unreadCount: 1,
        createdAt: dayAt(3, 10, 20),
      ),
      messages: thread.messages,
    ));
  }

  // ---------------------------------------------------- Dispute EVT-2041
  {
    const String id = 'mock-chat-dispute';
    final Map<String, Object?> lumiere = _person(
      mockLumiereId,
      'Studio Lumière',
    );
    final _ThreadBuilder thread = _ThreadBuilder(id, meId)
      ..system(
        'Dispute opened · Eventor support joined this conversation',
        dayAt(13, 9, 0),
      )
      ..add(
        mockLumiereId,
        'The session was delivered as agreed.',
        dayAt(13, 11, 15),
      )
      ..add(
        mockLumiereId,
        'The full gallery was sent two days after the event.',
        dayAt(13, 11, 16),
      )
      ..add(
        mockSupportId,
        "We have both sides' evidence and will answer within 48 h.",
        dayAt(12, 9, 30),
      )
      ..add(mockLumiereId, 'Understood, thank you.', dayAt(12, 10, 2))
      ..add(
        meId,
        'Thank you. The call log is in my first report.',
        dayAt(12, 10, 40),
      );
    seeds.add((
      conversation: _conversation(
        id: id,
        kind: 'dispute',
        other: support,
        participants: <Map<String, Object?>>[me, lumiere, support],
        messages: thread.messages,
        // The server's row preview, prefixed with the speaker — Figma 14.
        lastMessage: "Support: we have both sides' evidence.",
        booking: <String, Object?>{
          'id': 'mock-booking-2041',
          'reference': 'EVT-2041',
          'status': 'completed',
          'eventDate': _date(today.subtract(const Duration(days: 20))),
          'titleEn': 'Engagement photos',
          'titleAr': 'صور الخطوبة',
          'total': '30000.00',
        },
        // Dispute chats are never masked — an admin is reading.
        contactUnmasked: true,
        disputeId: 'mock-dispute-2041',
        createdAt: dayAt(13, 9, 0),
      ),
      messages: thread.messages,
    ));
  }

  // -------------------------------------------------------- Eventor support
  {
    const String id = 'mock-chat-support';
    final _ThreadBuilder thread = _ThreadBuilder(
      id,
      meId,
    )..add(mockSupportId, 'Hi $firstName, how can we help ?', dayAt(14, 10, 0));
    seeds.add((
      conversation: _conversation(
        id: id,
        kind: 'support',
        other: support,
        participants: <Map<String, Object?>>[me, support],
        messages: thread.messages,
        lastMessage: 'Hi $firstName, how can we help ?',
        createdAt: dayAt(14, 10, 0),
      ),
      messages: thread.messages,
    ));
  }

  // ------------------------------------------- Salle Les Oliviers (closed)
  {
    const String id = 'mock-chat-oliviers';
    final Map<String, Object?> oliviers = _person(
      mockOliviersId,
      'Salle Les Oliviers',
    );
    final _ThreadBuilder thread = _ThreadBuilder(id, meId)
      ..add(meId, 'Hello, is the garden open in June?', dayAt(16, 14, 0))
      ..add(
        mockOliviersId,
        'Yes, we will send you the quote tomorrow.',
        dayAt(16, 15, 20),
      );
    seeds.add((
      conversation: _conversation(
        id: id,
        kind: 'direct',
        other: oliviers,
        participants: <Map<String, Object?>>[me, oliviers],
        messages: thread.messages,
        lastMessage: 'Yes, we will send you the quote tomorrow.',
        status: 'closed',
        canWrite: false,
        closedReason: 'harassment',
        createdAt: dayAt(16, 14, 0),
      ),
      messages: thread.messages,
    ));
  }

  // --------------------------------------- Salle El Bahia (other blocked)
  {
    const String id = 'mock-chat-bahia';
    final Map<String, Object?> bahia = _person(
      mockBahiaId,
      'Salle El Bahia',
      blocked: true,
    );
    final _ThreadBuilder thread = _ThreadBuilder(id, meId)
      ..add(meId, 'Hello, what is the capacity of the hall?', dayAt(17, 9, 45))
      ..add(mockBahiaId, 'Up to 400 guests seated.', dayAt(17, 12, 10));
    seeds.add((
      conversation: _conversation(
        id: id,
        kind: 'direct',
        other: bahia,
        participants: <Map<String, Object?>>[me, bahia],
        messages: thread.messages,
        lastMessage: 'Up to 400 guests seated.',
        canWrite: false,
        createdAt: dayAt(17, 9, 45),
      ),
      messages: thread.messages,
    ));
  }

  // ------------------------------------------------------ Deleted account
  {
    const String id = 'mock-chat-deleted';
    final _ThreadBuilder thread = _ThreadBuilder(id, meId)
      ..add(meId, 'Hello, are you still taking bookings?', dayAt(18, 16, 0))
      ..add(mockDeletedUserId, 'See you on the day!', dayAt(18, 16, 45));
    seeds.add((
      conversation: _conversation(
        id: id,
        kind: 'direct',
        other: null,
        participants: <Map<String, Object?>>[me],
        messages: thread.messages,
        lastMessage: 'See you on the day!',
        canWrite: false,
        createdAt: dayAt(18, 16, 0),
      ),
      messages: thread.messages,
    ));
  }

  // --------------------------------------------------------------- filler
  final List<({String id, String name})> fillerOthers =
      <({String id, String name})>[
        ..._fillerCatalogProviders,
        for (final (int i, String name) in _fillerBusinesses.indexed)
          (id: 'mock-filler-provider-${i + 1}', name: name),
      ];
  for (final (int i, ({String id, String name}) other)
      in fillerOthers.indexed) {
    final String id = 'mock-chat-filler-${i + 1}';
    final Map<String, Object?> person = _person(other.id, other.name);
    final (String, String) exchange =
        _fillerExchanges[i % _fillerExchanges.length];
    // 20 to 84 days ago, four days apart — the "d MMM" end of the ladder.
    final int daysAgo = 20 + i * 4;
    final _ThreadBuilder thread = _ThreadBuilder(id, meId)
      ..add(meId, exchange.$1, dayAt(daysAgo, 11, 0))
      ..add(other.id, exchange.$2, dayAt(daysAgo, 13, 30));
    seeds.add((
      conversation: _conversation(
        id: id,
        kind: 'direct',
        other: person,
        participants: <Map<String, Object?>>[me, person],
        messages: thread.messages,
        lastMessage: exchange.$2,
        createdAt: dayAt(daysAgo, 11, 0),
      ),
      messages: thread.messages,
    ));
  }

  return seeds;
}

/// The eight Figma 16 notifications, newest first: `{id, type, data,
/// createdAt (DateTime), read, titleEn, bodyEn, titleAr, bodyAr}`. The store
/// resolves the language and derives `group` per request.
List<Map<String, Object?>> mockNotificationSeeds(DateTime now) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  // "Today" rows stay on today's date even just after midnight.
  DateTime earlierToday(Duration ago) {
    final DateTime at = now.subtract(ago);
    return at.isBefore(today) ? today : at;
  }

  DateTime daysAgo(int days, int hour, int minute) =>
      DateTime(today.year, today.month, today.day - days, hour, minute);

  Map<String, Object?> notification(
    int n,
    String type,
    DateTime createdAt, {
    required String titleEn,
    required String bodyEn,
    required String titleAr,
    required String bodyAr,
    Map<String, Object?>? data,
    bool read = true,
  }) => <String, Object?>{
    'id': 'mock-notification-$n',
    'type': type,
    'data': data,
    'createdAt': createdAt,
    'read': read,
    'titleEn': titleEn,
    'bodyEn': bodyEn,
    'titleAr': titleAr,
    'bodyAr': bodyAr,
  };

  return <Map<String, Object?>>[
    notification(
      1,
      'booking.accepted',
      earlierToday(const Duration(minutes: 20)),
      read: false,
      data: <String, Object?>{'bookingId': 'mock-booking-1'},
      titleEn: 'Booking accepted',
      bodyEn: 'Studio Lumière accepted your request for Sat 14 Mar.',
      titleAr: 'تم قبول الحجز',
      bodyAr: 'قَبِل Studio Lumière طلبك ليوم السبت 14 مارس.',
    ),
    notification(
      2,
      'message.new',
      earlierToday(const Duration(minutes: 90)),
      read: false,
      data: <String, Object?>{'conversationId': 'mock-chat-yasmine'},
      titleEn: 'New message',
      bodyEn: 'Salle Yasmine: Yes, the hall is free that weekend.',
      titleAr: 'رسالة جديدة',
      bodyAr: 'Salle Yasmine: نعم، القاعة متاحة في نهاية ذلك الأسبوع.',
    ),
    notification(
      3,
      'booking.waiting',
      daysAgo(3, 9, 0),
      data: <String, Object?>{'bookingId': 'mock-booking-2'},
      titleEn: 'Waiting for a reply',
      bodyEn: 'Traiteur El Djazair has not answered your booking request yet.',
      titleAr: 'في انتظار الرد',
      bodyAr: 'لم يردّ Traiteur El Djazair على طلب حجزك بعد.',
    ),
    notification(
      4,
      'review.request',
      daysAgo(4, 18, 0),
      titleEn: 'Leave a review',
      bodyEn: 'How was your engagement session with Studio Lumière ?',
      titleAr: 'اترك تقييمًا',
      bodyAr: 'كيف كانت جلسة خطوبتك مع Studio Lumière ؟',
    ),
    notification(
      5,
      'booking.declined',
      daysAgo(10, 14, 30),
      titleEn: 'Booking declined',
      bodyEn: 'DJ Amine declined your request: not available on that date.',
      titleAr: 'تم رفض الحجز',
      bodyAr: 'رفض DJ Amine طلبك: غير متاح في ذلك التاريخ.',
    ),
    notification(
      6,
      'booking.reschedule_proposed',
      daysAgo(13, 11, 0),
      titleEn: 'Date change proposed',
      bodyEn: 'Salle Yasmine proposed Sun 15 Mar instead of Sat 14 Mar.',
      titleAr: 'اقتراح تاريخ جديد',
      bodyAr: 'اقترحت Salle Yasmine الأحد 15 مارس بدل السبت 14 مارس.',
    ),
    notification(
      7,
      'dispute.message',
      daysAgo(15, 10, 0),
      // Typed ids, as the API sends them since 2026-09-27.
      data: <String, Object?>{
        'disputeId': 'mock-dispute-2041',
        'conversationId': 'mock-chat-dispute',
      },
      titleEn: 'Dispute update',
      bodyEn: 'Eventor support replied on your dispute for EVT-2041.',
      titleAr: 'تحديث النزاع',
      bodyAr: 'ردّ دعم Eventor على نزاعك.',
    ),
    notification(
      8,
      'review.reply',
      daysAgo(17, 16, 0),
      titleEn: 'Reply to your review',
      bodyEn: 'Studio Lumière replied to your review.',
      titleAr: 'رد على تقييمك',
      bodyAr: 'ردّ Studio Lumière على تقييمك.',
    ),
  ];
}

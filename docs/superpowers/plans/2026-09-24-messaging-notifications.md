# Messages, chat and notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the client's screens 14 Messages, 15 Chat (with its closed, removed, dispute and draft states) and 16 Notifications, on the live API and on an equivalent mock backend, in EN and AR. Wire them to the Messages tab, the bells on 11 and 14, "Message" on 12 and 13, and notification taps.

**Architecture:** Same layering as the discovery build. Shared code goes in `lib/core/messaging/` and `lib/core/notifications/`: models, a `MessagingRepository` and a `NotificationsRepository`, each with an `Api…` and a `Mock…` implementation picked once in `AppServices`, and a `ChatUpdates` poller behind an interface so Socket.IO can replace it later. Each screen is a thin feature folder: `features/messages`, `features/chat` and `features/notifications`, each with `view_model/` and `view/`. `ShellBadges` becomes the one source for both unread counts. 15 and 16 are root routes (full screen, no nav). 14 replaces the Messages-tab placeholder.

**Tech Stack:** Flutter 3.47 / Dart ^3.13, provider, go_router ^18, dio ^5 (multipart), cached_network_image ^4, file_picker ^12.3 (`FilePicker.pickFile` + `PlatformFile.readAsBytes()`), intl, flutter_svg, shared_preferences. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-09-24-messaging-notifications-design.md`. Its decision numbers (1–8) and defaults (D1–D16) are cited below; read the spec beside this plan. API facts come from the research notes `C:\Users\USER\AppData\Local\Temp\claude\D--Eventor\8423ca6c-e567-4381-b879-20b753c041dd\scratchpad\api\messaging-contract.md`. Figma notes are in `…\scratchpad\figma-messaging.md`, with screenshots in `…\scratchpad\figma-msg\*.png`. Those notes may be gone; everything this plan needs from them is copied in below.

## Global Constraints

- **User rule, tests:** write every test listed here and **do not run `flutter test`**. Each task is verified with `flutter analyze --no-pub lib test`, which must print "No issues found!". The user runs the suite.
- **User rule, git:** **no commits** unless the user asks. Tasks end with analyze, not with a commit.
- **Mock first:** every repository has a `Mock…` twin behind the same interface. They are wired only in `lib/app/app_services.dart`, and mock is the default build (`EVENTOR_DATA`). The mock builds API-shaped JSON and parses it with the same `fromJson`.
- **Conventions:**
  - Explicit types on locals and collections.
  - Why-comments only.
  - View models import no Material and produce no user-facing strings. They return enums, sealed outcomes or `Failure`s, and the view words them.
  - Colours and type come from `AppColors` and the theme. Every dimension goes through `.dh`/`.dw`, except font sizes, `AppRadii`, `maxContentWidth` and hairlines.
  - Layout is directional: `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`.
- **Text styles:** map Figma names to the theme like this:
  - Heading/XL = `headlineMedium`, Heading/S = `titleMedium`
  - Body/M Strong = `titleSmall`, Body/M = `bodyMedium`, Body/S = `bodySmall`
  - Label/L = `labelLarge`, Label/M = `labelMedium`, Caption = `labelSmall`
  - Overline = `AppTextStyles.overlineForLocale(locale)`
- **Arabic numbers (standing rule):** times, booking references and counts render as their own LTR run inside Arabic rows. Either use a separate `Text(textDirection: TextDirection.ltr)`, or wrap interpolated tokens with `ltrIsolate()` (Task 2). Always Western digits: never let `DateFormat` print digits.
- **Nested padding (standing rule):** when a container and its child both pad, the insets stack at the ends. The thread's 12/16 padding is the only horizontal inset: bubble rows add none.
- **Sheets (standing rule):** use `showAppBottomSheet` / `AppSheetScaffold` (P3: 0.5 scrim, 24/24/0/0).
- **"Coming soon":** unbuilt destinations use `showComingSoon(context, context.l10n.comingSoon)`. That covers the booking card, booking notifications and 20's message button, which is out of scope.
- **Copy:**
  - Every string goes in `app_en.arb` (with an `@key` description) and `app_ar.arb`, through the helper below.
  - Spec §6 holds the exact EN/AR copy for its keys. This plan adds a few more, with their copy given in the task that adds them.
  - Run `flutter gen-l10n` after ARB edits. `l10n_missing.json` must stay `{}`.
  - Group labels are uppercased in code for EN only.
- **ARB helper:** save the script below as `arb_add.js` in your temp/scratch directory (never in the repo). Run it as `node arb_add.js entries.json`, where entries are `[{key, en, ar, description, placeholders?}]`. It refuses duplicates and incomplete entries.
  ```js
  const fs = require('fs');
  const root = 'D:/Eventor/lib/l10n/';
  const entries = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const en = JSON.parse(fs.readFileSync(root + 'app_en.arb', 'utf8'));
  const ar = JSON.parse(fs.readFileSync(root + 'app_ar.arb', 'utf8'));
  for (const e of entries) {
    if (en[e.key] !== undefined || ar[e.key] !== undefined) { console.error('EXISTS: ' + e.key); process.exit(1); }
    if (!e.en || !e.ar || !e.description) { console.error('INCOMPLETE: ' + e.key); process.exit(1); }
    en[e.key] = e.en;
    const meta = { description: e.description };
    if (e.placeholders) meta.placeholders = e.placeholders;
    en['@' + e.key] = meta;
    ar[e.key] = e.ar;
  }
  fs.writeFileSync(root + 'app_en.arb', JSON.stringify(en, null, 2) + '\n');
  fs.writeFileSync(root + 'app_ar.arb', JSON.stringify(ar, null, 2) + '\n');
  console.log('added ' + entries.length);
  ```
  Placeholder metadata: `{"query": {"type": "String"}}`, `{"name": {"type": "String"}}`, `{"reference": {"type": "String"}}`, `{"mb": {"type": "int"}}`, `{"count": {"type": "int"}}`.
- **Polling budget:** the API allows 100 requests per 60 s, image downloads included. So only 15 polls: every 5 s, only while visible, with no overlapping ticks. 14 and 16 refresh on open, on pull, on resume and after reads, never on a timer.

## Review Focus

These are inputs the spec implies but no screen test would naturally hit. Each has a pinned test in the task that owns the code.

1. **A poll that lands while a send is still in flight.** The server already returns the message the app is still "sending". When the send completes, exactly one bubble must remain, not two (Task 12, "poll during send").
2. **Leaving 15, or backgrounding the app, while a poll or send is in flight.** There must be no notify after dispose, the poller must stop, and nothing may poll while the app is hidden. The rate limit is shared with image loads (Task 5 lifecycle tests; Task 11 dispose test).
3. **Double-tapping "Message" on 12/13.** One lookup and one push, never two stacked chats (Task 16, `chatRouteWith` returns `null` while busy).
4. **Image-only, caption-only and removed-image messages, plus a row whose last message was a photo.** None may render a blank bubble or a blank preview. An image-only last message previews as "Photo" (Task 3 `previewKind` tests; Task 13 bubble tests).
5. **Switching chips and typing fast on 14.** A slower, older response must not overwrite the newer list, and blank or whitespace search sends no `q` (Task 9 generation-guard and query-trim tests).

---

## File Structure

```
lib/core/network/api_client.dart                 (modify: getEnvelope)
lib/core/errors/failure.dart                     (modify: messaging ApiErrorCodes)
lib/core/base/base_view_model.dart               (modify: protected setFailure)
lib/core/config/app_config.dart                  (modify: maxPhotoMb, imageTypes)
lib/core/formatting/chat_time_format.dart        (new: D6 ladder, clockTime, ltrIsolate)
lib/core/messaging/models/chat_person.dart       (new)
lib/core/messaging/models/conversation.dart      (new: ConversationKind, ChatBooking, ConversationRow, ConversationDetail, PreviewKind)
lib/core/messaging/models/chat_message.dart      (new: MessageKind, ChatMessage, MessagePage)
lib/core/messaging/models/report_reason.dart     (new)
lib/core/messaging/conversation_filter.dart      (new)
lib/core/messaging/picked_image.dart             (new: PickedImage, ImageProblem)
lib/core/messaging/messaging_repository.dart     (new: interface + ApiMessagingRepository)
lib/core/messaging/chat_poller.dart              (new: ChatUpdates, TimerChatUpdates)
lib/core/messaging/chat_launcher.dart            (new: ChatLauncher mixin for 12/13)
lib/core/notifications/models/app_notification.dart (new)
lib/core/notifications/notifications_repository.dart (new: interface + ApiNotificationsRepository)
lib/core/notifications/notification_icon.dart    (new)
lib/core/services/photo_picker.dart              (new: PhotoPicker typedef + pickChatPhoto)
lib/core/routing/app_routes.dart, app_router.dart (modify)
lib/core/widgets/atoms/app_icon.dart             (modify: image, clock) + assets/icons/{image,clock}.svg
lib/core/widgets/atoms/app_avatar.dart           (modify: list 48, chatHeader 36)
lib/core/widgets/atoms/app_network_image.dart    (modify: data: URIs, errorBuilder)
lib/core/widgets/atoms/status_badge.dart         (modify: BookingStatusKind.fromApi)
lib/core/widgets/molecules/notification_bell.dart (new, extracted from HomeHeader)
lib/core/widgets/molecules/offline_banner.dart   (new)
lib/core/widgets/molecules/conversation_avatar.dart (new)
lib/core/widgets/organisms/divided_card.dart     (new)
lib/core/widgets/organisms/sticky_action_bar.dart (modify: message loading state)
lib/features/shell/shell_badges.dart             (modify: unreadNotifications, refresh)
lib/features/shell/view/client_shell.dart        (modify: refresh badges on resume)
lib/features/home/…                               (modify: bell → 16, dot from badges)
lib/features/service_detail/…, provider_profile/… (modify: Message → chat)
lib/features/messages/view_model/messages_view_model.dart
lib/features/messages/view/messages_view.dart + view/widgets/{messages_header,conversation_row,messages_skeleton}.dart
lib/features/chat/view_model/{chat_view_model,chat_thread}.dart
lib/features/chat/view/chat_view.dart + view/widgets/{chat_top_bar,booking_context_card,message_bubble,thread_pills,chat_composer,new_messages_pill,chat_skeleton,message_actions_sheet,report_sheet,photo_viewer}.dart
lib/features/notifications/view_model/notifications_view_model.dart
lib/features/notifications/view/notifications_view.dart + view/widgets/{notifications_header,notification_item}.dart
lib/mock/mock_messaging_data.dart, lib/mock/mock_messaging.dart (new)
lib/mock/mock_catalog.dart                       (modify: home counts from the messaging store)
lib/app/app_services.dart, lib/app/eventor_app.dart (modify: wire + provide)
test/fixtures/messaging/*.json                   (new, hand-written from the DTOs)
test/support/{fakes,fixtures,test_app}.dart      (modify)
test/… mirrors lib/
```

---

### Task 1: Foundations — envelope GET, error codes, photo limits, status parser, fixtures dir

**Files:**
- Modify: `lib/core/network/api_client.dart` (add `getEnvelope` after `getPage`)
- Modify: `lib/core/errors/failure.dart` (codes), `lib/core/base/base_view_model.dart` (`setFailure`)
- Modify: `lib/core/config/app_config.dart`
- Modify: `lib/core/widgets/atoms/status_badge.dart` and `lib/features/home/view/widgets/home_sections.dart` (use the new parser; delete `_status`)
- Modify: `test/support/fixtures.dart`
- Test: `test/core/network/api_client_test.dart`, `test/core/config/app_config_test.dart`, `test/core/widgets/atoms/status_badge_test.dart` (extend)

**Interfaces:**
- Produces:
```dart
// ApiClient — the message list's meta is {limit, hasMore, nextBefore}, which getPage cannot read.
Future<Map<String, Object?>> getEnvelope(String path, {Map<String, Object?>? query});
// ApiErrorCode
static const String notAParticipant = 'NOT_A_PARTICIPANT';
static const String conversationNotFound = 'CONVERSATION_NOT_FOUND';
static const String conversationClosed = 'CONVERSATION_CLOSED';
static const String conversationReadOnly = 'CONVERSATION_READ_ONLY';
static const String recipientInvalid = 'RECIPIENT_INVALID';
static const String userNotFound = 'USER_NOT_FOUND';
static const String messageNotFound = 'MESSAGE_NOT_FOUND';
// BaseViewModel — for view models that guard against stale responses themselves
@protected void setFailure(Failure failure);   // = _setFailure
// AppConfig
final int maxPhotoMb;             // uploads.maxPhotoMb, default 10
final List<String> imageTypes;    // uploads.imageTypes, default ['jpeg','png','webp','heic']
// status_badge.dart
enum BookingStatusKind { …; static BookingStatusKind fromApi(String api) } // unknown → pending
// fixtures.dart
Map<String, Object?> fixture(String name, {String dir = 'catalog'}); // + same `dir` on fixtureData / fixtureList
```

- [ ] **Step 1: Write the tests.**
  - `getEnvelope('/app/conversations/c-1/messages', query: {'before': 'm-9'})` returns `{data: [...], meta: {limit: 30, hasMore: true, nextBefore: 'm-1'}}` unchanged. The adapter saw `before=m-9` and the bearer header.
  - A 403 `NOT_A_PARTICIPANT` becomes `ApiFailure(code: 'NOT_A_PARTICIPANT', statusCode: 403)`.
  - `AppConfig.fromJson({'uploads': {'maxPhotoMb': 8, 'imageTypes': ['jpeg','png']}})` gives 8 and `['jpeg','png']`.
  - Missing, wrongly typed or empty `imageTypes` falls back to the default list. `maxPhotoMb: 'x'` falls back to 10.
  - `BookingStatusKind.fromApi`: all five values map to themselves, and `'weird'` maps to pending.
- [ ] **Step 2: Implement.**
  - `getEnvelope` is `_send(() => _dio.get<Object?>(path, queryParameters: query, options: _options(false)), isPublic: false, unwrap: false)`. A body that is not a map is returned as `{'data': body}`.
  - `imageTypes` reads a `List` of `String`s, lower-cased. When the result is empty, use the default.
- [ ] **Step 3: Verify:** `flutter analyze --no-pub lib test`.

### Task 2: The time ladder and LTR isolates (D6)

**Files:**
- Create: `lib/core/formatting/chat_time_format.dart`
- Test: `test/core/formatting/chat_time_format_test.dart`

**Interfaces:**
- Produces (pure functions: the words come in as arguments, so view models stay string-free):
```dart
String clockTime(DateTime time);  // "09:24", zero-padded, Western digits
String listTime(DateTime time, {required DateTime now, required String locale, required String yesterday});
String dayLabel(DateTime day, {required DateTime now, required String locale, required String today, required String yesterday});
String ltrIsolate(String text);   // '\u2066$text\u2069'
```

- [ ] **Step 1: Write the tests.**
  - Call `await initializeDateFormatting('en'); await initializeDateFormatting('ar');` in `setUpAll`, importing `package:intl/date_symbol_data_local.dart`.
  - `now = DateTime(2026, 3, 12, 15)` (a Thursday).
  - `listTime` cases:
    | time | expected |
    |---|---|
    | 09:24 the same day | `'09:24'` |
    | 00:05 the same day | `'00:05'` |
    | 1 minute in the future (clock skew) | `clockTime` |
    | `DateTime(2026,3,11,23,59)` | the `yesterday` argument |
    | `DateTime(2026,3,9,10)` in EN | `'Mon'` |
    | `DateTime(2026,3,9,10)` in AR | `DateFormat.EEEE('ar').format(DateTime(2026,3,9))`, the full name |
    | `DateTime(2026,3,5)` (7 days) | `'5 Mar'` / `'5 ${DateFormat.MMM('ar').format(…)}'` |
    | `DateTime(2025,12,1)` | `'1 Dec 2025'` |
  - No result contains Arabic-Indic digits (`RegExp('[٠-٩]')`).
  - `dayLabel` returns `today` / `yesterday`, then the same ladder.
  - `ltrIsolate('EVT-2041')` starts with U+2066 and ends with U+2069.
- [ ] **Step 2: Implement.** Day distance uses UTC calendar dates, so DST and time of day cannot shift it:
```dart
int _daysBetween(DateTime earlier, DateTime later) =>
    DateTime.utc(later.year, later.month, later.day)
        .difference(DateTime.utc(earlier.year, earlier.month, earlier.day))
        .inDays;
String _weekday(DateTime t, String locale) =>
    locale == 'ar' ? DateFormat.EEEE('ar').format(t) : DateFormat.E(locale).format(t); // Figma: EN short, AR full
String _dayMonth(DateTime t, String locale) => '${t.day} ${DateFormat.MMM(locale).format(t)}';
String listTime(DateTime t, {required DateTime now, required String locale, required String yesterday}) {
  final int days = _daysBetween(t, now);
  if (days <= 0) return clockTime(t);
  if (days == 1) return yesterday;
  if (days < 7) return _weekday(t, locale);
  if (t.year == now.year) return _dayMonth(t, locale);
  return '${_dayMonth(t, locale)} ${t.year}';
}
```
- [ ] **Step 3: Verify** with analyze.

### Task 3: Messaging and notification models, fixtures, filter, reasons, picked image, icon map

**Files:**
- Create: `lib/core/messaging/models/{chat_person,conversation,chat_message,report_reason}.dart`, `lib/core/messaging/conversation_filter.dart`, `lib/core/messaging/picked_image.dart`, `lib/core/notifications/models/app_notification.dart`, `lib/core/notifications/notification_icon.dart`
- Create fixtures: `test/fixtures/messaging/{conversations_page,conversation_detail,conversation_dispute,messages_page,notifications_page}.json`
- Test: `test/core/messaging/models_test.dart`, `test/core/notifications/notifications_models_test.dart`

**Interfaces:**
- Produces. Field names follow the API, and parsing follows `json_read.dart`:
```dart
enum ChatRole { client, provider, support; static ChatRole fromApi(String?); }       // unknown → client
class ChatPerson { id, name, String? avatarUrl, ChatRole role, bool blocked; factory fromJson; }
enum ConversationKind { direct, support, dispute; static ConversationKind fromApi(String?); } // unknown → direct
class ChatBooking { id, reference, String status, DateTime? eventDate, title, total; factory fromJson; }
enum PreviewKind { text, photo, removed, none }
class ConversationRow {
  id, ConversationKind kind, bool isClosed /* status == 'closed' */, ChatPerson? other,
  String? lastMessage, DateTime? lastMessageAt, int unreadCount, ChatBooking? booking, bool canWrite;
  factory fromJson;
  bool get isGroup => kind != ConversationKind.direct;   // support + dispute: sender labels, no ⋯
  PreviewKind get previewKind; // removed body → removed; non-blank → text; blank + lastMessageAt → photo (D11); else none
}
class ConversationDetail extends ConversationRow {
  List<ChatPerson> participants; bool contactUnmasked; String? disputeId; String? closedReason /* parsed, never shown */; DateTime createdAt;
  factory fromJson;
  ChatPerson? participant(String? userId);
  ChatPerson? get groupProvider; // first participant with role provider — "You, {provider} and Eventor support"
}
enum MessageKind { text, attachment, system; static MessageKind fromApi(String?); } // unknown → text
class ChatMessage {
  static const String removedBody = '[removed by Eventor]';
  id, conversationId, MessageKind kind, String? senderId, bool mine, String body, bool masked,
  String? imageUrl, String? imageLargeUrl, DateTime createdAt;
  factory fromJson;
  bool get isRemoved => body.trim() == removedBody;
  bool get hasImage => imageUrl != null && !isRemoved;
  ChatMessage withImages({String? imageUrl, String? imageLargeUrl}); // fresh signed URLs
}
class MessagePage { List<ChatMessage> items /* oldest first */; bool hasMore; String? nextBefore;
  factory MessagePage.fromEnvelope(Map<String, Object?> body); }
enum ReportReason { inappropriate('inappropriate'), spam('spam'), contactOutside('contact_outside'),
  harassment('harassment'), fake('fake'), other('other'); final String apiValue; }
enum ConversationFilter { all('all'), unread('unread'), booking('booking'); final String apiValue; }
enum ImageProblem { tooLarge, wrongType }
class PickedImage { const PickedImage({required this.name, required this.bytes, required this.extension});
  final String name; final Uint8List bytes; final String extension; // lower-case, no dot
  ImageProblem? validate({required int maxMb, required List<String> types}); }
enum NotificationGroup { today, thisWeek, earlier; static NotificationGroup fromApi(String?); } // 'this_week'; unknown → earlier
class NotificationData { String? conversationId, bookingId, href; factory fromJson(Map<String, Object?>?); } // non-strings ignored
sealed class NotificationTarget { const NotificationTarget(); }
class ChatTarget extends NotificationTarget { final String conversationId; }
class UnsupportedTarget extends NotificationTarget { const UnsupportedTarget(); }
class AppNotification { id, type, title, body, NotificationData data, NotificationGroup group, bool read, DateTime createdAt;
  factory fromJson; NotificationTarget get target; AppNotification copyWith({bool? read}); }
AppIcons notificationIcon(String type); // notification_icon.dart
```

- [ ] **Step 1: Write the fixtures.** Use the hand-written JSON below, shaped exactly like the DTOs in the research notes.

`conversations_page.json`:
```json
{"data": [
  {"id": "c-lumiere", "kind": "direct", "status": "open",
   "other": {"id": "p-lumiere", "name": "Studio Lumière", "avatarUrl": "https://files.example/a.jpg?exp=1&sig=x", "role": "provider", "blocked": false},
   "lastMessage": "Perfect — I'll hold Sat 14 Mar for you.", "lastMessageAt": "2026-03-12T09:24:00.000Z", "unreadCount": 2,
   "booking": {"id": "b-1", "reference": "EVT-000123", "status": "pending", "eventDate": "2026-03-14", "title": "Wedding photo & video coverage", "total": "57000.00"},
   "canWrite": true},
  {"id": "c-dispute", "kind": "dispute", "status": "open",
   "other": {"id": "u-support", "name": "Eventor support", "avatarUrl": null, "role": "support", "blocked": false},
   "lastMessage": "Support: we have both sides' evidence.", "lastMessageAt": "2026-03-02T10:00:00.000Z", "unreadCount": 0,
   "booking": {"id": "b-2", "reference": "EVT-2041", "status": "completed", "eventDate": "2026-02-20", "title": "Engagement photos", "total": "30000.00"},
   "canWrite": true},
  {"id": "c-support", "kind": "support", "status": "open",
   "other": {"id": "u-support", "name": "Eventor support", "avatarUrl": null, "role": "support", "blocked": false},
   "lastMessage": "Hi Amina, how can we help ?", "lastMessageAt": "2026-02-28T08:00:00.000Z", "unreadCount": 0, "booking": null, "canWrite": true},
  {"id": "c-deleted", "kind": "direct", "status": "open", "other": null,
   "lastMessage": "", "lastMessageAt": "2026-01-10T08:00:00.000Z", "unreadCount": 0, "booking": null, "canWrite": false},
  {"id": "c-weird", "kind": "broadcast", "status": "closed",
   "other": {"id": "p-yasmine", "name": "Salle Yasmine", "avatarUrl": null, "role": "robot", "blocked": true},
   "lastMessage": "[removed by Eventor]", "lastMessageAt": null, "unreadCount": 0, "booking": null, "canWrite": false}
], "meta": {"page": 1, "limit": 20, "total": 5, "totalPages": 1}}
```
`conversation_detail.json`: `{"data": { …the c-lumiere row…, "participants": [{"id": "u-me", "name": "Amina Benali", "avatarUrl": null, "role": "client", "blocked": false}, {"id": "p-lumiere", "name": "Studio Lumière", "avatarUrl": null, "role": "provider", "blocked": false}], "contactUnmasked": false, "disputeId": null, "closedReason": null, "createdAt": "2026-03-01T10:00:00.000Z"}}`.

`conversation_dispute.json`: the c-dispute row plus participants u-me (client), p-lumiere (provider) and u-support ("Eventor support", support), `"disputeId": "d-2041"`, `"closedReason": null`, `"contactUnmasked": true`, and a `createdAt`.

`messages_page.json`:
```json
{"data": [
  {"id": "m-1", "conversationId": "c-lumiere", "kind": "system", "senderId": null, "mine": false, "body": "Booking requested · phone numbers stay hidden until the provider accepts.", "masked": false, "imageUrl": null, "imageLargeUrl": null, "createdAt": "2026-03-11T08:55:00.000Z"},
  {"id": "m-2", "conversationId": "c-lumiere", "kind": "text", "senderId": "p-lumiere", "mine": false, "body": "Good morning — I saw your request for 14 March.", "masked": false, "imageUrl": null, "imageLargeUrl": null, "createdAt": "2026-03-12T09:02:00.000Z"},
  {"id": "m-3", "conversationId": "c-lumiere", "kind": "text", "senderId": "u-me", "mine": true, "body": "Full day please. My number is [phone hidden]", "masked": true, "imageUrl": null, "imageLargeUrl": null, "createdAt": "2026-03-12T09:20:00.000Z"},
  {"id": "m-4", "conversationId": "c-lumiere", "kind": "attachment", "senderId": "p-lumiere", "mine": false, "body": "Last month at Salle Yasmine", "masked": false, "imageUrl": "https://files.example/i4.jpg?exp=1&sig=a", "imageLargeUrl": "https://files.example/i4-large.jpg?exp=1&sig=b", "createdAt": "2026-03-12T09:24:00.000Z"},
  {"id": "m-5", "conversationId": "c-lumiere", "kind": "attachment", "senderId": "p-lumiere", "mine": false, "body": "[removed by Eventor]", "masked": false, "imageUrl": null, "imageLargeUrl": null, "createdAt": "2026-03-12T09:30:00.000Z"},
  {"id": "m-6", "conversationId": "c-lumiere", "kind": "sticker", "senderId": "p-lumiere", "mine": false, "body": "hi", "masked": false, "imageUrl": null, "imageLargeUrl": null, "createdAt": "2026-03-12T09:31:00.000Z"}
], "meta": {"limit": 30, "hasMore": true, "nextBefore": "m-1"}}
```
`notifications_page.json`:
```json
{"data": [
  {"id": "n-1", "type": "booking.accepted", "title": "Booking accepted", "body": "Studio Lumière accepted your request for Sat 14 Mar.", "data": {"bookingId": "b-1", "href": "booking/b-1"}, "group": "today", "read": false, "readAt": null, "createdAt": "2026-03-12T09:24:00.000Z"},
  {"id": "n-2", "type": "message.new", "title": "New message", "body": "Salle Yasmine: Yes, the hall is free that weekend.", "data": {"conversationId": "c-yasmine"}, "group": "today", "read": false, "readAt": null, "createdAt": "2026-03-12T08:10:00.000Z"},
  {"id": "n-3", "type": "review.request", "title": "Leave a review", "body": "How was your engagement session with Studio Lumière ?", "data": null, "group": "this_week", "read": true, "readAt": "2026-03-10T10:00:00.000Z", "createdAt": "2026-03-08T10:00:00.000Z"},
  {"id": "n-4", "type": "system.maintenance", "title": "Planned maintenance", "body": "Eventor will be unavailable on Sunday night.", "data": {"href": "https://eventor.dz/status", "conversationId": 42}, "group": "someday", "read": true, "readAt": null, "createdAt": "2026-02-01T10:00:00.000Z"}
], "meta": {"page": 1, "limit": 20, "total": 4, "totalPages": 1}}
```
- [ ] **Step 2: Write the tests.**
  - **Rows:**
    - Every row parses.
    - c-weird: kind falls back to `direct`, role to `client`, `isClosed` is true, and `previewKind` is `removed`.
    - c-deleted: `other == null` and `previewKind == photo`.
    - c-lumiere: `previewKind == text`, the booking parses with `eventDate == DateTime(2026,3,14)`, and `isGroup` is false.
    - c-dispute and c-support: `isGroup` is true.
    - A row with a blank `lastMessage` and a null `lastMessageAt` gives `none`.
  - **Details:**
    - The detail's `participant('p-lumiere')?.name` is `'Studio Lumière'`.
    - The dispute's `groupProvider?.name` is `'Studio Lumière'` and its `disputeId` is `'d-2041'`.
  - **Messages:**
    - `MessagePage.fromEnvelope` gives 6 items oldest first, `hasMore` true and `nextBefore` `'m-1'`.
    - A missing `meta` gives `hasMore false` and `nextBefore null`.
    - m-5: `isRemoved` true and `hasImage` false. m-4: `hasImage` true. m-3: `masked` true. m-6: kind `text`. m-1: `senderId` null.
  - **`PickedImage.validate(maxMb: 10, types: ['jpeg','png','webp','heic'])`:**
    - `jpg` is normalised to `jpeg` and passes. Upper-case `PNG` passes.
    - `gif` gives `wrongType`, and so does an empty extension.
    - Exactly 10 × 1024 × 1024 bytes passes. One byte more gives `tooLarge`.
    - A wrong type is reported before the size.
  - **Notifications:**
    - n-1's target is `UnsupportedTarget`. n-2's target is `ChatTarget('c-yasmine')`.
    - n-3 has `data == null`, so its fields are all null. n-4 ignores the numeric `conversationId`, so its target is unsupported.
    - n-4's group is `earlier` and n-3's is `thisWeek`. `copyWith(read: true)` keeps every other field.
  - **`notificationIcon`:**
    | type | icon |
    |---|---|
    | `booking.accepted` | check |
    | `booking.declined`, `booking.cancelled` | close |
    | `message.new`, `dispute.update` | message |
    | `booking.reminder`, `booking.reschedule_proposed`, `booking.waiting` | calendar |
    | `review.request`, `review.reply` | starFilled |
    | `booking.created`, `''`, `weird` | bell |
- [ ] **Step 3: Implement.**
  - `notificationIcon`: split on the first `.` into `area` and `event`, then check in order:
    1. exact `booking.accepted`
    2. exact `booking.declined` / `booking.cancelled`
    3. `area` is `message` or `dispute`
    4. `event` is `reminder` or `waiting`, or starts with `reschedule`
    5. `area` is `review`
    6. otherwise the bell
  - `ChatBooking.eventDate` uses `readDateOrNull`.
- [ ] **Step 4: Verify** with analyze.

### Task 4: `ApiMessagingRepository` and `ApiNotificationsRepository`

**Files:**
- Create: `lib/core/messaging/messaging_repository.dart`, `lib/core/notifications/notifications_repository.dart`
- Test: `test/core/messaging/api_messaging_repository_test.dart`, `test/core/notifications/api_notifications_repository_test.dart` (ScriptedAdapter + fixtures)

**Interfaces:**
- Consumes: `ApiClient.getPage/getEnvelope/get/post/upload` (Task 1), models (Task 3).
- Produces:
```dart
abstract interface class MessagingRepository {
  Future<ApiPage<ConversationRow>> conversations({ConversationFilter filter = ConversationFilter.all, String? q, int page = 1}); // limit 20
  Future<ConversationDetail> conversation(String id);
  Future<MessagePage> messages(String conversationId, {String? before});        // limit omitted → 30
  Future<ChatMessage> sendText(String conversationId, String body);
  Future<ChatMessage> sendPhoto(String conversationId, PickedImage image, {String? caption});
  Future<ChatMessage> sendDisputeText(String disputeId, String body);
  Future<ConversationDetail> start(String userId, String body);
  Future<void> markRead(String conversationId);
  Future<bool> reportMessage(String messageId, ReportReason reason, String? note);  // → created
  Future<bool> reportUser(String userId, ReportReason reason, String? note);        // → created
  Future<ConversationRow?> findWith(String userId, String name);
}
class ApiMessagingRepository implements MessagingRepository { ApiMessagingRepository(this._api); }

abstract interface class NotificationsRepository {
  Future<ApiPage<AppNotification>> list({int page = 1});        // limit 20
  Future<int> markRead(List<String> ids);                       // → new unread count
  Future<int> markAllRead();                                    // → new unread count
  Future<({int notifications, int conversations})> counts();   // GET /app/me
}
class ApiNotificationsRepository implements NotificationsRepository { ApiNotificationsRepository(this._api); }
```

- [ ] **Step 1: Write the tests.** Each one asserts the path, method, query or body, and the parsed result.
  - `conversations()` sends `GET /app/conversations?page=1&limit=20` with no `filter` and no `q`.
  - `conversations(filter: unread, q: '  studio ', page: 2)` sends `filter=unread&q=studio&page=2`. A blank `q` is never sent.
  - `conversation('c-1')` hits `GET /app/conversations/c-1`.
  - `messages('c-1', before: 'm-9')` sends `GET …/messages?before=m-9` with no `limit`, and parses the page.
  - `sendText` posts `{body}`.
  - `sendPhoto`:
    - It posts multipart to `/app/conversations/c-1/messages` with a `file` part whose filename is `image.name`, and a `body` field only when the caption is non-blank. Read the `FormData` from `request.data`.
    - It parses the returned attachment message.
  - `sendDisputeText('d-2041', 'x')` posts `/app/disputes/d-2041/messages` with `{body: 'x'}`.
  - `start('p-1', 'Hello')` posts `/app/conversations` with exactly `{userId, body}` and returns the detail.
  - `markRead` posts to `/app/conversations/c-1/read` with no body.
  - `reportMessage` posts `/app/messages/m-4/report` with `{reason: 'contact_outside'}`, sends `note` only when it is non-blank after trimming, and returns `created`.
  - `reportUser` posts `/app/reports` with `{targetType: 'user', targetId, reason}`.
  - `findWith`:
    - `findWith('p-yasmine', 'Salle Yasmine')` queries `q=Salle Yasmine` and returns the row whose `other.id` matches.
    - A name match with a different id returns `null`.
    - A dispute row with the same `other.id` is not returned (direct only).
    - A blank name returns `null` without a request.
  - Errors:
    - A 409 `CONVERSATION_CLOSED` on send and a 403 `CONVERSATION_CLOSED` on send both surface as `ApiFailure` with that code.
    - A 403 `NOT_A_PARTICIPANT` on `conversation` does the same.
  - Notifications:
    - `list(page: 2)` sends `GET /app/me/notifications?page=2&limit=20`.
    - `markRead(['n-1'])` posts `/app/me/notifications/read` with `{ids: ['n-1']}` and returns `unread`.
    - `markAllRead` posts `{all: true}`.
    - `counts()` reads `unreadNotifications` / `unreadConversations` from `GET /app/me`, and a missing field reads as 0.
- [ ] **Step 2: Implement.**
  - `sendPhoto` uses `_api.upload(path, form: () => FormData.fromMap({'file': MultipartFile.fromBytes(image.bytes, filename: image.name), if (caption?.trim().isNotEmpty ?? false) 'body': caption!.trim()}))`. The builder closure matters because a retry after a token refresh has to rebuild the form.
  - Do not send `sort`: the API ignores it.
- [ ] **Step 3: Verify** with analyze.

### Task 5: The 15 poller — `ChatUpdates` / `TimerChatUpdates`

**Files:**
- Create: `lib/core/messaging/chat_poller.dart`
- Test: `test/core/messaging/chat_poller_test.dart` (use `testWidgets` so timers run on the fake clock; there is no fake_async dependency)

**Interfaces:**
- Produces:
```dart
abstract interface class ChatUpdates {
  void start(Future<void> Function() onTick);
  void pause();
  void resume();   // ticks at once, then every interval
  void stop();     // final; also releases the lifecycle listener
}
class TimerChatUpdates implements ChatUpdates {
  TimerChatUpdates({this.interval = const Duration(seconds: 5), this.followAppLifecycle = true});
}
```
- The class comment explains decision 1: this is polling because the socket's auth and payloads are undocumented, and a Socket.IO implementation of `ChatUpdates` replaces it without touching 15.

- [ ] **Step 1: Write the tests.** Each is `testWidgets` with a `pumpWidget(const SizedBox())` so the binding exists.
  - `start`, then pumping 5 s gives 1 tick, and 15 s gives 3.
  - `pause` stops ticks. `resume` ticks immediately and then every 5 s.
  - `stop` stops forever, and a later `resume` does nothing.
  - A tick that takes 12 s (onTick awaits a Completer) never overlaps: after 15 s there has still been one call, until the completer finishes.
  - A throwing tick is swallowed and ticking continues.
  - With `followAppLifecycle: true`: `tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden)` stops the ticks, and returning to `resumed` ticks again right away (Review Focus 2).
- [ ] **Step 2: Implement.**
  - `Timer.periodic` plus an `_inFlight` flag.
  - An `AppLifecycleListener(onHide: pause, onShow: resume)` is created in `start` when `followAppLifecycle` is set, and disposed in `stop`.
  - `resume` is ignored unless the poller is running and paused.
- [ ] **Step 3: Verify** with analyze.

### Task 6: Mock messaging backend, wiring, and test fakes

**Files:**
- Create: `lib/mock/mock_messaging_data.dart` (seed builders), `lib/mock/mock_messaging.dart` (`MockMessagingStore`, `MockMessagingRepository`, `MockNotificationsRepository`)
- Modify: `lib/mock/mock_catalog.dart` (`MockCatalogRepository` takes an optional `MockMessagingStore? messaging`; `home()` overrides the two counts from it)
- Modify: `lib/app/app_services.dart` (+`messaging`, `notifications` fields; `ShellBadges()` is unchanged here, and Task 7 gives it the repository), `lib/app/eventor_app.dart` (`Provider<MessagingRepository>`, `Provider<NotificationsRepository>`)
- Modify: `test/support/fakes.dart` (+`FakeMessagingRepository`, `FakeNotificationsRepository`, `ManualChatUpdates`), `test/support/test_app.dart` (build and pass them; `TestApp.messaging`, `TestApp.notifications`)
- Test: `test/mock/mock_messaging_test.dart`

**Interfaces:**
- Consumes: `MockBackend.requireSession()`, `MockBackend.now`, `MockBackend.delay()`, the catalog provider ids in `mock_catalog_data.dart`, `AppConfig.maxPhotoMb`.
- Produces:
```dart
class MockMessagingStore {
  MockMessagingStore(this._backend, {this.replyDelay = const Duration(seconds: 4), required String Function() languageCode});
  // Per signed-in account email, seeded on first access, kept in memory only (a restart re-seeds — say so in the class comment).
  int unreadConversations();  int unreadNotifications();
}
class MockMessagingRepository implements MessagingRepository { MockMessagingRepository(MockMessagingStore store, MockBackend backend); }
class MockNotificationsRepository implements NotificationsRepository { MockNotificationsRepository(MockMessagingStore store, MockBackend backend); }
// fakes.dart
class FakeMessagingRepository implements MessagingRepository {
  final List<String> calls;                       // 'conversations:all:null:1', 'messages:c-1:null', 'sendText:c-1:hi', 'sendPhoto:c-1:a.jpg:cap',
                                                  // 'sendDisputeText:d-2041:hi', 'start:p-1:hi', 'markRead:c-1', 'reportMessage:m-4:spam:null',
                                                  // 'reportUser:p-1:spam:note', 'findWith:p-1:Studio', 'conversation:c-1'
  List<ConversationRow> rows;                     // from conversations_page.json; filtered + paged 20
  Map<String, ConversationDetail> details;        // c-lumiere, c-dispute from fixtures
  Map<String, List<ChatMessage>> threads;         // oldest first; messages() pages 30 from the newest with a before-cursor
  bool reportCreated = true;
  Failure? failNext; Failure? loadError; Failure? sendError; Failure? startError; Failure? markReadError; Failure? findError;
  Completer<void>? gate;       // every call waits on it
  Completer<void>? sendGate;   // only sends wait on it
}
class FakeNotificationsRepository implements NotificationsRepository {
  final List<String> calls; List<AppNotification> items; ({int notifications, int conversations}) countsResult = (notifications: 2, conversations: 1);
  Failure? failNext; Completer<void>? gate;
}
class ManualChatUpdates implements ChatUpdates {
  Future<void> Function()? onTick; bool started = false, stopped = false; int pauses = 0, resumes = 0;
  Future<void> tick() => onTick?.call() ?? Future<void>.value();
}
```

Mock data (`mock_messaging_data.dart`) is built relative to `backend.now`, so the D6 ladder shows Today, Yesterday, a weekday and dates. The `other.id` values are **catalog provider ids**, so "View profile", the D4 reply line and `findWith` from 12/13 all work.

| id | kind / other | state | last message / when | unread |
|---|---|---|---|---|
| `mock-chat-lumiere` | direct · Studio Lumière `3552815d-6aca-43fc-ace8-0409ee3a762e` | booking `EVT-000123` pending, event in 50 days, "Wedding photo & video coverage", "57000.00"; thread: the Figma 15 lines (2 received, 1 sent **masked** "Full day please. My number is [phone hidden]", 1 received **photo** `asset:assets/mock/photos/pexels-salles-des-fetes-2.webp` with caption "Last month at Salle Yasmine"), a **system** pill "Booking requested · phone numbers stay hidden until the provider accepts.", plus 40 older generated lines over the previous 20 days (enough to page older) | "Perfect — I'll hold Sat 14 Mar for you." · now − 20 min | 2 |
| `mock-chat-yasmine` | direct · Salle Yasmine `c62532f4-6fa9-4752-9f82-cdbea4b0dd07` | contains one **removed** message (`[removed by Eventor]`) | "Yes, the hall is free that weekend." · yesterday | 0 |
| `mock-chat-djazair` | direct · Traiteur El Djazair `6db77516-86a1-49ef-8b57-2c610c4e90ca` (Figma draws "Traiteur El Baraka"; the mock uses the catalog provider so 13 opens) | — | "Can you confirm the guest count ?" · 3 days ago | 1 |
| `mock-chat-dispute` | dispute · other = support `mock-support` "Eventor support"; participants me, Studio Lumière (provider), support; `disputeId` `mock-dispute-2041`; booking ref `EVT-2041` completed | system "Dispute opened · Eventor support joined this conversation", then provider, support, provider, me — so sender labels show runs | "Support: we have both sides' evidence." · 12 days ago | 0 |
| `mock-chat-support` | support · "Eventor support" | — | "Hi Amina, how can we help ?" · 14 days ago | 0 |
| `mock-chat-oliviers` | direct · Salle Les Oliviers `fe9734e0-24c4-4640-ae2a-d07220ed3f5a` | **closed**: `status: closed`, `canWrite: false`, `closedReason: 'harassment'` | older | 0 |
| `mock-chat-bahia` | direct · Salle El Bahia `94305376-287a-4966-9546-8c3afd247e88` | **other blocked**: `other.blocked: true` | older | 0 |
| `mock-chat-deleted` | direct · `other: null` | **deleted account**, `canWrite: false` | older | 0 |
| `mock-chat-filler-1…17` | direct · the 7 remaining catalog providers, then made-up businesses `mock-filler-provider-N` (their 13 shows "no longer available", which is fine for filler) | — | 20–90 days ago | 0 |

That makes 25 rows: two pages of 20.

Notifications: the 8 Figma 16 rows, with EN copy from the Figma table in the research notes (and AR when `languageCode() == 'ar'`), types `booking.accepted`, `message.new` (`data.conversationId: 'mock-chat-yasmine'`), `booking.waiting`, `review.request`, `booking.declined`, `booking.reschedule_proposed`, `dispute.update`, `review.reply`. Their `createdAt` values are today, today, 3 days ago, 4 days ago, then 10/13/15/17 days ago, and `group` is derived from those dates. The first two are unread.

Behaviour, matching the live API:
- **List:** `filter` and `q` (case-insensitive over `other.name`, or "Eventor support" for group rows) apply, sorted by `lastMessageAt` desc, with paging meta.
- **Messages:** the newest 30, with the `before` cursor and `{limit, hasMore, nextBefore}`.
- **Unknown ids:** an unknown conversation is 404 `CONVERSATION_NOT_FOUND`. An unknown `before` is 404 `MESSAGE_NOT_FOUND`.
- **Sending:**
  - To a closed chat: 409 `CONVERSATION_CLOSED`. To a blocked or deleted other: 403 `CONVERSATION_READ_ONLY`.
  - A photo over `maxPhotoMb` is 413 `FILE_TOO_LARGE`. A type outside `imageTypes` is 415 `FILE_TYPE_NOT_ALLOWED`.
  - A sent photo is stored as a `data:image/<ext>;base64,…` URL (Task 8 teaches `AppNetworkImage` to show it).
  - A text matching `RegExp(r'\+?\d[\d\s]{7,}\d')` has the match replaced by `[phone hidden]` and `masked: true`, unless `contactUnmasked`.
  - `lastMessage` and `lastMessageAt` are updated.
- **Mock reply (D3):**
  - The first send in a conversation during this run schedules one reply after `replyDelay`, for direct chats only.
  - The reply is EN "Thanks for your message — I'll get back to you shortly." or AR "شكرًا على رسالتك — سأعود إليك قريبًا.".
  - It increments that chat's `unreadCount`.
- **`start(userId, body)`:**
  - An existing direct pair appends to that chat (idempotent) and returns its detail.
  - A `userId` that is not a catalog provider id and not an existing `other.id` is 404 `USER_NOT_FOUND`.
  - Otherwise it creates a new direct chat, and the first send triggers the reply as above.
- **Reads and reports:**
  - `markRead` sets `unreadCount` to 0.
  - `reportMessage` / `reportUser` return `created: false` for a repeated `(targetType, targetId)`.
  - Notifications `markRead` / `markAllRead` return the new unread count, and `counts()` reads the store.
- **Every call:** `await backend.delay()` and `backend.requireSession()`.

- [ ] **Step 1: Write the tests** (`MockBackend.load(latency: Duration.zero, now: () => DateTime(2026, 3, 12, 15))`, signed in as `client@eventor.test`; the store uses `replyDelay: Duration(milliseconds: 10)`).
  - The list has 25 rows over 2 pages, the first row is Studio Lumière with 2 unread, and every drawn state is present: closed, blocked other, `other == null`, dispute, support.
  - `filter: unread` gives exactly Lumière and Djazair. `filter: booking` gives the rows with a booking. `q: 'yasm'` gives Salle Yasmine.
  - Lumière's newest page has 30 items with `hasMore: true`, and `before: nextBefore` returns the older ones with no overlap.
  - Dispute messages carry three different sender ids.
  - Sending to Oliviers throws `CONVERSATION_CLOSED`, and to Bahia `CONVERSATION_READ_ONLY`.
  - `sendText` with `0555 12 34 56` is stored masked.
  - `start` with the Lumière provider id appends to `mock-chat-lumiere` (no new row). `start` with the Douceurs d'Oran id `e1ad2116-c6a2-4d3f-a9ea-c4168694f925` creates a chat. `start('nope', …)` throws `USER_NOT_FOUND`.
  - **The reply arrives:** send in Yasmine, wait 20 ms, and the newest page ends with a received message while `unreadCount` is 1. A second send schedules no second reply.
  - After `markRead` on Lumière, `unreadConversations()` drops from 2 to 1.
  - Notifications: 8 items, with `counts().notifications == 2`. `markRead(['<first id>'])` returns 1 and `markAllRead()` returns 0.
  - A repeated report returns `false`.
  - Signed out, every call throws `SessionExpiredFailure`.
  - `MockCatalogRepository(…, messaging: store).home()` reports the store's two counts.
- [ ] **Step 2: Implement** the data, store and repositories. Wire them in `AppServices`:
  - Mock builds: `MockMessagingStore(mock, languageCode: languageCode)` is shared by both mock repositories and the mock catalog.
  - Live builds use `ApiMessagingRepository(api)` / `ApiNotificationsRepository(api)`.
  - Provide both repositories in `EventorApp`.
- [ ] **Step 3: Write the fakes** in `fakes.dart` with the semantics above.
  - `FakeMessagingRepository.sendText` returns `ChatMessage(id: 'sent-<n>', mine: true, createdAt: DateTime(2026,3,12,15,<n>), …)` and appends it to the thread.
  - `start` creates `details['c-new']` from the Lumière detail with `id: 'c-new'` and a one-message thread.
  - `findWith` returns the first direct row whose `other?.id == userId`.
- [ ] **Step 4:** Update `buildTestApp` to accept the two fakes, add `messaging`/`notifications` to `AppServices`, and fix every `AppServices(...)` call site. Then verify with analyze.

### Task 7: `ShellBadges`, resume refresh, the Home bell, routes and redirect

**Files:**
- Modify: `lib/features/shell/shell_badges.dart`, `lib/features/shell/view/client_shell.dart`
- Modify: `lib/features/home/view_model/home_view_model.dart` (`_apply` feeds both counts), `lib/features/home/view/home_view.dart` (bell → `context.push(AppRoutes.notifications)`, `hasUnread` from `context.watch<ShellBadges>().unreadNotifications > 0`)
- Create: `lib/core/widgets/molecules/notification_bell.dart` (the bell + dot moved out of `HomeHeader`, which now uses it)
- Modify: `lib/core/routing/app_routes.dart` (constants + `isClientOnly`)
- Modify: `lib/app/app_services.dart` (`ShellBadges(notifications: notifications)`)
- Test: `test/features/shell/shell_badges_test.dart` (new), `test/features/shell/client_shell_test.dart`, `test/features/home/home_view_model_test.dart`, `test/features/home/home_view_test.dart`, `test/core/routing/app_routes_test.dart`, `test/core/routing/app_redirect_test.dart`

**Interfaces:**
- Produces:
```dart
class ShellBadges extends ChangeNotifier {
  ShellBadges({NotificationsRepository? notifications});
  int get unreadConversations; int get unreadNotifications;
  void update({int? unreadConversations, int? unreadNotifications}); // notifies only on change
  Future<void> refresh();   // counts() → update; failures ignored (a badge is not worth an error); no-op without a repository
  void clear();             // both to 0
}
class NotificationBell extends StatelessWidget {
  const NotificationBell({required this.hasUnread, required this.onTap, super.key});
} // 48 touch target, bell on-brand-accent, 8 dot statusDeclined; semantics homeNotificationsUnread / homeNotificationsLabel
// AppRoutes
static const String conversations = '/conversations';
static const String chatDraft = '/conversations/new';
static const String notifications = '/notifications';
static String chatFor(String id) => '$conversations/$id';
static String chatDraftFor({required String userId, required String name}); // Uri with user=, name=
// isClientOnly additionally: path.startsWith('$conversations/') || path == notifications
```
- `ClientShell`'s state creates an `AppLifecycleListener(onResume: () => context.read<ShellBadges>().refresh())` in `initState` and disposes it.

- [ ] **Step 1: Write the tests.**
  - **`ShellBadges`:**
    - `update` with only one field keeps the other.
    - There is no notify when nothing changed.
    - `refresh` applies `counts()` from `FakeNotificationsRepository`, and a throwing `counts` leaves the values and does not throw.
    - `clear` zeroes both.
  - **HomeViewModel:** after `load`, the badges hold the feed's `unreadNotifications` and `unreadConversations`.
  - **Home view (EN):**
    - The dot shows when `badges.unreadNotifications > 0` and hides after `badges.update(unreadNotifications: 0)`.
    - The bell pushes `/notifications`. The screen arrives in Task 15, so until then the router shows `UnknownRouteView`. Assert the location instead: `app.services.router.routerDelegate.currentConfiguration.uri.path == '/notifications'`. That assertion stays true once Task 15 lands.
  - **Client shell:** `tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed)` after `paused` calls `counts()` once, visible in `FakeNotificationsRepository.calls`.
  - **Routes:**
    - `chatDraftFor(userId: 'p 1', name: 'Salle & Co')` round-trips through `Uri.parse(...).queryParameters`.
    - `isClientOnly('/conversations/x')`, `('/conversations/new')` and `('/notifications')` are all true.
    - A signed-in provider deep-linking to `/conversations/x` or `/notifications` is redirected to `/provider`.
- [ ] **Step 2: Implement.** Then verify with analyze.

### Task 8: Shared widgets — icons, avatar sizes, images, offline banner, divided card, conversation avatar

**Files:**
- Create: `assets/icons/image.svg`, `assets/icons/clock.svg`; modify `lib/core/widgets/atoms/app_icon.dart` (`image('image')`, `clock('clock')`)
- Modify: `lib/core/constants/ui_helpers.dart` (`AppSizes.avatarList = 48`, `AppSizes.avatarChatHeader = 36`), `lib/core/widgets/atoms/app_avatar.dart` (`AppAvatarSize.list`, `AppAvatarSize.chatHeader`, placeholder icon sizes 24 / 20)
- Modify: `lib/core/widgets/atoms/app_network_image.dart` (`data:` URIs; `errorBuilder`)
- Create: `lib/core/widgets/molecules/offline_banner.dart`, `lib/core/widgets/molecules/conversation_avatar.dart`, `lib/core/widgets/organisms/divided_card.dart`
- ARB: `offlineTitle` (spec §6), plus `offlineRetry` "Retry" / "إعادة المحاولة" ("The action on the offline banner.")
- Modify: `lib/features/gallery/view/gallery_view.dart` (a "Messaging" section: avatar kinds, offline banner EN)
- Test: `test/core/widgets/messaging_widgets_test.dart`

The icons are stroke SVGs. `AppIcon` recolours with `srcIn`, so a stroke works like the existing fills.
```xml
<!-- image.svg -->
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="3" width="18" height="18" rx="2" stroke="#6B6B75" stroke-width="2"/><circle cx="9" cy="9" r="2" stroke="#6B6B75" stroke-width="2"/><path d="M21 15L16 10L5 21" stroke="#6B6B75" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
<!-- clock.svg -->
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="9" stroke="#6B6B75" stroke-width="2"/><path d="M12 7V12L15 14" stroke="#6B6B75" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
```

**Interfaces:**
- Produces:
```dart
// AppNetworkImage
final Widget Function()? errorBuilder; // replaces the placeholder when a load fails (15's tap-to-reload tile, D15)
// 'data:' → Image.memory(UriData.parse(url).contentAsBytes()) — the mock's sent photos
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.body, required this.onRetry, super.key}); // title = l10n.offlineTitle
} // Row [alertTriangle 20 iconAccent, Expanded(Column[title Label/L primary, body Caption secondary], gap 2), Retry Label/M brand];
  // r12, bgAccentSubtle, 1px borderAccent, padding 12/16, gap 12. A Row in ambient direction = the corrected AR order.
class DividedCard extends StatelessWidget {
  const DividedCard({required this.children, super.key});
} // r16, bgSurface, 1px borderDefault, AppElevation.sm, clipped; 1px full-bleed borderDefault dividers between children
class ConversationAvatar extends StatelessWidget {
  const ConversationAvatar({required this.kind, required this.other, required this.size, super.key});
  final ConversationKind kind; final ChatPerson? other; final AppAvatarSize size;
} // support → AppAvatar(photoUrl: 'asset:assets/images/logo.png'); dispute → AppAvatar(name: '!'); other == null →
  // AppAvatar with no name (person glyph); else AppAvatar(name: other.name, photoUrl: other.avatarUrl)
```
- `AppAvatar` with `name: '!'` already renders "!" through `initialsOf`. For `other == null`, add `AppAvatar.anonymous({size})`, which draws the `_PhotoPlaceholder`.

- [ ] **Step 1: Write the tests.**
  - `AppIcons.image` and `AppIcons.clock` load (the existing icon test pattern).
  - `AppAvatarSize.list.diameter == 48` and `chatHeader == 36`.
  - `AppNetworkImage` shows `Image.memory` for a tiny `data:image/png;base64,…` PNG.
  - An `errorBuilder` is used when an asset URL fails (`asset:assets/nope.png`).
  - `OfflineBanner` in AR: the icon's centre x > the title's x > the Retry x. Tapping Retry calls `onRetry`.
  - `DividedCard` with 3 children draws 2 dividers.
  - `ConversationAvatar`: support shows the logo asset, dispute shows "!", null shows the person glyph, and a provider shows the initials "SL".
- [ ] **Step 2: Implement, add the ARB keys, run `flutter gen-l10n`, add the gallery section.** Then verify with analyze.

### Task 9: `MessagesViewModel` (14)

**Files:**
- Create: `lib/features/messages/view_model/messages_view_model.dart`
- Test: `test/features/messages/messages_view_model_test.dart`

**Interfaces:**
- Consumes: `MessagingRepository.conversations`, `ShellBadges.refresh`, `BaseViewModel.setFailure`.
- Produces:
```dart
enum MessagesEmpty { none, all, unread, bookings, search }
class MessagesViewModel extends BaseViewModel {
  MessagesViewModel({required MessagingRepository messaging, required ShellBadges badges,
    Duration debounce = const Duration(milliseconds: 300)}); // loads on creation
  ConversationFilter get filter; String get query;          // the applied, trimmed query
  List<ConversationRow> get items; bool get isFirstLoad; bool get hasMore; bool get isLoadingMore; bool get loadMoreFailed;
  bool get isOffline;       // the last load/refresh hit NetworkFailure while rows were showing → banner, rows kept
  MessagesEmpty get empty;  // none while loading, erroring, or with rows
  void setFilter(ConversationFilter filter);  // immediate reload (flushes a pending search)
  void setQuery(String text);                 // debounced; trimmed; blank → no q
  Future<void> load(); Future<void> loadMore(); Future<Failure?> refresh();
}
```
- The generation guard: every `load` and `refresh` takes `++_generation`. A response or failure whose generation is stale is dropped. `loadMore` is ignored while a load runs and drops a page that arrives after a newer load started.
- Every successful load or refresh also calls `badges.refresh()` without awaiting it.

- [ ] **Step 1: Write the tests** with `FakeMessagingRepository`. The debounce is `Duration.zero` except in the debounce test.
  - The first load shows the rows, `isFirstLoad` goes true then false, and `empty == none`.
  - `setFilter(unread)` calls `conversations:unread:null:1`.
  - **Debounce:** with 300 ms, `setQuery('st'); setQuery('stu')` within 100 ms gives one call with `q=stu` after the wait. `setQuery('   ')` sends `q` null (Review Focus 5).
  - **Generation guard:** gate the first call, `setFilter(unread)` while it hangs, then release. The final items are the unread set, and the first response is discarded (Review Focus 5).
  - `loadMore` appends page 2 and stops at `hasMore == false`. A failure sets `loadMoreFailed` and keeps the rows.
  - **Refresh:** a refresh `NetworkFailure` with rows gives `isOffline` true and keeps the rows. A later success clears it.
  - A first load failing with nothing cached gives `hasError`, `failure` set and `empty == none`.
  - **Empty variants:** no rows gives `all`; `unread` gives `unread`; `booking` gives `bookings`; a non-blank query gives `search`, whatever the filter.
  - A successful load calls `badges.refresh()`, visible as `counts` on `FakeNotificationsRepository`.
- [ ] **Step 2: Implement.** Then verify with analyze.

### Task 10: `MessagesView` (14) and the Messages tab

**Files:**
- Create: `lib/features/messages/view/messages_view.dart`, `view/widgets/messages_header.dart`, `view/widgets/conversation_row.dart`, `view/widgets/messages_skeleton.dart`
- Modify: `lib/core/routing/app_router.dart` (branch 3 → `_withViewModel<MessagesViewModel>(… , const MessagesView())`)
- ARB (spec §6 copy): `messagesTitle`, `messagesSearchHint`, `messagesFilterAll`, `messagesFilterUnread`, `messagesFilterBookings`, `messagesEmptyTitle`, `messagesEmptyBody`, `messagesEmptyAction`, `messagesUnreadEmpty`, `messagesBookingsEmpty`, `messagesNoMatch` ({query}), `offlineMessagesBody`, `chatDispute` ({reference}), `chatDisputeNoRef`, `chatSupport`, `chatDeletedAccount`, `chatPhoto`, `chatRemoved`, `chatYesterday`. Plus `messagesUnreadCount` ({count}): EN `{count, plural, =1{1 unread message} other{{count} unread messages}}`, AR `{count, plural, =0{لا رسائل غير مقروءة} =1{رسالة واحدة غير مقروءة} =2{رسالتان غير مقروءتين} few{{count} رسائل غير مقروءة} many{{count} رسالة غير مقروءة} other{{count} رسالة غير مقروءة}}` ("Screen-reader label for a conversation's unread badge.")
- Test: `test/features/messages/messages_view_test.dart`

**Layout** (Figma `579:1135` / `585:1186`, offline `1752:7252` / `1756:7563`):
- **Header:** `bgBrand`. Padding top `MediaQuery.paddingOf(context).top + AppSpacing.md`, then 16/20/16, gap 16.
  - Row: "Messages" (`headlineMedium`, textOnBrand) and `NotificationBell` → `context.push(AppRoutes.notifications)`, with the dot from the badges.
  - Below it, a search `TextField`: 48 high, r12, `bgSurface`, search icon 20, hint `messagesSearchHint`, `onChanged: vm.setQuery`.
- **Chips:** padding 16/16/4/16, gap 8, `AppChip` × 3, horizontally scrollable.
- **List:** `RefreshIndicator(onRefresh: vm.refresh)` around a `CustomScrollView` with `ScrollToTopOnReselect(branch: 3)`. Padding 16. The offline banner (gap 12) goes above a `DividedCard` of rows, and infinite scroll calls `loadMore` within 300 px of the end.
  - A `loadMoreFailed` foot row: `stateRetry` text button.
  - First load: a `DividedCard` of 3 skeleton rows, 68 high (48 circle plus two lines).
  - Error with nothing cached: `StateCard.error(onRetry: vm.load)`.
  - Empty states use `StateCard.empty`, with icon `AppIcons.message`:
    - `all`: title/body `messagesEmpty*`, action "Find a provider" → `context.go(AppRoutes.search)`.
    - `unread`: `messagesUnreadEmpty`.
    - `bookings`: `messagesBookingsEmpty`.
    - `search`: `messagesNoMatch(vm.query)`. The query is the user's own text, so it is passed raw with no isolate.
- **`ConversationRow`:** `InkWell`, padding 14/16, gap 12.
  - `ConversationAvatar(size: list)`.
  - Title column:
    - The name (`titleSmall`, one line, ellipsis) is `other.name`, or `chatSupport` for support, or `chatDispute(ltrIsolate(booking.reference))` / `chatDisputeNoRef` for a dispute, or `chatDeletedAccount` when `other == null`.
    - The preview (`bodySmall`, one line, ellipsis; primary when unread, secondary when read) is keyed on `previewKind`: `text` gives `lastMessage`, `photo` gives the `image` glyph 16 plus `chatPhoto`, `removed` gives `chatRemoved`, and `none` gives an empty line.
  - Meta column, end-aligned, gap 6:
    - Time: `listTime(lastMessageAt, now: DateTime.now(), locale, yesterday: l10n.chatYesterday)` in `labelSmall`, brand when unread, as an LTR `Text`.
    - Below it, the count badge (20 circle, brand, `labelMedium` on-brand, LTR digits, semantics `messagesUnreadCount`) or a 20 spacer.
- **Tap:** `await context.push(AppRoutes.chatFor(row.id)); vm.refresh();`.
- The view is a `StatefulWidget`. It owns the search `TextEditingController` and the scroll controller, and has an `AppLifecycleListener(onResume: vm.refresh)`.

- [ ] **Step 1: Write the tests.** Run them EN and AR through `buildTestApp` + `startAt(tester, app, '/messages')` as a signed-in client, with the fakes.
  - The skeleton shows, then the rows.
  - The Lumière row has its unread count and a primary-colour preview. The support row reads `chatSupport`. The dispute row reads "Dispute · EVT-2041" in EN and contains U+2066 in AR. The deleted row reads "Deleted account" with a "Photo" preview.
  - In AR, the row's time `Text` is LTR, and the badge is at a smaller x than the name.
  - Tapping a chip reloads with that filter. Typing "yas" and pumping 300 ms calls with `q=yas`.
  - Empty variants: the unread filter on an empty fake shows `messagesUnreadEmpty`, and a search shows `messagesNoMatch`.
  - With rows showing, a pull-to-refresh `NetworkFailure` shows the offline banner above the list, and Retry calls refresh.
  - The bell pushes `/notifications`.
  - A row tap pushes `/conversations/c-lumiere`, and popping back triggers another `conversations:` call.
  - Re-tapping the Messages tab scrolls to the top (the existing `TabReselect` pattern from the Home tests).
- [ ] **Step 2: Implement, add the ARB keys, run gen-l10n.** Then verify with analyze.

### Task 11: `ChatViewModel` — reading (load, thread, older pages, poll merge, read marks, states)

**Files:**
- Create: `lib/features/chat/view_model/chat_thread.dart` (thread item types + the pure builder), `lib/features/chat/view_model/chat_view_model.dart` (the reading half)
- Test: `test/features/chat/chat_thread_test.dart`, `test/features/chat/chat_view_model_read_test.dart`

**Interfaces:**
- Consumes: `MessagingRepository`, `CatalogRepository.provider` (D4), `ShellBadges`, `AppConfig`, `ChatUpdates`.
- Produces:
```dart
// chat_thread.dart
enum EntryState { sent, sending, failed }
class ChatEntry { const ChatEntry({required this.message, this.state = EntryState.sent, this.localImage});
  final ChatMessage message;       // a pending entry holds a synthetic message: id 'local-<n>', mine, createdAt now
  final EntryState state; final PickedImage? localImage;
  bool get isPending => state != EntryState.sent; ChatEntry copyWith({EntryState? state, ChatMessage? message}); }
sealed class ThreadItem { const ThreadItem(); String get key; }
class DayItem extends ThreadItem { final DateTime day; }                 // key 'day-yyyy-mm-dd'
class SystemItem extends ThreadItem { final ChatMessage message; }       // key message.id
class BubbleItem extends ThreadItem { final ChatEntry entry; final String? senderName; } // key message.id
/// Newest first — the order a reversed ListView draws bottom-up.
List<ThreadItem> buildThread({required List<ChatEntry> chronological, required bool isGroup,
  required String? Function(String? senderId) senderName});

// chat_view_model.dart
enum ChatLoadState { loading, ready, error, unavailable }
enum ComposerMode { open, closed, otherInactive } // closed: !canWrite or a CLOSED/READ_ONLY answer; otherInactive: other == null || other.blocked (D12)
class ChatDraftPeer { const ChatDraftPeer({required this.userId, required this.name}); final String userId, name; }
class ChatOpening { const ChatOpening({required this.detail, this.page}); final ConversationDetail detail; final MessagePage? page; }
class ChatViewModel extends BaseViewModel {
  ChatViewModel({required MessagingRepository messaging, required CatalogRepository catalog, required ShellBadges badges,
    required AppConfig config, required ChatUpdates updates, String? conversationId, ChatDraftPeer? draft,
    ChatOpening? opening, DateTime Function() now = DateTime.now});  // exactly one of conversationId / draft
  ChatLoadState get loadState; ConversationDetail? get detail; ChatDraftPeer? get draft; bool get isDraft;
  String? get replyTime; String? get peerAvatarUrl;   // D4, from /app/providers/{id}; null on any failure
  List<ThreadItem> get thread; bool get hasOlder; bool get isLoadingOlder; bool get olderFailed;
  bool get hasNewBelow; void setAtBottom(bool atBottom);
  ComposerMode get composerMode; bool get showsMenu;  // false for support, dispute and other == null
  Future<void> load();              // also the Retry of the error state
  Future<void> loadOlder();
  Future<void> reloadPhoto(String messageId);        // D15
}
```

**Thread builder** (the whole algorithm; unit-test it in isolation):
```dart
List<ThreadItem> buildThread({required List<ChatEntry> chronological, required bool isGroup,
    required String? Function(String? senderId) senderName}) {
  final List<ThreadItem> items = <ThreadItem>[];
  DateTime? day;
  String? runSender;
  for (final ChatEntry entry in chronological) {
    final ChatMessage m = entry.message;
    final DateTime d = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
    if (day != d) {
      items.add(DayItem(d));
      day = d;
      runSender = null; // a new day starts a new run
    }
    if (m.kind == MessageKind.system) {
      items.add(SystemItem(m));
      runSender = null;
      continue;
    }
    String? label;
    if (isGroup && !m.mine) {
      if (m.senderId != runSender) label = senderName(m.senderId);
      runSender = m.senderId;
    } else {
      runSender = null;
    }
    items.add(BubbleItem(entry, senderName: label));
  }
  return items.reversed.toList();
}
```

**Loading:**
- With `opening`: `detail` and the page come from it, `loadState` is `ready` at once, then read marks, the poller, and the reply line.
- With a draft: `loadState` is `ready` and the thread is empty. Only the reply line and avatar load (`catalog.provider(draft.userId)`). There is no poller.
- Otherwise `load()` runs `Future.wait([conversation(id), messages(id)])`.
  - An `ApiFailure` with code `NOT_A_PARTICIPANT` or `CONVERSATION_NOT_FOUND` gives `unavailable`.
  - Any other failure gives `error`, with `setFailure`.
  - Success gives `ready`. Then:
    1. `markRead(id)`, followed by `badges.refresh()`. Both are silent on failure: a failed read mark on 15 is not worth a toast, and the next poll retries it.
    2. `updates.start(_poll)`.
    3. `_loadReplyLine()`, only when `kind == direct && other?.role == provider`.

**Messages:**
- Confirmed messages are kept in `Map<String, ChatMessage> _confirmed`, and pending entries in `List<ChatEntry> _pending`.
- Chronological order is `_confirmed` sorted by `(createdAt, id)`, followed by `_pending`.
- Rebuild `thread` on every change.
- The sender name for group chats is `detail.participant(senderId)?.name`.

**Poll (`_poll`):**
- Skip when `loadState != ready`.
- Fetch `messages(id)` and find the new received messages: `!m.mine && !_confirmed.containsKey(m.id)`.
- Merge. Messages inside the fetched window that are missing from it were deleted by an admin, so drop them:
```dart
if (page.items.isNotEmpty) {
  final DateTime from = page.items.first.createdAt;
  final Set<String> ids = <String>{for (final ChatMessage m in page.items) m.id};
  _confirmed.removeWhere((String id, ChatMessage m) => !m.createdAt.isBefore(from) && !ids.contains(id));
}
for (final ChatMessage m in page.items) { _confirmed[m.id] = m; }
```
- If there were new received messages: `markRead` + `badges.refresh()`, and if not at the bottom, set `hasNewBelow = true`.
- Failures are ignored; the next tick retries.

**Older pages and photo reloads:**
- `loadOlder()` does nothing while loading, without `hasOlder`, or in a draft. It calls `messages(id, before: _nextBefore)` and merges without deleting. It updates `_nextBefore` / `hasOlder`. A failure sets `olderFailed`, and a retry calls again.
- `reloadPhoto(messageId)` finds the next newer confirmed message. With one, it fetches `messages(id, before: newer.id)`, a page that ends with the target. Without one, it fetches the newest page. Then it merges (fresh signed URLs replace old ones by id).

**Leaving:** `setAtBottom(true)` clears `hasNewBelow`. `dispose()` calls `updates.stop()` before `super.dispose()`.

- [ ] **Step 1: Write the `buildThread` tests.**
  - Two days produce `[today msgs newest-first…, Day(today), yesterday msgs…, Day(yesterday)]`.
  - A system message resets the run.
  - Group sender runs: for a provider/provider/support/provider/mine sequence, only the 1st, 3rd and 4th carry names, and `mine` never does.
  - Not a group: no names at all.
  - A pending entry sits after every confirmed message (index 0 of the newest-first result).
- [ ] **Step 2: Write the VM tests.** Use `FakeMessagingRepository`, `FakeCatalogRepository`, `ManualChatUpdates`, `ShellBadges(notifications: FakeNotificationsRepository())` and `flushAsync()`.
  - **Loading:**
    - A load gives `ready`, the thread has the fixture's 6 messages plus day items, the calls include `markRead:c-lumiere`, `updates.started` is true, and `counts` was called.
    - `replyTime` is the catalog provider's `replyTime` (the fake returns `providerDetail`). A `providerError` gives `replyTime == null` with the chat still `ready`.
    - `loadError = ApiFailure(403, NOT_A_PARTICIPANT)` gives `unavailable`. `CONVERSATION_NOT_FOUND` gives `unavailable`. `NetworkFailure` gives `error`, and `load()` again after clearing the error gives `ready`.
  - **Composer mode and menu:**
    - `composerMode`: a detail with `canWrite: false` gives `closed`. `other.blocked` gives `otherInactive`. `other == null` gives `otherInactive`.
    - `showsMenu` is false for the dispute and support details, and true for c-lumiere.
  - **Older pages:** a thread of 45 in the fake loads 30, then `loadOlder` adds 15 with `hasOlder` false. A second concurrent `loadOlder` makes no second call. `olderFailed` goes true on failure.
  - **Polling:**
    - Add a received message to the fake's thread and `tick()`: it appears, `markRead` is called again, and `counts` is refreshed.
    - With `setAtBottom(false)`, a new received message sets `hasNewBelow`. `setAtBottom(true)` clears it.
    - A tick after an admin removed a message inside the newest window (deleted from the fake) drops it.
    - A tick while `loadState == loading` does nothing.
  - **`reloadPhoto('m-4')`** calls `messages:c-lumiere:m-5` and replaces m-4's `imageUrl` with the fake's new one.
  - **`opening` given:** `ready` without calling `conversation:`. A draft: `ready`, an empty thread, no `updates.started`, and `replyTime` from the catalog.
  - **Dispose while a tick is gated:** dispose the view model, then release the gate. There is no exception, and `updates.stopped` is true (Review Focus 2).
- [ ] **Step 3: Implement.** Then verify with analyze.

### Task 12: `ChatViewModel` — writing (optimistic send, retry, photos, closed switch, draft start, reports)

**Files:**
- Modify: `lib/features/chat/view_model/chat_view_model.dart`
- Test: `test/features/chat/chat_view_model_write_test.dart`

**Interfaces:**
- Produces:
```dart
sealed class SendOutcome { const SendOutcome(); }
class SendSent extends SendOutcome { const SendSent(); }
class SendIgnored extends SendOutcome { const SendIgnored(); }                       // blank, closed, or a start already running
class SendFailed extends SendOutcome { const SendFailed(this.failure); final Failure failure; }        // bubble shows "Not sent"
class SendClosed extends SendOutcome { const SendClosed(); }                         // composer switched to closed
class SendPhotoRejected extends SendOutcome { const SendPhotoRejected(this.problem); final ImageProblem problem; }
class SendStartRejected extends SendOutcome { const SendStartRejected(this.failure, this.text); final Failure failure; final String text; }
class SendStarted extends SendOutcome { const SendStarted(this.conversationId, this.opening); final String conversationId; final ChatOpening opening; }
sealed class ReportOutcome { const ReportOutcome(); }
class ReportSent extends ReportOutcome { const ReportSent({required this.created}); final bool created; }
class ReportFailed extends ReportOutcome { const ReportFailed(this.failure); final Failure failure; }
// ChatViewModel additions
static const int maxTextLength = 4000;   // D7
static const int maxNoteLength = 2000;   // D16
bool get canAttach;                      // !isDraft && kind != dispute && composerMode == open
PickedImage? get attachment;
ImageProblem? attach(PickedImage image); // validates against config.maxPhotoMb / imageTypes; keeps it only when valid
void clearAttachment();
Future<SendOutcome> send(String text);
Future<SendOutcome> retry(String localId);
Future<ReportOutcome> reportMessage(ChatMessage message, ReportReason reason, String? note);
Future<ReportOutcome> reportPeer(ReportReason reason, String? note); // other.id, or draft.userId
```

**`send(text)`:**
1. `body = text.trim()`. If `composerMode != open`, or `body` is empty with no attachment, return `SendIgnored`.
2. Create a pending entry: a synthetic `ChatMessage` with `id: 'local-<seq>'`, `mine: true`, `body`, `createdAt: now()`, and `kind` of `attachment` when there is an image, else `text`. Hold `localImage` and state `sending`.
3. Clear `attachment`, rebuild, notify, then `_deliver(entry)`.

**`_deliver(entry)`:**
- **In a draft:**
  - `start(draft.userId, body)`, then `messages(detail.id)`. When `messages` fails, use `page: null`.
  - Return `SendStarted(detail.id, ChatOpening(detail: detail, page: page))`.
  - `RECIPIENT_INVALID` / `USER_NOT_FOUND`: remove the entry and return `SendStartRejected(failure, body)`. The view restores the text and toasts `forFailure`.
  - `CONVERSATION_CLOSED` / `CONVERSATION_READ_ONLY` handling is the same as below.
  - A `_starting` flag makes a second send during start return `SendIgnored`.
- **Otherwise** send with `sendPhoto(id, image, caption: body.isEmpty ? null : body)` if the entry has an image, else with `sendDisputeText(detail.disputeId!, body)` for a dispute, else with `sendText(id, body)`.
  - On success: remove the pending entry, then `_confirmed[sent.id] = sent`. The upsert is by id, so when a poll already brought this message only one bubble remains (Review Focus 1). Return `SendSent`.
  - `ApiFailure` with `CONVERSATION_CLOSED` (any status) or `CONVERSATION_READ_ONLY`: mark the entry `failed`, set `composerMode = closed` and return `SendClosed`. The poller keeps running, because a closed chat can still receive messages from support.
  - `FILE_TOO_LARGE` → `failed`, `SendPhotoRejected(tooLarge)`. `FILE_TYPE_NOT_ALLOWED` → `failed`, `SendPhotoRejected(wrongType)`.
  - Any other `Failure` → `failed`, `SendFailed(failure)`.
- **`retry(localId)`:** only for a `failed` entry while `composerMode == open`. Set it to `sending` and `_deliver` again. Anything else returns `SendIgnored`.
- **Reports:** blank notes become `null`, and notes are trimmed. `ReportSent(created)` or `ReportFailed(failure)`.

- [ ] **Step 1: Write the tests.** Each one asserts calls, thread states and outcomes.
  - **Optimistic send:** with `sendGate` pending, `send(' hi ')` puts a `sending` bubble with body `hi` at thread index 0. Releasing it gives `SendSent`, the pending entry is gone, and the server message is present.
  - **Blank and closed:** `send('   ')` without an attachment gives `SendIgnored` and no call. `send` while `closed` gives `SendIgnored`.
  - **Network failure and retry:** `sendError = NetworkFailure` gives `SendFailed` and a `failed` bubble. `retry(localId)` with the error cleared gives `SendSent`.
  - **Closed on send:** `sendError = ApiFailure(409, CONVERSATION_CLOSED)` gives `SendClosed` and `composerMode == closed`, with the bubble `failed`. The same happens with a 403 status. `CONVERSATION_READ_ONLY` gives `SendClosed`. A later `retry` gives `SendIgnored`.
  - **Photos:**
    - `attach(PickedImage(name: 'a.gif', …))` returns `wrongType` and `attachment` stays null.
    - A valid jpeg is attached, and `send('cap')` calls `sendPhoto:c-lumiere:a.jpg:cap`. The pending bubble holds the `localImage`.
    - `FILE_TOO_LARGE` gives `SendPhotoRejected(tooLarge)`.
    - `canAttach` is false for the dispute and in a draft.
  - **Dispute:** `send('x')` on the dispute detail calls `sendDisputeText:d-2041:x`.
  - **Draft:**
    - `send('Hello')` calls `start:p-1:Hello` then `messages:c-new:null`, and returns `SendStarted('c-new', opening)` with the opening's page holding the message.
    - `startError = ApiFailure(422, RECIPIENT_INVALID)` gives `SendStartRejected` with `text == 'Hello'` and an empty thread.
    - A `NetworkFailure` start gives `SendFailed`, and `retry` calls `start` again.
    - A second `send` during the gated start gives `SendIgnored`.
  - **Poll during send (Review Focus 1):** gate the send. The fake's `sendText` has already appended `sent-1`. `tick()` merges `sent-1` while the local entry is still pending. Releasing the send leaves exactly one bubble with body `hi`.
  - **Reports:** `reportMessage(m4, spam, '  ')` calls `reportMessage:m-4:spam:null` and gives `ReportSent(created: true)`. `reportCreated = false` gives `created: false`. `reportPeer` in a draft reports `draft.userId`. A failure gives `ReportFailed`.
- [ ] **Step 2: Implement.** Then verify with analyze.

### Task 13: Chat widgets

**Files:** (all under `lib/features/chat/view/widgets/`)
- `chat_top_bar.dart`, `booking_context_card.dart`, `message_bubble.dart`, `thread_pills.dart`, `chat_composer.dart`, `new_messages_pill.dart`, `chat_skeleton.dart`, `message_actions_sheet.dart`, `report_sheet.dart`, `photo_viewer.dart`
- ARB (spec §6): `chatComposerHint`, `chatComposerDisputeHint`, `chatClosed`, `chatOtherBlocked`, `chatMaskedNote`, `chatNotSent`, `chatNewMessages`, `chatSayHello` ({name}), `chatToday`, `chatGroupSubtitle` ({name}), `chatViewProfile`, `chatReportUser` ({name}), `chatCopy`, `chatReportMessage`, `photoReload`, `reportTitle`, `reportReasonInappropriate`, `reportReasonSpam`, `reportReasonContact`, `reportReasonHarassment`, `reportReasonFake`, `reportReasonOther`, `reportNoteHint`, `reportSend`.
- ARB (new):
  | key | EN | AR | description |
  |---|---|---|---|
  | `chatSend` | Send | إرسال | Send button label |
  | `chatAttach` | Add a photo | إضافة صورة | The composer's "+" |
  | `chatMore` | More options | خيارات أخرى | The ⋯ button |
  | `chatRemoveAttachment` | Remove photo | إزالة الصورة | The ✕ on the preview chip |
  | `chatSending` | Sending | جارٍ الإرسال | Screen-reader label for the clock |
  | `chatOlderFailed` | Could not load older messages | تعذّر تحميل الرسائل الأقدم | Top of the thread |
  | `photoViewerClose` | Close | إغلاق | Photo viewer's ✕ |
- Test: `test/features/chat/chat_widgets_test.dart`

**Interfaces** (Figma `581:1165` / `585:1283`; states `1452:45702` / `1452:45715`). All are stateless unless noted:
```dart
ChatTopBar({required Widget avatar, required String title, String? subtitle, VoidCallback? onPeerTap, VoidCallback? onMore, required VoidCallback onBack})
  // surface, bottom hairline, padding (safe top + 12)/16/12/16, gap 12: back (chevronLeft, directional, iconBrand, 48 target),
  // 36 avatar, Column(title titleMedium one line, subtitle labelSmall secondary), ⋯ moreHorizontal 22 iconBrand when onMore != null
BookingContextCard({required ChatBooking booking, required VoidCallback onTap})
  // wrapper 12/16/4/16; card bgBrandSubtle r12 padding 10/12 gap 10; camera 24 iconBrand; Column(title titleSmall textBrand 1 line,
  // Row[shortDate(eventDate) , ' · ', Text(reference, ltr)] labelSmall secondary); StatusBadge(BookingStatusKind.fromApi(status)); chevronRight 16
MessageBubble({required ChatEntry entry, String? senderName, VoidCallback? onLongPress, VoidCallback? onRetry,
  VoidCallback? onPhotoTap, VoidCallback? onPhotoReload})
DayPill(String label) ; SystemPill(String text)   // bgDisabled r999 padding 4/12 labelSmall secondary; SystemPill full width, centred, wraps
ChatComposer({required TextEditingController controller, required String hint, required bool canAttach, required bool canSend,
  PickedImage? attachment, required VoidCallback onAttach, required VoidCallback onRemoveAttachment, required VoidCallback onSend})
ClosedComposer({required String notice})          // the same container; one full-width field showing the notice (secondary)
NewMessagesPill({required VoidCallback onTap})      // brand pill "New messages ↓" (chevronDown), elevation md
ChatSkeleton()                                      // 6 alternating Skeleton bubbles, 180–240 wide, r16
enum MessageAction { copy, report }
Future<MessageAction?> showMessageActions(BuildContext context, {required bool canCopy, required bool canReport});
enum PeerAction { viewProfile, report }
Future<PeerAction?> showPeerActions(BuildContext context, {required String name, required bool canViewProfile});
Future<({ReportReason reason, String? note})?> showReportSheet(BuildContext context);
Future<void> showPhotoViewer(BuildContext context, {required String url}); // full-screen, black, InteractiveViewer
```

**`MessageBubble` rules** (these are the widget tests):
- **Row alignment:** received bubbles go to the start, sent to the end. With ambient `Directionality` that mirrors in AR. Max width 268, padding 9/12/7/12, gap 2.
- **Received:** surface, 1px border, text primary, time secondary. Corners EN TL16 TR16 BR16 BL4 (`BorderRadiusDirectional.only(topStart: 16, topEnd: 16, bottomEnd: 16, bottomStart: 4)`); the directional radius mirrors it in AR.
- **Sent:** brand fill, no border, text and time on-brand, `BorderRadiusDirectional.only(… bottomEnd: 4, bottomStart: 16)`.
- **Body:** `bodyMedium`, shown only when non-blank.
- **Photo** (`hasImage` or `localImage`): the first child, r8, the bubble's width, max 244×180, `BoxFit.cover`.
  - A pending local image uses `Image.memory(localImage.bytes)`.
  - A server image uses `AppNetworkImage(url: imageUrl, errorBuilder: tap-to-reload tile (image glyph + photoReload, labelSmall) → onPhotoReload)`, and a tap calls `onPhotoTap`.
- **Masked** (`message.masked`): a `chatMaskedNote` caption line (`labelSmall`) between the text and the time, in the bubble's secondary colour (on-brand at 0.8 for sent, secondary for received).
- **Removed** (`isRemoved`): always received styling. The text is `chatRemoved` at opacity 0.55, the time is kept, and there is no photo and no long-press.
- **Time:** `clockTime(createdAt)` in `labelSmall`, end-aligned, LTR.
- **Sending:** the whole bubble at opacity 0.6, and a `clock` 12 icon (semantics `chatSending`) before the time.
- **Failed:** the time is replaced by `chatNotSent` in `textDanger` `labelSmall`, and the bubble becomes tappable → `onRetry`.
- **Sender label** (`senderName != null`): `labelSmall` secondary, 4 above the bubble, start-aligned.

**`ChatComposer`:**
- Surface, top hairline, padding 10/16/24/16. The bottom padding adds `MediaQuery.paddingOf(context).bottom` only when `viewInsets.bottom == 0`.
- Row, gap 8:
  - "+": a 40 circle, `bgCanvas`, plus 20 iconDefault, semantics `chatAttach`. It is hidden when `!canAttach` and the caller shows a toast instead; see Task 14.
  - The field: `Expanded` `TextField` with `minLines: 1`, `maxLines: 5`, `maxLength: ChatViewModel.maxTextLength`, `buildCounter` returning null, r999, `bgCanvas`, 1px border, padding 10/14, `bodyMedium`, and `textInputAction: newline`.
  - Send: a 40 circle, brand, `chevronRight` 20 on-brand. Its opacity is 0.4 and it is inert when `!canSend`; semantics `chatSend`.
- With an attachment, a chip above the row: a 64 thumbnail (`Image.memory`), the file name (`bodySmall`, one line) and a ✕ (semantics `chatRemoveAttachment`).

**`showReportSheet`:**
- `AppSheetScaffold(title: reportTitle)`.
- 6 radio rows in the `ReportReason` order, with labels from the `reportReason*` keys.
- A note `AppTextField` (hint `reportNoteHint`, `maxLength: ChatViewModel.maxNoteLength`, 3 lines).
- A primary `MainButton(reportSend)`, disabled until a reason is picked. It pops `(reason, note)`.

**`showMessageActions` / `showPeerActions`:** `AppSheetScaffold` lists of rows.
- Message actions: `chatCopy`, then `chatReportMessage`, each shown only when allowed.
- Peer actions: `chatViewProfile` when `canViewProfile`, then `chatReportUser(name)`.

- [ ] **Step 1: Write the widget tests.** Use `pumpAppWidget`, EN and AR where noted.
  - **Corners:** the received bubble's decoration `borderRadius` resolves in EN to bottomLeft 4, and in AR to bottomRight 4. The sent bubble is the mirror.
  - **Alignment:** a sent bubble's right edge is greater than a received one's in EN, and the reverse in AR.
  - **Masked and removed:** a masked message shows `chatMaskedNote`. A removed message shows `chatRemoved` at opacity 0.55, and a long press does nothing (`onLongPress` not called).
  - **Photos:**
    - A photo with an empty body renders the image and no body `Text`.
    - A photo whose load fails shows `photoReload`, and a tap calls `onPhotoReload` (use `AppNetworkImage` with an `asset:` URL that does not exist).
    - A pending local-image bubble renders `Image.memory`.
  - **Pending states:** sending shows the clock with semantics `chatSending`. Failed shows `chatNotSent`, and a tap calls `onRetry`.
  - **Sender label:** shown above a received bubble in a group.
  - **Composer:**
    - Send is inert and dimmed when `canSend` is false, and calls `onSend` when true.
    - "+" is hidden when `!canAttach`.
    - The attachment chip shows the file name, and ✕ calls `onRemoveAttachment`.
    - `ClosedComposer` shows the notice and no Send button.
  - **Pills:** `DayPill('Today')` renders.
  - **Top bar in AR:** the back button's x > the title's x > the ⋯ x. There is no ⋯ when `onMore == null`.
  - **Booking card in AR:** the reference `Text` has `textDirection == ltr`, and the status badge shows "Pending".
  - **Report sheet:** Send is disabled until a reason is picked. Picking Spam and typing a note pops `(spam, 'note')`.
  - **Action sheets:** `showMessageActions(canCopy: false, canReport: true)` lists only Report.
- [ ] **Step 2: Implement, add the ARB keys, run gen-l10n.** Then verify with analyze.

### Task 14: `ChatView` (15) — assembly, routes, picker, navigation

**Files:**
- Create: `lib/core/services/photo_picker.dart`, `lib/features/chat/view/chat_view.dart`
- Modify: `lib/core/routing/app_router.dart` (`/conversations/new` **before** `/conversations/:id`)
- ARB (spec §6): `chatUnavailable`, `chatCopied`, `chatPhotoNeedsText`, `photoTooLarge` ({mb}), `photoWrongType`, `reportSent`, `reportAlready`
- Test: `test/features/chat/chat_view_test.dart`

**Interfaces:**
```dart
// photo_picker.dart — the file_picker call stays in the view layer (spec 4.2); injectable for tests.
typedef PhotoPicker = Future<PickedImage?> Function();
Future<PickedImage?> pickChatPhoto() async {
  final PlatformFile? file = await FilePicker.pickFile(type: FileType.image);
  if (file == null) return null;
  return PickedImage(name: file.name, bytes: await file.readAsBytes(), extension: file.extension?.toLowerCase() ?? '');
}
class ChatView extends StatefulWidget { const ChatView({this.pickPhoto = pickChatPhoto, super.key}); final PhotoPicker pickPhoto; }
```
Routes (in `app_router.dart`):
```dart
GoRoute(
  path: AppRoutes.chatDraft,
  redirect: (_, GoRouterState state) =>
      (state.uri.queryParameters['user'] ?? '').isEmpty ? AppRoutes.messages : null,
  builder: (_, GoRouterState state) => _withViewModel<ChatViewModel>(
    (BuildContext context) => ChatViewModel(
      messaging: context.read<MessagingRepository>(), catalog: context.read<CatalogRepository>(),
      badges: context.read<ShellBadges>(), config: context.read<AppConfigRepository>().current,
      updates: TimerChatUpdates(),
      draft: ChatDraftPeer(userId: state.uri.queryParameters['user']!, name: state.uri.queryParameters['name'] ?? ''),
    ),
    const ChatView(),
  ),
),
GoRoute(path: '${AppRoutes.conversations}/:id', builder: … conversationId: state.pathParameters['id'],
  opening: state.extra is ChatOpening ? state.extra! as ChatOpening : null …),
```

**Assembly:**
- `Scaffold(backgroundColor: bgCanvas, resizeToAvoidBottomInset: true)`, containing a `Column`:
  - **`ChatTopBar`:**
    - Avatar: a draft uses `AppAvatar(name: draft.name, photoUrl: vm.peerAvatarUrl, size: chatHeader)`; otherwise `ConversationAvatar(size: chatHeader)`.
    - Title: the same wording as the Task 10 row, or `draft.name`.
    - Subtitle: `chatGroupSubtitle(groupProvider.name)` for a dispute; `repliesIn(vm.replyTime)` when non-null; else none.
    - `onPeerTap`: provider chats and drafts → `context.push(AppRoutes.providerFor(id))`.
    - `onMore` when `vm.showsMenu`: `showPeerActions`. View profile → 13. Report → `showReportSheet`, then `vm.reportPeer`, then the toast `reportSent` / `reportAlready` / `forFailure`.
    - `onBack`: `context.canPop() ? context.pop() : context.go(AppRoutes.messages)`.
  - **`BookingContextCard`** when `booking != null`. Its tap shows Coming soon.
  - **`Expanded`**, by load state:
    - `loading` → `ChatSkeleton`.
    - `error` → `StateCard.error(onRetry: vm.load)`, padded.
    - `unavailable` → `StateCard.empty(icon: message, title: chatUnavailable, actionLabel: backLabel, onAction: back)`.
    - A draft with an empty thread → a centred quiet `chatSayHello(name)` (`bodyMedium` secondary).
    - Otherwise the thread (below).
  - **Composer**, keyed on `composerMode`:
    - `open` → `ChatComposer`. The hint is `chatComposerDisputeHint` for disputes and `chatComposerHint` otherwise.
    - `closed` → `ClosedComposer(chatClosed)`.
    - `otherInactive` → `ClosedComposer(chatOtherBlocked)`.
    - Hidden while `loading`, `error` or `unavailable`.
- **Thread:** a `Stack`:
  - `ListView.builder(reverse: true, padding: 12/16, itemCount: thread.length + (hasOlder || olderFailed ? 1 : 0))`. Items are 10 apart.
    - The last index (the top) is a small `AppSpinner` while `isLoadingOlder`, or `chatOlderFailed` + `stateRetry` when `olderFailed`.
    - Item keys are `ValueKey(item.key)`.
    - Day labels come from `dayLabel(day, now: DateTime.now(), locale, today: chatToday, yesterday: chatYesterday)`.
  - A `NotificationListener<ScrollNotification>` calls `vm.loadOlder()` when `metrics.extentAfter < 400`, and `vm.setAtBottom(metrics.pixels <= 48)`.
  - `NewMessagesPill` is centred 12 above the bottom when `vm.hasNewBelow`. Its tap animates to 0 and calls `setAtBottom(true)`.
- **Long press on a bubble:**
  - `canCopy = body.trim().isNotEmpty`, and `canReport = !mine`. No menu for system, removed or pending messages, or when neither is allowed.
  - Copy → `Clipboard.setData`, then toast `chatCopied`.
  - Report → `showReportSheet` → `vm.reportMessage` → toast.
- **Photo tap:** `showPhotoViewer(url: imageLargeUrl ?? imageUrl)`. Photo reload → `vm.reloadPhoto(id)`.
- **"+":**
  - In a draft → toast `chatPhotoNeedsText`.
  - Else `await widget.pickPhoto()`, then `vm.attach(image)`.
  - `tooLarge` → toast `photoTooLarge(config.maxPhotoMb)`. `wrongType` → toast `photoWrongType`. Error tone for both.
- **Send button:** `canSend = controller.text.trim().isNotEmpty || vm.attachment != null`, recomputed by listening to the controller. On send, keep `text`, clear the controller, `await vm.send(text)`, then switch on the outcome:
  - `SendStarted` → `context.pushReplacement(AppRoutes.chatFor(id), extra: opening)`.
  - `SendStartRejected` → put `text` back in the controller and toast `forFailure`.
  - `SendPhotoRejected` → the photo toasts.
  - `SendClosed` / `SendFailed` → nothing extra (the bubble and the composer already say it).

- [ ] **Step 1: Write the tests.** There are two harnesses:
  - **Routed:** `buildTestApp` with the fakes, then `startAt` a signed-in client at `/conversations/c-lumiere`. Use it for navigation, the ⋯ menu, sending, the closed switch, the draft and long press.
  - **Direct:** for the picker and the new-messages pill, which need an injected picker and `ManualChatUpdates`, build the view model yourself (`ChatViewModel(…, updates: ManualChatUpdates(), conversationId: 'c-lumiere')`). Pump `ChangeNotifierProvider<ChatViewModel>.value(value: vm, child: ChatView(pickPhoto: () async => fakeImage))` with `pumpAppWidget`, and don't tap anything that navigates.
  - **Load:** the skeleton, then bubbles. The booking card shows "EVT-000123", and tapping it shows Coming soon.
  - **Header:** tapping the avatar pushes `/providers/p-lumiere`.
  - **⋯ menu:** it shows View profile and "Report Studio Lumière". Report → Spam → Send reports the user and shows `reportSent`. With `reportCreated: false` it shows `reportAlready`.
  - **Sending:** typing "hi" enables Send. Tapping it clears the field, shows the bubble, and calls `sendText:c-lumiere:hi`.
  - **Closed switch:** `sendError = ApiFailure(409, CONVERSATION_CLOSED)` makes the composer show `chatClosed`, and the bubble shows `chatNotSent`.
  - **States:** the dispute route has no "+", shows the dispute hint, and has no ⋯. A route with `loadError: NOT_A_PARTICIPANT` shows `chatUnavailable`.
  - **Draft:** `/conversations/new?user=p-1&name=Salle%20Yasmine` shows `chatSayHello`. "+" shows `chatPhotoNeedsText`. Sending "Hello" replaces the route with `/conversations/c-new`, and Back returns to the previous route, not to the draft.
  - **Long press:** on a received message it offers Copy and Report. Copy shows `chatCopied`. On my own message it offers only Copy.
  - **Photos (direct harness):** the picker returns a 12 MB jpeg, so `photoTooLarge` is shown with "10". A valid jpeg shows the preview chip and enables Send with an empty field.
  - **New messages (direct harness):** drag the thread up, add a received message to the fake's thread, and `await updates.tick()`. The "New messages" pill shows, and tapping it hides the pill.
  - **AR:** the back chevron is at the right edge, and the Send chevron points left (the `Transform.flip` is present).
- [ ] **Step 2: Implement, add the ARB keys, run gen-l10n.** Then verify with analyze.

### Task 15: `NotificationsViewModel` + `NotificationsView` (16)

**Files:**
- Create: `lib/features/notifications/view_model/notifications_view_model.dart`, `view/notifications_view.dart`, `view/widgets/notifications_header.dart`, `view/widgets/notification_item.dart`
- Modify: `lib/core/routing/app_router.dart` (`GoRoute(path: AppRoutes.notifications, …)`)
- ARB (spec §6): `notificationsTitle`, `notificationsMarkAll`, `notificationsToday`, `notificationsThisWeek`, `notificationsEarlier`, `notificationsEmptyTitle`, `notificationsEmptyBody`. New keys:
  | key | EN | AR | description |
  |---|---|---|---|
  | `notificationUnread` | Unread | غير مقروء | Screen-reader suffix for an unread item |
  | `offlineNotificationsBody` | These are your last notifications. New ones arrive when you reconnect. | هذه آخر إشعاراتك. الجديدة تصل عند عودة الاتصال. | Offline banner on 16 |
- Test: `test/features/notifications/notifications_test.dart`

**Interfaces:**
```dart
class NotificationSection { const NotificationSection(this.group, this.items); final NotificationGroup group; final List<AppNotification> items; }
class NotificationsViewModel extends BaseViewModel {
  NotificationsViewModel({required NotificationsRepository notifications, required ShellBadges badges}); // loads on creation; D1: never marks on open
  List<NotificationSection> get sections;   // API order kept; a group appears once, at its first row
  bool get isFirstLoad; bool get hasMore; bool get isLoadingMore; bool get isOffline; bool get isEmpty;
  bool get canMarkAll;                      // badges.unreadNotifications > 0 || any loaded item unread
  Future<void> load(); Future<void> loadMore(); Future<Failure?> refresh();
  Future<Failure?> markRead(String id);     // optimistic; restores on failure; badges.update(unreadNotifications: result)
  Future<Failure?> markAllRead();           // optimistic for every loaded item; restores all on failure
}
```

**Layout** (Figma `583:1175` / `586:1226`; D2: the AR header **is** mirrored):
- **Header:** `bgBrand`. Padding (safe top + 16)/16/20/16. A Row with gap 12:
  - back (chevronLeft on-brand, directional)
  - `Expanded` "Notifications" (`headlineMedium` on-brand)
  - "Mark all read" (`labelMedium` textOnBrandAccent, 48-high tap target), only when `canMarkAll`
- **Body:** `RefreshIndicator` around a `ListView`.
  - Padding 20/16/24/16, with the groups 20 apart.
  - Each group: the label (overline, secondary, uppercased in EN only) with a gap of 10 before a `DividedCard` of items.
  - Offline banner (`offlineNotificationsBody`) on top when `isOffline`.
  - Skeleton: a `DividedCard` of 4 rows with a 40 tile and 3 lines.
  - Empty: `StateCard.empty(icon: bell, title: notificationsEmptyTitle, body: notificationsEmptyBody)`.
  - Error card, and infinite scroll as on 14.
- **`NotificationItem`:** padding 14, gap 12, top-aligned.
  - A 40 tile: `bgBrandSubtle`, r12, `notificationIcon(type)` 20 iconBrand.
  - Column, gap 2: title (`titleSmall`), body (`bodySmall` secondary, `maxLines: 3`, ellipsis), time (`listTime(...)`, `labelSmall` secondary, LTR).
  - An 8 brand dot at the top end when unread, else an 8 spacer.
  - Semantics: `'$title, ${l10n.notificationUnread}'` when unread.
- **Tap:**
  1. `final NotificationTarget target = n.target;`
  2. `unawaited(vm.markRead(n.id).then((Failure? f) { if (f != null && mounted) showAppToast(context, l10n.forFailure(f), tone: error); }));`
  3. Then `switch (target) { ChatTarget(:final conversationId) => context.push(AppRoutes.chatFor(conversationId)), UnsupportedTarget() => showComingSoon(...) }`.
- **Mark all read:** `final Failure? f = await vm.markAllRead(); if (f != null) toast`.

- [ ] **Step 1: Write the tests.**
  - **VM sections:** the fixture gives sections `[today(n-1, n-2), thisWeek(n-3), earlier(n-4)]`. Rows out of group order (today, earlier, today) give today's section 2 items, with its position at its first appearance.
  - **D1:** the load makes no `markRead` call.
  - **`markRead('n-1')`:** n-1 flips to read immediately with the gate held. The badge becomes the fake's return value. A failure restores `read: false` and returns the failure.
  - **`markRead` on an already-read item:** no call.
  - **`markAllRead`:** everything is read, and `canMarkAll` becomes false once the badge is 0. A failure restores the previous read flags.
  - **Paging and offline:** paging, and the offline banner, work as in Task 9.
  - **Widget, EN:** the group labels are "TODAY", "THIS WEEK", "EARLIER". Unread dots appear on n-1 and n-2. The icons are check, message, starFilled and bell.
  - **Taps:** tapping n-2 pushes `/conversations/c-yasmine` and calls `markRead(['n-2'])`. Tapping n-1 shows Coming soon.
  - **Mark all read:** it hides after a successful mark-all.
  - **Widget, AR:** the labels are *not* uppercased, and the back button's x > the title's x > the "Mark all read" x (D2).
  - **Empty:** an empty fake shows `notificationsEmptyTitle`.
  - **Routing:** Home bell → 16 → Back returns to Home. A 16 message notification → 15.
- [ ] **Step 2: Implement, add the ARB keys, run gen-l10n.** Then verify with analyze.

### Task 16: Entry points on 12 and 13, final wiring and checks

**Files:**
- Create: `lib/core/messaging/chat_launcher.dart`
- Modify: `lib/features/service_detail/view_model/service_detail_view_model.dart`, `…/view/service_detail_view.dart`, `lib/features/provider_profile/view_model/provider_profile_view_model.dart`, `…/view/provider_profile_view.dart`, `lib/core/widgets/organisms/sticky_action_bar.dart` (`MessageIconButton(isLoading)`, `StickyActionBar.notAccepting(isMessageLoading)`), `lib/core/routing/app_router.dart` (pass `messaging: context.read<MessagingRepository>()` to both view models)
- Modify tests that build those view models: `test/features/service_detail/service_detail_test.dart`, `test/features/provider_profile/provider_profile_test.dart` (add `messaging: FakeMessagingRepository()`)
- Test: `test/core/messaging/chat_launcher_test.dart`, extend the two feature tests and `test/app/app_flow_test.dart`

**Interfaces:**
```dart
mixin ChatLauncher on BaseViewModel {
  MessagingRepository get chatMessaging;
  bool _isOpeningChat = false;
  bool get isOpeningChat => _isOpeningChat;

  /// Where "Message" goes for [userId]: their conversation when the list has one, else a draft (decision 2).
  /// `null` while a lookup is already running — a double tap opens one chat, not two.
  Future<String?> chatRouteWith({required String userId, required String name}) async {
    if (_isOpeningChat) return null;
    _isOpeningChat = true;
    notifyListeners();
    try {
      final ConversationRow? row = await chatMessaging.findWith(userId, name);
      return row == null
          ? AppRoutes.chatDraftFor(userId: userId, name: name)
          : AppRoutes.chatFor(row.id);
    } catch (_) {
      // A failed lookup still lets the user write: the draft's first send
      // reaches the existing chat anyway, since there is one per pair.
      return AppRoutes.chatDraftFor(userId: userId, name: name);
    } finally {
      _isOpeningChat = false;
      notifyListeners();
    }
  }
}
// ServiceDetailViewModel / ProviderProfileViewModel: `with ChatLauncher`, ctor `required MessagingRepository messaging`,
// `MessagingRepository get chatMessaging => _messaging;`
```
- **12:** `MessageIconButton(isLoading: vm.isOpeningChat, onPressed: () async { final String? route = await vm.chatRouteWith(userId: service.provider.id, name: service.provider.businessName); if (route != null && context.mounted) context.push(route); })`. `StickyActionBar.notAccepting(onMessage: <same>, isMessageLoading: vm.isOpeningChat)`.
- **13:** the "Send a message" `MainButton(isLoading: vm.isOpeningChat, …)` and the not-accepting bar get the same wiring, with `provider.id` / `provider.businessName`.
- **`MessageIconButton(isLoading: true)`** shows an `AppSpinner(size: 20)` in place of the glyph and ignores taps.
- **20 Pack detail** keeps Coming soon (outside spec §1); flag it in the handoff.

- [ ] **Step 1: Write the tests.**
  - **`chatRouteWith`:**
    - An existing row gives `/conversations/c-lumiere`.
    - No row gives the draft route with both params.
    - `findError` gives the draft route.
    - Two concurrent calls (gated) give one `findWith` call, and the second returns `null` (Review Focus 3).
    - `isOpeningChat` is true while the lookup is gated.
  - **12 widget:** make the fake's first row belong to the fixture service's provider (`app.messaging.rows = <ConversationRow>[ConversationRow.fromJson({...rowJson, 'other': {...otherJson, 'id': app.catalog.serviceDetail.provider.id}})]`). The message icon then pushes `/conversations/c-lumiere`. With `app.messaging.gate` held, the icon shows a spinner.
  - **13 widget:** "Send a message" for a provider with no chat pushes `/conversations/new?user=…&name=…`. The not-accepting variant does the same.
  - **App flow (mock-shaped fakes, signed-in client):** Messages tab → row → 15 → Back → 14. Home bell → 16 → message notification → 15.
- [ ] **Step 2: Implement.**
- [ ] **Step 3: Final checks.**
  - Run `flutter gen-l10n` and confirm `l10n_missing.json` is `{}`.
  - `flutter analyze --no-pub lib test` must print "No issues found!".
  - `grep -rn "comingSoon" lib/features/home lib/features/service_detail lib/features/provider_profile` should now show only the booking, reviews and report destinations.
- [ ] **Step 4: Update memory.**
  - Add spec §10's 10 backend asks to `eventor-open-questions.md`.
  - Update `eventor-phase-status.md`: messaging built, uncommitted, tests written and not run.
  - Note there that the mock uses Traiteur El Djazair instead of Figma's "El Baraka", and that 20's message button is still Coming soon.

---

## Self-review notes

- **Spec coverage:**
  - §2 decisions:
    - 1 poll: Tasks 5, 11
    - 2 draft: Tasks 12, 14, 16
    - 3 photos: Tasks 3, 12, 13, 14
    - 4 notification taps: Task 15
    - 5 long-press: Tasks 13, 14
    - 6 ⋯ menu: Tasks 13, 14
    - 7 app copy: Tasks 10, 13, 14
    - 8 sender names: Tasks 11, 13
    - Corrections (report user, dispute text-only): Tasks 11, 12, 14
  - D1–D16:
    - D1, D2: Task 15
    - D3: Task 6
    - D4: Tasks 11, 14
    - D5: Task 7
    - D6: Task 2
    - D7, D8: Tasks 12, 13
    - D9, D10: Tasks 11, 14
    - D11: Tasks 3, 10
    - D12: Tasks 11, 14. Interpretation: a deleted account (`other == null`) also gets the D12 notice composer.
    - D13: Task 9
    - D14: Task 13
    - D15: Tasks 11, 13
    - D16: Task 13
  - §4.3 routes: Tasks 7, 10, 14, 15. §7 errors: Tasks 9, 11, 12, 14, 15. §8 tests: distributed as listed.
- **Deviations to confirm with the user:**
  - `ShellBadges.refresh()` takes the repository at construction instead of as an argument (simpler for view models).
  - The mock's third chat is Traiteur El Djazair, so profile links work.
  - Chat read-mark failures on 15 are silent, rather than the §7 "toast" row, which applies to 16.

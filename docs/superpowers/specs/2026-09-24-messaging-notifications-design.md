# Messages, chat and notifications — design spec

Status: design approved in chat 2026-09-24; this document awaits review.
Research: `scratchpad/api/messaging-contract.md` (API), `scratchpad/figma-messaging.md` (Figma).

## 1. Goal

Build the client's messaging and notifications on the live API and on an equivalent mock
backend, in English and Arabic, in the style of the discovery build (spec
`2026-09-24-client-discovery-design.md`):

| Code | Screen | Figma (EN / AR) |
|---|---|---|
| 14 | Messages (the Messages tab) | `579:1135` / `585:1186` |
| 14 | State · offline | `1752:7252` / `1756:7563` |
| 15 | Chat | `581:1165` / `585:1283` |
| 15 | States · Closed chat, removed message | `1452:45702` / `1452:45715` |
| 16 | Notifications | `583:1175` / `586:1226` |

Generic patterns reused: G1 skeletons `1750:6977`, G2 empty / error / offline `1750:7023`.
Dispute chat D4 (`1643:4866`) has the same anatomy as 15 and is served by it.

Entry points wired in this build: the Messages tab, the bell on 11 Home and on 14, "Send a
message" on 13 (including its not-accepting state), the message button on 12, and a tapped
notification.

## 2. Decisions taken (user, 2026-09-24)

| # | Decision |
|---|---|
| 1 | **Poll, don't socket.** While 15 is open it fetches the newest page every 5 s. 14 and the badges refresh on open, on pull, on return to the app and after a read. Socket.IO waits for the backend to document auth and payloads; the poller sits behind an interface so it can be swapped. |
| 2 | **Draft chat.** "Message" on 12/13 opens 15 for that provider. If a chat with them is found in the list it opens with its history. Otherwise it's an empty draft, and the first send creates the chat (`POST /app/conversations`, idempotent per pair). Nothing from 12 is attached; the API only attaches bookings. |
| 3 | **Photos from the gallery.** "+" picks one image with `file_picker` (already a dependency), with an optional caption. Type (jpeg/png/webp/heic) and size (≤ 10 MB, from `/app/config`) are checked before upload. The photo shows while it sends, a failed send offers Retry, and tapping any photo opens it full screen. No camera. |
| 4 | **Notifications open what exists.** A tap marks the notification read. One carrying a `conversationId` opens 15. Everything else says "Coming soon". The icon comes from the `type` prefix, with the bell as fallback. |
| 5 | **Long-press: Copy + Report.** Your own messages get Copy. Others' messages get Copy and Report (reason sheet plus an optional note). System and removed messages have no menu. |
| 6 | **⋯ menu: View profile + Report.** Tapping the name or avatar also opens 13. The booking card says "Coming soon". |
| 7 | **The app words it.** A closed chat always shows the app's notice, never `closedReason`. A removed message is recognised by its literal body and drawn with the app's own translated text. |
| 8 | **Sender names in group chats.** In support and dispute chats, a received message carries its sender's name above the bubble, once per run of messages from the same sender. |

**Corrections found while writing, for review:**
- The API cannot report a *conversation*: `/app/reports` takes `service | pack | user | review | message`. So "Report" in ⋯ reports the **other person** (`targetType: user`). Support and dispute chats have no one sensible to report, so **their ⋯ menu is hidden**.
- Dispute chats write through `POST /app/disputes/{id}/messages`, which takes **text only**. So a dispute chat has **no "+"**, and its placeholder is "Write to both parties" (D4).

## 3. Defaults I chose — please confirm or correct

| # | Default | Why |
|---|---|---|
| D1 | **Opening 16 does not mark anything read.** Only a tap or "Mark all read" does. | Figma draws "Mark all read", which would be pointless if opening cleared everything. |
| D2 | **16's Arabic header is mirrored** like every other screen (back on the right, "Mark all read" on the left). | Figma's AR frame is unmirrored by mistake; 15 AR is correct. |
| D3 | **Mock providers answer.** After your first send in a mock chat, the provider replies once about 4 s later with a canned line. | Makes the 5 s poll visible without a server. Mock only. |
| D4 | **"Usually replies in…" comes from 13's data.** For a provider chat, 15 loads `/app/providers/{other.id}` and shows its `replyTime`. The line is hidden on any failure or when the value is null. | The chat DTO has no reply time. That `provider.id` is a user id is unconfirmed (backend ask); a 404 simply hides the line. |
| D5 | **Messages tab keeps its unread badge** (count of chats with unread messages). The Home bell dot shows when `unreadNotifications > 0`. Both come from one `ShellBadges`. | The badge already exists and users expect it. Figma's nav component has no badge state, but the app added one in the discovery build. |
| D6 | **Time ladder** for rows, notifications and date pills: today `HH:mm`; "Yesterday"; this week the weekday (EN short "Mon", AR full "الإثنين"); this year `d MMM`; older `d MMM yyyy`. Always Western digits, and the time is its own LTR run. | Figma's ladder, plus a year for old chats. Digits follow the standing Arabic rule. |
| D7 | **Blank messages can't be sent.** Send is dimmed until the text (trimmed) or a photo exists. Text is capped at 4000 characters. | The API caps the first message at 4000; the send route has no limit, so cap it. |
| D8 | **Sending states.** A message shows at once, faded, with a small clock. On success it becomes the server's message. On failure it turns into "Not sent · Tap to retry" (error colour), and a tap re-sends it. | WhatsApp-style optimism; the API has no delivery or read states, so there are no ticks. |
| D9 | **"New messages" pill.** If a poll brings messages while you're scrolled up, a pill "New messages ↓" appears. A tap jumps to the bottom. At the bottom, new messages just appear. | Standard; avoids yanking the scroll while reading history. |
| D10 | **Older messages load as you scroll up** (30 per page via `before` = `nextBefore`), with a small spinner at the top while loading. | The API is cursor-paged, oldest-first within a page. |
| D11 | **Image-only messages** preview in 14 as "Photo" (with the image glyph) when `lastMessage` is empty. A sent photo bubble is the received one mirrored (brand fill). | Neither is drawn; both follow Figma's bubble rules. |
| D12 | **A deleted account** (`other == null`) shows as "Deleted account" with a generic avatar. **A blocked other party** (`other.blocked`) shows the notice "This account is no longer active. You can still read the conversation." in place of the composer. | The API allows both; Figma draws neither. Same pattern as the closed state. |
| D13 | **Search on 14** filters server-side (`q`, 300 ms debounce) and combines with the chips. No-match shows "No conversations match "…"". | The API supports `q` + `filter`. |
| D14 | **Masked messages** show Figma's caption under the text: "Number hidden until the booking is accepted" (in the bubble's secondary colour, own or received). Dispute chats never mask. | The API sets `masked: true`; Figma draws the caption on a sent bubble. |
| D15 | **An expired photo URL** (403 or failed load) shows a tap-to-reload tile. A tap refetches the newest page, which carries fresh signed URLs, and retries. | Signed URLs expire in ~15 min. |
| D16 | **The report sheet** is the standard bottom sheet (P3 treatment: 0.5 scrim, 24/24/0/0 corners). It lists the 6 reasons as radio rows (Inappropriate, Spam, Sharing contact details, Harassment, Fake or scam, Other), plus an optional note (≤ 2000) and a primary "Send report". A toast follows: "Thanks — we'll look into it" or, when `created == false`, "You already reported this". | Standing bottom-sheet rule. The API returns `created`. |

## 4. Architecture

### 4.1 Layers (unchanged pattern)

View → view model (`BaseViewModel`, no Material, no user-facing strings) → repository
interface → `Api…` / `Mock…` implementation → `ApiClient`. The `DataSource` switch (`EVENTOR_DATA`,
default mock) is wired only in `lib/app/app_services.dart`. The mock builds API-shaped JSON and
parses it with the same `fromJson`.

### 4.2 New shared code

| Path | Holds |
|---|---|
| `core/messaging/models/chat_person.dart` | `ChatPerson {id, name, avatarUrl?, role (client/provider/support), blocked}`. |
| `core/messaging/models/conversation.dart` | `ConversationKind {direct, support, dispute}`; `ChatBooking {id, reference, status, eventDate, title, total}`; `ConversationRow {id, kind, isClosed, other?, lastMessage?, lastMessageAt?, unreadCount, booking?, canWrite}`; `ConversationDetail` = row + `participants`, `contactUnmasked`, `disputeId?`, `createdAt`. `closedReason` is parsed but never shown. |
| `core/messaging/models/chat_message.dart` | `MessageKind {text, attachment, system}`; `ChatMessage {id, conversationId, kind, senderId?, mine, body, masked, imageUrl?, imageLargeUrl?, createdAt}` + `isRemoved` (`body == '[removed by Eventor]'`); `MessagePage {items (oldest first), hasMore, nextBefore?}`. |
| `core/messaging/models/report_reason.dart` | `ReportReason {inappropriate, spam, contactOutside, harassment, fake, other}` with API values. |
| `core/messaging/conversation_filter.dart` | `ConversationFilter {all, unread, booking}` with API values. |
| `core/messaging/messaging_repository.dart` | `MessagingRepository`: `conversations({filter, q, page})` → `ApiPage<ConversationRow>`, `conversation(id)`, `messages(id, {before})` → `MessagePage`, `sendText(id, body)`, `sendPhoto(id, PickedImage, {caption})` → `ChatMessage`, `sendDisputeText(disputeId, body)`, `start(userId, body)` → `ConversationDetail`, `markRead(id)`, `reportMessage(id, reason, note)`, `reportUser(userId, reason, note)` → `bool created`, `findWith(userId, name)` → `ConversationRow?` (list `q=name`, match `other.id`). `ApiMessagingRepository`. |
| `core/messaging/chat_poller.dart` | `ChatUpdates` interface (`start(onTick)`, `stop()`, `pause()`, `resume()`); `TimerChatUpdates` (5 s `Timer.periodic`; pauses via `AppLifecycleListener` when the app is hidden). A Socket.IO version can replace it later. |
| `core/messaging/picked_image.dart` | `PickedImage {name, bytes, extension}` + `validate(maxMb, types)` → `ImageProblem? {tooLarge, wrongType}`. The picker call lives in the view layer. |
| `core/notifications/models/app_notification.dart` | `AppNotification {id, type, title, body, data (conversationId?, bookingId?, href?), group (today/thisWeek/earlier), read, createdAt}` + `NotificationTarget` (chat(id) / unsupported). |
| `core/notifications/notifications_repository.dart` | `NotificationsRepository`: `list({page})`, `markRead(ids)` / `markAllRead()` → new unread count, `counts()` → `({int notifications, int conversations})` from `GET /app/me`. `ApiNotificationsRepository`. |
| `core/notifications/notification_icon.dart` | `type` prefix → `AppIcons` glyph (booking.accepted → check, .declined/.cancelled → close, message.*/dispute.* → message, *.reminder/*.reschedule*/*.waiting → calendar, review.* → star-filled, else bell). |
| `core/formatting/chat_time_format.dart` | The D6 ladder (`listTime`, `dayLabel`), `bubbleTime` (`HH:mm`). |
| `features/shell/shell_badges.dart` | + `unreadNotifications`; + `refresh(NotificationsRepository)` (on resume, after reads, on 14/16 load); `clear()` on sign-out. `HomeViewModel` keeps feeding it too. |
| `mock/mock_messaging.dart` + `mock/mock_messaging_data.dart` | In-memory conversations, messages and notifications built on the mock catalog's providers and Pexels photos. `MockMessagingRepository`, `MockNotificationsRepository`. |

Mock data covers every drawn state:
- 5 conversations mirroring Figma 14 (Studio Lumière, 2 unread, with a booking card; Salle Yasmine; Traiteur El Baraka, 1 unread; a dispute EVT-2041; Eventor support), plus more to page past 20.
- Inside them:
  - one closed chat
  - one chat whose other party is blocked
  - one deleted account
  - a removed message
  - a masked sent message
  - a received photo
  - a system pill
  - enough history to page older
- 8 notifications mirroring Figma 16 across Today / This week / Earlier, one of them a message notification carrying a `conversationId`.

### 4.3 Routing

| Route | Screen | Navigator |
|---|---|---|
| `/messages` | 14 | shell branch 3 (replaces the placeholder) |
| `/conversations/:id` | 15 | root (full screen, no nav) |
| `/conversations/new?user=&name=` | 15 draft | root; replaced by `/conversations/:id` after the first send |
| `/notifications` | 16 | root |

All four are client-only (`isClientOnly`). Screens open them with `push`, so Back returns to
where the user was (12, 13, 14, 16 or Home).

## 5. Screens

### 14 Messages
- **Header** (brand fill, padding 44/16/20/16, gap 16):
  - "Messages" Heading/XL on-brand, and the bell (on-brand-accent) → 16. The bell carries the same red dot as Home when there are unread notifications.
  - Search field (48, r12, surface).
- **Chips** All / Unread / Bookings (36 high, r999, Label/M; selected brand / default outlined).
- **List:** one card (r16, surface, border, card shadow, 1px dividers), with rows 76 high, padding 14/16, gap 12.
  - 48 avatar (photo or initials; support shows the Eventor mark; dispute shows "!").
  - Name (Body/M Strong) and a one-line preview (Body/S; primary colour when unread, secondary when read).
  - Meta column: time (Caption; brand when unread) and the count badge (20, brand) or a 20 spacer.
  - Dispute title: "Dispute · {reference}" when there is a booking reference, else "Dispute".
- **Paging and states:**
  - Pull to refresh; 20 per page with infinite scroll.
  - First load: G1 list-row skeleton.
  - Empty states (G2 pattern):
    - All: "No messages yet" / "When you write to a provider, your conversations appear here." / Secondary "Find a provider" → Search tab.
    - Unread: "You're all caught up".
    - Bookings: "No booking conversations yet".
    - Search: "No conversations match "{q}"".
  - Error with nothing cached: G2 error card with Retry.
  - Offline with a list showing: the offline banner (accent-subtle, border/accent, "You are offline" / "These are your last messages. New ones arrive when you reconnect." / "Retry"), with the AR order corrected.
- **Tab behaviour:** re-tapping the tab scrolls to the top (existing `TabReselect`). Returning from 15 refreshes the list.

### 15 Chat
- **Top bar** (surface, bottom border, padding 44/16/12/16, gap 12):
  - Back, 36 avatar, name (Heading/S), the D4 reply line (Caption), and ⋯ (hidden for support and dispute chats).
  - Name and avatar → 13 for a provider.
  - Group chats show "You, {provider} and Eventor support" as the subtitle.
- **Booking card** (when `booking != null`): brand-subtle, r12, padding 10/12.
  - Category icon (camera fallback), title (Body/M Strong brand, one line), and `{date} · {reference}` (Caption).
  - Status badge (pending/accepted/declined/cancelled/completed) and chevron → "Coming soon".
- **Thread:**
  - Padding 12/16, gap 10; newest at the bottom; list reversed so it opens at the bottom.
  - Date pills (bg/disabled, r999, Caption).
  - System pills (full width, centred Caption).
  - Bubbles:
    - Max width 268, padding 9/12/7/12.
    - Time inside, at the end (Caption).
    - Received: surface + border, corners 16/16/16/4.
    - Sent: brand, corners 16/16/4/16, mirrored in AR.
    - Photo bubble: image r8 at the bubble's width (max 244×180, fit cover), with the caption under it.
  - Masked caption (D14). Removed bubble: received style, text "Removed by Eventor" at 0.55 opacity, time kept.
  - Group sender labels (decision 8): Caption, secondary, 4 above the bubble.
  - Sending, failed and the "New messages" pill as D8/D9.
- **Composer** (surface, top border, padding 10/16/24/16 plus the keyboard inset, gap 8):
  - "+" (40, canvas; hidden in dispute chats).
  - Field (r999, canvas, border; grows to 5 lines then scrolls; placeholder "Write a message" or "Write to both parties").
  - Send (40, brand, chevron in the reading direction; dimmed when blank).
  - With a photo picked, a preview chip (64 thumbnail, file name, ✕) sits above the field, and the text becomes its caption.
- **Closed variants** (the composer becomes one full-width field showing the notice, secondary text):
  - Closed or muted: "This conversation was closed by Eventor. You can still read it." / "أغلق Eventor هذه المحادثة. لا يزال بإمكانك قراءتها." (AR aligned to EN).
  - Other party blocked: the D12 notice.
  - A send rejected with `CONVERSATION_CLOSED` (409 or 403) or `CONVERSATION_READ_ONLY` switches the chat to the closed variant and keeps the failed message as "Not sent".
- **Lifecycle:**
  - Open → load detail and the newest page → `markRead` → start the poller.
  - Each poll that brings new received messages calls `markRead` and refreshes `ShellBadges`.
  - Leaving stops the poller; pausing the app pauses it.
- **Draft state** (from 12/13):
  - Top bar from the provider (name, avatar, reply line); empty thread with a quiet "Say hello to {name}" hint.
  - Composer active. The first send → `start` → the route is replaced by `/conversations/:id`, and the history loads.
  - A photo can't be the first message (the API requires text). "+" in a draft shows "Send a message first".
- **Long-press** (decision 5): a small menu sheet. Copy → clipboard + toast "Copied". Report → D16 sheet.
- **Photo viewer:** full screen, black, `InteractiveViewer` (pinch/double-tap zoom), close ✕ and swipe down to dismiss; `imageLargeUrl` falling back to `imageUrl`.
- **States:**
  - First load: skeleton bubbles.
  - Load error: G2 error card with Retry (top bar still shown).
  - Not a participant / not found: "This conversation is no longer available" with Back.

### 16 Notifications
- **Header** (brand, padding 44/16/20/16): back, "Notifications" Heading/XL, "Mark all read" (Label/M on-brand-accent). The action is hidden when nothing is unread.
- **Groups:**
  - TODAY / THIS WEEK / EARLIER from the API's `group` (Overline secondary), gap 20.
  - Each group is a card with 1px dividers.
- **Item** (padding 14, gap 12, top-aligned):
  - 40 tile (brand-subtle, r12, 20 icon).
  - Title (Body/M Strong), body (Body/S secondary, up to 3 lines), time (Caption).
  - 8 unread dot at the top end, or an 8 spacer.
- **Tap:** mark read (optimistic; restored on failure with an error toast) → decision 4.
- **Paging and states:**
  - Pull to refresh; 20 per page.
  - Skeleton on first load.
  - Empty: "No notifications yet" / "Booking updates, messages and reminders will show up here."
  - Error card; offline banner as on 14.

### Entry-point changes
- **11 Home:** bell → `/notifications` (was "Coming soon"); dot from `ShellBadges.unreadNotifications`.
- **12 Service Detail:** the message icon button → draft or existing chat with `service.provider`.
- **13 Provider Profile:** "Send a message" (both states) → same.
- **While a lookup runs:** the button shows its loading state; a failed lookup opens the draft anyway.

## 6. Strings (EN / AR), new

`messagesTitle` Messages / الرسائل · `messagesSearchHint` Search a conversation / ابحث في المحادثات ·
`messagesFilterAll` All / الكل · `messagesFilterUnread` Unread / غير المقروءة · `messagesFilterBookings` Bookings / الحجوزات ·
`messagesEmptyTitle` No messages yet / لا توجد رسائل بعد · `messagesEmptyBody` When you write to a provider, your conversations appear here. / عندما تراسل مقدّم خدمة، ستظهر محادثاتك هنا. ·
`messagesEmptyAction` Find a provider / ابحث عن مقدّم خدمة · `messagesUnreadEmpty` You're all caught up / لا رسائل غير مقروءة ·
`messagesBookingsEmpty` No booking conversations yet / لا محادثات حجز بعد · `messagesNoMatch` No conversations match "{query}" / لا محادثات تطابق "{query}" ·
`offlineTitle` You are offline / أنت غير متّصل · `offlineMessagesBody` These are your last messages. New ones arrive when you reconnect. / هذه آخر رسائلك. الجديدة تصل عند عودة الاتصال. ·
`chatDispute` Dispute · {reference} / نزاع · {reference} · `chatDisputeNoRef` Dispute / نزاع · `chatSupport` Eventor support / دعم Eventor · `chatDeletedAccount` Deleted account / حساب محذوف ·
`chatPhoto` Photo / صورة · `chatToday` Today / اليوم · `chatYesterday` Yesterday / أمس ·
`chatComposerHint` Write a message / اكتب رسالة · `chatComposerDisputeHint` Write to both parties / اكتب إلى الطرفين ·
`chatClosed` This conversation was closed by Eventor. You can still read it. / أغلق Eventor هذه المحادثة. لا يزال بإمكانك قراءتها. ·
`chatOtherBlocked` This account is no longer active. You can still read the conversation. / هذا الحساب لم يعد نشطًا. لا يزال بإمكانك قراءة المحادثة. ·
`chatRemoved` Removed by Eventor / حذفه Eventor · `chatMaskedNote` Number hidden until the booking is accepted / الرقم مخفي حتى قبول الحجز ·
`chatNotSent` Not sent · Tap to retry / لم تُرسل · اضغط لإعادة المحاولة · `chatNewMessages` New messages / رسائل جديدة ·
`chatSayHello` Say hello to {name} / قل مرحبًا لـ {name} · `chatPhotoNeedsText` Send a message first / أرسل رسالة أولًا ·
`chatGroupSubtitle` You, {name} and Eventor support / أنت و{name} ودعم Eventor · `chatUnavailable` This conversation is no longer available / لم تعد هذه المحادثة متاحة ·
`chatViewProfile` View profile / عرض الملف · `chatReportUser` Report {name} / الإبلاغ عن {name} · `chatCopy` Copy / نسخ · `chatCopied` Copied / تم النسخ · `chatReportMessage` Report / إبلاغ ·
`photoTooLarge` This photo is larger than {mb} MB / هذه الصورة أكبر من {mb} ميغابايت · `photoWrongType` Use a JPEG, PNG, WebP or HEIC photo / استخدم صورة بصيغة JPEG أو PNG أو WebP أو HEIC · `photoReload` Tap to reload / اضغط لإعادة التحميل ·
`reportTitle` Report / إبلاغ · `reportReasonInappropriate` Inappropriate / غير لائق · `reportReasonSpam` Spam / رسائل مزعجة · `reportReasonContact` Sharing contact details / مشاركة بيانات الاتصال · `reportReasonHarassment` Harassment / تحرّش أو مضايقة · `reportReasonFake` Fake or scam / احتيال أو حساب مزيّف · `reportReasonOther` Other / سبب آخر ·
`reportNoteHint` Add a note (optional) / أضف ملاحظة (اختياري) · `reportSend` Send report / إرسال البلاغ · `reportSent` Thanks — we'll look into it / شكرًا — سنراجع الأمر · `reportAlready` You already reported this / سبق أن أبلغت عن هذا ·
`notificationsTitle` Notifications / الإشعارات · `notificationsMarkAll` Mark all read / تعليم الكل كمقروء · `notificationsToday` Today / اليوم · `notificationsThisWeek` This week / هذا الأسبوع · `notificationsEarlier` Earlier / أقدم ·
`notificationsEmptyTitle` No notifications yet / لا إشعارات بعد · `notificationsEmptyBody` Booking updates, messages and reminders will show up here. / ستظهر هنا تحديثات الحجوزات والرسائل والتذكيرات.

Group labels are uppercased in code for EN only. Every string goes through `arb_add.js`;
`l10n_missing.json` stays `{}`.

## 7. Errors

| Where | Failure | Behaviour |
|---|---|---|
| 14 / 16 load | network, cached list shown | offline banner + Retry |
| 14 / 16 load | anything, nothing cached | G2 error card + Retry |
| 15 load | `NOT_A_PARTICIPANT`, `CONVERSATION_NOT_FOUND` | "no longer available" state |
| 15 poll | any | silent; next tick retries |
| send | `CONVERSATION_CLOSED` (409/403), `CONVERSATION_READ_ONLY` | closed variant; message "Not sent" |
| send | `FILE_TOO_LARGE` / `FILE_TYPE_NOT_ALLOWED` | toast with D-copy; message "Not sent" |
| send | network, `RATE_LIMITED`, other | message "Not sent · Tap to retry" |
| start | `RECIPIENT_INVALID`, `USER_NOT_FOUND` | toast `forFailure`; draft stays |
| mark read / report | any | error toast via `forFailure`; state restored |
| any | session expired | the app's existing expiry flow |

## 8. Testing (written, not run)

- **Model parsing:**
  - row, detail, message (removed detection, masked, photo), page meta, notification (target, group)
  - null `other`, unknown `kind`/`type`
- **Repositories:**
  - `ApiMessagingRepository` / `ApiNotificationsRepository` against the scripted adapter: paths, query, bodies, multipart photo, dispute route, `findWith` match by id, 409 and 403 mapping.
  - Mock repositories: every drawn state present; start → reply after the delay.
- **`TimerChatUpdates`:** ticks every 5 s, pauses when hidden, stops on dispose (fake async).
- **View models:**
  - `MessagesViewModel`: filter + search debounce + paging + generation guard.
  - `ChatViewModel`:
    - load, older pages, poll merge by id, markRead on new received messages
    - optimistic send → success/failure → retry, photo validation
    - closed switch on error
    - draft → start → id
    - group sender runs
  - `NotificationsViewModel`: grouping, tap target, optimistic read + rollback, mark all.
- **Widgets:**
  - bubble corners EN/AR, masked caption, removed bubble, closed composer
  - send dimmed when blank, date pills, sender labels
  - 14 row unread styling, empty variants, offline banner order in AR
  - 16 header mirrored in AR, dot, icon mapping
- **Routing:** client-only redirects for the 3 new routes; Home bell → 16; 13 and 12 → draft; 16 message notification → 15.
- **Arabic number rule:** times and references render as LTR runs inside Arabic rows.

## 9. Out of scope

Socket.IO, FCM push and device tokens, F5 notification settings, booking screens (the card and
notification targets say "Coming soon"), the provider-side Messages list (providers still land
on their placeholder), deleting notifications or messages, blocking, camera capture, typing and
read receipts.

## 10. Backend asks (log in `eventor-open-questions`)

1. Socket.IO `/app`: auth transport, `message:new` / `conversation:updated` payloads, a `notification:new` event.
2. Notification `type` enum and `data.href` grammar; a `conversationId` in message and dispute notifications.
3. A `removed: true` flag on `AppMessageDto`.
4. `GET /app/conversations?userId=` (or `conversationId` on the provider DTOs).
5. Confirm catalog `provider.id` is the provider's user id.
6. `closedReason` as a localised enum; what a muted participant sees in `status`.
7. A delete-notification route (`NOTIFICATION_NOT_FOUND` exists unused).
8. One status for `CONVERSATION_CLOSED` (403 vs 409); `maxLength` on the send `body`.
9. `lastMessageMine` / `lastMessageKind` on the row (image-only previews come back blank).
10. Whether `POST /app/conversations/{id}/messages` also works in dispute chats (would allow photos there).

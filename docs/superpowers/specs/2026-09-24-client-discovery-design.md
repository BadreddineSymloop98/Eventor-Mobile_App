# Client discovery — design spec

**Date:** 2026-09-24 · **Status:** awaiting review · **Approach:** A (shared catalog layer, thin feature folders, shared favourites controller, `StatefulShellRoute`)

## 1. Goal

Replace the placeholder Home with the client's discovery experience, wired to the
live API and to an equivalent mock backend, in English and Arabic:

| Code | Screen | Figma (EN / AR) |
|---|---|---|
| 11 | Home · Client (+ loading state, + 11c no-budget card) | `460:508` / `573:952` |
| 11a | Home · Filters (right drawer) | `547:729` / `574:1017` |
| 11a | Wilaya picker (drill-in inside the drawer) | `1665:5804` / `1665:6215` |
| 12 | Service Detail | `501:626` / `507:670` |
| 13 | Provider Profile | `560:847` / `563:887` |
| 13 | State · Not accepting bookings | `1452:45657` / `1452:45664` |
| 19 | Ready Packs | `600:1521` / `601:1545` |
| 20 | Pack Detail | `603:1569` / `605:1600` |
| 17 | Favorites | `589:1237` / `594:1995` |
| S1 | Search · idle | `1652:5188` / `1653:6074` |
| S2 | Search results | `1651:5143` / `1653:6161` |
| S2a | Results · category | `1652:5340` / `1653:6264` |
| S2b | Results · empty | `1652:5449` / `1653:6369` |
| S3 | Wilaya picker · single | `1653:5289` / `1653:6419` |

Plus the **client shell**: the five-tab bottom nav with the animated `NavItem`
(filled glyphs, pop, stretchy indicator, per-icon signature loop).

**Success:** a signed-in client lands on a real Home, can browse, search,
filter, open services, providers and packs, pick a date on a calendar, and save
favourites — every list and detail handles loading, empty, error and the
not-accepting-bookings case — in mock builds (default) and with
`--dart-define=EVENTOR_DATA=live`.

## 2. Decisions already taken (user, 2026-09-24)

1. **Packs** are built to the live API as-is: one provider, 2–6 of their services.
2. **Section 13 search** (S1, S2, S2a, S2b, S3) is added to the scope.
3. **Unbuilt destinations stay visible and show a "Coming soon" toast.** Full
   5-tab nav; Bookings and Messages tabs are placeholders; the Profile tab is a
   placeholder with two working rows — **Favorites** (→ 17) and **Log out**.
4. **Home's wilaya pill** saves the city to the profile (`PATCH /app/me
   {wilayaCode}`), then Home reloads.
5. **Home's last section is "Services near you"** (the API returns services):
   service title, "Provider · Category", price + unit, rating; tap → 12; See all
   → S2 filtered to the user's wilaya.
6. **Filters adapted to the API:** category **single**-select; wilaya chips =
   your city + already-selected + "All wilayas" (drill-in, searchable, multi);
   **no Event type group, no "typical budget" line**; keep Sort, Budget range
   (0–500 000+ DA), Event date, Rating, Favourites only, live "Show N services".
7. **Calendars on 12 and 20:** live availability, month paging, date-only
   selection (no time range). Request buttons show "Coming soon" but keep the
   chosen date. **20's calendar replaces B9**: later, "Request pack" goes
   straight to B9a.
8. **Un-favourite** from 12/13/19/20/S2/Home = POST (idempotent, returns the
   row id) then DELETE — hidden inside the repository.
9. **Mock photos:** ~15–20 of the backend's own published photos (medium WebP)
   bundled as mock-only assets with a credits note.

## 3. Defaults I chose — please confirm or correct

These are not in the design or the API; each is what a well-known marketplace app does.

| # | Default | Why |
|---|---|---|
| D1 | **Providers keep today's placeholder**, moved to `/provider`; the client shell and every catalog route are client-only (providers redirected to `/provider`). | `21 Home · Provider` has its own nav and is not in this build; a provider in a client shell would be wrong. |
| D2 | **Empty Home sections are hidden** (no bookings → no "Your bookings"; no packs → no rail). The budget card always shows (11c when none). | The design draws no empty section states; famous feeds collapse them. |
| D3 | **Unrated items show "New"** instead of `0.0 ★` (API sends `"0.00"`, `ratingCount 0`). | Zero stars reads as bad, not as new. |
| D4 | **`on_quote` services show "On quote"** with no amount, though the API still sends a `basePrice`. | "From 45 000 DA" on a quote-only service is a promise the provider did not make. |
| D5 | **Greeting follows the clock**: Good morning (5–12), Good afternoon (12–18), Good evening (18–5). | The design shows "Good evening"; a fixed string would be wrong most of the day. |
| D6 | **Removing a favourite on 17 drops the card and offers Undo** in the toast (the toast gains an optional action). Elsewhere the heart just toggles. | Standard for destructive list edits. |
| D7 | **S3 closes on tap** (the existing single-select sheet), no "Done" button. | Same sheet as register's wilaya field; one tap is fewer than two. |
| D8 | **Pull-to-refresh** on Home, S2, 17 and 19; **infinite scroll** (20 per page) on S2, 17 and 19. | Brief requires pagination; both are expected on lists. |
| D9 | **Recent searches** are stored on the device, newest first, max 8, each removable, "Clear" empties them. | S1 draws them; the API has no search history. |
| D10 | **"See all N" on 13's services is shown only when the API returned fewer than `servicesCount`**, and then says "Coming soon" (no endpoint lists a provider's services). | The profile caps services at 10. |

## 4. Architecture

### 4.1 Layers (unchanged pattern)

`view` → `view model` (ChangeNotifier, no Material, no strings) → `repository`
interface → `Api…` (dio `ApiClient`) **or** `Mock…` (`MockBackend`), chosen once in
`AppServices` by `DataSource`.

### 4.2 New shared code — `lib/core/`

| Path | Holds |
|---|---|
| `network/api_client.dart` | + `getPage(path, query)` → `ApiPage<Map>` keeping `meta {page, limit, total, totalPages}`; + `delete(path)`. |
| `network/api_page.dart` | `ApiPage<T> {items, page, totalPages, total, hasMore}` + `map`. |
| `catalog/models/…` | Hand-written `fromJson` models, same style as `account.dart`: `Money`, `PriceType`, `Photo`, `ProviderSummary`, `ServiceCard`, `ServiceDetail` (facts, extras, photos, ratingBreakdown, recentReviews, providerPacks), `ProviderDetail` (checks, services, packs), `PackCard`, `PackDetail` (items, wilayas), `Review`, `RatingBar`, `Availability` + `AvailabilityDay {date, state}`, `Favourite`, `HomeFeed` (+ `UpcomingBooking`, `BudgetSummary`), `CategoryWithCount`, `EventType`. |
| `catalog/service_query.dart` | Immutable filter set: `q`, `categoryId`, `wilayaCodes`, `priceMin/Max`, `minRating`, `eventDate`, `favouritesOnly`, `order`; `toQuery()` for the API (repeated `wilaya=`), `activeCount`, `copyWith`, `cleared()`. |
| `catalog/catalog_repository.dart` | `CatalogRepository`: `home()`, `services(query, page)`, `service(id)`, `serviceAvailability(id, month)`, `provider(id)`, `packs({eventType, order, page})`, `pack(id)`, `packAvailability(id, month)`, `categories()` (with counts). `ApiCatalogRepository`. |
| `catalog/favourites_repository.dart` | `FavouritesRepository`: `list({kind, categoryId, page})`, `add(target)` → `Favourite`, `remove(target)` (POST-then-DELETE, decision 8), `removeById(id)`. `ApiFavouritesRepository`. |
| `catalog/favourites_controller.dart` | App-wide `ChangeNotifier` (above the router, like `SessionController`). Holds per-target overrides so a heart toggled anywhere shows everywhere at once; **optimistic** toggle with rollback + error toast; cleared on sign-out. |
| `formatting/money_format.dart` | `"120000.00"` → `"120 000"` (thin-space grouping, Western digits, `.00` dropped, other decimals kept). Never parses to `double`. |
| `widgets/…` | See §6. |

### 4.3 Profile write

`AuthRepository.updateWilaya(int code)` → `PATCH /app/me {wilayaCode}` →
returns `AppUser`; `SessionController.updateUser(user)` notifies. (The mock
backend gains the same, and **fixes `toUser()` to carry the seeded wilaya** — the
seed client is in 16 Alger but the mock drops it today.)

### 4.4 Routing — `StatefulShellRoute.indexedStack`

| Route | Screen | Navigator |
|---|---|---|
| `/home` | 11 Home | shell branch 0 |
| `/search` | S1 | shell branch 1 |
| `/bookings` | placeholder | shell branch 2 |
| `/messages` | placeholder | shell branch 3 |
| `/profile` | placeholder (Favorites, Log out) | shell branch 4 |
| `/search/results?q=&category=&wilaya=…` | S2 / S2a / S2b | root (full screen, no nav — as drawn) |
| `/services/:id` | 12 | root |
| `/providers/:id` | 13 | root |
| `/packs?eventType=` | 19 | root |
| `/packs/:id` | 20 | root |
| `/favourites` | 17 | root |
| `/provider` | provider placeholder (D1) | root |

Filters (11a) is a **modal side drawer** (`showGeneralDialog`, slides from the
trailing edge, 320 wide, 24 radius on its leading corners, 0.5 scrim) that
returns a `ServiceQuery`; its wilaya drill-in is a second page *inside* the
drawer (Back returns to the filters). S3 is the existing selection sheet.
Filter state travels as **query parameters**, so S2 is deep-linkable and Back
restores it.

`AppRedirect` gains: signed-in **provider** on any client route → `/provider`;
signed-in **client** on `/provider` → `/home`. Shell tabs keep their own stack
and scroll; re-tapping the active tab scrolls it to the top.

## 5. Screens

Every list/detail follows **G1/G2**: skeleton that matches the layout on first
load (no spinner), an error card with "Try again", an empty card with one
action. A refresh that fails keeps the old content and shows an error toast.

**11 Home** — brand header: initials avatar (`AppAvatar`), time-of-day greeting
(D5), full name, bell with unread dot from `unreadNotifications` (→ Coming soon),
wilaya pill (`wilaya` or "Choose your city") → S3 → `updateWilaya` → reload;
search field (tap → Search tab) + filter button (→ 11a → S2). Then: category rail
(→ S2a) · Your bookings (≤2 `upcomingBookings`, `BookingCard`, See all → Bookings
tab, card → Coming soon) · budget card (`budget.exists` ? summary : 11c; both →
Coming soon) · Ready Packs rail (→ 20, See all → 19) · Services near you (→ 12,
See all → S2 with wilaya). Loading: `11 · State · loading` skeleton.
Pull-to-refresh. Unread Messages count feeds the nav badge.

**S1 Search idle** — autofocused search field, recent searches (D9), browse
categories with `servicesCount`. Submit → S2 `?q=`.

**S2 / S2a / S2b** — header (query or category title + Back), "N services",
chips "Sort · X" (sheet with 6 orders) and "Filters · N" (→ 11a), result cards
per S2 (thumb, title, "Provider · Category", rating or New, heart, wilaya,
"Booked N times", price + unit), infinite scroll. S2a = category preset shown
as a removable chip. S2b = no results: message naming the active filters, their
removable chips, "Clear all filters".

**11a Filters** — decision 6. Live count: debounced (300 ms) `limit=1` request,
"Show N services"; "Clear all" resets. Event date opens the shared month
calendar in a sheet; past days disabled.

**12 Service Detail** — photo carousel (counter, Back, heart; placeholder tile
when no photos) · verified badge · title · rating/New · wilayas · provider
mini-card (reply time only when the API has it) → 13 · facts card
(`facts[]`) · About (4 lines + "Read more") · Good to know
(`cancellationPolicy`, shown only when set — never the hard-coded "30 days") ·
Extras (name + price, info only) · **calendar** (decision 7; min notice from
`/app/config`; legend: available / fully booked / unavailable / selected) ·
Reviews (summary + breakdown + 3 recent; See all → Coming soon) · Packs from
this provider (→ 20) · Report (→ Coming soon) · sticky bar: price + unit (D4),
Message (Coming soon), **Request booking** (Coming soon, date kept).
**Not accepting** (`provider.acceptingBookings == false`): the bar becomes 13's
state — "Not taking new bookings" + "Messages are still open" + Message; the
calendar still shows but cannot be selected.

**13 Provider Profile** — brand cover band (the API has no cover photo),
88 avatar with initials, verified badge, name, "Category · wilayas", stat strip
(rating or New · completed bookings · years in business, each hidden when null),
What we checked (`checks[]`), About, Services (≤10 rows → 12; D10), Packs (→ 20),
Where they work (wilayas, languages, member since), Reviews, Report, sticky bar
"Usually replies in X" (hidden when null) + Send a message (Coming soon).
**13 · Not accepting** state replaces the bar exactly as drawn.

**19 Ready Packs** — header + subtitle, event-type chips (All + the API's types
except `academic`), sort row (sheet: best savings, lowest/highest price, top
rated, most popular), large pack cards (photo, savings pill, heart, name,
"N services · categories" with duplicates removed, provider, price), infinite
scroll, per-filter empty state.

**20 Pack Detail** — carousel · "Ready Pack · N services" · name · rating/New ·
"N bookings" · wilaya · price card (price, struck `sumOfItems`, savings pill) ·
provider card → 13 · What's inside (items → 12, "Booked separately" total) ·
calendar (pack availability — only days every item is free) · About · Good to
know (max guests; "Available in" the wilayas every item covers) · recent reviews
· sticky bar price + Message + **Request pack** (Coming soon, date kept) ·
not-accepting state as on 12.

**17 Favorites** — header, Services / Packs tabs (`kind`), category chips on
Services (`categoryId`), 2-column grid (photo, heart, title, provider, From X),
unavailable variant (40% photo, "No longer available", not tappable), per-tab
empty state with "Explore" → Search tab, infinite scroll, D6 undo.

**Profile placeholder** — name + email, rows: Favorites (→ 17), Log out; a
"More settings are coming soon" note.

## 6. Shared widgets to add

`AppNetworkImage` (cached; cache key strips `exp`/`sig` so 15-minute signed
URLs stay cached; placeholder = category tile) · `PhotoCarousel` · `PriceText`
(amount token LTR + unit, Arabic reading order per the number-token rule) ·
`FavouriteButton` (reads `FavouritesController`; filled heart glyph added) ·
`SectionHeader` (title + optional action) · `CategoryRail` · `PackCard`
(compact rail / large list) · `ServiceResultCard` · `FavouriteTile` ·
`ReviewCard` + `RatingSummary` · `FactsCard` · `ReadMoreText` · `StatStrip` ·
`StickyActionBar` (+ not-accepting variant) · `MonthCalendar` (states,
legend, paging, selection, RTL-aware weekday order) · `SideDrawer` ·
`RangeSliderField` · `Skeleton` blocks · `StateCard` (empty / error) ·
`VerifiedBadge`. All added to the debug gallery. `showAppToast` gains an
optional action (D6).

## 7. Mock backend

`lib/mock/mock_catalog_data.dart`: a snapshot of the live catalog (12
providers, 41 services, 8 packs, categories, reviews) **plus edge cases** the
live data lacks: a provider with bookings paused, an unrated service, an
`on_quote` service, a provider with 12 services (D10), a favourite that is no
longer available, a service with no photos. Photos from `assets/mock/photos/`
(decision 9). Availability generated per month (busy/blocked days, min
notice). `MockCatalogRepository` and `MockFavouritesRepository` implement the
API's filters, sort orders, paging and error codes (`SERVICE_NOT_FOUND`,
`PACK_NOT_FOUND`, `FAVOURITE_*`); favourites and the profile wilaya persist in
`MockBackend`; "Reset mock data" clears them.

## 8. Errors

New `ApiErrorCode`s: `SERVICE_NOT_FOUND`, `PACK_NOT_FOUND`, `PROVIDER_NOT_FOUND`,
`FAVOURITE_NOT_FOUND`, `FAVOURITE_TARGET_INVALID`, `FORBIDDEN_ROLE`. A detail
that 404s shows "This is no longer available" with Back; a favourite toggle
that fails rolls back with a toast. The catalog is public but always sent with
the token (the API silently treats a stale token as anonymous — hearts would
all read off), so the client refreshes first.

## 9. Localization

All new copy in both ARB files with `@` descriptions; counts via ICU plurals
(six Arabic forms); amounts never interpolated into Arabic strings (§6
`PriceText`); UI house style keeps the space before `?`/`!`.

## 10. Testing (written, run by the user)

Model `fromJson` from the saved live samples; `ApiClient.getPage/delete`;
`ServiceQuery.toQuery`; money format; each view model (load, empty, error,
paging, refresh, filters, favourite rollback, not-accepting); mock repositories
(filters/sort/paging match the API); `FavouritesController` sync; redirect
(client/provider routing, shell); widget tests per screen in EN and AR
(skeleton → content, empty, error, not-accepting, RTL amount order); calendar
states and RTL.

## 11. Out of scope

B1/B9a booking, 16 Notifications, 15 Chat, B3/B4 bookings, 18 Budget, R2 reviews
list, RP1 report, F1 real profile, 21 Provider home, 11b rating prompt, offline
cache (cold-start offline screen `26` belongs to the gates work).

## 12. Backend asks (to send)

`favouriteId` on cards or delete-by-target · a wilaya ranking or
`servicesCount` per wilaya · `providerId` on `/app/services` (see all of a
provider's services) · Arabic search · `sort` ignored (only `order` works) ·
pack reviews + breakdown · per-provider cancellation policy on packs · the hidden
"Transport" category · the Beauty category's empty Arabic name · paused-bookings
reason / until · `eventDate` should respect min notice · a documented deep-link
and share URL format.

# Client discovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the placeholder Home with the client shell (animated 5-tab nav) and 14 discovery screens (11, 11a + wilaya drill-in, 12, 13 + not-accepting, 17, 19, 20, S1, S2, S2a, S2b, S3), backed by the live API and an equivalent mock backend, in EN and AR.

**Architecture:** Approach A. A shared catalog layer in `lib/core/catalog/` (models, `CatalogRepository`, `FavouritesRepository`, `ServiceQuery`, app-wide `FavouritesController`), each repository with an `Api…` and a `Mock…` implementation picked once in `AppServices`. Thin feature folders per screen (`view_model/` + `view/`). Navigation moves to a go_router `StatefulShellRoute.indexedStack`; detail screens open on the root navigator.

**Tech Stack:** Flutter 3.47 / Dart ^3.13, provider, go_router ^18, dio ^5, cached_network_image ^4, intl, flutter_svg, shared_preferences.

**Spec:** `docs/superpowers/specs/2026-09-24-client-discovery-design.md` (approved 2026-09-24). API reference: the session scratchpad `api/catalog-contract.md` (field lists copied into Task 3 below).

## Global Constraints

- **User rule — tests:** write every test listed; **do not run `flutter test`**. The verification step of each task is `flutter analyze --no-pub lib test` → "No issues found!". The user runs the suite.
- **User rule — git:** **no commits** unless the user asks. Tasks end with analyze, not commit.
- **Mock first:** every repository has a `Mock…` twin behind the same interface, wired only in `lib/app/app_services.dart`; mock is the default build.
- **Conventions:** explicit types on locals/collections; why-comments only; view models import no Material and produce no user-facing strings; widgets read colours/type from `AppColors` / theme; every dimension through `.dh`/`.dw` except font sizes, `AppRadii`, `maxContentWidth`, hairlines; `EdgeInsetsDirectional` / `AlignmentDirectional`.
- **Arabic amounts:** never interpolate a spaced number into an Arabic string; render amount (LTR token) and unit/currency as separate `Text`s (`PriceText`, Task 2).
- **Money:** strings with 2 decimals, DZD; never parsed to `double`.
- **Copy:** every string in `app_en.arb` (with `@key` description) and `app_ar.arb`; counts via ICU plural (Arabic six forms); space before `?`/`!` in EN UI copy; run `flutter gen-l10n` after ARB edits; `l10n_missing.json` must stay `{}`.
- **Sheets:** `showAppBottomSheet` / `AppSheetScaffold` (P3 rule: 0.5 scrim, 24/24/0/0).
- **"Coming soon":** one l10n key `comingSoon`, shown via `showAppToast(..., tone: info)` for every unbuilt destination (spec §2.3).

## Review Focus

1. **A 15-minute signed photo URL** changes on every response — images must not re-download or 403 after expiry (cache key strips `exp`/`sig`; Task 10 test).
2. **Toggling a heart twice fast / on a flaky network** — the heart must end in the last-tapped state and roll back only the failed request (Task 9 test: overlapping toggles, one failure).
3. **A provider account** opening any client route (deep link, Back stack) must land on `/provider`, never a half-working client screen (Task 12 redirect tests).
4. **Arabic amounts** in every price row (cards, sticky bars, pack price card, filters range) must read `[currency][number]` in visual order and keep `45 000` unreversed (Task 2 test + per-screen AR widget tests).
5. **Paging past the end / empty filter results / a detail that 404s** must show S2b / empty cards / "no longer available", never a spinner forever (Tasks 16, 17, 20, 21 tests).

---

## File Structure

```
lib/core/network/api_client.dart            (modify: getPage, delete)
lib/core/network/api_page.dart              (new)
lib/core/formatting/money_format.dart       (new)
lib/core/catalog/models/catalog_ref.dart    (new: CategoryRef, CategoryWithCount, WilayaRef→reuse Wilaya)
lib/core/catalog/models/money.dart          (new: Money, PriceType)
lib/core/catalog/models/photo.dart          (new)
lib/core/catalog/models/provider.dart       (new: ProviderSummary, ProviderCheck, ProviderDetail)
lib/core/catalog/models/service.dart        (new: ServiceCard, ServiceDetail, ServiceFact, ServiceExtra)
lib/core/catalog/models/pack.dart           (new: EventType, PackCard, PackDetail, PackItem)
lib/core/catalog/models/review.dart         (new: Review, RatingBucket)
lib/core/catalog/models/availability.dart   (new: Availability, AvailabilityDay, DayState)
lib/core/catalog/models/favourite.dart      (new: Favourite, FavouriteKind, FavouriteTarget)
lib/core/catalog/models/home_feed.dart      (new: HomeFeed, UpcomingBooking, BudgetSummary)
lib/core/catalog/service_query.dart         (new)
lib/core/catalog/catalog_repository.dart    (new: interface + ApiCatalogRepository)
lib/core/catalog/favourites_repository.dart (new: interface + ApiFavouritesRepository)
lib/core/catalog/favourites_controller.dart (new)
lib/core/catalog/recent_searches.dart       (new)
lib/mock/mock_catalog_data.dart             (new)
lib/mock/mock_catalog.dart                  (new: MockCatalogRepository, MockFavouritesRepository)
lib/mock/mock_backend.dart                  (modify: favourites + wilaya state, toUser wilaya)
lib/mock/mock_repositories.dart             (modify: MockAuthRepository.updateWilaya)
assets/mock/photos/*.webp + CREDITS.md      (new)
lib/core/widgets/atoms/{app_network_image,skeleton,verified_badge}.dart
lib/core/widgets/molecules/{price_text,favourite_button,section_header,state_card,read_more_text,stat_strip}.dart
lib/core/widgets/organisms/{month_calendar,photo_carousel,review_views,facts_card,sticky_action_bar,pack_cards,service_result_card,favourite_tile,category_rail,side_drawer,range_slider_field}.dart
lib/core/routing/{app_routes,app_router}.dart (modify: shell, routes, redirect)
lib/features/shell/view/client_shell.dart   (new)
lib/features/shell/view/placeholder_tab_view.dart, profile_tab_view.dart (new)
lib/features/home/{view_model/home_view_model.dart, view/home_view.dart, view/widgets/*}
lib/features/provider_home/view/provider_home_view.dart (moved placeholder)
lib/features/search/{view_model/search_view_model.dart, results_view_model.dart, view/search_view.dart, view/results_view.dart}
lib/features/filters/{view_model/filters_view_model.dart, view/filters_drawer.dart, view/wilaya_drill_in.dart}
lib/features/service_detail/{view_model,view}/…
lib/features/provider_profile/{view_model,view}/…
lib/features/packs/{view_model,view}/…          (19)
lib/features/pack_detail/{view_model,view}/…    (20)
lib/features/favourites/{view_model,view}/…     (17)
test/… mirrors lib/ ; test/fixtures/catalog/*.json (copied live samples)
```

---

### Task 1: Paged GET and DELETE on `ApiClient`

**Files:**
- Create: `lib/core/network/api_page.dart`
- Modify: `lib/core/network/api_client.dart` (add methods beside `get`)
- Test: `test/core/network/api_client_test.dart` (extend, uses `ScriptedAdapter`)

**Interfaces:**
- Produces:
```dart
class ApiPage<T> {
  const ApiPage({required this.items, required this.page, required this.totalPages, required this.total});
  final List<T> items; final int page; final int totalPages; final int total;
  bool get hasMore => page < totalPages;
  ApiPage<R> map<R>(R Function(T) convert);
  static ApiPage<T> empty<T>() ;
}
// ApiClient
Future<ApiPage<Map<String, Object?>>> getPage(String path, {Map<String, Object?>? query, bool isPublic = false});
Future<void> delete(String path);
```
- `getPage` must pass list query values through dio as repeated keys (`ListFormat.multi`) so `wilaya=16&wilaya=31` is sent.

- [ ] **Step 1: tests** — `getPage` returns items + meta from `{data:[…], meta:{page:1,limit:20,total:41,totalPages:3}}`; `hasMore` true on page 1 of 3, false on 3 of 3 and on `totalPages: 0`; a list query value is sent as repeated keys (assert the adapter saw `wilaya=16&wilaya=31`); `delete` sends DELETE with the bearer token and accepts 204; a 404 on `delete` maps to `ApiFailure(code: 'FAVOURITE_NOT_FOUND')`.
- [ ] **Step 2: implement** — reuse `_send`/interceptors; `_unwrapPage` reads `data` (List) and `meta`.
- [ ] **Step 3: verify** — `flutter analyze --no-pub lib test`.

### Task 2: Money formatting and `PriceText`

**Files:**
- Create: `lib/core/formatting/money_format.dart`, `lib/core/widgets/molecules/price_text.dart`
- Modify: ARB files — `currencyDzd` ("DA" / "دج"), `priceOnQuote` ("On quote" / "حسب الطلب"), `ratingNew` ("New" / "جديد")
- Test: `test/core/formatting/money_format_test.dart`, `test/core/widgets/molecules/price_text_test.dart`

**Interfaces:**
```dart
/// "120000.00" → "120 000"; "2500.50" → "2 500.50"; "0.00" → "0". Thin no-break space (U+202F).
String formatAmount(String apiAmount);
class PriceText extends StatelessWidget {
  const PriceText({required this.amount, this.prefix, this.unit, this.style, this.unitStyle, super.key});
  final String amount;      // API string
  final String? prefix;     // e.g. l10n.priceFrom
  final String? unit;       // e.g. priceTypeLabel
}
```
- Visual order: EN `[prefix] [amount] [DA] [unit]`; AR the same **reading** order, i.e. a `Row` in ambient RTL whose children are `[prefix, amount(LTR), دج, unit]` — the Row mirrors, so the leading word has the greatest x.
- [ ] **Step 1: tests** — format cases above plus `"45000"`, `"1200.00"`; widget test in AR: `ابتداءً من` has greater x than the amount, amount `Text.textDirection == ltr`, amount string equals `'45 000'`.
- [ ] **Step 2: implement.**  **Step 3:** `flutter gen-l10n` then analyze.

### Task 3: Catalog models

**Files:** `lib/core/catalog/models/*.dart` (see File Structure); fixtures `test/fixtures/catalog/{home,services_page,service_detail,provider_detail,packs_page,pack_detail,availability,favourites_page}.json` copied from the scratchpad `api/live_*.json`; test `test/core/catalog/models_test.dart`.

**Interfaces (field names = API):**
```dart
enum PriceType { perEvent, perHour, perPerson, perDay, onQuote; static PriceType fromApi(String?); } // unknown → perEvent
class CategoryRef { id, slug, name, nameEn, nameAr, icon }            // name resolved by server
class CategoryWithCount extends CategoryRef { position, servicesCount }
// Wilaya reused from core/models/account.dart (code, nameEn, nameAr, nameFor)
class Photo { id, thumbUrl, mediumUrl, largeUrl, int? width, int? height }
class ProviderSummary { id, businessName, CategoryRef? category, String? avatarUrl, bool verified,
  String avgRating, int ratingCount, int completedBookingsCount, int? yearsActive, String? replyTime,
  bool acceptingBookings; bool get isRated => ratingCount > 0; }
class ProviderCheck { code, title, detail, passed }
class ProviderDetail extends ProviderSummary { String? bio, List<String> languagesSpoken, List<Wilaya> wilayas,
  List<ProviderCheck> checks, int servicesCount, List<ServiceCard> services, List<PackCard> packs,
  List<RatingBucket> ratingBreakdown, List<Review> recentReviews, DateTime memberSince }
class ServiceCard { id, title, CategoryRef? category, String basePrice, PriceType priceType, String priceTypeLabel,
  String avgRating, int ratingCount, int bookingsCount, String? coverUrl, List<Wilaya> wilayas,
  ProviderSummary provider, bool isFavourite; bool get isRated; }
class ServiceFact { label, value } ; class ServiceExtra { id, name, price }
class ServiceDetail extends ServiceCard { description, String? cancellationPolicy, facts, extras, photos,
  int? maxGuests, int maxEventsPerDay, ratingBreakdown, recentReviews, List<PackCard> providerPacks }
enum EventType { wedding, engagement, henna, birthday, circumcision, graduation, corporate, conference, academic, other }
class PackCard { id, name, EventType eventType, Wilaya wilaya, price, sumOfItems, savings, num savingsPercent,
  int itemsCount, List<String> categoryNames /* de-duplicated, order kept */, coverUrl, avgRating, ratingCount,
  bookingsCount, ProviderSummary provider, bool isFavourite }
class PackItem { serviceId, title, CategoryRef? category, price, PriceType priceType, coverUrl, position }
class PackDetail extends PackCard { String? description, int? maxGuests, photos, items (sorted by position), wilayas, recentReviews }
class Review { id, authorName, String? authorAvatarUrl, int rating, comment, bool redacted, String? reply, DateTime createdAt }
class RatingBucket { int stars, int count, num percent }
enum DayState { available, busy, blocked }
class AvailabilityDay { DateTime date, DayState state }
class Availability { String month, int minNoticeDays, DateTime firstBookableDate, List<AvailabilityDay> days;
  DayState stateOf(DateTime day); }
enum FavouriteKind { service, pack }
class FavouriteTarget { FavouriteKind kind; String id; }   // == / hashCode on both
class Favourite { id, FavouriteKind kind, targetId, title, providerName, CategoryRef? category, fromPrice,
  coverUrl, avgRating, ratingCount, bool available, DateTime createdAt; FavouriteTarget get target; }
class UpcomingBooking { id, reference, providerName, String? title, CategoryRef? category, DateTime eventDate, String? startTime, String status }
class BudgetSummary { bool exists, spentTotal, totalAmount, num spentPercent, int bookedCount, int itemsCount }
class HomeFeed { fullName, Wilaya? wilaya, int unreadNotifications, int unreadConversations,
  List<CategoryWithCount> categories, List<UpcomingBooking> upcomingBookings, BudgetSummary budget,
  List<PackCard> packs, List<ServiceCard> nearbyServices }
```
- Localised fields: parse the server-resolved `name`/`title`/`description` (the server translates by `Accept-Language`). Style of `account.dart`: `factory X.fromJson(Map<String, Object?> json)`, defensive casts, `(num).toInt()`.
- [ ] **Step 1: tests** — each fixture parses; spot-check: `PriceType.fromApi('per_day') == perDay`; unknown price type → `perEvent`; `"0.00"`/0 → `isRated == false`; pack `categoryNames` `["Photography","Photography"]` → `["Photography"]`; `PackDetail.items` sorted by `position`; `Availability.stateOf` for a listed day and an unlisted day (→ `blocked`); `FavouriteTarget` equality.
- [ ] **Step 2: implement.**  **Step 3:** analyze.

### Task 4: `ServiceQuery`

**Files:** `lib/core/catalog/service_query.dart`; test `test/core/catalog/service_query_test.dart`.

```dart
enum ServiceOrder { relevance, priceAsc, priceDesc, rating, popular, newest; String get apiValue; }
class ServiceQuery {
  const ServiceQuery({this.q, this.categoryId, this.wilayaCodes = const <int>{}, this.priceMin, this.priceMax,
    this.minRating, this.eventDate, this.favouritesOnly = false, this.order = ServiceOrder.relevance});
  static const int priceCeiling = 500000; // "500 000+" = no priceMax
  Map<String, Object?> toQuery();          // omits defaults; wilaya → List<int>; eventDate → 'YYYY-MM-DD'; minRating → num
  int get filterCount;                     // excludes q and order
  ServiceQuery copyWith({...}); ServiceQuery clearFilters(); // keeps q
  Map<String, String> toRouteParams(); static ServiceQuery fromRouteParams(Map<String, List<String>>);
}
```
- [ ] **Step 1: tests** — defaults → `{}`; each field maps (`order=price_asc`, `rating=4.5`, `favourite=true`, `eventDate=2026-03-14`); `priceMax == priceCeiling` omitted; route params round-trip incl. two wilayas; `filterCount` counts category, wilayas (as 1), price, rating, date, favourites.
- [ ] **Step 2: implement.**  **Step 3:** analyze.

### Task 5: `CatalogRepository` (API)

**Files:** `lib/core/catalog/catalog_repository.dart`; test `test/core/catalog/api_catalog_repository_test.dart` (ScriptedAdapter + fixtures).

```dart
abstract interface class CatalogRepository {
  Future<HomeFeed> home();                                            // GET /app/home
  Future<List<CategoryWithCount>> categories();                        // GET /app/categories (cached per run)
  Future<ApiPage<ServiceCard>> services(ServiceQuery query, {int page = 1, int limit = 20}); // GET /app/services
  Future<ServiceDetail> service(String id);                            // GET /app/services/{id}
  Future<Availability> serviceAvailability(String id, DateTime month); // ?month=YYYY-MM
  Future<ProviderDetail> provider(String id);                          // GET /app/providers/{id}
  Future<ApiPage<PackCard>> packs({EventType? eventType, PackOrder order = PackOrder.savings, int page = 1});
  Future<PackDetail> pack(String id);
  Future<Availability> packAvailability(String id, DateTime month);
}
enum PackOrder { savings, priceAsc, priceDesc, rating, popular; String get apiValue; }
class ApiCatalogRepository implements CatalogRepository { ApiCatalogRepository(this._api); }
```
- Catalog calls are sent **with** the token (not `isPublic`) so `isFavourite` is filled (spec §8).
- [ ] **Step 1: tests** — paths/params per method (month `2026-03`, packs `eventType=wedding&order=price_asc`), parsing into models, 404 → `ApiFailure` code `SERVICE_NOT_FOUND`.
- [ ] **Step 2: implement.**  **Step 3:** add `ApiErrorCode.serviceNotFound, packNotFound, providerNotFound, favouriteNotFound, favouriteTargetInvalid, forbiddenRole` to `failure.dart`; analyze.

### Task 6: `FavouritesRepository` (API)

**Files:** `lib/core/catalog/favourites_repository.dart`; test `test/core/catalog/api_favourites_repository_test.dart`.

```dart
abstract interface class FavouritesRepository {
  Future<ApiPage<Favourite>> list({FavouriteKind? kind, String? categoryId, int page = 1});
  Future<Favourite> add(FavouriteTarget target);      // POST {serviceId}|{packId}
  Future<void> remove(FavouriteTarget target);        // POST (idempotent) → id → DELETE (decision 8)
  Future<void> removeById(String favouriteId);        // DELETE, used by 17
}
```
- [ ] **Step 1: tests** — `add` body is exactly one key; `remove` issues POST then DELETE with the returned id; `removeById` 404 `FAVOURITE_NOT_FOUND` is swallowed (already gone = success); list passes `kind`, `categoryId`.
- [ ] **Step 2: implement.**  **Step 3:** analyze.

### Task 7: Profile wilaya write

**Files:** modify `lib/features/auth/data/auth_repository.dart` (+`updateWilaya`), `lib/core/session/session_controller.dart` (+`updateUser`), `test/support/fakes.dart` (FakeAuthRepository.updateWilaya), tests in `test/core/session/session_controller_test.dart` and the auth repository test.

```dart
Future<AppUser> updateWilaya(int wilayaCode); // PATCH /app/me {wilayaCode}
void SessionController.updateUser(AppUser user); // replaces user, notifies; no-op when signed out
```
- [ ] tests: PATCH body; session notifies with the new wilaya; signed-out no-op. Implement. Analyze.

### Task 8: Mock catalog

**Files:**
- Create: `assets/mock/photos/` (18 WebP, `GET …/files/{id}?variant=medium` of live published photos — read-only GETs) + `assets/mock/photos/CREDITS.md`; `pubspec.yaml` assets entry `assets/mock/photos/`
- Create: `lib/mock/mock_catalog_data.dart` (providers, services, packs, reviews, categories with counts; snapshot of live + edge cases: paused provider `Salle El Djazair` (`acceptingBookings: false`), unrated service, `on_quote` service, provider with 12 services, a service with no photos, an unavailable favourite seed)
- Create: `lib/mock/mock_catalog.dart` — `MockCatalogRepository implements CatalogRepository`, `MockFavouritesRepository implements FavouritesRepository`
- Modify: `lib/mock/mock_backend.dart` — persisted `favourites` (list of `{id, kind, targetId, createdAt}`) and `wilayaCode` per account; `toUser()` fills `wilaya` from `mockWilayas`; `reset()` clears; `lib/mock/mock_repositories.dart` — `MockAuthRepository.updateWilaya`
- Mock photo URLs are `asset:` URIs (`asset:assets/mock/photos/p07.webp`); `AppNetworkImage` (Task 10) loads them with `AssetImage`.
- Availability: deterministic per (id, month): Fridays `busy`, every 9th day `blocked`, days before `today + minNoticeDays(1)` `blocked`.
- Behaviour parity: filters (q over title+provider **in both languages** — the mock is kinder than live; note in a comment), category, wilaya OR, price range, rating, eventDate (drops busy/blocked), favourite, the six orders, paging `meta`; `SERVICE_NOT_FOUND`/`PACK_NOT_FOUND`/`PROVIDER_NOT_FOUND`; `requireSession()` for home/favourites.
- Wire: `AppServices` picks Mock/Api for both repositories; `EventorApp` provides them.
- [ ] tests `test/mock/mock_catalog_test.dart`: each filter and order; paging totals; paused provider flagged; eventDate drops a Friday; favourites add/remove persist across `MockBackend.load`; `toUser` carries wilaya 16 for `client@eventor.test`; updateWilaya persists.
- [ ] implement; analyze.

### Task 9: `FavouritesController`

**Files:** `lib/core/catalog/favourites_controller.dart`; wire in `AppServices` / `EventorApp` (ChangeNotifierProvider above `MaterialApp.router`), cleared when `SessionController` signs out; `test/support/fakes.dart` gains `FakeCatalogRepository`, `FakeFavouritesRepository` (configurable data, `gate` Completer, error injection) and `test_app.dart` passes them; test `test/core/catalog/favourites_controller_test.dart`.

```dart
class FavouritesController extends ChangeNotifier {
  FavouritesController(this._repository);
  bool isFavourite(FavouriteTarget target, {required bool fallback}); // override wins, else the DTO flag
  Future<Failure?> toggle(FavouriteTarget target, {required bool current}); // optimistic; returns failure after rollback
  void clear();
  int get version; // bumps when a favourite is added/removed — 17 reloads on change
}
```
- Overlapping toggles: each toggle records a sequence number per target; a response only rolls back if it is still the latest request for that target.
- [ ] tests: optimistic flip before the repository answers (gate); rollback + failure returned on error; **two quick toggles, first fails after second succeeds → final state = second** (Review Focus 2); `clear()` forgets overrides.
- [ ] implement; analyze.

### Task 10: Shared widgets A — images, skeletons, states, badges, hearts, toast action

**Files:** `atoms/app_network_image.dart`, `atoms/skeleton.dart`, `atoms/verified_badge.dart`, `molecules/state_card.dart`, `molecules/section_header.dart`, `molecules/favourite_button.dart`, `molecules/read_more_text.dart`, `molecules/stat_strip.dart`; `assets/icons/heart-filled.svg` + `AppIcons.heartFilled`; `molecules/app_toast.dart` gains `actionLabel` / `onAction` and `AppToastTone.info`; ARB: `comingSoon`, `stateErrorTitle` ("We could not load this"), `stateRetry` ("Try again"), `verifiedProvider`, `readMore`, `readLess`, `seeAll`, `seeAllCount` (plural), `noLongerAvailable`, `undo`, `favouriteAdded`, `favouriteRemoved`, `favouriteFailed`.

```dart
AppNetworkImage({required String? url, required double width, required double height, BorderRadius? radius, AppIcons placeholderIcon = AppIcons.camera})
  // url null → IconTile placeholder; 'asset:' prefix → Image.asset; else CachedNetworkImage(cacheKey: stableKey(url))
static String AppNetworkImage.stableKey(String url); // strips exp & sig query params
Skeleton.block({required double height, double? width, BorderRadius? radius}) // bg/disabled
StateCard.error({required VoidCallback onRetry}); StateCard.empty({required AppIcons icon, required String title, String? body, String? actionLabel, VoidCallback? onAction})
SectionHeader({required String title, String? actionLabel, VoidCallback? onAction})
FavouriteButton({required FavouriteTarget target, required bool initial, FavouriteButtonStyle style = onPhoto|inline})
VerifiedBadge()
ReadMoreText(String text, {int trimLines = 4})
StatStrip(List<StatItem> items)  // StatItem{value (LTR token), label}
```
- `FavouriteButton` reads `FavouritesController`, calls `toggle`, shows `favouriteFailed` toast on failure; semantics "Save"/"Saved" (`favouriteSave`, `favouriteSaved`).
- [ ] tests: `stableKey` strips only `exp`/`sig` (Review Focus 1); placeholder when url null; asset URL path; toast action fires; FavouriteButton flips and announces; ReadMoreText toggles; StateCard retry.
- [ ] implement; gallery sections; `flutter gen-l10n`; analyze.

### Task 11: Shared widgets B — calendar, carousel, reviews, facts, bars, cards, drawer, slider

**Files:** `organisms/month_calendar.dart`, `photo_carousel.dart`, `review_views.dart` (`RatingSummary`, `RatingBars`, `ReviewCard`), `facts_card.dart`, `sticky_action_bar.dart`, `pack_cards.dart` (`PackRailCard`, `PackListCard`), `service_result_card.dart`, `favourite_tile.dart`, `category_rail.dart`, `side_drawer.dart` (`showSideDrawer<T>`), `range_slider_field.dart`. ARB: calendar legend (`calendarAvailable`, `calendarBooked`, `calendarUnavailable`, `calendarSelected`), `calendarMinNotice` (plural days), weekday/month via `DateFormat` (locale), `notAcceptingTitle` ("Not taking new bookings"), `notAcceptingBody` ("Messages are still open"), `sendMessage`, `requestBooking`, `requestPack`, `savePill` (`Save {amount}` built as tokens), `servicesCount` (plural), `bookedTimes` (plural), `basedOnReviews` (plural), `photoCounter` built as LTR tokens.

```dart
MonthCalendar({required DateTime month, required Availability? availability, required DateTime? selected,
  required ValueChanged<DateTime>? onSelect /* null = read-only */, required ValueChanged<DateTime> onMonthChanged,
  required bool isLoading, DateTime? firstMonth})
  // week starts Sunday (design); columns follow Directionality (RTL mirrors); past & blocked → disabled grey;
  // busy → strikethrough; available → brand-subtle; selected → brand; skeleton grid while loading
PhotoCarousel({required List<Photo> photos, required double height, required Widget overlay /* back+heart */})
StickyActionBar({required Widget leading, required List<Widget> actions}); StickyActionBar.notAccepting({required VoidCallback onMessage})
PackRailCard(PackCard pack, {VoidCallback? onTap}); PackListCard(PackCard pack, {VoidCallback? onTap})
ServiceResultCard(ServiceCard service, {VoidCallback? onTap})
FavouriteTile(Favourite favourite, {VoidCallback? onTap, required VoidCallback onRemove})
CategoryRail({required List<CategoryRef> categories, required ValueChanged<CategoryRef> onTap})
Future<T?> showSideDrawer<T>(BuildContext context, {required WidgetBuilder builder}) // trailing edge, 320 wide, radius 24 on leading corners, 0.5 scrim
RangeSliderField({required RangeValues values, required double max, required ValueChanged<RangeValues> onChanged}) // labels via PriceText, "500 000+"
```
- [ ] tests: calendar — states render, selecting a blocked day does nothing, RTL puts Sunday on the right, month paging callback, read-only when `onSelect == null`; drawer slides from the trailing edge (LTR right, RTL left); price tokens in AR; pack card savings pill; favourite tile unavailable variant not tappable.
- [ ] implement; gallery sections; gen-l10n; analyze.

### Task 12: Client shell, routes, redirect, placeholder tabs

**Files:** modify `app_routes.dart`, `app_router.dart`; create `lib/features/shell/view/client_shell.dart`, `placeholder_tab_view.dart`, `profile_tab_view.dart`; move provider placeholder to `lib/features/provider_home/view/provider_home_view.dart`; ARB: `navHome`, `navSearch`, `navBookings`, `navMessages`, `navProfile`, `tabComingSoonTitle`, `tabComingSoonBody`, `profileFavourites`, `profileMoreSoon`.

```dart
AppRoutes: home '/home', search '/search', bookings '/bookings', messages '/messages', profile '/profile',
  results '/search/results', service '/services/:id' (serviceFor(id)), provider '/providers/:id' (providerFor(id)),
  packs '/packs' (packsFor({EventType?})), pack '/packs/:id' (packFor(id)), favourites '/favourites',
  providerHome '/provider', resultsFor(ServiceQuery)
static bool isClientOnly(String path); // shell + catalog routes
```
- `ClientShell(navigationShell)` = `Scaffold(body: navigationShell, bottomNavigationBar: AppBottomNav(...filled icons...))`; re-tap on the active tab → `navigationShell.goBranch(i, initialLocation: true)` (pops to root) and scroll-to-top via a `PrimaryScrollController`; Messages badge = `HomeFeed.unreadConversations` (exposed through a small `ShellBadges` ChangeNotifier the Home VM updates).
- Redirect: signed-in provider on a client-only path → `/provider`; client on `/provider` → `/home`; `_landing()` for a provider → `/provider`.
- [ ] tests (`app_redirect_test.dart`, `test/features/shell/client_shell_test.dart`): provider deep link `/services/x` → `/provider`; client `/provider` → `/home`; tab switch keeps each tab's state; nav shows filled glyph on the active tab; Profile tab → Favorites pushes 17, Log out signs out; placeholder tabs render.
- [ ] implement; update `app_flow_test.dart` expectations (restored client session lands on Home 11, provider on `/provider`); analyze.

### Task 13: 11 Home · Client

**Files:** `lib/features/home/view_model/home_view_model.dart`, `lib/features/home/view/home_view.dart`, `view/widgets/{home_header,upcoming_bookings_section,budget_card,packs_rail_section,nearby_services_section,home_skeleton}.dart`; ARB: `greetingMorning/Afternoon/Evening`, `chooseCity`, `homeSearchHint` ("Search a service or a provider"), `homeYourBookings`, `homeYourBudget`, `budgetSpentOf` (tokens), `budgetBookedOf` (plural), `budgetDetails`, `budgetEmptyTitle`, `budgetEmptyBody`, `budgetCreate`, `homeReadyPacks`, `homeServicesNearYou`, `cityChanged`.

```dart
class HomeViewModel extends BaseViewModel {
  HomeViewModel({required CatalogRepository catalog, required AuthRepository auth, required SessionController session, required ShellBadges badges, required DateTime Function() now});
  HomeFeed? get feed; bool get isFirstLoad; Greeting get greeting; // morning|afternoon|evening per D5
  Future<void> load(); Future<void> refresh(); // refresh keeps feed on failure (failure exposed for a toast)
  Future<Failure?> changeCity(int wilayaCode); // updateWilaya → session.updateUser → load()
}
```
- [ ] tests (VM): first load → feed; error → failure, no feed; refresh failure keeps old feed; greeting boundaries 04:59/05:00/11:59/12:00/17:59/18:00; changeCity calls updateWilaya then reloads, failure leaves city; badges updated. Widget (EN+AR): skeleton → content; hidden empty bookings/packs (D2); 11c when `budget.exists == false`; "Choose your city" when `wilaya == null`; tapping a service pushes 12; See all packs → 19; See all near you → S2 with the wilaya; category → S2a; bell/budget/booking → comingSoon toast; AR amount order in budget card.
- [ ] implement; analyze.

### Task 14: S1 Search · idle + S3 + recent searches

**Files:** `lib/core/catalog/recent_searches.dart` (PreferencesService-backed, max 8, newest first, dedupe case-insensitive), `lib/features/search/view_model/search_view_model.dart`, `view/search_view.dart`; ARB: `searchRecent`, `searchClear`, `searchBrowseCategories`, `servicesCountShort` (plural), `searchRemoveRecent`.

- [ ] tests: store dedupes/caps/persists; VM loads categories (with counts), submit adds to recents and returns the results route; clearing; widget: recent tap → S2 `?q=`; category → S2a.
- [ ] implement; analyze.

### Task 15: 11a Filters drawer + wilaya drill-in

**Files:** `lib/features/filters/view_model/filters_view_model.dart`, `view/filters_drawer.dart`, `view/wilaya_drill_in.dart`; ARB: `filtersTitle`, `filtersSortBy`, sort labels (6), `filtersCategory`, `filtersWilaya`, `filtersAllWilayas`, `filtersBudget`, `filtersEventDate`, `filtersEventDateHint`, `filtersRating`, `filtersRatingAny`, `filtersRatingAtLeast` (tokens), `filtersSaved`, `filtersFavouritesOnly`, `filtersClearAll`, `filtersShowCount` (plural), `wilayaDrillTitle`, `wilayaDoneCount` (plural), `wilayaClear`.

```dart
class FiltersViewModel extends BaseViewModel {
  FiltersViewModel({required ServiceQuery initial, required CatalogRepository catalog, required ReferenceRepository reference, required int? homeWilaya, Duration debounce = const Duration(milliseconds: 300)});
  ServiceQuery get query; int? get resultCount; bool get isCounting;
  List<Wilaya> get wilayaChips; // home wilaya + selected, home first, then by code
  void setOrder(ServiceOrder); void setCategory(String?); void setWilayas(Set<int>); void setPrice(RangeValues);
  void setMinRating(num?); void setEventDate(DateTime?); void setFavouritesOnly(bool); void clearAll();
}
```
- Count = `catalog.services(query, limit: 1)` → `total`, debounced, stale responses ignored.
- [ ] tests: each setter updates query and triggers one debounced count; stale count ignored; clearAll keeps `q`; wilaya chips order; widget: opens from the trailing edge, "Show N services" pops with the query, drill-in Back returns to filters with selection kept, Done shows count.
- [ ] implement; analyze.

### Task 16: S2 / S2a / S2b results

**Files:** `lib/features/search/view_model/results_view_model.dart`, `view/results_view.dart`; ARB: `resultsCount` (plural), `resultsSortChip`, `resultsFiltersChip` (count), `resultsEmptyTitle` ("Nothing matches those filters"), `resultsEmptyBody`, `resultsClearFilters`, `resultsLoadMoreFailed`.

- VM: `ResultsViewModel({required ServiceQuery query, required CatalogRepository catalog})`; `items`, `total`, `hasMore`, `isLoadingMore`, `loadMore()` (guarded against double calls), `refresh()`, `applyQuery(ServiceQuery)` (updates route via returned params), `removeFilter(FilterChipKind)`.
- [ ] tests: first page, loadMore appends, stops at `hasMore == false`, load-more failure keeps items and exposes a retry (Review Focus 5), empty → S2b with chips, removing a chip reloads, category preset title (S2a), sort sheet applies order; AR price order on a card.
- [ ] implement; analyze.

### Task 17: 12 Service Detail

**Files:** `lib/features/service_detail/view_model/service_detail_view_model.dart`, `view/service_detail_view.dart`, `view/widgets/*`; ARB: `serviceFacts`, `serviceAbout`, `serviceGoodToKnow`, `serviceCancellation`, `serviceExtras`, `servicePickDate`, `serviceSelectedDate`, `serviceReviews`, `servicePacksFromProvider`, `serviceReport`, `repliesIn` (tokens), `yearsInBusiness` (plural), `detailGoneTitle` ("This is no longer available"), `detailGoneBody`.

```dart
class ServiceDetailViewModel extends BaseViewModel {
  ServiceDetailViewModel({required String id, required CatalogRepository catalog, required AppConfig config, required DateTime Function() today});
  ServiceDetail? get service; bool get isGone; // 404
  DateTime get visibleMonth; Availability? get availability; bool get isLoadingMonth;
  DateTime? get selectedDate; bool get canBook; // provider.acceptingBookings
  Future<void> load(); Future<void> showMonth(DateTime month); void selectDate(DateTime day); // ignores non-available
}
```
- [ ] tests: load; 404 → `isGone`; month paging fetches once per month (cached); cannot page before the current month; selecting busy/blocked ignored; not-accepting → `canBook false`, calendar read-only; widget: facts/extras/cancellation shown only when present, "New" when unrated, `on_quote` shows "On quote", sticky bar variants, Request booking → comingSoon toast, provider card → 13, pack → 20, gone state with Back.
- [ ] implement; analyze.

### Task 18: 13 Provider Profile + not-accepting state

**Files:** `lib/features/provider_profile/view_model/provider_profile_view_model.dart`, `view/provider_profile_view.dart`, `view/widgets/*`; ARB: `profileChecked` ("What we checked"), `profileAbout`, `profileServices`, `profilePacks`, `profileWhereTheyWork`, `profileLanguages`, `profileMemberSince`, `profileReviews`, `profileReport`, `statReviews` (plural), `statCompleted` (plural), `statYears` (plural), `usuallyReplies`, language names (`langAr`, `langFr`, `langEn`).

- [ ] tests: load/gone; stat strip hides null `yearsActive`; D10 "See all" only when `services.length < servicesCount`; reply time hidden when null; not-accepting bar exactly as 13 state; service row → 12; AR layout.
- [ ] implement; analyze.

### Task 19: 19 Ready Packs

**Files:** `lib/features/packs/view_model/packs_view_model.dart`, `view/packs_view.dart`; ARB: `packsTitle`, `packsSubtitle`, `packsAll`, event type labels (9, no academic), `packsSortedBy`, pack sort labels (5), `packsEmptyTitle`, `packsEmptyBody`.

- [ ] tests: chip filter reloads page 1; sort sheet; paging; empty per filter; heart toggles via controller; card → 20.
- [ ] implement; analyze.

### Task 20: 20 Pack Detail

**Files:** `lib/features/pack_detail/view_model/pack_detail_view_model.dart`, `view/pack_detail_view.dart`, `view/widgets/*`; ARB: `packBadge` (plural services), `packBookings` (plural), `packVersus` ("versus booking separately"), `packInside` ("What is inside"), `packBookedSeparately`, `packCalendarHint` ("Only days when every service in the pack is free"), `packMaxGuests`, `packAvailableIn`, `packAllServices` (plural).

- VM mirrors Task 17 with `packAvailability`.
- [ ] tests: load/gone; price card tokens (AR order); items sorted and tappable → 12; calendar; not-accepting; Request pack → comingSoon; no cancellation line.
- [ ] implement; analyze.

### Task 21: 17 Favorites

**Files:** `lib/features/favourites/view_model/favourites_view_model.dart`, `view/favourites_view.dart`; ARB: `favouritesTitle`, `favouritesServices`, `favouritesPacks`, `favouritesAll`, `favouritesEmptyServices`, `favouritesEmptyPacks`, `favouritesExplore`.

```dart
class FavouritesViewModel extends BaseViewModel {
  FavouritesViewModel({required FavouritesRepository favourites, required CatalogRepository catalog, required FavouritesController controller});
  FavouriteKind get kind; String? get categoryId; List<Favourite> get items; bool get hasMore;
  Future<void> load(); Future<void> loadMore(); void setKind(FavouriteKind); void setCategory(String?);
  Favourite? removeWithUndo(Favourite f); Future<void> undo(); // D6: removed locally, DELETE after the toast closes unless undone
}
```
- [ ] tests: tabs switch kind, category chips only on services; remove → gone from list, undo restores without a network call, toast dismissal commits `removeById`; unavailable tile not tappable; empty per tab → Explore switches to the Search tab; reloads when `controller.version` changes.
- [ ] implement; analyze.

### Task 22: Finish — gallery, l10n check, device build

- [ ] Every new widget has a gallery section (EN/AR toggle already exists).
- [ ] `flutter gen-l10n`; `l10n_missing.json` is `{}`.
- [ ] `flutter analyze --no-pub lib test` → no issues.
- [ ] `flutter build apk --release` → copy to `Desktop\eventor_login_flow.apk`; install on `R9JR20ED7YJ` (split-per-ABI armeabi-v7a if storage is short); screenshot Home, 12, 13 (paused provider), 17, filters in EN and AR from the phone.
- [ ] Update memory `eventor-phase-status` and the backend asks list.

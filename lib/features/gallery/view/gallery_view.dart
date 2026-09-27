import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/widgets/atoms/app_avatar.dart';
import '../../../core/widgets/atoms/app_chip.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/app_spinner.dart';
import '../../../core/widgets/atoms/app_switch.dart';
import '../../../core/widgets/atoms/icon_tile.dart';
import '../../../core/widgets/atoms/page_dots.dart';
import '../../../core/widgets/atoms/rating_line.dart';
import '../../../core/widgets/atoms/rating_view.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/atoms/status_badge.dart';
import '../../../core/widgets/atoms/verified_badge.dart';
import '../../../core/widgets/molecules/app_select_field.dart';
import '../../../core/widgets/molecules/app_text_field.dart';
import '../../../core/widgets/molecules/code_input.dart';
import '../../../core/widgets/molecules/document_upload_field.dart';
import '../../../core/widgets/molecules/inline_banner.dart';
import '../../../core/widgets/molecules/language_switch.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/nav_item.dart';
import '../../../core/widgets/molecules/price_text.dart';
import '../../../core/widgets/molecules/prompt_row.dart';
import '../../../core/widgets/molecules/role_card.dart';
import '../../../core/widgets/molecules/section_header.dart';
import '../../../core/widgets/molecules/stat_strip.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/app_bottom_nav.dart';
import '../../../core/widgets/organisms/app_top_bar.dart';
import '../../../core/widgets/organisms/cards.dart';
import '../../../core/widgets/organisms/info_card.dart';
import '../../../core/widgets/organisms/month_calendar.dart';
import '../../../core/widgets/organisms/pack_cards.dart';
import '../../../core/widgets/organisms/selection_sheet.dart';
import '../../../core/widgets/organisms/sticky_action_bar.dart';
import '../../../mock/mock_backend.dart';

/// Every component in the library, in every state — a debug-only screen for
/// checking the design system on a real device in both languages.
///
/// Registered only in debug builds (see the router), so it never ships. Its
/// own section labels are plain English on purpose: it is a developer tool,
/// not product copy.
class GalleryView extends StatefulWidget {
  const GalleryView({super.key});

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  final TextEditingController _field = TextEditingController(text: 'Amina');
  final TextEditingController _empty = TextEditingController();
  final TextEditingController _code = TextEditingController(text: '2849');
  bool _switch = true;
  int _chip = 0;
  int _tab = 0;
  bool _role = true;
  DateTime? _calendarDay;

  @override
  void dispose() {
    _field.dispose();
    _empty.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocaleController locale = context.watch<LocaleController>();
    final bool isArabic =
        (locale.locale ?? Localizations.localeOf(context)).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppTopBar(
        title: 'Component gallery',
        actionIcon: AppIcons.settings,
        actionLabel: 'Switch language',
        onAction: () =>
            locale.setLocale(Locale(isArabic ? 'en' : 'ar')),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _tab,
        onSelected: (int i) => setState(() => _tab = i),
        destinations: const <AppNavDestination>[
          AppNavDestination(
            icon: AppIcons.home,
            activeIcon: AppIcons.homeFilled,
            label: 'Home',
          ),
          AppNavDestination(
            icon: AppIcons.search,
            activeIcon: AppIcons.searchFilled,
            label: 'Search',
          ),
          AppNavDestination(
            icon: AppIcons.calendar,
            activeIcon: AppIcons.calendarFilled,
            label: 'Bookings',
          ),
          AppNavDestination(
            icon: AppIcons.message,
            activeIcon: AppIcons.messageFilled,
            label: 'Messages',
            badgeCount: 3,
          ),
          AppNavDestination(
            icon: AppIcons.user,
            activeIcon: AppIcons.userFilled,
            label: 'Profile',
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPaddingAll,
        children: <Widget>[
          if (context.read<MockBackend?>() != null) ...<Widget>[
            _section('Mock data'),
            MainButton(
              label: 'Reset mock data',
              style: MainButtonStyle.secondary,
              tone: MainButtonTone.danger,
              onPressed: () async {
                final MockBackend backend = context.read<MockBackend?>()!;
                // Sign out first so the session and the store agree.
                await context.read<SessionController>().signOut();
                await backend.reset();
              },
            ),
          ],
          _section('Icons'),
          Wrap(
            spacing: AppSpacing.sm.dw,
            runSpacing: AppSpacing.sm.dh,
            children: <Widget>[
              for (final AppIcons icon in AppIcons.values)
                Tooltip(message: icon.name, child: AppIcon(icon)),
              const AppSpinner(),
            ],
          ),
          _section('Buttons'),
          for (final MainButtonTone tone in MainButtonTone.values)
            _onTone(
              tone,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final MainButtonStyle style in MainButtonStyle.values)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.xs.dh),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: MainButton(
                              label: '${style.name} · ${tone.name}',
                              style: style,
                              tone: tone,
                              icon: AppIcons.plus,
                              onPressed: () {},
                            ),
                          ),
                          SizedBox(width: AppSpacing.xs.dw),
                          Expanded(
                            child: MainButton(
                              label: 'Loading',
                              style: style,
                              tone: tone,
                              isLoading: true,
                              onPressed: () {},
                            ),
                          ),
                          SizedBox(width: AppSpacing.xs.dw),
                          Expanded(
                            child: MainButton(
                              label: 'Disabled',
                              style: style,
                              tone: tone,
                              onPressed: null,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          _section('Inputs'),
          AppTextField(controller: _field, label: 'Default', helperText: 'Helper'),
          _gap(),
          AppTextField(controller: _empty, label: 'Placeholder', hintText: 'name@example.com'),
          _gap(),
          AppTextField(controller: _field, label: 'Error', errorText: 'Something is wrong'),
          _gap(),
          AppTextField(controller: _field, label: 'Disabled', enabled: false),
          _gap(),
          AppTextField(controller: _empty, label: 'Password', obscureText: true),
          _gap(),
          AppSelectField(label: 'Select', value: 'Photography', onTap: () => _openSheet(context)),
          _gap(),
          AppSelectField(label: 'Select · empty', value: null, placeholder: 'Choose', onTap: () {}),
          _gap(),
          CodeInput(controller: _code),
          _gap(),
          CodeInput(controller: _code, hasError: true),
          _section('Document upload'),
          DocumentUploadField(label: 'Empty', helperText: 'PDF or image', onTap: () {}),
          _gap(),
          const DocumentUploadField(label: 'Uploading', fileName: 'id.pdf', isUploading: true, helperText: 'Uploading…', onTap: null),
          _gap(),
          DocumentUploadField(label: 'Uploaded', fileName: 'id.pdf', helperText: 'Received', onTap: () {}),
          _gap(),
          DocumentUploadField(label: 'Rejected', fileName: 'id.pdf', errorText: 'Unreadable scan', onTap: () {}),
          _section('Banners'),
          InlineBanner(title: 'Email or password is incorrect', message: 'Check the address and try again.', actionLabel: 'Send a new code', onAction: () {}),
          _gap(),
          const InlineBanner(title: 'Your session has ended', message: 'Log in again.', tone: InlineBannerTone.info),
          _section('Selection'),
          RoleCard(icon: AppIcons.user, title: 'I\'m planning an event', description: 'Find and book my event team', isSelected: _role, onTap: () => setState(() => _role = !_role)),
          _gap(),
          Wrap(
            spacing: AppSpacing.xs.dw,
            children: <Widget>[
              for (int i = 0; i < 3; i++)
                AppChip(label: 'Chip $i', isSelected: _chip == i, onTap: () => setState(() => _chip = i)),
              const AppChip(label: 'Disabled', isSelected: false, onTap: null),
            ],
          ),
          Row(
            children: <Widget>[
              AppSwitch(value: _switch, onChanged: (bool v) => setState(() => _switch = v)),
              const AppSwitch(value: false, onChanged: null),
              const Spacer(),
              const LanguageSwitch(),
            ],
          ),
          _section('Identity & status'),
          Wrap(
            spacing: AppSpacing.xs.dw,
            runSpacing: AppSpacing.xs.dh,
            children: <Widget>[
              for (final BookingStatusKind s in BookingStatusKind.values) StatusBadge(s),
              const AvailabilityBadge(isAvailable: true),
              const AvailabilityBadge(isAvailable: false),
            ],
          ),
          _gap(),
          Row(
            children: <Widget>[
              for (final AppAvatarSize size in AppAvatarSize.values) ...<Widget>[
                AppAvatar(name: 'Amina Benali', size: size),
                SizedBox(width: AppSpacing.xs.dw),
              ],
              const AppAvatar(name: 'No Photo', photoUrl: 'https://invalid.example/x.jpg'),
              SizedBox(width: AppSpacing.xs.dw),
              const IconTile(AppIcons.home),
              SizedBox(width: AppSpacing.xs.dw),
              const IconTile.serviceThumb(AppIcons.camera),
            ],
          ),
          _gap(),
          const RatingView(score: '4.8', count: 32),
          _gap(),
          const PageDots(count: 3, currentIndex: 1),
          _gap(),
          PromptRow(question: 'Already have an account ?', actionLabel: 'Log in', onTap: () {}),
          Row(
            children: <Widget>[
              NavItem(icon: AppIcons.home, activeIcon: AppIcons.homeFilled, label: 'Home', isActive: true, onTap: () {}),
              NavItem(icon: AppIcons.message, activeIcon: AppIcons.messageFilled, label: 'Messages', isActive: false, badgeCount: 12, onTap: () {}),
            ],
          ),
          _section('Cards'),
          const ProviderCard(name: 'Studio Lumière', meta: 'Photographer · Alger', amount: '45000.00', unit: 'per day', score: '4.8', reviewCount: 32),
          _gap(),
          BookingCard(counterpartName: 'Salle Yasmine', meta: 'Venue · Sat 14 Mar', status: BookingStatusKind.pending, onTap: () {}),
          _gap(),
          RequestCard(clientName: 'Nadia Kaci', meta: 'Wedding photography · Sat 14 Mar · 150 guests', onAccept: () {}, onDecline: () {}),
          _gap(),
          const ServiceItem(title: 'Wedding photography', price: '45 000 DA', unit: 'per day', isAvailable: true),
          _gap(),
          const ProviderCard(name: 'Corporate event stage', meta: 'Limousine Prestige', amount: '0.00', unit: '', isNew: true, quoteLabel: 'On quote'),
          _section('Prices & ratings'),
          const PriceText(amount: '45000.00', prefix: 'From', unit: 'per day'),
          _gap(),
          const ServicePrice(amount: '120000.00', type: PriceType.onQuote),
          _gap(),
          const SavingsPill(savings: '45000.00', percent: 12),
          _gap(),
          const Row(children: <Widget>[RatingLine(avgRating: '4.80', ratingCount: 32), SizedBox(width: 16), RatingLine(avgRating: '0.00', ratingCount: 0)]),
          _gap(),
          const Align(alignment: AlignmentDirectional.centerStart, child: VerifiedBadge()),
          _gap(),
          const StatStrip(<StatItem>[
            StatItem(value: '4.8', label: 'reviews', icon: AppIcons.starFilled),
            StatItem(value: '48', label: 'bookings completed'),
            StatItem(value: '6', label: 'years in business'),
          ]),
          _section('States (G1 / G2)'),
          const SectionHeader(title: 'Ready Packs', actionLabel: 'See all', onAction: _noop),
          _gap(),
          Skeleton(height: 76.dh),
          _gap(),
          StateCard.empty(icon: AppIcons.heart, title: 'No saved services yet', body: 'Tap the heart to keep it here.', actionLabel: 'Explore', onAction: () {}),
          _gap(),
          StateCard.error(onRetry: () {}),
          _section('Info card & sticky bar'),
          InfoCard(
            title: 'Good to know',
            rows: <InfoRow>[
              const InfoRow(icon: AppIcons.user, text: 'Up to 300 guests'),
              InfoRow(icon: AppIcons.mapPin, text: 'Alger · Blida · Boumerdès', onTap: () {}),
            ],
          ),
          _gap(),
          StickyActionBar(
            leading: const ServicePrice(amount: '45000.00', type: PriceType.perDay),
            actions: <Widget>[
              MessageIconButton(onPressed: () {}),
              MainButton(label: 'Request booking', onPressed: () {}),
            ],
          ),
          _gap(),
          StickyActionBar.notAccepting(onMessage: () {}),
          _section('Calendar'),
          MonthCalendar(
            month: DateTime.now(),
            availability: _galleryMonth(),
            selected: _calendarDay,
            onSelect: (DateTime day) => setState(() => _calendarDay = day),
            onMonthChanged: (_) {},
            firstMonth: DateTime.now(),
          ),
          SizedBox(height: AppSpacing.xl3.dh),
        ],
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) {
    return showSelectionSheet<int>(
      context,
      title: 'Choose your wilaya',
      multiple: true,
      options: <SelectionOption<int>>[
        for (int i = 1; i <= 20; i++)
          SelectionOption<int>(value: i, label: 'Wilaya $i'),
      ],
    );
  }

  Widget _onTone(MainButtonTone tone, Widget child) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.xs.dh),
      padding: EdgeInsets.all(AppSpacing.xs.dw),
      decoration: BoxDecoration(
        color: tone == MainButtonTone.inverse ? AppColors.bgBrand : AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
      ),
      child: child,
    );
  }

  Widget _gap() => SizedBox(height: AppSpacing.sm.dh);

  static void _noop() {}

  /// This month with every state on show: the 10th fully booked, the 20th
  /// blocked, days before today too soon.
  Availability _galleryMonth() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int days = DateTime(now.year, now.month + 1, 0).day;
    return Availability(
      month: '${now.year}-${now.month}',
      minNoticeDays: 1,
      firstBookableDate: today,
      days: <AvailabilityDay>[
        for (int d = 1; d <= days; d++)
          AvailabilityDay(
            date: DateTime(now.year, now.month, d),
            state: DateTime(now.year, now.month, d).isBefore(today) || d == 20
                ? DayState.blocked
                : d == 10
                    ? DayState.busy
                    : DayState.available,
          ),
      ],
    );
  }

  Widget _section(String title) => Padding(
        padding: EdgeInsets.only(top: AppSpacing.xl.dh, bottom: AppSpacing.xs.dh),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
      );
}

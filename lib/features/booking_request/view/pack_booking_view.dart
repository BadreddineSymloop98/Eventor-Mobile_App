import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/bookings/bookings_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/localization/catalog_labels.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/app_spinner.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/organisms/booking_cards.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../core/widgets/organisms/detail_states.dart';
import '../../../core/widgets/organisms/discard_guard.dart';
import '../../../core/widgets/organisms/divided_card.dart';
import '../../../core/widgets/organisms/month_calendar.dart';
import '../../../core/widgets/organisms/sticky_action_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/booking_request_view_model.dart';
import 'booking_request_view.dart' show revealProblem;
import 'widgets/booking_form_sections.dart';

/// B9 Book this pack: what is in it, the day (only when every service in it
/// is free), and the event's details — then B9a to review and send.
class PackBookingView extends StatefulWidget {
  const PackBookingView({super.key});

  @override
  State<PackBookingView> createState() => _PackBookingViewState();
}

class _PackBookingViewState extends State<PackBookingView> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final Map<BookingField, GlobalKey> _sections = <BookingField, GlobalKey>{
    for (final BookingField field in BookingField.values) field: GlobalKey(),
  };

  @override
  void dispose() {
    _scroll.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final BookingRequestViewModel viewModel = context.read<BookingRequestViewModel>();
    FocusScope.of(context).unfocus();
    final BookingQuote? quote = await viewModel.review();
    if (!mounted) return;
    if (quote == null) {
      final Failure? failure = viewModel.failure;
      if (failure != null && viewModel.problem == null) {
        showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
        return;
      }
      await revealProblem(_scroll, _sections, viewModel);
      return;
    }
    final BookingDetail? created = await context.push<BookingDetail>(
      AppRoutes.packReviewFor(viewModel.packId!),
      extra: viewModel,
    );
    if (!mounted) return;
    if (created != null) {
      context.pushReplacement(
        AppRoutes.bookingSent,
        extra: RequestSentArgs(booking: created, replyTime: viewModel.provider?.replyTime),
      );
    } else if (viewModel.problem != null) {
      // B9a came back because the day was taken: B1b's banner is up here.
      await revealProblem(_scroll, _sections, viewModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final BookingRequestViewModel viewModel = context.watch<BookingRequestViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final PackDetail? pack = viewModel.pack;

    if (pack == null) {
      return Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            BrandTopBar(title: l10n.packBookingTitle),
            Expanded(
              child: viewModel.isGone
                  ? DetailGoneView(onBack: () => context.pop())
                  : viewModel.hasError
                      ? DetailErrorView(onRetry: viewModel.load, onBack: () => context.pop())
                      : const Center(child: AppSpinner()),
            ),
          ],
        ),
      );
    }

    final int count = pack.items.length;
    final bool busy = viewModel.isBusy;

    return DiscardGuard(
      isDirty: viewModel.isDirty,
      child: Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            BrandTopBar(title: l10n.packBookingTitle),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (viewModel.problem != null) ...<Widget>[
                      SendProblemBanner(viewModel: viewModel),
                      SizedBox(height: AppSpacing.md.dh),
                    ],
                    BookingSection(
                      title: pack.name.of(language),
                      child: DividedCard(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.md.dw,
                              vertical: AppSpacing.sm.dh,
                            ),
                            child: Text(
                              l10n.packBookingSummary(
                                count,
                                pack.provider.businessName,
                                pack.wilaya.nameFor(language),
                              ),
                              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          for (final PackItem item in pack.items)
                            PackItemRow(
                              title: item.title.of(language),
                              icon: subjectIcon(item.category),
                              caption: l10n.priceUnit(item.priceType),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg.dh),
                    KeyedSubtree(
                      key: _sections[BookingField.date],
                      child: BookingDateSection(
                        viewModel: viewModel,
                        intro: l10n.packBookingDaysIntro(count),
                        legend: CalendarLegendLabels(
                          available: l10n.packLegendAllFree(count),
                          booked: l10n.packLegendBusy,
                          unavailable: l10n.packLegendTooSoon,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg.dh),
                    KeyedSubtree(
                      key: _sections[BookingField.eventType],
                      child: BookingEventSection(viewModel: viewModel),
                    ),
                    SizedBox(height: AppSpacing.lg.dh),
                    KeyedSubtree(
                      key: _sections[BookingField.wilaya],
                      child: BookingWhereSection(viewModel: viewModel, address: _address),
                    ),
                    SizedBox(height: AppSpacing.lg.dh),
                    BookingNoteField(viewModel: viewModel, controller: _note),
                  ],
                ),
              ),
            ),
            StickyActionBar(
              leading: BookingBarTotal(total: pack.price, caption: l10n.packPriceCaption),
              actions: <Widget>[
                MainButton(
                  label: l10n.packBookingContinue,
                  isLoading: busy,
                  canBeTapped: viewModel.problem != SendProblem.notAccepting,
                  onPressed: _continue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One service of a pack: its glyph, its name, and a caption (its unit on
/// B9, its price on B9a).
class PackItemRow extends StatelessWidget {
  const PackItemRow({
    required this.title,
    required this.icon,
    this.caption,
    this.trailing,
    super.key,
  });

  final String title;
  final AppIcons icon;
  final String? caption;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? line = caption;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md.dw,
        vertical: AppSpacing.sm.dh,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.bgBrandSubtle,
              borderRadius: AppRadii.smAll,
            ),
            child: AppIcon(icon, size: AppSizes.iconMd, color: AppColors.iconBrand),
          ),
          SizedBox(width: AppSpacing.sm.dw),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
                if (line != null)
                  Text(line, style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

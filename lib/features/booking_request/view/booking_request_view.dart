import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/bookings/bookings_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_spinner.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../core/widgets/organisms/detail_states.dart';
import '../../../core/widgets/organisms/discard_guard.dart';
import '../../../core/widgets/organisms/sticky_action_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/booking_request_view_model.dart';
import 'widgets/booking_form_sections.dart';

/// B1 Request booking — and, when a send fails, B1a (Try again) and B1b
/// (the date was just taken). Opened from 12 with the day picked there.
class BookingRequestView extends StatefulWidget {
  const BookingRequestView({super.key});

  @override
  State<BookingRequestView> createState() => _BookingRequestViewState();
}

class _BookingRequestViewState extends State<BookingRequestView> {
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

  Future<void> _send() async {
    final BookingRequestViewModel viewModel = context.read<BookingRequestViewModel>();
    FocusScope.of(context).unfocus();
    final BookingDetail? created = await viewModel.send();
    if (!mounted) return;
    if (created != null) {
      // B2 takes B1's place: Back from it returns to the service.
      context.pushReplacement(
        AppRoutes.bookingSent,
        extra: RequestSentArgs(booking: created, replyTime: viewModel.provider?.replyTime),
      );
      return;
    }
    await revealProblem(_scroll, _sections, viewModel);
  }

  @override
  Widget build(BuildContext context) {
    final BookingRequestViewModel viewModel = context.watch<BookingRequestViewModel>();
    final AppLocalizations l10n = context.l10n;
    final ServiceDetail? service = viewModel.service;
    final String language = Localizations.localeOf(context).languageCode;

    if (service == null) {
      return Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            BrandTopBar(title: l10n.requestBookingTitle),
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

    final bool dateless = viewModel.selectedDate == null || viewModel.dateRefused;
    final SendProblem? problem = viewModel.problem;

    return DiscardGuard(
      isDirty: viewModel.isDirty,
      child: Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            BrandTopBar(title: l10n.requestBookingTitle),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (problem != null) ...<Widget>[
                      SendProblemBanner(viewModel: viewModel),
                      SizedBox(height: AppSpacing.md.dh),
                    ],
                    BookingSubjectPill(
                      title: service.title.of(language),
                      providerName: service.provider.businessName,
                      icon: subjectIcon(service.category),
                    ),
                    SizedBox(height: AppSpacing.md.dh),
                    KeyedSubtree(
                      key: _sections[BookingField.date],
                      child: BookingDateSection(viewModel: viewModel),
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
                    if (service.extras.isNotEmpty) ...<Widget>[
                      SizedBox(height: AppSpacing.lg.dh),
                      BookingExtrasSection(viewModel: viewModel, extras: service.extras),
                    ],
                    SizedBox(height: AppSpacing.lg.dh),
                    BookingNoteField(viewModel: viewModel, controller: _note),
                    SizedBox(height: AppSpacing.lg.dh),
                    BookingPriceSection(viewModel: viewModel),
                  ],
                ),
              ),
            ),
            StickyActionBar(
              leading: BookingBarTotal(
                total: viewModel.total,
                caption: l10n.bookingTotalCaption,
                isEmpty: problem == SendProblem.dateTaken && dateless,
              ),
              actions: <Widget>[
                MainButton(
                  label: switch (problem) {
                    SendProblem.failed => l10n.bookingTryAgain,
                    SendProblem.dateTaken || SendProblem.tooSoon when dateless =>
                      l10n.bookingPickNewDate,
                    _ => l10n.bookingSend,
                  },
                  isLoading: viewModel.isSending,
                  canBeTapped: viewModel.canSend,
                  onPressed: _send,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// After a refused send: the banner at the top when there is one, else the
/// first section still missing — so the reason is always on screen.
Future<void> revealProblem(
  ScrollController scroll,
  Map<BookingField, GlobalKey> sections,
  BookingRequestViewModel viewModel,
) async {
  if (viewModel.problem != null) {
    if (scroll.hasClients) {
      await scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
    return;
  }
  for (final BookingField field in BookingField.values) {
    if (!viewModel.missing.contains(field)) continue;
    // Time sits inside the date card.
    final BuildContext? target =
        sections[field == BookingField.time ? BookingField.date : field]?.currentContext ??
            sections[field == BookingField.guests ? BookingField.eventType : field]?.currentContext;
    if (target != null) {
      await Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    return;
  }
}

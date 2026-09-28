import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/widgets/atoms/page_dots.dart';
import '../../../core/widgets/layout/content_container.dart';
import '../../../core/widgets/molecules/language_switch.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/layout/photo_backdrop.dart';
import '../../../l10n/app_localizations.dart';
import '../model/onboarding_section.dart';
import '../view_model/onboarding_view_model.dart';

/// A swipeable introduction to the app, over full-bleed photography.
///
/// Finishing or skipping it records that it has been seen, so later launches
/// go straight past it.
///
/// Only the photograph lives in the [PageView]; the copy, the dots and the
/// button sit still above it and change with the page. That keeps the copy
/// exactly where the design puts it relative to the controls under it, which
/// sliding it would make dependent on arithmetic between two separate stacks.
///
/// The [PageView] follows the app's text direction on its own, so the flow
/// runs right to left in Arabic without anything here changing.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  /// Breathing room at the top and bottom on a device that reports no system
  /// inset of its own.
  ///
  /// The design's 32pt frame inset *is* the system inset — the status bar at
  /// the top, the home indicator at the bottom. Taking that from the device
  /// and adding nothing on top is what keeps the top bar where the design
  /// puts it; adding another 32 pushed it a third of the way down the gap.
  static EdgeInsets get _minimumInset =>
      EdgeInsets.symmetric(vertical: AppSpacing.md.dh);

  /// How long the copy takes to change once the photograph has settled.
  static const Duration _copyFade = Duration(milliseconds: 320);

  /// How far the copy travels as it fades, as a fraction of its own height.
  static const double _copyRise = 0.22;

  /// Fades the copy in while it drifts upward into place.
  ///
  /// [AnimatedSwitcher] drives the outgoing child with the same animation run
  /// backwards, so the section being left slides back down as it goes. That
  /// reads as the two belonging to one movement rather than as a cut.
  static Widget _riseAndFade(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, _copyRise),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  TextDirection? _direction;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final TextDirection direction = Directionality.of(context);
    final TextDirection? previous = _direction;
    _direction = direction;

    if (previous == null || previous == direction) return;

    // The language switch on this screen can flip the pager's axis while the
    // user is part way through it. The viewport keeps its scroll offset but
    // reads it from the other end, so offset zero stops meaning the first
    // section and starts meaning the last. Re-seating the controller on the
    // section that was actually being read puts it back.
    final OnboardingViewModel viewModel = context.read<OnboardingViewModel>();
    final int section = viewModel.currentIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !viewModel.pageController.hasClients) return;
      viewModel.pageController.jumpToPage(section);
    });
  }

  Future<void> _goToNextSection(BuildContext context) async {
    final OnboardingViewModel viewModel = context.read<OnboardingViewModel>();
    final GoRouter router = GoRouter.of(context);

    final String? nextRoute = await viewModel.goToNextSection();

    // A null route means onboarding simply advanced a section.
    if (nextRoute == null || !context.mounted) return;
    // `go`, not `push`: onboarding is finished and must not be walkable back
    // into.
    router.go(nextRoute);
  }

  Future<void> _skip(BuildContext context) async {
    final OnboardingViewModel viewModel = context.read<OnboardingViewModel>();
    final GoRouter router = GoRouter.of(context);

    final String nextRoute = await viewModel.finish();

    if (!context.mounted) return;
    router.go(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final OnboardingViewModel viewModel = context.watch<OnboardingViewModel>();
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bgBrand,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
            controller: viewModel.pageController,
            onPageChanged: viewModel.onSectionChanged,
            itemCount: viewModel.sectionCount,
            itemBuilder: (BuildContext context, int index) => PhotoBackdrop(
              asset: OnboardingViewModel.sections[index].image,
            ),
          ),
          SafeArea(
            minimum: OnboardingView._minimumInset,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md.dw,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _TopBar(onSkip: () => _skip(context)),
                  ContentContainer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // The copy sits over the pager and is not interactive,
                        // so a swipe that starts on it must reach the pager
                        // underneath — otherwise the middle of the screen,
                        // where a thumb naturally swipes, would not page.
                        IgnorePointer(
                          child: AnimatedSwitcher(
                            duration: OnboardingView._copyFade,
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: OnboardingView._riseAndFade,
                            child: _Copy(
                              // Keyed so the switcher treats each section's
                              // copy as a different child and transitions.
                              key: ValueKey<int>(viewModel.currentIndex),
                              section: OnboardingViewModel
                                  .sections[viewModel.currentIndex],
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.xl.dh),
                        Center(
                          child: PageDots(
                            count: viewModel.sectionCount,
                            currentIndex: viewModel.currentIndex,
                            tone: PageDotsTone.inverse,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xl.dh),
                        MainButton(
                          label: viewModel.isLastSection
                              ? l10n.getStarted
                              : l10n.next,
                          tone: MainButtonTone.inverse,
                          onPressed: viewModel.isBusy
                              ? null
                              : () => _goToNextSection(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skip on one side, the language switch on the other.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.controlMd.dh,
      // Mirrors with the language, like the rest of the screen. Skip is the
      // way out and so belongs on the side the reader leaves from.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          MainButton(
            label: context.l10n.skip,
            style: MainButtonStyle.ghost,
            tone: MainButtonTone.inverse,
            // The label, not the box, lines up with the screen margin.
            flushStart: true,
            onPressed: onSkip,
          ),
          const LanguageSwitch(),
        ],
      ),
    );
  }
}

/// The title and body of one section.
class _Copy extends StatelessWidget {
  const _Copy({required this.section, super.key});

  final OnboardingSection section;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          section.title(l10n),
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(
            color: AppColors.textOnBrand,
          ),
        ),
        SizedBox(height: AppSpacing.sm.dh),
        Text(
          section.description(l10n),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textOnBrand.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }
}

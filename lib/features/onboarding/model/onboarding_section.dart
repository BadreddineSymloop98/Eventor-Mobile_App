import '../../../l10n/app_localizations.dart';

/// The pages of the onboarding flow, in the order they are shown.
///
/// Only the photograph is fixed; the copy is localised and so has to be looked
/// up with a [BuildContext] at build time rather than stored here.
enum OnboardingSection {
  services('assets/images/onboarding_1.jpg'),
  compare('assets/images/onboarding_2.jpg'),
  track('assets/images/onboarding_3.jpg');

  const OnboardingSection(this.image);

  /// Full-bleed photograph behind the copy.
  final String image;

  String title(AppLocalizations l10n) {
    return switch (this) {
      OnboardingSection.services => l10n.onboardingServicesTitle,
      OnboardingSection.compare => l10n.onboardingCompareTitle,
      OnboardingSection.track => l10n.onboardingTrackTitle,
    };
  }

  String description(AppLocalizations l10n) {
    return switch (this) {
      OnboardingSection.services => l10n.onboardingServicesDescription,
      OnboardingSection.compare => l10n.onboardingCompareDescription,
      OnboardingSection.track => l10n.onboardingTrackDescription,
    };
  }
}

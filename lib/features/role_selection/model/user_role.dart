import '../../../l10n/app_localizations.dart';

/// How someone intends to use Eventor.
///
/// The design is explicit that this shapes the whole experience and cannot be
/// changed afterwards, so it is a property of the account rather than a
/// setting — which is why it is asked before the register form rather than
/// after it.
enum UserRole {
  /// Books the services for their own event.
  planner('assets/icons/user.svg'),

  /// Sells a service and manages the bookings against it.
  provider('assets/icons/briefcase.svg'),

  /// Requests events on behalf of an organisation.
  institution('assets/icons/building.svg');

  const UserRole(this.icon);

  /// The glyph shown in the card's tile.
  final String icon;

  String title(AppLocalizations l10n) {
    return switch (this) {
      UserRole.planner => l10n.rolePlannerTitle,
      UserRole.provider => l10n.roleProviderTitle,
      UserRole.institution => l10n.roleInstitutionTitle,
    };
  }

  String description(AppLocalizations l10n) {
    return switch (this) {
      UserRole.planner => l10n.rolePlannerDescription,
      UserRole.provider => l10n.roleProviderDescription,
      UserRole.institution => l10n.roleInstitutionDescription,
    };
  }
}

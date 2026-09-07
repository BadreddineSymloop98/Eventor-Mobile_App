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

  /// The line under "Create your account" on the register screen.
  ///
  /// A planner is signing up to book; the other two are signing up to be
  /// reviewed, and the subtitle is where that is first said out loud.
  String registerSubtitle(AppLocalizations l10n) {
    return switch (this) {
      UserRole.planner => l10n.registerSubtitle,
      UserRole.provider => l10n.registerSubtitleProvider,
      UserRole.institution => l10n.registerSubtitleInstitution,
    };
  }

  /// What the document review gates for this role, or `null` for a role that
  /// supplies no documents.
  String? documentsNote(AppLocalizations l10n) {
    return switch (this) {
      UserRole.planner => null,
      UserRole.provider => l10n.registerDocumentsProviderNote,
      UserRole.institution => l10n.registerDocumentsInstitutionNote,
    };
  }
}

import '../../../l10n/app_localizations.dart';
import '../../role_selection/model/user_role.dart';

/// A document an account has to supply before an admin can review it.
///
/// Only the roles that trade or act on behalf of someone else are asked for
/// these: a planner books for themselves and has nothing to prove. The list is
/// keyed off the role rather than off the screen, so the form and whatever
/// eventually uploads them cannot disagree about what is required.
///
/// The names are Algerian: the app is sold into that market, so the paperwork
/// is the paperwork the state actually issues.
enum AccountDocument {
  /// Carte nationale d'identité. Asked of every reviewed account, because the
  /// other documents are only as good as the person attached to them.
  identityCard,

  /// Registre de commerce *or* carte d'artisan — one field, not two.
  /// Photographers, decorators and florists commonly register with the
  /// Chambre de l'Artisanat rather than the CNRC, so demanding a commercial
  /// register would turn away legitimate providers.
  commercialRegister,

  /// Carte d'immatriculation fiscale. Anything on the commercial register also
  /// carries a NIF, and invoicing needs it.
  taxRegistration,

  /// Agrément — the accreditation the wilaya issues to an association or club.
  accreditation,

  /// Proof that this person may act for the institution. The agrément says the
  /// body is accredited; it does not say who speaks for it.
  authorisationLetter,

  /// Statuts de l'association. Not every academic body is an association, so
  /// this is the one document that may be skipped.
  associationStatutes;

  /// Whether the form may be submitted without it.
  bool get isOptional => this == AccountDocument.associationStatutes;

  /// What [role] has to attach, in the order the form asks for it.
  ///
  /// A planner returns an empty list, which is what collapses the whole
  /// documents section away rather than leaving an empty heading behind.
  static List<AccountDocument> forRole(UserRole? role) {
    return switch (role) {
      UserRole.provider => const <AccountDocument>[
        AccountDocument.identityCard,
        AccountDocument.commercialRegister,
        AccountDocument.taxRegistration,
      ],
      UserRole.institution => const <AccountDocument>[
        AccountDocument.identityCard,
        AccountDocument.accreditation,
        AccountDocument.authorisationLetter,
        AccountDocument.associationStatutes,
      ],
      UserRole.planner || null => const <AccountDocument>[],
    };
  }

  String label(AppLocalizations l10n) {
    return switch (this) {
      AccountDocument.identityCard => l10n.documentIdentityCard,
      AccountDocument.commercialRegister => l10n.documentCommercialRegister,
      AccountDocument.taxRegistration => l10n.documentTaxRegistration,
      AccountDocument.accreditation => l10n.documentAccreditation,
      AccountDocument.authorisationLetter => l10n.documentAuthorisationLetter,
      AccountDocument.associationStatutes => l10n.documentAssociationStatutes,
    };
  }

  /// The line under the field, describing which paper is meant.
  String hint(AppLocalizations l10n) {
    return switch (this) {
      AccountDocument.identityCard => l10n.documentIdentityCardHint,
      AccountDocument.commercialRegister => l10n.documentCommercialRegisterHint,
      AccountDocument.taxRegistration => l10n.documentTaxRegistrationHint,
      AccountDocument.accreditation => l10n.documentAccreditationHint,
      AccountDocument.authorisationLetter =>
        l10n.documentAuthorisationLetterHint,
      AccountDocument.associationStatutes =>
        l10n.documentAssociationStatutesHint,
    };
  }
}

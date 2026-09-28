import '../../../core/catalog/models/price_type.dart';
import '../../../core/localization/catalog_labels.dart';
import '../../../core/models/account.dart';
import '../../../core/provider_catalog/provider_catalog_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/catalog_outcomes.dart';
import '../view_model/provider_services_view_model.dart';
import '../view_model/service_form_view_model.dart';

/// The words of section 10's services and packs, in one place.
extension CatalogWording on AppLocalizations {
  /// "English title", "a photo" — one key of a draft's missing list.
  String missingItem(ServiceMissing item) => switch (item) {
        ServiceMissing.titleEn => providerServiceMissingTitleEn,
        ServiceMissing.titleAr => providerServiceMissingTitleAr,
        ServiceMissing.descriptionEn => providerServiceMissingDescriptionEn,
        ServiceMissing.descriptionAr => providerServiceMissingDescriptionAr,
        ServiceMissing.price => providerServiceMissingPrice,
        ServiceMissing.photos => providerServiceMissingPhotos,
        ServiceMissing.category => providerServiceMissingCategory,
        ServiceMissing.wilayas => providerServiceMissingWilayas,
      };

  /// P9's row.
  String serviceCheck(ServiceChecklistItem item) => switch (item) {
        ServiceChecklistItem.englishText => providerServiceCheckEnglish,
        ServiceChecklistItem.arabicText => providerServiceCheckArabic,
        ServiceChecklistItem.price => providerServiceCheckPrice,
        ServiceChecklistItem.photos => providerServiceCheckPhotos,
        ServiceChecklistItem.category => providerServiceCheckCategory,
        ServiceChecklistItem.wilayas => providerServiceCheckWilayas,
      };

  /// P9's primary, for the first thing missing.
  String serviceFix(ServiceChecklistItem item) => switch (item) {
        ServiceChecklistItem.englishText => providerServiceFixEnglish,
        ServiceChecklistItem.arabicText => providerServiceFixArabic,
        ServiceChecklistItem.price => providerServiceFixPrice,
        ServiceChecklistItem.photos => providerServiceFixPhotos,
        ServiceChecklistItem.category => providerServiceFixCategory,
        ServiceChecklistItem.wilayas => providerServiceFixWilayas,
      };

  /// P14's row.
  String packCheck(PackChecklistItem item) => switch (item) {
        PackChecklistItem.englishName => providerPackCheckEnglish,
        PackChecklistItem.arabicName => providerPackCheckArabic,
        PackChecklistItem.services => providerPackCheckServices,
        PackChecklistItem.price => providerPackCheckPrice,
        PackChecklistItem.wilaya => providerPackCheckWilaya,
        PackChecklistItem.profile => providerPackCheckProfile,
      };

  /// The picker's "Per day" — [priceUnit] is the card's lowercase "per day".
  String priceTypeOption(PriceType type) => providerServicePriceTypeOption(type.apiValue);

  /// The card's price-type line — "per day", or "On quote".
  String priceTypeLine(PriceType type) => priceUnit(type) ?? priceOnQuote;

  /// Decision 4's note under a service card.
  String? serviceNote(ServiceNote? note, String language) {
    switch (note) {
      case null:
        return null;
      case MissingNote(:final List<ServiceMissing> missing):
        return providerServiceMissingNote(
          missing.map(missingItem).join(providerServiceListSeparator),
        );
      case NotVisibleNote(:final List<ServiceVisibilityReason> reasons, :final List<Wilaya> closedWilayas):
        if (reasons.contains(ServiceVisibilityReason.providerBlocked)) {
          return providerServiceNotVisibleBlocked;
        }
        if (reasons.contains(ServiceVisibilityReason.providerNotVerified)) {
          return providerServiceNotVisibleReview;
        }
        if (closedWilayas.isNotEmpty) {
          return providerServiceNotVisibleClosed(
            closedWilayas.length,
            closedWilayas
                .map((Wilaya w) => w.nameFor(language))
                .join(providerServiceListSeparator),
          );
        }
        return providerServiceNotVisibleNoWilaya;
      case HiddenNote(:final HiddenInfo? info):
        final String base = info?.allowResubmit ?? false
            ? providerServiceHiddenReviewable
            : providerServiceHiddenFinal;
        final String? message = info?.message;
        return message == null ? base : '$base\n${providerServiceHiddenMessage(message)}';
    }
  }

  /// A P7b blocker row.
  String deleteBlocker(DeleteBlocker blocker) {
    final int? count = blocker.count;
    return switch (blocker.kind) {
      DeleteBlockerKind.bookings => count == null
          ? providerServiceBlockerBookingsUncounted
          : providerServiceBlockerBookings(count),
      DeleteBlockerKind.packs => count == null
          ? providerServiceBlockerPacksUncounted
          : providerServiceBlockerPacks(count),
    };
  }

  /// The helper under P7's language control.
  String serviceLanguageCaption(List<ServiceMissing> gaps, {required bool isLive}) {
    final bool titleEn = gaps.contains(ServiceMissing.titleEn);
    final bool descriptionEn = gaps.contains(ServiceMissing.descriptionEn);
    if (titleEn || descriptionEn) {
      return providerServiceLangEnglishMissing(
        titleEn && descriptionEn ? 'both' : (titleEn ? 'title' : 'description'),
      );
    }
    final bool titleAr = gaps.contains(ServiceMissing.titleAr);
    final bool descriptionAr = gaps.contains(ServiceMissing.descriptionAr);
    if (titleAr || descriptionAr) {
      return providerServiceLangArabicMissing(
        titleAr && descriptionAr ? 'both' : (titleAr ? 'title' : 'description'),
      );
    }
    return isLive ? providerServiceLangCompleteLive : providerServiceLangComplete;
  }

  /// A form field's own problem, or the server's words for it.
  String? fieldError(FieldProblem? problem, String? server, {int min = 1, int? max}) {
    if (server != null) return server;
    return switch (problem) {
      null => null,
      FieldProblem.required => providerServiceFieldRequired,
      FieldProblem.outOfRange =>
        max == null ? providerServiceFieldRequired : providerServiceRange(min, max),
    };
  }
}

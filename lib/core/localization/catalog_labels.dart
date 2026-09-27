import '../../l10n/app_localizations.dart';
import '../catalog/models/catalog_models.dart';

/// The catalog's enums in words.
extension CatalogLabels on AppLocalizations {
  /// "per day". `null` for a quote-only service, which has no unit — the
  /// price itself is replaced by [priceOnQuote].
  String? priceUnit(PriceType type) => switch (type) {
        PriceType.perEvent => priceUnitPerEvent,
        PriceType.perHour => priceUnitPerHour,
        PriceType.perPerson => priceUnitPerPerson,
        PriceType.perDay => priceUnitPerDay,
        PriceType.onQuote => null,
      };

  String eventTypeLabel(EventType type) => switch (type) {
        EventType.wedding => eventTypeWedding,
        EventType.engagement => eventTypeEngagement,
        EventType.henna => eventTypeHenna,
        EventType.birthday => eventTypeBirthday,
        EventType.circumcision => eventTypeCircumcision,
        EventType.graduation => eventTypeGraduation,
        EventType.corporate => eventTypeCorporate,
        EventType.conference => eventTypeConference,
        // Not offered as a filter; worded as "other" if a pack carries it.
        EventType.academic || EventType.other => eventTypeOther,
      };
}

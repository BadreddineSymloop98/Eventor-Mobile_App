import 'package:flutter/material.dart';

import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/provider/provider_repository.dart';
import '../../../../core/widgets/atoms/app_avatar.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/atoms/dashed_border_box.dart';
import '../../../../core/widgets/atoms/skeleton.dart';
import '../../../../core/widgets/atoms/status_badge.dart';
import '../../../../core/widgets/molecules/main_button.dart';
import '../../../../core/widgets/molecules/notification_bell.dart';
import '../../../../core/widgets/organisms/app_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/documents_repository.dart';
import '../../view_model/provider_home_view_model.dart';

/// The purple head of 21: who is signed in, the bell, and — once verified —
/// the "Accepting bookings" pill.
class ProviderHomeHeader extends StatelessWidget {
  const ProviderHomeHeader({
    required this.greeting,
    required this.fullName,
    required this.hasUnread,
    required this.onBell,
    this.accepting,
    this.onAvailability,
    super.key,
  });

  final Greeting greeting;
  final String fullName;
  final bool hasUnread;
  final VoidCallback onBell;

  /// `null` hides the pill — 21a / 21b, which cannot take bookings yet.
  final bool? accepting;
  final VoidCallback? onAvailability;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool? isAccepting = accepting;

    return Container(
      color: AppColors.bgBrand,
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md.dw,
        MediaQuery.paddingOf(context).top + AppSpacing.md.dh,
        AppSpacing.md.dw,
        AppSpacing.xl.dh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(name: fullName),
              SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      switch (greeting) {
                        Greeting.morning => l10n.greetingMorning,
                        Greeting.afternoon => l10n.greetingAfternoon,
                        Greeting.evening => l10n.greetingEvening,
                      },
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textOnBrand.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(color: AppColors.textOnBrand),
                    ),
                  ],
                ),
              ),
              NotificationBell(hasUnread: hasUnread, onTap: onBell),
            ],
          ),
          if (isAccepting != null) ...<Widget>[
            SizedBox(height: AppSpacing.md.dh),
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: onAvailability,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.sm.dw,
                    vertical: AppSpacing.xs.dh,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.fullAll,
                    border: Border.all(color: AppColors.borderOnBrand),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AppIcon(
                        isAccepting ? AppIcons.check : AppIcons.clock,
                        size: AppSizes.iconMd,
                        color: AppColors.iconOnBrand,
                      ),
                      SizedBox(width: AppSpacing.xs.dw),
                      Text(
                        isAccepting ? l10n.providerAccepting : l10n.providerPaused,
                        style: textTheme.labelLarge?.copyWith(color: AppColors.textOnBrand),
                      ),
                      SizedBox(width: AppSpacing.xs.dw),
                      const AppIcon(
                        AppIcons.chevronDown,
                        size: AppSizes.iconMd,
                        color: AppColors.iconOnBrand,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 21's three counters.
class ProviderStats extends StatelessWidget {
  const ProviderStats({required this.counts, super.key});

  final ProviderCounts counts;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    Widget tile(int value, String label) => Expanded(
          child: Container(
            padding: EdgeInsetsDirectional.all(AppSpacing.sm.dw),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: AppRadii.mdAll,
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$value',
                  textDirection: TextDirection.ltr,
                  style: textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
                ),
                SizedBox(height: AppSpacing.xs2.dh),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: <Widget>[
        tile(counts.requests, l10n.providerStatRequests),
        SizedBox(width: AppSpacing.xs.dw),
        tile(counts.upcoming, l10n.providerStatUpcoming),
        SizedBox(width: AppSpacing.xs.dw),
        tile(counts.services, l10n.providerStatServices),
      ],
    );
  }
}

/// 21a / 21b: where the review stands, the documents, and the one thing to
/// do next.
class VerificationCard extends StatelessWidget {
  const VerificationCard({
    required this.home,
    required this.onUpload,
    required this.onResubmit,
    super.key,
  });

  final ProviderHome home;

  /// 21a with documents missing — opens 08e.
  final VoidCallback onUpload;

  /// 21b — opens 08d.
  final VoidCallback onResubmit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool rejected = home.state == ProviderHomeState.rejected;
    final ProviderDocuments? documents = home.documents;
    final List<ProviderDocument> toFix =
        documents?.needingAction ?? const <ProviderDocument>[];
    final List<ProviderDocument> refused = toFix
        .where((ProviderDocument d) => d.status == ProviderDocumentStatus.rejected)
        .toList();
    final List<ProviderDocument> missing = toFix
        .where((ProviderDocument d) => d.status == ProviderDocumentStatus.missing)
        .toList();
    final int sent = documents?.sentCount ?? 0;
    final int total = ProviderDocumentType.values.length;

    final String title;
    final String body;
    if (rejected) {
      title = l10n.providerRejectedTitle;
      body = refused.length == 1
          ? l10n.providerRejectedOne(documentPhrase(l10n, refused.single.type))
          : l10n.providerRejectedMany(refused.length);
    } else if (missing.isNotEmpty) {
      title = l10n.providerFinishTitle;
      body = missing.length == 1
          ? l10n.providerMissingOne(documentPhrase(l10n, missing.single.type))
          : l10n.providerMissingMany(missing.length);
    } else {
      title = l10n.providerReviewTitle;
      body = l10n.providerReviewBody;
    }

    String stepLabel(VerificationStepKey key) => switch (key) {
          VerificationStepKey.accountCreated => l10n.providerStepAccount,
          VerificationStepKey.documentsSubmitted => !rejected && sent < total
              ? l10n.providerStepDocumentsCount(sent, total)
              : l10n.providerStepDocuments,
          VerificationStepKey.underReview =>
            rejected ? l10n.providerStepReviewed : l10n.providerStepUnderReview,
          VerificationStepKey.approved =>
            rejected ? l10n.providerStepNotApproved : l10n.providerStepApproved,
        };

    final Widget? action = rejected
        ? MainButton(label: l10n.providerResubmit, onPressed: onResubmit)
        : missing.isEmpty
            ? null
            : MainButton(
                label: missing.length == 1
                    ? uploadLabel(l10n, missing.single.type)
                    : l10n.homeUploadDocuments,
                onPressed: onUpload,
              );

    return Container(
      padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: AppElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                ),
              ),
              SizedBox(width: AppSpacing.xs.dw),
              StatusBadge(rejected ? BookingStatusKind.declined : BookingStatusKind.pending),
            ],
          ),
          SizedBox(height: AppSpacing.xs.dh),
          Text(body, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.dh),
            child: const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
          ),
          for (final VerificationStep step in home.steps)
            _StepRow(label: stepLabel(step.key), step: step, isRefusal: rejected),
          SizedBox(height: AppSpacing.sm.dh),
          Text(
            l10n.providerYourDocuments,
            style: textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
          ),
          if (documents != null)
            for (final ProviderDocumentType type in ProviderDocumentType.values)
              if (documents.byType(type) case final ProviderDocument document)
                Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xs.dh),
                  child: DocumentStatusRow(document: document),
                ),
          if (action != null) ...<Widget>[
            SizedBox(height: AppSpacing.md.dh),
            action,
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.step, required this.isRefusal});

  static const double _dot = 6;

  final String label;
  final VerificationStep step;
  final bool isRefusal;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    // The refusal is the one step drawn in red; the one under way is amber.
    final Color current = isRefusal ? AppColors.statusDeclined : AppColors.statusPending;

    final Widget marker = step.done
        ? const AppIcon(AppIcons.check, size: AppSizes.iconSm, color: AppColors.statusAccepted)
        : Container(
            width: _dot.dw,
            height: _dot.dw,
            decoration: BoxDecoration(
              color: step.current ? current : AppColors.bgDisabled,
              shape: BoxShape.circle,
            ),
          );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs2.dh),
      child: Row(
        children: <Widget>[
          SizedBox(width: AppSizes.iconSm.dw, child: Center(child: marker)),
          SizedBox(width: AppSpacing.xs.dw),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: step.current
                    ? (isRefusal ? AppColors.textDanger : AppColors.textPrimary)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One document with where it stands: a red outline once refused, dashed
/// while missing.
class DocumentStatusRow extends StatelessWidget {
  const DocumentStatusRow({required this.document, super.key});

  final ProviderDocument document;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool rejected = document.status == ProviderDocumentStatus.rejected;
    final bool missing = document.status == ProviderDocumentStatus.missing;

    final Widget content = Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm.dw,
        vertical: AppSpacing.sm.dh,
      ),
      child: Row(
        children: <Widget>[
          AppIcon(
            AppIcons.document,
            size: AppSizes.iconMd,
            color: rejected ? AppColors.iconDanger : AppColors.iconBrand,
          ),
          SizedBox(width: AppSpacing.xs.dw),
          Expanded(
            child: Text(
              documentName(context.l10n, document.type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ),
          SizedBox(width: AppSpacing.xs.dw),
          DocumentStatusPill(switch (document.status) {
            ProviderDocumentStatus.pending => DocumentStatusKind.inReview,
            ProviderDocumentStatus.approved => DocumentStatusKind.approved,
            ProviderDocumentStatus.rejected => DocumentStatusKind.rejected,
            ProviderDocumentStatus.missing => DocumentStatusKind.missing,
          }),
        ],
      ),
    );

    if (missing) return DashedBorderBox(child: content);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        border: Border.all(
          color: rejected ? AppColors.borderDanger : AppColors.borderDefault,
        ),
      ),
      child: content,
    );
  }
}

/// A document's name as the lists write it.
String documentName(AppLocalizations l10n, ProviderDocumentType type) => switch (type) {
      ProviderDocumentType.nationalId => l10n.documentIdentityCard,
      ProviderDocumentType.commercialRegister => l10n.documentRegisterShort,
      ProviderDocumentType.taxCard => l10n.documentTaxRegistration,
    };

/// A document as a sentence names it — "your tax card (NIF)".
String documentPhrase(AppLocalizations l10n, ProviderDocumentType type) => switch (type) {
      ProviderDocumentType.nationalId => l10n.documentPhraseNationalId,
      ProviderDocumentType.commercialRegister => l10n.documentPhraseRegister,
      ProviderDocumentType.taxCard => l10n.documentPhraseTaxCard,
    };

/// "Upload tax card".
String uploadLabel(AppLocalizations l10n, ProviderDocumentType type) => switch (type) {
      ProviderDocumentType.nationalId => l10n.providerUploadNationalId,
      ProviderDocumentType.commercialRegister => l10n.providerUploadRegister,
      ProviderDocumentType.taxCard => l10n.providerUploadTaxCard,
    };

/// 21's "Accepting bookings ▾": taking requests, or paused. `null` when
/// dismissed.
Future<bool?> showAvailabilitySheet(BuildContext context, {required bool accepting}) {
  final AppLocalizations l10n = context.l10n;
  return showAppBottomSheet<bool>(
    context,
    builder: (BuildContext sheetContext) => AppSheetScaffold(
      title: l10n.providerAvailabilityTitle,
      subtitle: l10n.providerAvailabilityBody,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ChoiceRow(
            title: l10n.providerAccepting,
            subtitle: l10n.providerAcceptingHint,
            isSelected: accepting,
            onTap: () => Navigator.pop(sheetContext, true),
          ),
          SizedBox(height: AppSpacing.xs.dh),
          _ChoiceRow(
            title: l10n.providerPaused,
            subtitle: l10n.providerPausedHint,
            isSelected: !accepting,
            onTap: () => Navigator.pop(sheetContext, false),
          ),
        ],
      ),
    ),
  );
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.bgBrandSubtle : AppColors.bgSurface,
            borderRadius: AppRadii.mdAll,
            border: Border.all(
              color: isSelected ? AppColors.borderBrand : AppColors.borderDefault,
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary)),
                    SizedBox(height: AppSpacing.xs2.dh),
                    Text(subtitle, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (isSelected) ...<Widget>[
                SizedBox(width: AppSpacing.sm.dw),
                const AppIcon(AppIcons.check, color: AppColors.iconBrand),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 21's shape while the first load runs.
class ProviderHomeSkeleton extends StatelessWidget {
  const ProviderHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPaddingAll,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              for (int i = 0; i < 3; i++) ...<Widget>[
                if (i > 0) SizedBox(width: AppSpacing.xs.dw),
                Expanded(child: Skeleton(height: 70.dh)),
              ],
            ],
          ),
          SizedBox(height: AppSpacing.xl.dh),
          for (int i = 0; i < 3; i++) ...<Widget>[
            Skeleton(height: 120.dh, radius: AppRadii.lgAll),
            SizedBox(height: AppSpacing.sm.dh),
          ],
        ],
      ),
    );
  }
}

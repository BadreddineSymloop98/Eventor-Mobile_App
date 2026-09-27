import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/services/document_picker.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/dashed_border_box.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/discard_guard.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/documents_repository.dart';
import '../../provider_home/view/widgets/provider_home_widgets.dart';
import '../view_model/resubmit_documents_view_model.dart';

/// `08d Resubmit documents` — why each refused document was refused, the
/// three documents as they stand, and a file to pick for each one to send
/// again. Opened from 21b; closes with `true` once everything was sent.
class ResubmitDocumentsView extends StatelessWidget {
  const ResubmitDocumentsView({super.key});

  Future<void> _submit(BuildContext context, ResubmitDocumentsViewModel viewModel) async {
    final AppLocalizations l10n = context.l10n;
    final bool sent = await viewModel.submit();
    if (!context.mounted) return;
    if (sent) {
      showAppToast(context, l10n.resubmitSent);
      Navigator.of(context).pop(true);
    } else {
      showAppToast(context, l10n.resubmitFailed, tone: AppToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ResubmitDocumentsViewModel viewModel = context.watch<ResubmitDocumentsViewModel>();
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;

    final List<Widget> content;
    if (viewModel.isFirstLoad) {
      content = <Widget>[
        Skeleton(height: 140.dh, radius: AppRadii.lgAll),
        SizedBox(height: AppSpacing.md.dh),
        for (int i = 0; i < 3; i++) ...<Widget>[
          Skeleton(height: 48.dh),
          SizedBox(height: AppSpacing.xs.dh),
        ],
      ];
    } else if (viewModel.current == null) {
      content = <Widget>[StateCard.error(onRetry: viewModel.load)];
    } else {
      final List<ProviderDocument> rejected = viewModel.rejected;
      final List<ProviderDocumentType> toSend = viewModel.toSend;
      content = <Widget>[
        Text(
          toSend.isEmpty
              ? l10n.resubmitNothingBody
              : rejected.isEmpty
                  ? l10n.resubmitMissingBody(toSend.length)
                  : l10n.resubmitBody(rejected.length),
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        for (final ProviderDocument document in rejected) ...<Widget>[
          SizedBox(height: AppSpacing.md.dh),
          _ReasonCard(
            document: document,
            // Named only when there is more than one to tell apart.
            name: rejected.length > 1 ? documentName(l10n, document.type) : null,
            language: language,
          ),
        ],
        SizedBox(height: AppSpacing.lg.dh),
        Text(
          l10n.providerYourDocuments,
          style: textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
        ),
        for (final ProviderDocument document in viewModel.documents) ...<Widget>[
          SizedBox(height: AppSpacing.xs.dh),
          DocumentStatusRow(document: document),
          if (toSend.contains(document.type)) ...<Widget>[
            SizedBox(height: AppSpacing.sm.dh),
            _UploadSlot(
              slot: viewModel.slotFor(document.type),
              maxMegabytes: viewModel.maxMegabytes,
              isLocked: viewModel.isSubmitting,
              onPick: () => viewModel.pick(document.type),
              onRemove: () => viewModel.remove(document.type),
            ),
            SizedBox(height: AppSpacing.xs.dh),
          ],
        ],
      ];
    }

    return DiscardGuard(
      isDirty: viewModel.isDirty,
      child: Scaffold(
        backgroundColor: AppColors.bgSurface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md.dw,
                    AppSpacing.xl.dh,
                    AppSpacing.md.dw,
                    AppSpacing.lg.dh,
                  ),
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.resubmitTitle,
                        style: textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs.dh),
                    ...content,
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md.dw,
                  AppSpacing.sm.dh,
                  AppSpacing.md.dw,
                  AppSpacing.md.dh,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (viewModel.toSend.isNotEmpty) ...<Widget>[
                      MainButton(
                        label: l10n.providerResubmit,
                        isLoading: viewModel.isSubmitting,
                        canBeTapped: viewModel.canSubmit,
                        onPressed: () => _submit(context, viewModel),
                      ),
                      SizedBox(height: AppSpacing.xs.dh),
                    ],
                    MainButton(
                      label: viewModel.toSend.isEmpty ? l10n.backLabel : l10n.resubmitNotNow,
                      style: MainButtonStyle.secondary,
                      onPressed: viewModel.isSubmitting
                          ? null
                          : () => Navigator.maybePop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Why a document was refused — the reviewer's reason and note, and when.
class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.document, required this.name, required this.language});

  final ProviderDocument document;
  final String? name;
  final String language;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DateTime? reviewed = document.reviewedAt;
    final String? reason = document.rejectReason;
    final String? note = document.rejectNote;
    final String? label = name;

    return Container(
      padding: EdgeInsetsDirectional.all(AppSpacing.md.dw),
      decoration: const BoxDecoration(
        color: AppColors.bgDangerSubtle,
        borderRadius: AppRadii.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (reviewed != null) ...<Widget>[
            Container(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.sm.dw,
                vertical: AppSpacing.xs2.dh,
              ),
              decoration: const BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppRadii.fullAll,
              ),
              child: Text(
                l10n.resubmitRejectedOn(dayMonthYear(reviewed, language)),
                style: textTheme.labelSmall?.copyWith(color: AppColors.textDanger),
              ),
            ),
            SizedBox(height: AppSpacing.sm.dh),
          ],
          Text(
            label == null ? l10n.resubmitReasonGiven : '${l10n.resubmitReasonGiven} · $label',
            style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.xs2.dh),
          Text(
            reason ?? l10n.resubmitNoReason,
            style: textTheme.titleSmall?.copyWith(color: AppColors.textDanger),
          ),
          if (note != null && note.trim().isNotEmpty) ...<Widget>[
            SizedBox(height: AppSpacing.xs.dh),
            Text(note, style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary)),
          ],
        ],
      ),
    );
  }
}

/// Where the new file for one document goes: a dashed "Upload a new file"
/// until one is picked, then the file with Change and remove — or its
/// progress, or why it was refused.
class _UploadSlot extends StatelessWidget {
  const _UploadSlot({
    required this.slot,
    required this.maxMegabytes,
    required this.isLocked,
    required this.onPick,
    required this.onRemove,
  });

  final ResubmitSlot slot;
  final int maxMegabytes;
  final bool isLocked;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DocumentFile? file = slot.file;
    final String? error = slot.error == null ? null : l10n.forDocumentError(slot.error!);

    final Widget box;
    if (file == null) {
      box = Semantics(
        button: true,
        child: GestureDetector(
          onTap: isLocked ? null : onPick,
          behavior: HitTestBehavior.opaque,
          child: DashedBorderBox(
            padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.md.dh),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const AppIcon(AppIcons.plus, size: AppSizes.iconMd, color: AppColors.iconBrand),
                SizedBox(width: AppSpacing.xs.dw),
                Text(l10n.resubmitUploadNew, style: textTheme.labelLarge?.copyWith(color: AppColors.textBrand)),
              ],
            ),
          ),
        ),
      );
    } else {
      box = Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm.dw,
          vertical: AppSpacing.sm.dh,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppRadii.mdAll,
          border: Border.all(color: error != null ? AppColors.borderDanger : AppColors.borderBrand),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                AppIcon(
                  AppIcons.fileText,
                  size: AppSizes.iconMd,
                  color: error != null ? AppColors.iconDanger : AppColors.iconBrand,
                ),
                SizedBox(width: AppSpacing.xs.dw),
                Expanded(
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                  ),
                ),
                if (!slot.isUploading) ...<Widget>[
                  GestureDetector(
                    onTap: isLocked ? null : onPick,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.xs.dw),
                      child: Text(
                        l10n.resubmitChange,
                        style: textTheme.labelMedium?.copyWith(color: AppColors.textBrand),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: l10n.resubmitRemove,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: isLocked ? null : onRemove,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox.square(
                        dimension: AppSizes.touchTarget.dw,
                        child: const Center(
                          child: AppIcon(AppIcons.close, size: AppSizes.iconMd, color: AppColors.iconDefault),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (slot.isUploading) ...<Widget>[
              SizedBox(height: AppSpacing.xs.dh),
              ClipRRect(
                borderRadius: AppRadii.fullAll,
                child: LinearProgressIndicator(
                  value: slot.progress == 0 ? null : slot.progress,
                  minHeight: 4,
                  backgroundColor: AppColors.bgDisabled,
                  color: AppColors.bgBrand,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        box,
        SizedBox(height: AppSpacing.xs2.dh),
        Text(
          error ?? l10n.resubmitHint(maxMegabytes),
          style: textTheme.labelSmall?.copyWith(
            color: error != null ? AppColors.textDanger : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

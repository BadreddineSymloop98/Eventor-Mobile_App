import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/layout/collapsing_photo_header.dart';
import '../../../core/widgets/layout/content_container.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/document_upload_field.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/documents_repository.dart';
import '../view_model/documents_view_model.dart';

/// `08e Verification documents` — right after a provider confirms their
/// email, and again from their home while anything is missing.
///
/// Back does what "I'll do it later" does: the account already exists and is
/// signed in, so there is nothing behind this screen to go back to.
class DocumentsView extends StatelessWidget {
  const DocumentsView({super.key});

  void _later(BuildContext context) => context.go(AppRoutes.home);

  Future<void> _submit(BuildContext context) async {
    final DocumentsViewModel viewModel = context.read<DocumentsViewModel>();
    await viewModel.submit();
    if (!context.mounted) return;
    final Failure? failure = viewModel.failure;
    if (failure != null) {
      showAppToast(
        context,
        context.l10n.forFailure(failure),
        tone: AppToastTone.error,
      );
      return;
    }
    showAppToast(context, context.l10n.documentsSubmitted);
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final DocumentsViewModel viewModel = context.watch<DocumentsViewModel>();
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _later(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.bgSurface,
        body: CustomScrollView(
          slivers: <Widget>[
            CollapsingPhotoHeader(
              title: l10n.documentsTitle,
              subtitle: l10n.documentsSubtitle,
              onBack: () => _later(context),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md.dw,
                ),
                child: ContentContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(height: AppSpacing.xl.dh),
                      Text(
                        l10n.documentsSectionTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs2.dh),
                      Text(
                        l10n.documentsSectionNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      for (final ProviderDocumentType type
                          in DocumentsViewModel.types) ...<Widget>[
                        SizedBox(height: AppSpacing.md.dh),
                        _DocumentField(type: type, viewModel: viewModel),
                      ],
                      SizedBox(height: AppSpacing.xl.dh),
                      MainButton(
                        label: l10n.documentsSubmit,
                        canBeTapped: viewModel.canSubmit,
                        // Its own work only — not the first load of the page.
                        isLoading: viewModel.isBusy && !viewModel.isLoading,
                        onPressed: () => _submit(context),
                      ),
                      SizedBox(height: AppSpacing.sm.dh),
                      MainButton(
                        label: l10n.documentsLater,
                        style: MainButtonStyle.ghost,
                        onPressed: () => _later(context),
                      ),
                      SizedBox(height: AppSpacing.xl2.dh),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentField extends StatelessWidget {
  const _DocumentField({required this.type, required this.viewModel});

  final ProviderDocumentType type;
  final DocumentsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DocumentSlot slot = viewModel.slotFor(type);

    final (String label, String hint) = switch (type) {
      ProviderDocumentType.nationalId => (
          l10n.documentIdentityCard,
          l10n.documentIdentityCardHint,
        ),
      ProviderDocumentType.commercialRegister => (
          l10n.documentCommercialRegister,
          l10n.documentCommercialRegisterHint,
        ),
      ProviderDocumentType.taxCard => (
          l10n.documentTaxRegistration,
          l10n.documentTaxRegistrationHint,
        ),
    };

    final String? error = slot.error != null
        ? l10n.forDocumentError(slot.error!)
        : slot.serverReason;

    final String helper = slot.isUploading
        ? l10n.documentUploading
        : switch (slot.status) {
            ProviderDocumentStatus.approved => l10n.documentApproved,
            ProviderDocumentStatus.pending => l10n.documentUnderReview,
            _ => hint,
          };

    return DocumentUploadField(
      label: label,
      // A file uploaded on another visit has no local name; the status line
      // says it is there.
      fileName: slot.fileName ?? (slot.isReceived ? l10n.documentUploaded : null),
      helperText: helper,
      errorText: error,
      isUploading: slot.isUploading,
      // An approved document is final; the rest can be (re)picked. Nothing is
      // tappable until the current state has loaded.
      onTap: viewModel.isLoading ||
              slot.isUploading ||
              slot.status == ProviderDocumentStatus.approved
          ? null
          : () => viewModel.pick(type),
    );
  }
}

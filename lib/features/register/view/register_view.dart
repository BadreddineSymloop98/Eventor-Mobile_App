import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/input_rules.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/content_container.dart';
import '../../../core/widgets/document_actions_sheet.dart';
import '../../../core/widgets/document_upload_field.dart';
import '../../../core/widgets/main_button.dart';
import '../../../core/widgets/prompt_row.dart';
import '../../../l10n/app_localizations.dart';
import '../model/account_document.dart';
import '../view_model/register_view_model.dart';
import 'widgets/register_header.dart';

/// The sign-up form.
///
/// The whole screen scrolls under a header that shrinks as it goes: the
/// photograph and the subtitle give way, and only "Create your account" and
/// the top bar are left pinned. That keeps the user's place in a four-field
/// form without losing the way back or the language switch.
class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  Future<void> _submit(BuildContext context) async {
    final RegisterViewModel viewModel = context.read<RegisterViewModel>();
    final AppLocalizations l10n = context.l10n;

    // Dismiss the keyboard first: the toast appears at the bottom, which is
    // exactly where the keyboard would otherwise be.
    FocusScope.of(context).unfocus();

    final bool succeeded = await viewModel.submit();
    if (!succeeded || !context.mounted) return;

    showAppToast(context, l10n.registerSuccess);

    // The design sends a new account on to confirm its number.
    await Navigator.of(context).pushNamed(
      AppRoutes.verifyCode,
      arguments: viewModel.phoneController.text,
    );
  }

  /// Decides what a tap on a document field means.
  ///
  /// An empty field has one obvious gesture, so it goes straight to the
  /// browser. A field that already holds a file has two — replace it or drop
  /// it — and one tap cannot mean both, so it asks.
  Future<void> _onDocumentTap(
    BuildContext context,
    RegisterViewModel viewModel,
    AccountDocument document,
  ) async {
    final String? fileName = viewModel.fileNameFor(document);
    if (fileName == null) {
      await viewModel.pickDocument(document);
      return;
    }

    final DocumentAction? action = await showDocumentActionsSheet(
      context,
      fileName: fileName,
    );
    // Dismissed without choosing, which is not an answer.
    if (action == null || !context.mounted) return;

    switch (action) {
      case DocumentAction.replace:
        await viewModel.pickDocument(document);
      case DocumentAction.remove:
        viewModel.removeDocument(document);
    }
  }

  void _goToLogin(BuildContext context) =>
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final RegisterViewModel viewModel = context.watch<RegisterViewModel>();
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bgSurface,
      body: CustomScrollView(
        slivers: <Widget>[
          RegisterHeader(
            // A role that never made it this far — a deep link, or a reload —
            // still gets the planner's wording rather than an empty header.
            subtitle:
                viewModel.role?.registerSubtitle(l10n) ?? l10n.registerSubtitle,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md.dw,
              ),
              child: ContentContainer(
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(height: AppSpacing.xl.dh),
                      _Form(viewModel: viewModel, l10n: l10n),
                      if (viewModel.isReviewed) ...<Widget>[
                        SizedBox(height: AppSpacing.xl.dh),
                        _Documents(
                          viewModel: viewModel,
                          l10n: l10n,
                          onTapDocument: (AccountDocument document) =>
                              _onDocumentTap(context, viewModel, document),
                        ),
                      ],
                      SizedBox(height: AppSpacing.xl.dh),
                      const _Terms(),
                      SizedBox(height: AppSpacing.sm.dh),
                      MainButton(
                        label: l10n.registerCreateAccount,
                        // Disabled until every field is fillable, and again
                        // while the request is in flight so it cannot be
                        // submitted twice.
                        canBeTapped: viewModel.canSubmit,
                        isLoading: viewModel.isBusy,
                        onPressed: () => _submit(context),
                      ),
                      SizedBox(height: AppSpacing.sm.dh),
                      PromptRow(
                        question: l10n.registerHasAccountPrompt,
                        actionLabel: l10n.logIn,
                        onTap: () => _goToLogin(context),
                      ),
                      SizedBox(height: AppSpacing.xl2.dh),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The typed fields, each with the rules its own value follows.
///
/// The institution field only exists for the role that acts on behalf of one,
/// which is why the focus chain steps over it rather than through it.
class _Form extends StatelessWidget {
  const _Form({required this.viewModel, required this.l10n});

  final RegisterViewModel viewModel;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          controller: viewModel.nameController,
          focusNode: viewModel.nameFocusNode,
          label: l10n.nameLabel,
          keyboardType: TextInputType.name,
          autofillHints: const <String>[AutofillHints.name],
          inputFormatters: InputRules.nameFormatters,
          hintText: l10n.namePlaceholder,
          helperText: viewModel.isNameSatisfied
              ? null
              : l10n.nameHint(InputRules.minNameLength),
          errorText: viewModel.nameError == null
              ? null
              : l10n.forNameError(viewModel.nameError!),
          onSubmitted: (_) => viewModel.moveFocusAfterName(),
        ),
        if (viewModel.needsInstitution) ...<Widget>[
          SizedBox(height: AppSpacing.md.dh),
          AppTextField(
            controller: viewModel.institutionController,
            focusNode: viewModel.institutionFocusNode,
            label: l10n.institutionLabel,
            keyboardType: TextInputType.text,
            autofillHints: const <String>[AutofillHints.organizationName],
            inputFormatters: InputRules.institutionFormatters,
            hintText: l10n.institutionPlaceholder,
            helperText: viewModel.isInstitutionSatisfied
                ? null
                : l10n.institutionHint(InputRules.minInstitutionLength),
            errorText: viewModel.institutionError == null
                ? null
                : l10n.forInstitutionError(viewModel.institutionError!),
            onSubmitted: (_) => viewModel.moveFocusToEmail(),
          ),
        ],
        SizedBox(height: AppSpacing.md.dh),
        AppTextField(
          controller: viewModel.emailController,
          focusNode: viewModel.emailFocusNode,
          label: l10n.emailLabel,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const <String>[AutofillHints.email],
          inputFormatters: InputRules.emailFormatters,
          // An address is Latin text even in an Arabic UI.
          textDirection: TextDirection.ltr,
          hintText: l10n.emailPlaceholder,
          helperText: viewModel.isEmailSatisfied ? null : l10n.emailHint,
          errorText: viewModel.emailError == null
              ? null
              : l10n.forEmailError(viewModel.emailError!),
          onSubmitted: (_) => viewModel.moveFocusToPhone(),
        ),
        SizedBox(height: AppSpacing.md.dh),
        AppTextField(
          controller: viewModel.phoneController,
          focusNode: viewModel.phoneFocusNode,
          label: l10n.phoneLabel,
          keyboardType: TextInputType.phone,
          autofillHints: const <String>[AutofillHints.telephoneNumber],
          inputFormatters: InputRules.phoneFormatters,
          // A number reads left to right whatever the surrounding language.
          textDirection: TextDirection.ltr,
          hintText: l10n.phonePlaceholder,
          helperText: viewModel.isPhoneSatisfied
              ? null
              : l10n.phoneHint(
                  InputRules.phoneLength,
                  InputRules.phoneLeadingDigit,
                ),
          errorText: viewModel.phoneError == null
              ? null
              : l10n.forPhoneError(viewModel.phoneError!),
          onSubmitted: (_) => viewModel.moveFocusToPassword(),
        ),
        SizedBox(height: AppSpacing.md.dh),
        AppTextField(
          controller: viewModel.passwordController,
          focusNode: viewModel.passwordFocusNode,
          label: l10n.passwordLabel,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.newPassword],
          inputFormatters: InputRules.passwordFormatters,
          textDirection: TextDirection.ltr,
          helperText: viewModel.isPasswordSatisfied
              ? null
              : l10n.passwordHint(InputRules.minPasswordLength),
          errorText: viewModel.passwordError == null
              ? null
              : l10n.forPasswordError(viewModel.passwordError!),
        ),
      ],
    );
  }
}

/// The papers a reviewed account has to attach, under a heading that says what
/// the review is for.
///
/// Only built when the role supplies documents, so a planner never sees an
/// empty heading.
class _Documents extends StatelessWidget {
  const _Documents({
    required this.viewModel,
    required this.l10n,
    required this.onTapDocument,
  });

  final RegisterViewModel viewModel;
  final AppLocalizations l10n;

  /// What a tap on one field means is the screen's decision, not the
  /// field's — see [RegisterView._onDocumentTap].
  final ValueChanged<AccountDocument> onTapDocument;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? note = viewModel.role?.documentsNote(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.registerDocumentsTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        if (note != null) ...<Widget>[
          SizedBox(height: AppSpacing.xs2.dh),
          Text(
            note,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        for (final AccountDocument document in viewModel.documents) ...<Widget>[
          SizedBox(height: AppSpacing.md.dh),
          DocumentUploadField(
            label: document.label(l10n),
            fileName: viewModel.fileNameFor(document),
            helperText: document.hint(l10n),
            errorText: viewModel.errorFor(document) == null
                ? null
                : l10n.forDocumentError(viewModel.errorFor(document)!),
            onTap: () => onTapDocument(document),
          ),
        ],
      ],
    );
  }
}

/// The terms line, with its second half in the brand colour.
class _Terms extends StatelessWidget {
  const _Terms();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    final TextStyle? base = theme.textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: <InlineSpan>[
          TextSpan(text: l10n.registerTermsPrefix),
          TextSpan(
            text: l10n.registerTermsLink,
            style: base?.copyWith(color: AppColors.textBrand),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

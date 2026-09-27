import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/input_rules.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/validation_error.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/models/account.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/layout/collapsing_photo_header.dart';
import '../../../core/widgets/layout/content_container.dart';
import '../../../core/widgets/molecules/app_select_field.dart';
import '../../../core/widgets/molecules/app_text_field.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/inline_banner.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/prompt_row.dart';
import '../../../core/widgets/organisms/selection_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/register_view_model.dart';

/// `08 Register` and `08a Register · Provider`, with `08b` as a banner.
///
/// The whole screen scrolls under a header that shrinks as it goes, keeping
/// the way back and the language switch while the form is filled in.
class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  Future<void> _submit(BuildContext context) async {
    final RegisterViewModel viewModel = context.read<RegisterViewModel>();
    FocusScope.of(context).unfocus();

    final VerifyEmailArgs? args = await viewModel.submit();
    if (!context.mounted) return;

    if (args != null) {
      // `go`, not `push`: the account now exists, so there is no form to come
      // back to — Back on 10b leads to Login instead.
      context.go(AppRoutes.verifyEmail, extra: args);
      return;
    }
    final Failure? failure = viewModel.failure;
    if (failure != null) {
      showAppToast(
        context,
        context.l10n.forFailure(failure),
        tone: AppToastTone.error,
      );
    }
  }

  void _goToLogin(BuildContext context, RegisterViewModel viewModel) {
    // Carries the address over when the server has just said it has an
    // account — the obvious next step is to log in with it.
    context.pushReplacement(
      AppRoutes.loginWith(
        email: viewModel.emailTaken ? viewModel.emailController.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RegisterViewModel viewModel = context.watch<RegisterViewModel>();
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bgSurface,
      body: CustomScrollView(
        slivers: <Widget>[
          CollapsingPhotoHeader(
            title: l10n.registerTitle,
            subtitle: viewModel.isProvider
                ? l10n.registerSubtitleProvider
                : l10n.registerSubtitle,
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
                      if (viewModel.emailTaken) ...<Widget>[
                        InlineBanner(
                          title: l10n.registerEmailTakenTitle,
                          message: l10n.registerEmailTakenBody,
                        ),
                        SizedBox(height: AppSpacing.md.dh),
                      ],
                      _PersonalFields(viewModel: viewModel),
                      if (viewModel.isProvider) ...<Widget>[
                        SizedBox(height: AppSpacing.xl.dh),
                        _BusinessFields(viewModel: viewModel),
                      ],
                      SizedBox(height: AppSpacing.xl.dh),
                      const _Terms(),
                      SizedBox(height: AppSpacing.sm.dh),
                      MainButton(
                        label: l10n.registerCreateAccount,
                        canBeTapped: viewModel.canSubmit,
                        isLoading: viewModel.isBusy,
                        onPressed: () => _submit(context),
                      ),
                      SizedBox(height: AppSpacing.sm.dh),
                      PromptRow(
                        question: l10n.registerHasAccountPrompt,
                        actionLabel: l10n.logIn,
                        onTap: () => _goToLogin(context, viewModel),
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

/// Name, email, phone, the client's optional wilaya, password.
class _PersonalFields extends StatelessWidget {
  const _PersonalFields({required this.viewModel});

  final RegisterViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          controller: viewModel.nameController,
          focusNode: viewModel.nameFocusNode,
          label: l10n.nameLabel,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          autofillHints: const <String>[AutofillHints.name],
          inputFormatters: InputRules.nameFormatters,
          hintText: l10n.namePlaceholder,
          errorText: viewModel.nameError == null
              ? null
              : l10n.forNameError(viewModel.nameError!),
          onSubmitted: (_) => viewModel.moveFocusToEmail(),
        ),
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
          // The banner above already says it; the red outline is enough here.
          errorText: viewModel.emailError == null || viewModel.emailTaken
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
          helperText: l10n.phoneHint,
          errorText: viewModel.phoneError == null
              ? null
              : l10n.forPhoneError(viewModel.phoneError!),
          onSubmitted: (_) => viewModel.moveFocusToPassword(),
        ),
        if (!viewModel.isProvider) ...<Widget>[
          SizedBox(height: AppSpacing.md.dh),
          AppSelectField(
            label: l10n.wilayaOptionalLabel,
            placeholder: l10n.wilayaPlaceholder,
            value: viewModel.wilaya?.nameFor(language),
            helperText: viewModel.referenceFailed ? l10n.referenceLoadFailed : null,
            onTap: () => _pickWilaya(context, viewModel, language),
          ),
        ],
        SizedBox(height: AppSpacing.md.dh),
        AppTextField(
          controller: viewModel.passwordController,
          focusNode: viewModel.passwordFocusNode,
          label: l10n.passwordLabel,
          obscureText: true,
          textInputAction:
              viewModel.isProvider ? TextInputAction.next : TextInputAction.done,
          autofillHints: const <String>[AutofillHints.newPassword],
          inputFormatters: InputRules.passwordFormatters,
          textDirection: TextDirection.ltr,
          helperText: l10n.passwordHint(viewModel.minPasswordLength),
          errorText: viewModel.passwordError == null
              ? null
              : l10n.forPasswordError(viewModel.passwordError!),
          onSubmitted: (_) {
            if (viewModel.isProvider) viewModel.moveFocusToBusinessName();
          },
        ),
      ],
    );
  }

  Future<void> _pickWilaya(
    BuildContext context,
    RegisterViewModel viewModel,
    String language,
  ) async {
    if (viewModel.wilayas.isEmpty) {
      await viewModel.loadReference();
      if (viewModel.wilayas.isEmpty || !context.mounted) return;
    }
    final Set<Wilaya>? picked = await showSelectionSheet<Wilaya>(
      context,
      title: context.l10n.wilayaSheetTitle,
      searchHint: context.l10n.wilayaSearchHint,
      options: _wilayaOptions(viewModel.wilayas, language),
      selected: <Wilaya>{if (viewModel.wilaya != null) viewModel.wilaya!},
    );
    if (picked != null && picked.isNotEmpty) viewModel.selectWilaya(picked.first);
  }
}

/// `08a`'s "Your business": name, category, wilayas served.
class _BusinessFields extends StatelessWidget {
  const _BusinessFields({required this.viewModel});

  final RegisterViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    final List<Wilaya> served = viewModel.wilayasServed.toList()
      ..sort((Wilaya a, Wilaya b) => a.code.compareTo(b.code));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.registerBusinessTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.xs2.dh),
        Text(
          l10n.registerBusinessNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.md.dh),
        AppTextField(
          controller: viewModel.businessNameController,
          focusNode: viewModel.businessNameFocusNode,
          label: l10n.businessNameLabel,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          autofillHints: const <String>[AutofillHints.organizationName],
          inputFormatters: InputRules.businessNameFormatters,
          hintText: l10n.businessNamePlaceholder,
          errorText: switch (viewModel.businessNameError) {
            null => null,
            _ when viewModel.businessNameController.text.trim().isEmpty =>
              l10n.businessNameRequired,
            final NameError error => l10n.forNameError(error),
          },
        ),
        SizedBox(height: AppSpacing.md.dh),
        AppSelectField(
          label: l10n.categoryLabel,
          placeholder: l10n.categoryPlaceholder,
          value: viewModel.category?.nameFor(language),
          errorText: viewModel.categoryError == null
              ? (viewModel.referenceFailed ? l10n.referenceLoadFailed : null)
              : l10n.categoryRequired,
          onTap: () => _pickCategory(context, language),
        ),
        SizedBox(height: AppSpacing.md.dh),
        AppSelectField(
          label: l10n.wilayasServedLabel,
          placeholder: l10n.wilayasServedPlaceholder,
          value: served.isEmpty
              ? null
              : served.map((Wilaya w) => w.nameFor(language)).join(language == 'ar' ? '، ' : ', '),
          errorText: viewModel.wilayasError == null ? null : l10n.wilayasRequired,
          onTap: () => _pickWilayasServed(context, language),
        ),
      ],
    );
  }

  Future<void> _pickCategory(BuildContext context, String language) async {
    if (viewModel.categories.isEmpty) {
      await viewModel.loadReference();
      if (viewModel.categories.isEmpty || !context.mounted) return;
    }
    final Set<ServiceCategory>? picked =
        await showSelectionSheet<ServiceCategory>(
      context,
      title: context.l10n.categorySheetTitle,
      options: viewModel.categories
          .map(
            (ServiceCategory c) => SelectionOption<ServiceCategory>(
              value: c,
              label: c.nameFor(language),
            ),
          )
          .toList(),
      selected: <ServiceCategory>{
        if (viewModel.category != null) viewModel.category!,
      },
    );
    if (picked != null && picked.isNotEmpty) {
      viewModel.selectCategory(picked.first);
    }
  }

  Future<void> _pickWilayasServed(BuildContext context, String language) async {
    if (viewModel.wilayas.isEmpty) {
      await viewModel.loadReference();
      if (viewModel.wilayas.isEmpty || !context.mounted) return;
    }
    final Set<Wilaya>? picked = await showSelectionSheet<Wilaya>(
      context,
      title: context.l10n.wilayasServedSheetTitle,
      searchHint: context.l10n.wilayaSearchHint,
      multiple: true,
      options: _wilayaOptions(viewModel.wilayas, language),
      selected: viewModel.wilayasServed,
    );
    if (picked != null) viewModel.selectWilayasServed(picked);
  }
}

List<SelectionOption<Wilaya>> _wilayaOptions(
  List<Wilaya> wilayas,
  String language,
) {
  return wilayas
      .map(
        (Wilaya w) => SelectionOption<Wilaya>(
          value: w,
          // The number is how Algerians identify a wilaya ("16 — Alger"),
          // and it keeps the list scannable in both scripts.
          label: '${w.code.toString().padLeft(2, '0')} — ${w.nameFor(language)}',
        ),
      )
      .toList();
}

/// "By continuing you agree to our Terms and Privacy Policy." — the link opens
/// the terms page when the server publishes one (it does not yet), otherwise
/// it is plain text rather than a link to nowhere.
class _Terms extends StatelessWidget {
  const _Terms();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    final String? termsUrl =
        context.read<AppConfigRepository>().current.termsUrl;
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
            recognizer: termsUrl == null
                ? null
                : (TapGestureRecognizer()
                  ..onTap = () => launchUrl(
                        Uri.parse(termsUrl),
                        mode: LaunchMode.externalApplication,
                      )),
          ),
          TextSpan(text: l10n.registerTermsSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

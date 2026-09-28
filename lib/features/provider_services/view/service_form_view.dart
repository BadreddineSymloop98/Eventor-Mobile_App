import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/catalog/models/price_type.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/amount_input.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/models/account.dart';
import '../../../core/provider_catalog/provider_catalog_repository.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/molecules/app_text_area.dart';
import '../../../core/widgets/molecules/app_text_field.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/content_language_switch.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/price_text.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/bottom_action_bar.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../core/widgets/organisms/confirm_sheet.dart';
import '../../../core/widgets/organisms/discard_guard.dart';
import '../../../core/widgets/organisms/selection_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/catalog_outcomes.dart';
import '../view_model/service_form_view_model.dart';
import 'catalog_wording.dart';
import 'widgets/catalog_form_parts.dart';
import 'widgets/catalog_sheets.dart';

/// P7 Add a service and P7a Edit service. Closes with `true` once something
/// was saved, published or deleted, so P6 reloads.
class ServiceFormView extends StatefulWidget {
  const ServiceFormView({super.key});

  @override
  State<ServiceFormView> createState() => _ServiceFormViewState();
}

class _ServiceFormViewState extends State<ServiceFormView> {
  late final ServiceFormViewModel _viewModel = context.read<ServiceFormViewModel>();

  final TextEditingController _titleEn = TextEditingController();
  final TextEditingController _titleAr = TextEditingController();
  final TextEditingController _descriptionEn = TextEditingController();
  final TextEditingController _descriptionAr = TextEditingController();
  final TextEditingController _policyEn = TextEditingController();
  final TextEditingController _policyAr = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();
  final ScrollController _scroll = ScrollController();

  final GlobalKey _basicsKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _capacityKey = GlobalKey();
  final GlobalKey _includedKey = GlobalKey();
  final GlobalKey _wilayasKey = GlobalKey();

  bool _isFilled = false;

  /// Whether anything reached the server — what P6 is told on the way out.
  bool _changedSomething = false;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_fillOnce);
    _fillOnce();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_fillOnce);
    for (final TextEditingController c in <TextEditingController>[
      _titleEn,
      _titleAr,
      _descriptionEn,
      _descriptionAr,
      _policyEn,
      _policyAr,
      _price,
    ]) {
      c.dispose();
    }
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _priceFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Puts the loaded service into the fields, once — P7 has nothing to wait
  /// for, P7a its detail.
  void _fillOnce() {
    if (_isFilled || _viewModel.isFirstLoad || _viewModel.loadFailed) return;
    _isFilled = true;
    _titleEn.text = _viewModel.titleEn;
    _titleAr.text = _viewModel.titleAr;
    _descriptionEn.text = _viewModel.descriptionEn;
    _descriptionAr.text = _viewModel.descriptionAr;
    _policyEn.text = _viewModel.policyEn;
    _policyAr.text = _viewModel.policyAr;
    _price.text = groupDinars('${_viewModel.basePrice ?? ''}');
    final ServiceChecklistItem? fix = _viewModel.takeFix();
    if (fix != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyFix(fix);
      });
    }
  }

  void _close() => Navigator.of(context).pop(_changedSomething);

  void _error(Failure failure) {
    showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
    if (ServiceFormViewModel.isGoneFailure(failure)) _close();
  }

  Future<void> _reveal(GlobalKey key) async {
    final BuildContext? target = key.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// P9's primary: to the first thing still missing.
  Future<void> _applyFix(ServiceChecklistItem item) async {
    switch (item) {
      case ServiceChecklistItem.englishText || ServiceChecklistItem.arabicText:
        final ContentLanguage language = item == ServiceChecklistItem.arabicText
            ? ContentLanguage.arabic
            : ContentLanguage.english;
        _viewModel.setLanguage(language);
        await _reveal(_basicsKey);
        final bool titleMissing = language == ContentLanguage.arabic
            ? _viewModel.titleAr.trim().isEmpty
            : _viewModel.titleEn.trim().isEmpty;
        if (mounted) (titleMissing ? _titleFocus : _descriptionFocus).requestFocus();
      case ServiceChecklistItem.price:
        await _reveal(_pricingKey);
        if (mounted) _priceFocus.requestFocus();
      case ServiceChecklistItem.photos:
        await _openPhotos();
      case ServiceChecklistItem.category:
        await _reveal(_basicsKey);
        await _pickCategory();
      case ServiceChecklistItem.wilayas:
        await _reveal(_wilayasKey);
        await _pickWilayas();
    }
  }

  /// The fields a save needs, flagged; to the first of them.
  Future<void> _showInvalid(List<ServiceField> fields) async {
    showAppToast(context, context.l10n.providerServiceFixFields, tone: AppToastTone.error);
    if (fields.isEmpty) return;
    final ServiceField first = fields.first;
    if (first == ServiceField.titleEn) _viewModel.setLanguage(ContentLanguage.english);
    await _reveal(switch (first) {
      ServiceField.category || ServiceField.titleEn || ServiceField.titleAr => _basicsKey,
      ServiceField.descriptionEn || ServiceField.descriptionAr => _basicsKey,
      ServiceField.basePrice || ServiceField.priceType => _pricingKey,
      ServiceField.maxEventsPerDay || ServiceField.maxGuests => _capacityKey,
      ServiceField.facts || ServiceField.extras => _includedKey,
      ServiceField.wilayas => _wilayasKey,
      ServiceField.cancellationEn || ServiceField.cancellationAr => _wilayasKey,
    });
  }

  // -------------------------------------------------------------- pickers

  Future<void> _pickCategory() async {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    FocusScope.of(context).unfocus();
    final List<ServiceCategory> categories;
    try {
      categories = await _viewModel.categories();
    } on Failure catch (failure) {
      if (mounted) _error(failure);
      return;
    }
    if (!mounted) return;
    final Set<String>? picked = await showSelectionSheet<String>(
      context,
      title: l10n.providerServiceCategory,
      selected: <String>{if (_viewModel.category case final ServiceCategory c) c.id},
      options: <SelectionOption<String>>[
        for (final ServiceCategory category in categories)
          SelectionOption<String>(value: category.id, label: category.nameFor(language)),
      ],
    );
    if (picked == null || picked.isEmpty) return;
    for (final ServiceCategory category in categories) {
      if (category.id == picked.first) _viewModel.setCategory(category);
    }
  }

  Future<void> _pickPriceType() async {
    final AppLocalizations l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final Set<PriceType>? picked = await showSelectionSheet<PriceType>(
      context,
      title: l10n.providerServicePriceTypeLabel,
      selected: <PriceType>{if (_viewModel.priceType case final PriceType t) t},
      options: <SelectionOption<PriceType>>[
        for (final PriceType type in PriceType.values)
          SelectionOption<PriceType>(value: type, label: l10n.priceTypeOption(type)),
      ],
    );
    if (picked != null && picked.isNotEmpty) _viewModel.setPriceType(picked.first);
  }

  Future<void> _pickWilayas() async {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    FocusScope.of(context).unfocus();
    final List<Wilaya> open;
    try {
      open = List<Wilaya>.of(await _viewModel.openWilayas())
        ..sort((Wilaya a, Wilaya b) => a.nameFor(language).compareTo(b.nameFor(language)));
    } on Failure catch (failure) {
      if (mounted) _error(failure);
      return;
    }
    if (!mounted) return;
    final Set<int>? picked = await showSelectionSheet<int>(
      context,
      title: l10n.providerServiceWilayas,
      subtitle: l10n.providerServiceWilayaPickerBody,
      multiple: true,
      selected: <int>{for (final Wilaya w in _viewModel.wilayas) w.code},
      options: <SelectionOption<int>>[
        for (final Wilaya wilaya in open)
          SelectionOption<int>(value: wilaya.code, label: wilaya.nameFor(language)),
      ],
    );
    if (picked == null) return;
    _viewModel.setWilayas(<Wilaya>[
      for (final Wilaya wilaya in open)
        if (picked.contains(wilaya.code)) wilaya,
      // A covered wilaya that has since closed is not offered again, but it
      // is not the picker's to drop either.
      for (final Wilaya kept in _viewModel.wilayas)
        if (!open.any((Wilaya w) => w.code == kept.code)) kept,
    ]);
  }

  Future<void> _editFact({int? index}) async {
    FocusScope.of(context).unfocus();
    final SheetEdit<ServiceFact>? edit = await showFactSheet(
      context,
      initial: index == null ? null : _viewModel.facts[index],
    );
    if (edit == null) return;
    if (edit.removed && index != null) {
      _viewModel.removeFact(index);
    } else if (edit.value case final ServiceFact fact) {
      _viewModel.putFact(fact, index: index);
    }
  }

  Future<void> _editExtra({int? index}) async {
    FocusScope.of(context).unfocus();
    final SheetEdit<ServiceExtra>? edit = await showExtraSheet(
      context,
      initial: index == null ? null : _viewModel.extras[index],
    );
    if (edit == null) return;
    if (edit.removed && index != null) {
      _viewModel.removeExtra(index);
    } else if (edit.value case final ServiceExtra extra) {
      _viewModel.putExtra(extra, index: index);
    }
  }

  // -------------------------------------------------------------- actions

  Future<void> _save() async {
    final AppLocalizations l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final bool wasDraft = _viewModel.isNew || (_viewModel.saved?.isDraft ?? false);
    final SaveOutcome? outcome = await _viewModel.save();
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case SaveDone():
        _changedSomething = true;
        showAppToast(context, wasDraft ? l10n.providerServiceDraftSaved : l10n.providerServiceChangesSaved);
        _close();
      case SaveInvalid(:final List<ServiceField> fields):
        await _showInvalid(fields);
      case SaveFailed(:final Failure failure):
        _error(failure);
    }
  }

  Future<void> _publish() async {
    final AppLocalizations l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final PublishOutcome<ServiceMissing>? outcome = await _viewModel.publish();
    if (!mounted || outcome == null) return;
    // Anything past an invalid form saved the draft on the way.
    if (outcome is! PublishInvalid<ServiceMissing>) _changedSomething = !_viewModel.isNew;
    switch (outcome) {
      case PublishDone<ServiceMissing>():
        showAppToast(context, l10n.providerServicePublished);
        _close();
      case PublishChecklist<ServiceMissing>(:final List<ServiceMissing> missing):
        final bool fix = await showServiceChecklistSheet(context, missing: missing);
        if (!fix || !mounted) return;
        for (final ServiceChecklistItem item in ServiceChecklistItem.values) {
          if (item.isMissingIn(missing)) {
            await _applyFix(item);
            return;
          }
        }
      case PublishNotVerified<ServiceMissing>():
        await showNotVerifiedSheet(context);
      case PublishInvalid<ServiceMissing>():
        await _showInvalid(<ServiceField>[
          for (final ServiceField field in ServiceField.values)
            if (_viewModel.problemOf(field) != null) field,
        ]);
      case PublishFailed<ServiceMissing>(:final Failure failure):
        _error(failure);
    }
  }

  Future<void> _unpublish() async {
    final AppLocalizations l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final bool confirmed = await showConfirmSheet(
      context,
      title: l10n.providerServiceUnpublishTitle,
      message: l10n.providerServiceUnpublishBody,
      confirmLabel: l10n.providerServiceUnpublish,
      cancelLabel: l10n.providerServiceKeepPublished,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _runUnpublish();
  }

  Future<void> _runUnpublish() async {
    final Failure? failure = await _viewModel.unpublish();
    if (!mounted) return;
    if (failure == null) {
      _changedSomething = true;
      showAppToast(context, context.l10n.providerServiceUnpublished, tone: AppToastTone.info);
    } else {
      _error(failure);
    }
  }

  Future<void> _delete() async {
    final AppLocalizations l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final bool confirmed = await showConfirmSheet(
      context,
      title: l10n.providerServiceDeleteTitle,
      message: l10n.providerServiceDeleteBody,
      confirmLabel: l10n.providerServiceDeleteConfirm,
      cancelLabel: l10n.providerServiceDeleteKeep,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final DeleteOutcome? outcome = await _viewModel.delete();
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case DeleteDone():
        _changedSomething = true;
        showAppToast(context, l10n.providerServiceDeleted, tone: AppToastTone.info);
        _close();
      case DeleteRefused(:final List<DeleteBlocker> blockers):
        final bool unpublish = await showDeleteRefusedSheet(
          context,
          title: l10n.providerServiceDeleteRefusedTitle,
          blockers: blockers,
          canUnpublish: _viewModel.isPublished,
        );
        if (unpublish && mounted) await _runUnpublish();
      case DeleteFailed(:final Failure failure):
        _error(failure);
    }
  }

  Future<void> _openPhotos() async {
    final AppLocalizations l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final bool wasNew = _viewModel.isNew;
    final PhotosAccess? access = await _viewModel.openPhotos();
    if (!mounted || access == null) return;
    switch (access) {
      case PhotosReady(:final String serviceId):
        if (wasNew) {
          _changedSomething = true;
          showAppToast(context, l10n.providerServiceDraftSavedForPhotos);
        }
        await context.push(AppRoutes.providerServicePhotosFor(serviceId));
        if (mounted) await _viewModel.reloadPhotos();
      case PhotosNeedDraft(:final List<ServiceField> fields):
        showAppToast(context, l10n.providerServicePhotosNeedDraft, tone: AppToastTone.error);
        if (fields.isNotEmpty) {
          if (fields.first == ServiceField.titleEn) _viewModel.setLanguage(ContentLanguage.english);
          await _reveal(fields.first == ServiceField.basePrice || fields.first == ServiceField.priceType
              ? _pricingKey
              : _basicsKey);
        }
      case PhotosFailed(:final Failure failure):
        _error(failure);
    }
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final ServiceFormViewModel viewModel = context.watch<ServiceFormViewModel>();
    final AppLocalizations l10n = context.l10n;

    final Widget body;
    if (viewModel.isFirstLoad) {
      body = const _FormSkeleton();
    } else if (viewModel.loadFailed) {
      body = Padding(
        padding: AppSpacing.screenPaddingAll,
        child: viewModel.isGone
            ? StateCard.empty(
                icon: AppIcons.alertTriangle,
                title: l10n.detailGoneTitle,
                body: l10n.detailGoneBody,
                actionLabel: l10n.detailGoneBack,
                onAction: _close,
              )
            : StateCard.error(onRetry: viewModel.load),
      );
    } else {
      body = AbsorbPointer(
        absorbing: viewModel.isWorking,
        child: _form(viewModel),
      );
    }

    return DiscardGuard(
      isDirty: viewModel.isDirty && !viewModel.isWorking,
      child: Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            BrandTopBar(
              title: viewModel.isEditing ? l10n.providerServiceEditTitle : l10n.providerAddService,
            ),
            Expanded(child: body),
            if (!viewModel.isFirstLoad && !viewModel.loadFailed)
              BottomActionBar(child: _actions(viewModel)),
          ],
        ),
      ),
    );
  }

  Widget _actions(ServiceFormViewModel viewModel) {
    final AppLocalizations l10n = context.l10n;
    final ServiceFormAction? action = viewModel.action;
    final bool free = action == null;
    final bool dirty = viewModel.isDirty;
    if (viewModel.isNew) {
      return FormActionRow(
        secondary: MainButton(
          label: l10n.providerServiceSaveDraft,
          style: MainButtonStyle.secondary,
          isLoading: action == ServiceFormAction.save,
          canBeTapped: free,
          onPressed: _save,
        ),
        primary: MainButton(
          label: l10n.providerServicePublish,
          isLoading: action == ServiceFormAction.publish,
          canBeTapped: free,
          onPressed: _publish,
        ),
      );
    }
    if (viewModel.isHidden) {
      return MainButton(
        label: l10n.providerServiceSave,
        isLoading: action == ServiceFormAction.save,
        canBeTapped: free && dirty,
        onPressed: _save,
      );
    }
    if (viewModel.isPublished) {
      return FormActionRow(
        secondary: MainButton(
          label: l10n.providerServiceUnpublish,
          style: MainButtonStyle.secondary,
          isLoading: action == ServiceFormAction.unpublish,
          canBeTapped: free,
          onPressed: _unpublish,
        ),
        primary: MainButton(
          label: l10n.providerServiceSaveChanges,
          isLoading: action == ServiceFormAction.save,
          canBeTapped: free && dirty,
          onPressed: _save,
        ),
      );
    }
    return FormActionRow(
      secondary: MainButton(
        label: l10n.providerServiceSave,
        style: MainButtonStyle.secondary,
        isLoading: action == ServiceFormAction.save,
        canBeTapped: free && dirty,
        onPressed: _save,
      ),
      primary: MainButton(
        label: l10n.providerServicePublish,
        isLoading: action == ServiceFormAction.publish,
        canBeTapped: free,
        onPressed: _publish,
      ),
    );
  }

  Widget _form(ServiceFormViewModel viewModel) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final bool arabic = viewModel.language == ContentLanguage.arabic;
    final String content = viewModel.language.code;
    final bool onQuote = viewModel.priceType == PriceType.onQuote;
    SizedBox gap(double value) => SizedBox(height: value.dh);

    String? error(ServiceField field, {int? max}) => l10n.fieldError(
          viewModel.problemOf(field),
          viewModel.serverErrorOf(field),
          max: max,
        );

    final String? categoryError = error(ServiceField.category);
    final String? priceTypeError = error(ServiceField.priceType);
    final String? eventsError =
        error(ServiceField.maxEventsPerDay, max: ServiceFormViewModel.maxEventsPerDayLimit);
    final String? guestsError =
        error(ServiceField.maxGuests, max: ServiceFormViewModel.maxGuestsLimit);
    final String? wilayasError = error(ServiceField.wilayas);
    final String? factsError = error(ServiceField.facts);
    final String? extrasError = error(ServiceField.extras);

    return SingleChildScrollView(
      controller: _scroll,
      padding: AppSpacing.screenPaddingAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ContentLanguageSwitch(
            value: viewModel.language,
            onChanged: viewModel.setLanguage,
            englishLabel: l10n.providerServiceLangEnglish,
            arabicLabel: l10n.providerServiceLangArabic,
            caption: l10n.serviceLanguageCaption(viewModel.textGaps, isLive: viewModel.isLive),
          ),
          gap(AppSpacing.md),
          CatalogFormSection(
            key: _basicsKey,
            title: l10n.providerServiceBasics,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FormRowCard(
                  children: <Widget>[
                    FormValueRow(
                      label: l10n.providerServiceCategory,
                      value: viewModel.category?.nameFor(language),
                      placeholder: l10n.providerServiceChoose,
                      isLoading: viewModel.isLoadingCategories,
                      hasError: categoryError != null,
                      onTap: _pickCategory,
                    ),
                  ],
                ),
                if (categoryError != null) FormErrorText(categoryError),
                gap(AppSpacing.sm),
                AppTextField(
                  key: ValueKey<String>('title-$content'),
                  controller: arabic ? _titleAr : _titleEn,
                  focusNode: _titleFocus,
                  label: l10n.providerServiceTitleLabel(content),
                  textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                  textCapitalization: TextCapitalization.sentences,
                  errorText: error(arabic ? ServiceField.titleAr : ServiceField.titleEn),
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(ServiceFormViewModel.maxTitleLength),
                  ],
                  onChanged: viewModel.setTitle,
                ),
                gap(AppSpacing.sm),
                AppTextArea(
                  key: ValueKey<String>('description-$content'),
                  controller: arabic ? _descriptionAr : _descriptionEn,
                  focusNode: _descriptionFocus,
                  label: l10n.providerServiceDescriptionLabel(content),
                  maxLength: ServiceFormViewModel.maxTextLength,
                  minLines: 3,
                  maxLines: 8,
                  errorText: error(arabic ? ServiceField.descriptionAr : ServiceField.descriptionEn),
                  onChanged: viewModel.setDescription,
                ),
              ],
            ),
          ),
          gap(AppSpacing.md),
          CatalogFormSection(
            key: _pricingKey,
            title: l10n.providerServicePricing,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  controller: _price,
                  focusNode: _priceFocus,
                  label: onQuote
                      ? l10n.providerServiceStartingPriceLabel
                      : l10n.providerServiceBasePriceLabel,
                  helperText: onQuote
                      ? l10n.providerServiceStartingPriceHelper
                      : l10n.providerServiceBasePriceHelper,
                  hintText: '0',
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  errorText: error(ServiceField.basePrice),
                  inputFormatters: const <TextInputFormatter>[DinarInputFormatter()],
                  onChanged: (String text) => viewModel.setBasePrice(parseDinars(text)),
                ),
                gap(AppSpacing.sm),
                FormRowCard(
                  children: <Widget>[
                    FormValueRow(
                      label: l10n.providerServicePriceTypeLabel,
                      value: viewModel.priceType == null ? null : l10n.priceTypeOption(viewModel.priceType!),
                      placeholder: l10n.providerServiceChoose,
                      hasError: priceTypeError != null,
                      onTap: _pickPriceType,
                    ),
                  ],
                ),
                if (priceTypeError != null) FormErrorText(priceTypeError),
              ],
            ),
          ),
          gap(AppSpacing.md),
          CatalogFormSection(
            key: _capacityKey,
            title: l10n.providerServiceCapacity,
            tight: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FormRowCard(
                  children: <Widget>[
                    FormQuantityRow(
                      label: l10n.providerServiceMaxEventsLabel,
                      value: viewModel.maxEventsPerDay,
                      onChanged: viewModel.setMaxEventsPerDay,
                      max: ServiceFormViewModel.maxEventsPerDayLimit,
                      hasError: eventsError != null,
                    ),
                    FormQuantityRow(
                      label: l10n.providerServiceMaxGuestsLabel,
                      value: viewModel.maxGuests,
                      onChanged: viewModel.setMaxGuests,
                      max: ServiceFormViewModel.maxGuestsLimit,
                      hasError: guestsError != null,
                    ),
                  ],
                ),
                if (eventsError != null) FormErrorText(eventsError),
                if (guestsError != null)
                  FormErrorText(guestsError)
                else if (viewModel.maxGuests == null) ...<Widget>[
                  gap(AppSpacing.xs2),
                  FormHintText(l10n.providerServiceMaxGuestsNone),
                ],
              ],
            ),
          ),
          gap(AppSpacing.md),
          CatalogFormSection(
            key: _includedKey,
            title: l10n.providerServiceIncluded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (viewModel.facts.isEmpty)
                  FormHintText(l10n.providerServiceNoFacts)
                else
                  FormRowCard(
                    children: <Widget>[
                      for (int i = 0; i < viewModel.facts.length; i++)
                        FormValueRow(
                          label: viewModel.facts[i].labelFor(content),
                          value: viewModel.facts[i].valueFor(content),
                          showChevron: false,
                          onTap: () => _editFact(index: i),
                        ),
                    ],
                  ),
                if (factsError != null) FormErrorText(factsError),
                MainButton(
                  label: l10n.providerServiceAddFact,
                  style: MainButtonStyle.ghost,
                  onPressed: () => _editFact(),
                ),
              ],
            ),
          ),
          CatalogFormSection(
            title: l10n.providerServiceExtras,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (viewModel.extras.isEmpty)
                  FormHintText(l10n.providerServiceNoExtras)
                else
                  FormRowCard(
                    children: <Widget>[
                      for (int i = 0; i < viewModel.extras.length; i++)
                        FormValueRow(
                          label: viewModel.extras[i].nameFor(content),
                          valueWidget: PriceText(
                            amount: viewModel.extras[i].price,
                            amountStyle: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
                          ),
                          showChevron: false,
                          onTap: () => _editExtra(index: i),
                        ),
                    ],
                  ),
                if (extrasError != null) FormErrorText(extrasError),
                MainButton(
                  label: l10n.providerServiceAddExtra,
                  style: MainButtonStyle.ghost,
                  onPressed: () => _editExtra(),
                ),
              ],
            ),
          ),
          CatalogFormSection(
            key: _wilayasKey,
            title: l10n.providerServiceWilayas,
            tight: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Wrap(
                  spacing: AppSpacing.xs.dw,
                  runSpacing: AppSpacing.xs.dh,
                  children: <Widget>[
                    for (final Wilaya wilaya in viewModel.wilayas)
                      RemovableChip(
                        label: wilaya.nameFor(language),
                        removeLabel: l10n.providerServiceRemoveWilaya(wilaya.nameFor(language)),
                        onRemove: () => viewModel.removeWilaya(wilaya),
                      ),
                    AddChip(
                      label: l10n.providerServiceAddWilaya,
                      isLoading: viewModel.isLoadingWilayas,
                      onTap: _pickWilayas,
                    ),
                  ],
                ),
                if (wilayasError != null)
                  FormErrorText(wilayasError)
                else if (viewModel.wilayas.isEmpty) ...<Widget>[
                  gap(AppSpacing.xs2),
                  FormHintText(l10n.providerServiceNoWilayas),
                ],
              ],
            ),
          ),
          gap(AppSpacing.md),
          CatalogFormSection(
            title: l10n.providerServicePolicy,
            tight: true,
            child: AppTextArea(
              key: ValueKey<String>('policy-$content'),
              controller: arabic ? _policyAr : _policyEn,
              label: l10n.providerServicePolicyLabel(content),
              maxLength: ServiceFormViewModel.maxTextLength,
              minLines: 2,
              maxLines: 6,
              errorText: error(arabic ? ServiceField.cancellationAr : ServiceField.cancellationEn),
              onChanged: viewModel.setPolicy,
            ),
          ),
          gap(AppSpacing.md),
          CatalogFormSection(
            title: l10n.providerServicePhotos,
            tight: true,
            child: FormRowCard(
              children: <Widget>[
                FormValueRow(
                  label: l10n.providerServicePhotos,
                  value: l10n.providerServicePhotosAdded(viewModel.photosCount),
                  isLoading: viewModel.action == ServiceFormAction.photos,
                  onTap: _openPhotos,
                ),
              ],
            ),
          ),
          if (!viewModel.isNew) ...<Widget>[
            gap(AppSpacing.xl),
            DangerZone(
              buttonLabel: l10n.providerServiceDeleteButton,
              caption: l10n.providerServiceDeleteCaption,
              isLoading: viewModel.action == ServiceFormAction.delete,
              onPressed: viewModel.isWorking ? null : _delete,
            ),
          ],
          gap(AppSpacing.md),
        ],
      ),
    );
  }
}

/// G1 for P7a: the language chips, then the first cards.
class _FormSkeleton extends StatelessWidget {
  const _FormSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: AppSpacing.screenPaddingAll,
      children: <Widget>[
        Skeleton(height: AppSizes.controlSm.dh, width: 180.dw, radius: AppRadii.fullAll),
        SizedBox(height: AppSpacing.xl.dh),
        Skeleton(height: 52.dh),
        SizedBox(height: AppSpacing.md.dh),
        Skeleton(height: 76.dh),
        SizedBox(height: AppSpacing.md.dh),
        Skeleton(height: 120.dh),
        SizedBox(height: AppSpacing.md.dh),
        Skeleton(height: 96.dh),
      ],
    );
  }
}

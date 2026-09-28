import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/catalog/models/pack.dart' show EventType;
import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/amount_input.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/localization/catalog_labels.dart';
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
import '../view_model/pack_form_view_model.dart';
import 'catalog_wording.dart';
import 'widgets/catalog_form_parts.dart';
import 'widgets/catalog_sheets.dart';

/// P11 Create pack and P12 Edit pack.
class PackFormView extends StatefulWidget {
  const PackFormView({super.key});

  @override
  State<PackFormView> createState() => _PackFormViewState();
}

class _PackFormViewState extends State<PackFormView> {
  late final PackFormViewModel _viewModel = context.read<PackFormViewModel>();

  final TextEditingController _nameEn = TextEditingController();
  final TextEditingController _nameAr = TextEditingController();
  final TextEditingController _descriptionEn = TextEditingController();
  final TextEditingController _descriptionAr = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();
  final ScrollController _scroll = ScrollController();

  final GlobalKey _basicsKey = GlobalKey();
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _placeKey = GlobalKey();

  bool _isFilled = false;

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
      _nameEn,
      _nameAr,
      _descriptionEn,
      _descriptionAr,
      _price,
    ]) {
      c.dispose();
    }
    _nameFocus.dispose();
    _priceFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _fillOnce() {
    if (_isFilled || _viewModel.isFirstLoad || _viewModel.loadFailed) return;
    _isFilled = true;
    _nameEn.text = _viewModel.nameEn;
    _nameAr.text = _viewModel.nameAr;
    final ProviderPackDetail? saved = _viewModel.saved;
    _descriptionEn.text = saved?.descriptionEn ?? '';
    _descriptionAr.text = saved?.descriptionAr ?? '';
    _price.text = groupDinars('${_viewModel.price ?? ''}');
    final PackChecklistItem? fix = _viewModel.takeFix();
    if (fix != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyFix(fix);
      });
    }
  }

  void _close() => Navigator.of(context).pop(true);

  void _error(Failure failure) {
    showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);
    if (failure is ApiFailure &&
        (failure.code == ApiErrorCode.packNotFound || failure.code == ApiErrorCode.notOwner)) {
      _close();
    }
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

  /// P14's primary: to the first thing still to fix.
  Future<void> _applyFix(PackChecklistItem item) async {
    switch (item) {
      case PackChecklistItem.englishName || PackChecklistItem.arabicName:
        _viewModel.setLanguage(item == PackChecklistItem.arabicName
            ? ContentLanguage.arabic
            : ContentLanguage.english);
        await _reveal(_basicsKey);
        if (mounted) _nameFocus.requestFocus();
      case PackChecklistItem.services:
        await _reveal(_servicesKey);
        await _chooseServices();
      case PackChecklistItem.price:
        await _reveal(_pricingKey);
        if (mounted) _priceFocus.requestFocus();
      case PackChecklistItem.wilaya:
        await _reveal(_placeKey);
        await _pickWilaya();
      case PackChecklistItem.profile:
        break;
    }
  }

  Future<void> _showInvalid(List<PackField> fields) async {
    showAppToast(context, context.l10n.providerServiceFixFields, tone: AppToastTone.error);
    if (fields.isEmpty) return;
    final PackField first = fields.first;
    if (first == PackField.nameEn) _viewModel.setLanguage(ContentLanguage.english);
    await _reveal(switch (first) {
      PackField.nameEn || PackField.nameAr || PackField.descriptionEn || PackField.descriptionAr =>
        _basicsKey,
      PackField.services => _servicesKey,
      PackField.price => _pricingKey,
      PackField.eventType || PackField.wilaya || PackField.maxGuests => _placeKey,
    });
  }

  // -------------------------------------------------------------- pickers

  Future<void> _chooseServices() async {
    FocusScope.of(context).unfocus();
    final List<String>? chosen = await context.push<List<String>>(
      AppRoutes.providerChooseServices,
      extra: ChooseServicesArgs(
        selected: _viewModel.serviceIds,
        wilayaCode: _viewModel.wilaya?.code,
      ),
    );
    if (chosen != null && mounted) _viewModel.setServices(chosen);
  }

  Future<void> _pickEventType() async {
    final AppLocalizations l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final Set<EventType>? picked = await showSelectionSheet<EventType>(
      context,
      title: l10n.providerPackEventType,
      selected: <EventType>{if (_viewModel.eventType case final EventType t) t},
      options: <SelectionOption<EventType>>[
        for (final EventType type in EventType.browsable)
          SelectionOption<EventType>(value: type, label: l10n.eventTypeLabel(type)),
      ],
    );
    if (picked != null && picked.isNotEmpty) _viewModel.setEventType(picked.first);
  }

  Future<void> _pickWilaya() async {
    final AppLocalizations l10n = context.l10n;
    final String language = Localizations.localeOf(context).languageCode;
    FocusScope.of(context).unfocus();
    final List<Wilaya> open;
    try {
      open = List<Wilaya>.of(await _viewModel.openWilayas())
        ..sort((Wilaya a, Wilaya b) {
          // The wilayas the provider's services cover come first.
          final int covered = _viewModel.servicesCovering(b).compareTo(_viewModel.servicesCovering(a));
          return covered != 0 ? covered : a.nameFor(language).compareTo(b.nameFor(language));
        });
    } on Failure catch (failure) {
      if (mounted) _error(failure);
      return;
    }
    if (!mounted) return;
    final Set<int>? picked = await showSelectionSheet<int>(
      context,
      title: l10n.providerPackWilaya,
      subtitle: l10n.providerPackWilayaPickerBody,
      selected: <int>{if (_viewModel.wilaya case final Wilaya w) w.code},
      options: <SelectionOption<int>>[
        for (final Wilaya wilaya in open)
          SelectionOption<int>(
            value: wilaya.code,
            label: wilaya.nameFor(language),
            detail: l10n.providerPackWilayaCovering(_viewModel.servicesCovering(wilaya)),
          ),
      ],
    );
    if (picked == null || picked.isEmpty) return;
    for (final Wilaya wilaya in open) {
      if (wilaya.code == picked.first) _viewModel.setWilaya(wilaya);
    }
  }

  // -------------------------------------------------------------- actions

  Future<void> _save() async {
    final AppLocalizations l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final bool wasDraft = _viewModel.isNew || !_viewModel.isPublished;
    final PackSaveOutcome? outcome = await _viewModel.save();
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case PackSaveDone():
        showAppToast(context, wasDraft ? l10n.providerServiceDraftSaved : l10n.providerServiceChangesSaved);
        _close();
      case PackSaveInvalid(:final List<PackField> fields):
        await _showInvalid(fields);
      case PackSaveFailed(:final Failure failure):
        _error(failure);
    }
  }

  Future<void> _publish() async {
    final AppLocalizations l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final PublishOutcome<PackMissing>? outcome = await _viewModel.publish();
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case PublishDone<PackMissing>():
        showAppToast(context, l10n.providerPackPublished);
        _close();
      case PublishChecklist<PackMissing>(:final List<PackMissing> missing):
        final bool fix = await showPackChecklistSheet(context, missing: missing);
        if (!fix || !mounted) return;
        for (final PackChecklistItem item in PackChecklistItem.values) {
          if (item != PackChecklistItem.profile && item.isMissingIn(missing)) {
            await _applyFix(item);
            return;
          }
        }
      case PublishNotVerified<PackMissing>():
        await showNotVerifiedSheet(context);
      case PublishInvalid<PackMissing>():
        await _showInvalid(<PackField>[
          for (final PackField field in PackField.values)
            if (_viewModel.problemOf(field) != null) field,
        ]);
      case PublishFailed<PackMissing>(:final Failure failure):
        _error(failure);
    }
  }

  Future<void> _unpublish() async {
    final AppLocalizations l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final bool confirmed = await showConfirmSheet(
      context,
      title: l10n.providerPackUnpublishTitle,
      message: l10n.providerPackUnpublishBody,
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
      showAppToast(context, context.l10n.providerPackUnpublished, tone: AppToastTone.info);
    } else {
      _error(failure);
    }
  }

  Future<void> _delete() async {
    final AppLocalizations l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final bool confirmed = await showConfirmSheet(
      context,
      title: l10n.providerPackDeleteTitle,
      message: l10n.providerPackDeleteBody,
      confirmLabel: l10n.providerServiceDeleteConfirm,
      cancelLabel: l10n.providerServiceDeleteKeep,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final DeleteOutcome? outcome = await _viewModel.delete();
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case DeleteDone():
        showAppToast(context, l10n.providerPackDeleted, tone: AppToastTone.info);
        _close();
      case DeleteRefused(:final List<DeleteBlocker> blockers):
        final bool unpublish = await showDeleteRefusedSheet(
          context,
          title: l10n.providerPackDeleteRefusedTitle,
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
    final PackPhotosAccess? access = await _viewModel.openPhotos();
    if (!mounted || access == null) return;
    switch (access) {
      case PackPhotosReady(:final String packId):
        if (wasNew) showAppToast(context, l10n.providerServiceDraftSavedForPhotos);
        await context.push(AppRoutes.providerPackPhotosFor(packId));
        if (mounted) await _viewModel.reloadPhotos();
      case PackPhotosNeedDraft(:final List<PackField> fields):
        showAppToast(context, l10n.providerPackPhotosNeedDraft, tone: AppToastTone.error);
        if (fields.isNotEmpty) await _showInvalidQuietly(fields.first);
      case PackPhotosFailed(:final Failure failure):
        _error(failure);
    }
  }

  Future<void> _showInvalidQuietly(PackField first) async {
    if (first == PackField.nameEn) _viewModel.setLanguage(ContentLanguage.english);
    await _reveal(switch (first) {
      PackField.services => _servicesKey,
      PackField.price => _pricingKey,
      PackField.eventType || PackField.wilaya || PackField.maxGuests => _placeKey,
      _ => _basicsKey,
    });
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final PackFormViewModel viewModel = context.watch<PackFormViewModel>();
    final AppLocalizations l10n = context.l10n;

    final Widget body;
    if (viewModel.isFirstLoad) {
      body = ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: AppSpacing.screenPaddingAll,
        children: <Widget>[
          Skeleton(height: AppSizes.controlSm.dh, width: 180.dw, radius: AppRadii.fullAll),
          SizedBox(height: AppSpacing.xl.dh),
          Skeleton(height: 52.dh),
          SizedBox(height: AppSpacing.md.dh),
          Skeleton(height: 140.dh),
          SizedBox(height: AppSpacing.md.dh),
          Skeleton(height: 96.dh),
        ],
      );
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
      body = AbsorbPointer(absorbing: viewModel.isWorking, child: _form(viewModel));
    }

    return DiscardGuard(
      isDirty: viewModel.isDirty && !viewModel.isWorking,
      child: Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            BrandTopBar(
              title: viewModel.isEditing ? l10n.providerPackEditTitle : l10n.providerPackCreateTitle,
            ),
            Expanded(child: body),
            if (!viewModel.isFirstLoad && !viewModel.loadFailed)
              BottomActionBar(child: _actions(viewModel)),
          ],
        ),
      ),
    );
  }

  Widget _actions(PackFormViewModel viewModel) {
    final AppLocalizations l10n = context.l10n;
    final PackFormAction? action = viewModel.action;
    final bool free = action == null;
    final bool dirty = viewModel.isDirty;
    if (viewModel.isPublished) {
      return FormActionRow(
        secondary: MainButton(
          label: l10n.providerServiceUnpublish,
          style: MainButtonStyle.secondary,
          isLoading: action == PackFormAction.unpublish,
          canBeTapped: free,
          onPressed: _unpublish,
        ),
        primary: MainButton(
          label: l10n.providerServiceSaveChanges,
          isLoading: action == PackFormAction.save,
          canBeTapped: free && dirty,
          onPressed: _save,
        ),
      );
    }
    return FormActionRow(
      secondary: MainButton(
        label: viewModel.isNew ? l10n.providerServiceSaveDraft : l10n.providerServiceSave,
        style: MainButtonStyle.secondary,
        isLoading: action == PackFormAction.save,
        canBeTapped: free && (viewModel.isNew || dirty),
        onPressed: _save,
      ),
      primary: MainButton(
        label: l10n.providerServicePublish,
        isLoading: action == PackFormAction.publish,
        canBeTapped: free,
        onPressed: _publish,
      ),
    );
  }

  String _languageCaption(PackFormViewModel viewModel) {
    final AppLocalizations l10n = context.l10n;
    final List<PackMissing> gaps = viewModel.nameGaps;
    if (gaps.contains(PackMissing.nameEn)) return l10n.providerPackLangEnglishMissing;
    if (gaps.contains(PackMissing.nameAr)) return l10n.providerPackLangArabicMissing;
    return viewModel.isLive ? l10n.providerPackLangCompleteLive : l10n.providerServiceLangComplete;
  }

  Widget _form(PackFormViewModel viewModel) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final bool arabic = viewModel.language == ContentLanguage.arabic;
    final String content = viewModel.language.code;
    final List<PackFormItem> items = viewModel.items;
    final Wilaya? wilaya = viewModel.wilaya;
    SizedBox gap(double value) => SizedBox(height: value.dh);

    String? error(PackField field, {int? max}) =>
        l10n.fieldError(viewModel.problemOf(field), viewModel.serverErrorOf(field), max: max);

    final String? servicesError = viewModel.serverErrorOf(PackField.services) ??
        (viewModel.problemOf(PackField.services) == null ? null : l10n.providerPackServicesRange);
    final String? eventError = error(PackField.eventType);
    final String? wilayaError = error(PackField.wilaya);
    final String? guestsError = error(PackField.maxGuests, max: PackFormViewModel.maxGuestsLimit);
    final bool? below = viewModel.isPriceBelowSum;
    final int? savings = viewModel.savingsCents;
    final int? percent = viewModel.savingsPercent;

    String? itemWarning(PackFormItem item) {
      if (item.status == ProviderServiceStatus.hidden) return l10n.providerPackItemHidden;
      if (!item.isPublished) return l10n.providerPackItemDraft;
      if (!item.coversWilaya && wilaya != null) {
        return l10n.providerPackItemNotCovering(wilaya.nameFor(language));
      }
      return null;
    }

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
            caption: _languageCaption(viewModel),
          ),
          gap(AppSpacing.md),
          CatalogFormSection(
            key: _basicsKey,
            title: l10n.providerServiceBasics,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  key: ValueKey<String>('name-$content'),
                  controller: arabic ? _nameAr : _nameEn,
                  focusNode: _nameFocus,
                  label: l10n.providerPackNameLabel(content),
                  textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                  textCapitalization: TextCapitalization.sentences,
                  errorText: error(arabic ? PackField.nameAr : PackField.nameEn),
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(PackFormViewModel.maxNameLength),
                  ],
                  onChanged: viewModel.setName,
                ),
                gap(AppSpacing.sm),
                AppTextArea(
                  key: ValueKey<String>('description-$content'),
                  controller: arabic ? _descriptionAr : _descriptionEn,
                  label: l10n.providerServiceDescriptionLabel(content),
                  maxLength: PackFormViewModel.maxDescriptionLength,
                  minLines: 3,
                  maxLines: 8,
                  errorText: error(arabic ? PackField.descriptionAr : PackField.descriptionEn),
                  onChanged: viewModel.setDescription,
                ),
              ],
            ),
          ),
          gap(AppSpacing.md),
          CatalogFormSection(
            key: _servicesKey,
            title: l10n.providerPackServicesSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (items.isEmpty)
                  FormHintText(l10n.providerPackNoServices)
                else
                  FormRowCard(
                    children: <Widget>[
                      for (final PackFormItem item in items)
                        _PackItemRow(
                          title: item.title.of(language),
                          price: item.price,
                          warning: itemWarning(item),
                        ),
                    ],
                  ),
                if (servicesError != null) FormErrorText(servicesError),
                MainButton(
                  label: l10n.providerPackEditServices,
                  style: MainButtonStyle.ghost,
                  onPressed: _chooseServices,
                ),
                if (items.isNotEmpty)
                  PriceText(
                    prefix: l10n.providerPackSumCaption(items.length),
                    amount: _apiAmount(viewModel.sumCents),
                    amountStyle: textTheme.labelSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
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
                  label: l10n.providerPackPriceLabel,
                  hintText: '0',
                  helperText: l10n.providerPackPriceHelper,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  errorText: error(PackField.price) ?? (below == false ? l10n.providerPackPriceNotBelow : null),
                  inputFormatters: const <TextInputFormatter>[DinarInputFormatter()],
                  onChanged: (String text) => viewModel.setPrice(parseDinars(text)),
                ),
                if (below == true && savings != null) ...<Widget>[
                  gap(AppSpacing.xs),
                  PriceText(
                    prefix: l10n.providerPackClientsSave,
                    amount: _apiAmount(savings),
                    unit: percent == null ? null : l10n.providerPackSavingPercent(percent),
                    amountStyle: textTheme.labelSmall?.copyWith(
                      color: AppColors.statusAccepted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          gap(AppSpacing.md),
          CatalogFormSection(
            key: _placeKey,
            title: l10n.providerPackEventPlace,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FormRowCard(
                  children: <Widget>[
                    FormValueRow(
                      label: l10n.providerPackEventType,
                      value: viewModel.eventType == null ? null : l10n.eventTypeLabel(viewModel.eventType!),
                      placeholder: l10n.providerServiceChoose,
                      hasError: eventError != null,
                      onTap: _pickEventType,
                    ),
                    FormValueRow(
                      label: l10n.providerPackWilaya,
                      value: wilaya?.nameFor(language),
                      placeholder: l10n.providerServiceChoose,
                      hasError: wilayaError != null,
                      isLoading: viewModel.isLoadingWilayas,
                      onTap: _pickWilaya,
                    ),
                  ],
                ),
                if (eventError != null) FormErrorText(eventError),
                if (wilayaError != null) FormErrorText(wilayaError),
              ],
            ),
          ),
          gap(AppSpacing.md),
          CatalogFormSection(
            title: l10n.providerServiceCapacity,
            tight: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FormRowCard(
                  children: <Widget>[
                    FormQuantityRow(
                      label: l10n.providerServiceMaxGuestsLabel,
                      value: viewModel.maxGuests,
                      onChanged: viewModel.setMaxGuests,
                      max: PackFormViewModel.maxGuestsLimit,
                      hasError: guestsError != null,
                    ),
                  ],
                ),
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
            title: l10n.providerServicePhotos,
            tight: true,
            child: FormRowCard(
              children: <Widget>[
                FormValueRow(
                  label: l10n.providerServicePhotos,
                  value: l10n.providerServicePhotosAdded(viewModel.photosCount),
                  isLoading: viewModel.action == PackFormAction.photos,
                  onTap: _openPhotos,
                ),
              ],
            ),
          ),
          if (!viewModel.isNew) ...<Widget>[
            gap(AppSpacing.xl),
            DangerZone(
              buttonLabel: l10n.providerPackDeleteButton,
              caption: l10n.providerPackDeleteCaption,
              isLoading: viewModel.action == PackFormAction.delete,
              onPressed: viewModel.isWorking ? null : _delete,
            ),
          ],
          gap(AppSpacing.md),
        ],
      ),
    );
  }

  static String _apiAmount(int cents) =>
      '${cents ~/ 100}.${(cents.abs() % 100).toString().padLeft(2, '0')}';
}

/// A "Services in this pack" line: the service, its price, and why it
/// holds the pack back, if it does.
class _PackItemRow extends StatelessWidget {
  const _PackItemRow({required this.title, required this.price, this.warning});

  final String title;
  final String price;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? note = warning;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md.dw,
        vertical: AppSpacing.sm.dh,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                if (note != null)
                  Text(note, style: textTheme.labelSmall?.copyWith(color: AppColors.textDanger)),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.dw),
          PriceText(
            amount: price,
            amountStyle: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/formatting/amount_input.dart';
import '../../../../core/formatting/money_format.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/provider_catalog/provider_catalog_repository.dart';
import '../../../../core/widgets/molecules/app_text_field.dart';
import '../../../../core/widgets/molecules/checklist_row.dart';
import '../../../../core/widgets/molecules/main_button.dart';
import '../../../../core/widgets/organisms/app_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../view_model/catalog_outcomes.dart';
import '../catalog_wording.dart';

/// P9: what a service still needs before it can go live. `true` when the
/// primary ("Add the Arabic") was tapped — the caller jumps to the first
/// missing field; `false` for "Keep as draft" or a dismissal.
Future<bool> showServiceChecklistSheet(
  BuildContext context, {
  required List<ServiceMissing> missing,
}) async {
  final AppLocalizations l10n = context.l10n;
  ServiceChecklistItem? first;
  for (final ServiceChecklistItem item in ServiceChecklistItem.values) {
    if (first == null && item.isMissingIn(missing)) first = item;
  }
  final ServiceChecklistItem? fix = first;
  final bool? chosen = await showAppBottomSheet<bool>(
    context,
    builder: (BuildContext sheet) => AppSheetScaffold(
      title: l10n.providerServiceChecklistTitle,
      subtitle: l10n.providerServiceChecklistBody,
      body: SingleChildScrollView(
        child: ChecklistCard(
          children: <Widget>[
            for (final ServiceChecklistItem item in ServiceChecklistItem.values)
              _checkRow(l10n, l10n.serviceCheck(item), done: !item.isMissingIn(missing)),
          ],
        ),
      ),
      actions: <Widget>[
        if (fix != null)
          MainButton(
            label: l10n.serviceFix(fix),
            onPressed: () => Navigator.pop(sheet, true),
          ),
        MainButton(
          label: l10n.providerServiceKeepDraft,
          style: MainButtonStyle.secondary,
          onPressed: () => Navigator.pop(sheet, false),
        ),
      ],
    ),
  );
  return chosen ?? false;
}

/// P14: what a pack still needs. `true` when "Fix these two" was tapped.
Future<bool> showPackChecklistSheet(
  BuildContext context, {
  required List<PackMissing> missing,
}) async {
  final AppLocalizations l10n = context.l10n;
  final List<PackChecklistItem> rows = PackChecklistItem.shownFor(missing);
  final int failing = rows
      .where((PackChecklistItem item) =>
          item.isMissingIn(missing) && item != PackChecklistItem.profile)
      .length;
  final bool? chosen = await showAppBottomSheet<bool>(
    context,
    builder: (BuildContext sheet) => AppSheetScaffold(
      title: l10n.providerServiceChecklistTitle,
      subtitle: l10n.providerPackChecklistBody,
      body: SingleChildScrollView(
        child: ChecklistCard(
          children: <Widget>[
            for (final PackChecklistItem item in rows)
              _checkRow(l10n, l10n.packCheck(item), done: !item.isMissingIn(missing)),
          ],
        ),
      ),
      actions: <Widget>[
        // The profile is not something this form can fix.
        if (failing > 0)
          MainButton(
            label: l10n.providerPackFixThese(failing),
            onPressed: () => Navigator.pop(sheet, true),
          ),
        MainButton(
          label: l10n.providerServiceKeepDraft,
          style: MainButtonStyle.secondary,
          onPressed: () => Navigator.pop(sheet, false),
        ),
      ],
    ),
  );
  return chosen ?? false;
}

Widget _checkRow(AppLocalizations l10n, String label, {required bool done}) => ChecklistRow(
      label: label,
      state: done ? ChecklistState.done : ChecklistState.missing,
      stateLabel: done ? l10n.providerServiceCheckDone : l10n.providerServiceCheckMissing,
    );

/// `PROVIDER_NOT_VERIFIED` on Publish: the draft is saved, publishing
/// unlocks once the documents are approved.
Future<void> showNotVerifiedSheet(BuildContext context) async {
  final AppLocalizations l10n = context.l10n;
  await showAppBottomSheet<void>(
    context,
    builder: (BuildContext sheet) => AppSheetScaffold(
      title: l10n.providerServiceNotVerifiedTitle,
      subtitle: l10n.providerServiceNotVerifiedBody,
      body: const SizedBox.shrink(),
      actions: <Widget>[
        MainButton(
          label: l10n.providerServiceGotIt,
          onPressed: () => Navigator.pop(sheet),
        ),
      ],
    ),
  );
}

/// P7b: the server refused a delete, for [blockers]. `true` when
/// "Unpublish instead" was tapped (offered only when [canUnpublish]).
Future<bool> showDeleteRefusedSheet(
  BuildContext context, {
  required String title,
  required List<DeleteBlocker> blockers,
  required bool canUnpublish,
}) async {
  final AppLocalizations l10n = context.l10n;
  final bool? chosen = await showAppBottomSheet<bool>(
    context,
    builder: (BuildContext sheet) => AppSheetScaffold(
      title: title,
      subtitle: canUnpublish
          ? l10n.providerServiceDeleteRefusedBody
          : l10n.providerServiceDeleteRefusedBodyPlain,
      body: ChecklistCard(
        children: <Widget>[
          for (final DeleteBlocker blocker in blockers)
            ChecklistRow(label: l10n.deleteBlocker(blocker), state: ChecklistState.blocked),
        ],
      ),
      actions: <Widget>[
        if (canUnpublish)
          MainButton(
            label: l10n.providerServiceUnpublishInstead,
            onPressed: () => Navigator.pop(sheet, true),
          ),
        MainButton(
          label: l10n.providerServiceCancel,
          style: canUnpublish ? MainButtonStyle.secondary : MainButtonStyle.primary,
          onPressed: () => Navigator.pop(sheet, false),
        ),
      ],
    ),
  );
  return chosen ?? false;
}

/// What a fact or extra sheet closed with: a new value, a removal, or —
/// `null` from the show function — nothing.
class SheetEdit<T> {
  const SheetEdit.saved(T this.value) : removed = false;
  const SheetEdit.removed()
      : value = null,
        removed = true;

  final T? value;
  final bool removed;
}

/// "Add a fact" / "Edit a fact": the label and value in both languages at
/// once — the API refuses a fact missing any of the four.
Future<SheetEdit<ServiceFact>?> showFactSheet(
  BuildContext context, {
  ServiceFact? initial,
}) =>
    showAppBottomSheet<SheetEdit<ServiceFact>>(
      context,
      builder: (BuildContext sheet) => _FactSheet(initial: initial),
    );

class _FactSheet extends StatefulWidget {
  const _FactSheet({this.initial});

  final ServiceFact? initial;

  @override
  State<_FactSheet> createState() => _FactSheetState();
}

class _FactSheetState extends State<_FactSheet> {
  late final TextEditingController _labelEn =
      TextEditingController(text: widget.initial?.labelEn ?? '');
  late final TextEditingController _valueEn =
      TextEditingController(text: widget.initial?.valueEn ?? '');
  late final TextEditingController _labelAr =
      TextEditingController(text: widget.initial?.labelAr ?? '');
  late final TextEditingController _valueAr =
      TextEditingController(text: widget.initial?.valueAr ?? '');
  bool _tried = false;

  @override
  void dispose() {
    _labelEn.dispose();
    _valueEn.dispose();
    _labelAr.dispose();
    _valueAr.dispose();
    super.dispose();
  }

  bool get _isComplete => <TextEditingController>[_labelEn, _valueEn, _labelAr, _valueAr]
      .every((TextEditingController c) => c.text.trim().isNotEmpty);

  void _save() {
    if (!_isComplete) {
      setState(() => _tried = true);
      return;
    }
    Navigator.pop(
      context,
      SheetEdit<ServiceFact>.saved(
        ServiceFact(
          labelEn: _labelEn.text.trim(),
          labelAr: _labelAr.text.trim(),
          valueEn: _valueEn.text.trim(),
          valueAr: _valueAr.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    Widget field(
      TextEditingController controller,
      String label,
      int maxLength, {
      bool arabic = false,
    }) =>
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm.dh),
          child: AppTextField(
            controller: controller,
            label: label,
            textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
            textCapitalization: TextCapitalization.sentences,
            errorText: _tried && controller.text.trim().isEmpty
                ? l10n.providerServiceFieldRequired
                : null,
            inputFormatters: <TextInputFormatter>[LengthLimitingTextInputFormatter(maxLength)],
            onChanged: (_) {
              if (_tried) setState(() {});
            },
          ),
        );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      child: AppSheetScaffold(
        title: widget.initial == null ? l10n.providerServiceAddFact : l10n.providerServiceEditFact,
        subtitle: l10n.providerServiceFactSheetBody,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              field(_labelEn, l10n.providerServiceFactLabelEn, ServiceFact.maxLabelLength),
              field(_valueEn, l10n.providerServiceFactValueEn, ServiceFact.maxValueLength),
              field(_labelAr, l10n.providerServiceFactLabelAr, ServiceFact.maxLabelLength, arabic: true),
              field(_valueAr, l10n.providerServiceFactValueAr, ServiceFact.maxValueLength, arabic: true),
            ],
          ),
        ),
        actions: <Widget>[
          MainButton(label: l10n.providerServiceSheetSave, onPressed: _save),
          if (widget.initial != null)
            MainButton(
              label: l10n.providerServiceRemove,
              style: MainButtonStyle.ghost,
              tone: MainButtonTone.danger,
              onPressed: () => Navigator.pop(context, const SheetEdit<ServiceFact>.removed()),
            ),
        ],
      ),
    );
  }
}

/// "Add an extra" / "Edit an extra": the English name and the price are
/// needed; the Arabic name may wait (a draft allows it empty).
Future<SheetEdit<ServiceExtra>?> showExtraSheet(
  BuildContext context, {
  ServiceExtra? initial,
}) =>
    showAppBottomSheet<SheetEdit<ServiceExtra>>(
      context,
      builder: (BuildContext sheet) => _ExtraSheet(initial: initial),
    );

class _ExtraSheet extends StatefulWidget {
  const _ExtraSheet({this.initial});

  final ServiceExtra? initial;

  @override
  State<_ExtraSheet> createState() => _ExtraSheetState();
}

class _ExtraSheetState extends State<_ExtraSheet> {
  late final TextEditingController _nameEn =
      TextEditingController(text: widget.initial?.nameEn ?? '');
  late final TextEditingController _nameAr =
      TextEditingController(text: widget.initial?.nameAr ?? '');
  late final TextEditingController _price = TextEditingController(
    text: widget.initial == null
        ? ''
        : groupDinars('${amountCents(widget.initial!.price) ~/ 100}'),
  );
  bool _tried = false;

  @override
  void dispose() {
    _nameEn.dispose();
    _nameAr.dispose();
    _price.dispose();
    super.dispose();
  }

  void _save() {
    final int? price = parseDinars(_price.text);
    if (_nameEn.text.trim().isEmpty || price == null) {
      setState(() => _tried = true);
      return;
    }
    Navigator.pop(
      context,
      SheetEdit<ServiceExtra>.saved(
        ServiceExtra(
          nameEn: _nameEn.text.trim(),
          nameAr: _nameAr.text.trim(),
          price: apiAmountOf(price),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    String? required(String text) =>
        _tried && text.trim().isEmpty ? l10n.providerServiceFieldRequired : null;
    void redraw(String _) {
      if (_tried) setState(() {});
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      child: AppSheetScaffold(
        title: widget.initial == null ? l10n.providerServiceAddExtra : l10n.providerServiceEditExtra,
        subtitle: l10n.providerServiceExtraSheetBody,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppTextField(
                controller: _nameEn,
                label: l10n.providerServiceExtraNameEn,
                textDirection: TextDirection.ltr,
                textCapitalization: TextCapitalization.sentences,
                errorText: required(_nameEn.text),
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(ServiceExtra.maxNameLength),
                ],
                onChanged: redraw,
              ),
              SizedBox(height: AppSpacing.sm.dh),
              AppTextField(
                controller: _nameAr,
                label: l10n.providerServiceExtraNameAr,
                helperText: l10n.providerServiceExtraNameArHelper,
                textDirection: TextDirection.rtl,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(ServiceExtra.maxNameLength),
                ],
              ),
              SizedBox(height: AppSpacing.sm.dh),
              AppTextField(
                controller: _price,
                label: l10n.providerServiceExtraPrice,
                hintText: '0',
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.done,
                errorText: required(_price.text),
                inputFormatters: const <TextInputFormatter>[DinarInputFormatter()],
                onChanged: redraw,
                onSubmitted: (_) => _save(),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          MainButton(label: l10n.providerServiceSheetSave, onPressed: _save),
          if (widget.initial != null)
            MainButton(
              label: l10n.providerServiceRemove,
              style: MainButtonStyle.ghost,
              tone: MainButtonTone.danger,
              onPressed: () => Navigator.pop(context, const SheetEdit<ServiceExtra>.removed()),
            ),
        ],
      ),
    );
  }
}

/// A gallery photo's actions — P8's cover and order, and removal.
enum PhotoAction { makeCover, moveEarlier, moveLater, remove }

Future<PhotoAction?> showPhotoActionsSheet(
  BuildContext context, {
  required bool canMakeCover,
  required bool canMoveEarlier,
  required bool canMoveLater,
}) {
  final AppLocalizations l10n = context.l10n;
  return showAppBottomSheet<PhotoAction>(
    context,
    builder: (BuildContext sheet) => AppSheetScaffold(
      title: l10n.providerServicePhotoActionsTitle,
      body: const SizedBox.shrink(),
      actions: <Widget>[
        if (canMakeCover)
          MainButton(
            label: l10n.providerServicePhotoMakeCover,
            onPressed: () => Navigator.pop(sheet, PhotoAction.makeCover),
          ),
        if (canMoveEarlier)
          MainButton(
            label: l10n.providerServicePhotoMoveEarlier,
            style: MainButtonStyle.secondary,
            onPressed: () => Navigator.pop(sheet, PhotoAction.moveEarlier),
          ),
        if (canMoveLater)
          MainButton(
            label: l10n.providerServicePhotoMoveLater,
            style: MainButtonStyle.secondary,
            onPressed: () => Navigator.pop(sheet, PhotoAction.moveLater),
          ),
        MainButton(
          label: l10n.providerServiceRemove,
          style: MainButtonStyle.ghost,
          tone: MainButtonTone.danger,
          onPressed: () => Navigator.pop(sheet, PhotoAction.remove),
        ),
      ],
    ),
  );
}

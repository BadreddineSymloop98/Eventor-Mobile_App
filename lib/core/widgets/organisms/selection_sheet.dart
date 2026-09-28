import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../../localization/app_localizations_x.dart';
import '../atoms/app_icon.dart';
import '../molecules/main_button.dart';
import 'app_bottom_sheet.dart';

/// One choice in a [showSelectionSheet].
class SelectionOption<T> {
  const SelectionOption({required this.value, required this.label, this.detail});

  final T value;
  final String label;

  /// A quieter note at the row's end — the To picker's "next day · 8 h".
  final String? detail;
}

/// Opens a sheet listing [options] and returns what was picked — the design's
/// wilaya picker (`S3`), generalised.
///
/// * Single choice (`multiple: false`): tapping a row picks it and closes the
///   sheet. Returns a one-element set, or `null` if dismissed.
/// * Multiple choice (`multiple: true`): rows toggle, and **Done** returns the
///   set. `null` if dismissed without Done, so a dismissal never overwrites a
///   previous choice.
///
/// A search field filters the list as it is typed, once there are more than a
/// handful of options — 58 wilayas are not scrolled through by hand.
Future<Set<T>?> showSelectionSheet<T>(
  BuildContext context, {
  required String title,
  required List<SelectionOption<T>> options,
  Set<T> selected = const <Never>{},
  bool multiple = false,
  String? subtitle,
  String? searchHint,
}) {
  return showAppBottomSheet<Set<T>>(
    context,
    builder: (BuildContext sheetContext) => _SelectionSheet<T>(
      title: title,
      subtitle: subtitle,
      options: options,
      initial: selected,
      multiple: multiple,
      searchHint: searchHint,
    ),
  );
}

class _SelectionSheet<T> extends StatefulWidget {
  const _SelectionSheet({
    required this.title,
    required this.options,
    required this.initial,
    required this.multiple,
    this.subtitle,
    this.searchHint,
  });

  /// Below this many options the list fits without a search field.
  static const int _searchThreshold = 8;

  final String title;
  final String? subtitle;
  final List<SelectionOption<T>> options;
  final Set<T> initial;
  final bool multiple;
  final String? searchHint;

  @override
  State<_SelectionSheet<T>> createState() => _SelectionSheetState<T>();
}

class _SelectionSheetState<T> extends State<_SelectionSheet<T>> {
  late final Set<T> _selected = <T>{...widget.initial};
  final TextEditingController _query = TextEditingController();

  bool get _hasSearch =>
      widget.options.length > _SelectionSheet._searchThreshold;

  List<SelectionOption<T>> get _visible {
    final String query = _query.text.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    return widget.options
        .where((SelectionOption<T> option) =>
            option.label.toLowerCase().contains(query))
        .toList();
  }

  void _onTap(T value) {
    if (!widget.multiple) {
      Navigator.of(context).pop(<T>{value});
      return;
    }
    setState(() {
      if (!_selected.remove(value)) _selected.add(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<SelectionOption<T>> visible = _visible;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: AppSheetScaffold(
        title: widget.title,
        subtitle: widget.subtitle,
        expandBody: _hasSearch,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_hasSearch) ...<Widget>[
              _SearchField(
                controller: _query,
                hint: widget.searchHint ?? context.l10n.searchHint,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: AppSpacing.md.dh),
            ],
            Flexible(
              child: visible.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.xl.dh,
                      ),
                      child: Text(
                        context.l10n.selectionNoMatch,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : _OptionList<T>(
                      options: visible,
                      selected: _selected,
                      onTap: _onTap,
                    ),
            ),
          ],
        ),
        actions: widget.multiple
            ? <Widget>[
                MainButton(
                  label: _selected.isEmpty
                      ? context.l10n.selectionDone
                      : context.l10n.selectionDoneCount(_selected.length),
                  onPressed: () => Navigator.of(context).pop(_selected),
                ),
              ]
            : const <Widget>[],
      ),
    );
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      height: AppSizes.controlSm.dh,
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
      decoration: BoxDecoration(
        // The design draws this white on the white sheet, which leaves no
        // visible field at all; the canvas grey gives it an edge.
        color: AppColors.bgCanvas,
        borderRadius: AppRadii.mdAll,
      ),
      child: Row(
        children: <Widget>[
          const AppIcon(AppIcons.search, size: AppSizes.iconMd),
          SizedBox(width: AppSpacing.xs.dw),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.borderBrand,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The white card of rows, full-bleed dividers between them.
class _OptionList<T> extends StatelessWidget {
  const _OptionList({
    required this.options,
    required this.selected,
    required this.onTap,
  });

  final List<SelectionOption<T>> options;
  final Set<T> selected;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.mdAll,
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: options.length,
          separatorBuilder: (_, _) => const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderDefault,
          ),
          itemBuilder: (BuildContext context, int index) {
            final SelectionOption<T> option = options[index];
            final bool isSelected = selected.contains(option.value);

            return Semantics(
              button: true,
              selected: isSelected,
              child: GestureDetector(
                onTap: () => onTap(option.value),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: AppSizes.controlMd.dh,
                  ),
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md.dw,
                    vertical: AppSpacing.sm.dh,
                  ),
                  color: isSelected ? AppColors.bgBrandSubtle : null,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          option.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (option.detail case final String detail) ...<Widget>[
                        SizedBox(width: AppSpacing.sm.dw),
                        Text(
                          detail,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      SizedBox(width: AppSpacing.sm.dw),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        opacity: isSelected ? 1 : 0,
                        child: const AppIcon(
                          AppIcons.check,
                          size: AppSizes.iconMd,
                          color: AppColors.iconBrand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

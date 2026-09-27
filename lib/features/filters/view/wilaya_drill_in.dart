import 'package:flutter/material.dart';

import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/constants/ui_helpers.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../l10n/app_localizations.dart';

/// "11a · Wilaya picker" — the drill-in page of the filters drawer: every
/// open wilaya, searchable, several at once, with the ticks trailing.
///
/// Works on its own copy; Back leaves the filters as they were, Done hands
/// the new set back.
class WilayaDrillIn extends StatefulWidget {
  const WilayaDrillIn({
    required this.wilayas,
    required this.selected,
    required this.onBack,
    required this.onDone,
    super.key,
  });

  final List<Wilaya> wilayas;
  final Set<int> selected;
  final VoidCallback onBack;
  final ValueChanged<Set<int>> onDone;

  @override
  State<WilayaDrillIn> createState() => _WilayaDrillInState();
}

class _WilayaDrillInState extends State<WilayaDrillIn> {
  late final Set<int> _picked = Set<int>.of(widget.selected);
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String language = Localizations.localeOf(context).languageCode;
    final String needle = _search.text.trim().toLowerCase();
    final List<Wilaya> shown = widget.wilayas
        .where(
          (Wilaya w) =>
              needle.isEmpty ||
              w.nameEn.toLowerCase().contains(needle) ||
              w.nameAr.contains(needle) ||
              '${w.code}' == needle,
        )
        .toList();

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.xs.dw,
            AppSpacing.md.dh,
            AppSpacing.md.dw,
            AppSpacing.xs.dh,
          ),
          child: Row(
            children: <Widget>[
              Semantics(
                button: true,
                label: l10n.backLabel,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: widget.onBack,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox.square(
                    dimension: AppSizes.touchTarget.dw,
                    child: Center(
                      child: AppIcon(AppIcons.chevronLeft, color: AppColors.iconBrand),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  l10n.filtersWilaya,
                  style: textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.wilayaSearchHint,
              prefixIcon: Padding(
                padding: EdgeInsetsDirectional.all(AppSpacing.sm.dw),
                child: AppIcon(AppIcons.search, size: AppSizes.iconMd, color: AppColors.iconDefault),
              ),
              filled: true,
              // The design's search field sits on the canvas grey, not white
              // on white (re-align decision, 2026-09-23).
              fillColor: AppColors.bgCanvas,
              border: const OutlineInputBorder(
                borderRadius: AppRadii.mdAll,
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xs.dh),
        Expanded(
          child: ListView.separated(
            itemCount: shown.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
            itemBuilder: (BuildContext context, int index) {
              final Wilaya wilaya = shown[index];
              final bool isPicked = _picked.contains(wilaya.code);
              return Semantics(
                button: true,
                selected: isPicked,
                child: GestureDetector(
                  onTap: () => setState(() {
                    if (!_picked.remove(wilaya.code)) _picked.add(wilaya.code);
                  }),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.md.dw,
                      vertical: AppSpacing.sm.dh,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            wilaya.nameFor(language),
                            style: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                        if (isPicked)
                          AppIcon(AppIcons.check, size: AppSizes.iconMd, color: AppColors.iconBrand),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md.dw,
            AppSpacing.sm.dh,
            AppSpacing.md.dw,
            AppSpacing.md.dh,
          ),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderDefault)),
          ),
          child: Row(
            children: <Widget>[
              MainButton(
                label: l10n.wilayaClear,
                style: MainButtonStyle.ghost,
                onPressed: _picked.isEmpty ? null : () => setState(_picked.clear),
              ),
              SizedBox(width: AppSpacing.xs.dw),
              Expanded(
                child: MainButton(
                  label: l10n.wilayaDoneCount(_picked.length),
                  onPressed: () => widget.onDone(Set<int>.of(_picked)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/ui_helpers.dart';
import '../../../../core/widgets/atoms/app_icon.dart';
import '../../../../core/widgets/atoms/app_spinner.dart';
import '../../../../core/widgets/molecules/main_button.dart';
import '../../../../core/widgets/molecules/quantity_input.dart';

/// A titled block of P7 / P11: the heading (`Heading/S`), then its content.
class CatalogFormSection extends StatelessWidget {
  const CatalogFormSection({
    required this.title,
    required this.child,
    this.tight = false,
    super.key,
  });

  final String title;
  final Widget child;

  /// Capacity, Photos, Wilayas and Cancellation sit 8pt under their
  /// heading; the rest 12pt.
  final bool tight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        SizedBox(height: (tight ? AppSpacing.xs : AppSpacing.sm).dh),
        child,
      ],
    );
  }
}

/// The white card of a form's rows — border, 12pt corners, `elevation/sm`,
/// hairlines between the rows.
class FormRowCard extends StatelessWidget {
  const FormRowCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // A Material rather than a decorated box, so a row's ink shows on the
    // card instead of under it.
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: AppRadii.mdAll,
        boxShadow: AppElevation.sm,
      ),
      child: Material(
        color: AppColors.bgSurface,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.mdAll,
          side: BorderSide(color: AppColors.borderDefault),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
            children[i],
          ],
        ],
        ),
      ),
    );
  }
}

/// A label on the start, a value on the end — a select row with a chevron
/// when [onTap] is set and [showChevron], a static fact or extra line
/// otherwise.
class FormValueRow extends StatelessWidget {
  const FormValueRow({
    required this.label,
    this.value,
    this.placeholder,
    this.valueWidget,
    this.onTap,
    this.showChevron = true,
    this.isLoading = false,
    this.hasError = false,
    super.key,
  });

  final String label;
  final String? value;

  /// Shown in grey while [value] is `null`.
  final String? placeholder;

  /// Replaces [value] — a price as a token row.
  final Widget? valueWidget;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? shown = value ?? placeholder;
    final Widget? custom = valueWidget;
    return Semantics(
      button: onTap != null,
      label: label,
      value: value,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: AppSizes.touchTarget.dh),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md.dw,
            vertical: AppSpacing.sm.dh,
          ),
          child: Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: hasError ? AppColors.textDanger : AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md.dw),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: custom ??
                      Text(
                        shown ?? '',
                        textAlign: TextAlign.end,
                        style: textTheme.titleSmall?.copyWith(
                          color: value == null ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                ),
              ),
              if (onTap != null && showChevron) ...<Widget>[
                SizedBox(width: AppSpacing.xs.dw),
                if (isLoading)
                  const AppSpinner(size: AppSizes.iconMd)
                else
                  const AppIcon(AppIcons.chevronRight, size: AppSizes.iconMd),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A capacity line: the label, and a typed-or-stepped count on the end.
class FormQuantityRow extends StatelessWidget {
  const FormQuantityRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.max,
    this.min = 1,
    this.hasError = false,
    super.key,
  });

  final String label;
  final int? value;
  final ValueChanged<int?>? onChanged;
  final int min;
  final int max;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md.dw,
        vertical: AppSpacing.xs.dh,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: hasError ? AppColors.textDanger : AppColors.textSecondary,
                  ),
            ),
          ),
          SizedBox(width: AppSpacing.sm.dw),
          QuantityInput(
            value: value,
            onChanged: onChanged,
            min: min,
            max: max,
            hasError: hasError,
            label: label,
          ),
        ],
      ),
    );
  }
}

/// A red line under a field or a card.
class FormErrorText extends StatelessWidget {
  const FormErrorText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.only(top: AppSpacing.xs2.dh),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textDanger),
        ),
      ),
    );
  }
}

/// A grey line — a card's empty state or a helper.
class FormHintText extends StatelessWidget {
  const FormHintText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
    );
  }
}

/// One chosen wilaya: the navy chip, with × to take it out.
class RemovableChip extends StatelessWidget {
  const RemovableChip({
    required this.label,
    required this.removeLabel,
    required this.onRemove,
    super.key,
  });

  final String label;

  /// "Remove Blida", for screen readers.
  final String removeLabel;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.controlSm.dh,
      padding: EdgeInsetsDirectional.only(start: AppSpacing.sm.dw),
      decoration: const BoxDecoration(
        color: AppColors.bgBrand,
        borderRadius: AppRadii.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textOnBrand),
          ),
          Semantics(
            button: true,
            label: removeLabel,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: AppSizes.controlSm.dw,
                height: AppSizes.controlSm.dh,
                child: const Center(
                  child: AppIcon(AppIcons.close, size: AppSizes.iconSm, color: AppColors.iconOnBrand),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The outlined "+ Add wilaya" chip.
class AddChip extends StatelessWidget {
  const AddChip({required this.label, required this.onTap, this.isLoading = false, super.key});

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: AppSizes.controlSm.dh,
          padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm.dw),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadii.fullAll,
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (isLoading) ...<Widget>[
                const AppSpinner(size: AppSizes.iconSm),
                SizedBox(width: AppSpacing.xs2.dw),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// P7a's / P12's last block: the danger button and why it may be refused.
class DangerZone extends StatelessWidget {
  const DangerZone({
    required this.buttonLabel,
    required this.caption,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String buttonLabel;
  final String caption;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MainButton(
          label: buttonLabel,
          style: MainButtonStyle.secondary,
          tone: MainButtonTone.danger,
          isLoading: isLoading,
          onPressed: onPressed,
        ),
        SizedBox(height: AppSpacing.xs.dh),
        FormHintText(caption),
      ],
    );
  }
}

/// The sticky bar's buttons: the secondary on the leading side, the primary
/// on the trailing one (section 10's "[Decline][Accept]" rule); a lone
/// button takes the full width.
class FormActionRow extends StatelessWidget {
  const FormActionRow({this.secondary, required this.primary, super.key});

  final Widget? secondary;
  final Widget primary;

  @override
  Widget build(BuildContext context) {
    final Widget? leading = secondary;
    if (leading == null) return primary;
    return Row(
      children: <Widget>[
        Expanded(child: leading),
        SizedBox(width: AppSpacing.xs.dw),
        Expanded(child: primary),
      ],
    );
  }
}

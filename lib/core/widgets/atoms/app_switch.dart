import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';

/// An on/off toggle — the design's `Switch`.
///
/// 44×26 track, 20pt knob, 3pt inset. On is a brand track with the knob at
/// the *end*; off is a grey track with the knob at the *start*. "End" and
/// "start" are directional, so in Arabic the knob travels the other way — the
/// design's RTL rule for this component (On → MIN, Off → MAX).
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  static const double _trackWidth = 44;
  static const double _trackHeight = 26;
  static const double _knobSize = 20;
  static const double _inset = 3;
  static const Duration _duration = Duration(milliseconds: 150);

  final bool value;

  /// `null` disables the switch.
  final ValueChanged<bool>? onChanged;

  /// What the switch controls, for screen readers. Usually the row's label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<bool>? handler = onChanged;

    return Semantics(
      toggled: value,
      enabled: handler != null,
      label: semanticLabel,
      child: GestureDetector(
        onTap: handler == null ? null : () => handler(!value),
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          // The 26pt track sits inside a full tap target.
          constraints: BoxConstraints(minHeight: AppSizes.touchTarget.dh),
          child: Center(
            widthFactor: 1,
            child: Opacity(
              opacity: handler == null ? 0.5 : 1,
              child: AnimatedContainer(
                duration: _duration,
                width: _trackWidth.dw,
                height: _trackHeight.dw,
                padding: EdgeInsets.all(_inset.dw),
                decoration: BoxDecoration(
                  color: value ? AppColors.bgBrand : AppColors.bgDisabled,
                  borderRadius: AppRadii.fullAll,
                ),
                child: AnimatedAlign(
                  duration: _duration,
                  curve: Curves.easeOut,
                  alignment: value
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: Container(
                    width: _knobSize.dw,
                    height: _knobSize.dw,
                    decoration: const BoxDecoration(
                      color: AppColors.bgSurface,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

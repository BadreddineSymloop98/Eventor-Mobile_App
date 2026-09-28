import 'package:flutter/material.dart';

import '../../../../core/constants/ui_helpers.dart';

/// How far along a step of the timeline is.
enum TimelineStepState { done, current, todo, bad }

class TimelineStep {
  const TimelineStep({
    required this.title,
    required this.subtitle,
    required this.state,
    this.subtitleIsLtr = false,
  });

  final String title;
  final String subtitle;
  final TimelineStepState state;

  /// A date and a clock time, kept in order in Arabic.
  final bool subtitleIsLtr;
}

/// B4's status timeline: a rail of dots — done, current (with a halo),
/// still to come, or gone wrong in red — beside each step's title and time.
class BookingTimeline extends StatelessWidget {
  const BookingTimeline({required this.steps, super.key});

  final List<TimelineStep> steps;

  static const double _rail = 20;
  static const double _dot = 14;
  static const double _todoDot = 10;
  static const double _halo = 22;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    Widget dot(TimelineStepState state) {
      final bool bad = state == TimelineStepState.bad;
      final Color color = bad ? AppColors.textDanger : AppColors.bgBrand;
      return switch (state) {
        TimelineStepState.todo => Container(
            width: _todoDot,
            height: _todoDot,
            decoration: const BoxDecoration(color: AppColors.bgDisabled, shape: BoxShape.circle),
          ),
        TimelineStepState.done => Container(
            width: _dot,
            height: _dot,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        _ => Container(
            width: _halo,
            height: _halo,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Container(
              width: _dot,
              height: _dot,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
      };
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.dh),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: AppElevation.sm,
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md.dw),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(
                      width: _halo,
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            height: _halo + 4,
                            child: Center(child: dot(steps[i].state)),
                          ),
                          if (i < steps.length - 1)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: steps[i].state == TimelineStepState.done
                                    ? AppColors.bgBrand
                                    : AppColors.bgDisabled,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm.dw - (_halo - _rail)),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: AppSpacing.xs2.dh,
                          bottom: i < steps.length - 1 ? AppSpacing.md.dh : AppSpacing.xs2.dh,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              steps[i].title,
                              style: textTheme.labelLarge?.copyWith(
                                color: steps[i].state == TimelineStepState.todo
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs2.dh / 2),
                            Text(
                              steps[i].subtitle,
                              style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

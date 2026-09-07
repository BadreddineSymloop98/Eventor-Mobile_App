import 'package:flutter/material.dart';

/// Colours the app needs that [ColorScheme] has no slot for.
///
/// Material gives us `error` but nothing for success, warning or an
/// informational note, and those turn up as soon as there are forms, banners
/// and status badges. Registering them as a [ThemeExtension] means widgets
/// read them the same way they read everything else — from the theme — and
/// both brightnesses stay defined in one place.
///
/// Values are placeholders until the design is approved.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;

  static const AppSemanticColors _light = AppSemanticColors(
    success: Color(0xFF1B873B),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFB26B00),
    onWarning: Color(0xFFFFFFFF),
    info: Color(0xFF1B63C4),
    onInfo: Color(0xFFFFFFFF),
  );

  static const AppSemanticColors _dark = AppSemanticColors(
    success: Color(0xFF6FD48A),
    onSuccess: Color(0xFF07290F),
    warning: Color(0xFFE9B564),
    onWarning: Color(0xFF2E1C00),
    info: Color(0xFF8FBCFF),
    onInfo: Color(0xFF00224C),
  );

  static AppSemanticColors of(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
    );
  }

  @override
  AppSemanticColors lerp(
    ThemeExtension<AppSemanticColors>? other,
    double t,
  ) {
    if (other is! AppSemanticColors) return this;

    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
    );
  }
}

/// Shorthand so widgets can write `context.semanticColors.success`.
extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ??
      AppSemanticColors.of(Theme.of(this).brightness);
}

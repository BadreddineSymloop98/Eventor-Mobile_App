import 'app_icon.dart';

/// The glyph for a category, from the icon name the server sends.
///
/// The server names its own icons (`building`, `utensils`, `sparkles`…); the
/// app has the design's set. Anything unknown — a category added on the
/// dashboard later — gets the neutral `layers` glyph rather than nothing.
AppIcons categoryIcon(String? serverIcon) => switch (serverIcon) {
      'building' => AppIcons.building,
      'camera' => AppIcons.camera,
      'utensils' || 'catering' => AppIcons.catering,
      'music' => AppIcons.music,
      'sparkles' || 'decor' => AppIcons.decor,
      'flower' => AppIcons.flower,
      'brush' => AppIcons.brush,
      'video' => AppIcons.video,
      // No cake or car in the design's set yet.
      'cake' => AppIcons.catering,
      _ => AppIcons.layers,
    };

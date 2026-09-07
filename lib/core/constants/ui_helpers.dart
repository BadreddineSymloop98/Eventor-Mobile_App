import 'package:flutter/material.dart';

/// The app's design vocabulary, taken from the "🎨 Foundations" page of the
/// design file.
///
/// Everything here is now real — the placeholders this file shipped with are
/// gone. The design binds every sample on that page to a live variable, so the
/// names below deliberately mirror the variable names rather than inventing
/// their own: `--color-bg-brand` is [AppColors.bgBrand], `spacing/2xl` is
/// [AppSpacing.xl2], and so on. Keeping the two vocabularies identical is what
/// makes a design change a one-line edit here.
///
/// ## Everything dimensional is responsive
///
/// Gaps, insets, paddings, heights and widths are all expressed as a share of
/// the window rather than in fixed logical pixels, so a layout keeps the
/// proportions it was drawn with instead of leaving the spare space at the
/// bottom of a taller phone.
///
/// The numbers in [AppSpacing], [AppRadii] and [AppSizes] are the design's own
/// measurements on its 375×812 frame. They are **not** meant to be used raw:
/// convert them at the point of use with [DesignNum.dh] for a vertical value
/// and [DesignNum.dw] for a horizontal or square one —
/// `AppSpacing.md.dh`, `AppSizes.controlMd.dh`, `AppSpacing.xl.dw`. Use
/// [ResponsiveNum.h] and [ResponsiveNum.w] directly only for a true
/// proportion, like a hero that should take half the width.
///
/// Two things stay in fixed logical pixels:
///
/// * **Type.** A percentage-sized font ignores the user's accessibility
///   text-scale setting, which is the one size the user is entitled to
///   control. [AppTextStyles] is therefore fixed.
/// * **Corner radii.** A radius is a shape, not a space. Scaling it with the
///   window would make a 12pt corner read differently on two phones showing
///   the same card.

/// The size of the window, cached so that [ResponsiveNum] can be used without
/// a [BuildContext].
///
/// Kept up to date by [MediaQuery] at the root of the widget tree — see the
/// `builder` in `EventorApp` — rather than read once at startup, so that it
/// survives a window resize and is correct inside widget tests.
abstract final class ScreenMetrics {
  /// Frame the design is drawn against, and the denominator every percentage
  /// in the app is derived from. Matches the screen frames in the design file.
  ///
  /// Also the value [ResponsiveNum] falls back to before the first frame has
  /// reported a real size, which keeps it usable in unit tests and in widgets
  /// pumped without the app around them.
  static const Size designSize = Size(375, 812);

  static Size _size = designSize;

  /// Whether a real window size has been reported yet.
  static bool get isInitialized => _isInitialized;
  static bool _isInitialized = false;

  static double get width => _size.width;
  static double get height => _size.height;

  /// Called on every build of the app root; cheap, and a no-op when nothing
  /// has changed.
  ///
  /// ## The one limitation of caching this
  ///
  /// Reading a static creates no dependency, so a `const` widget that sizes
  /// itself with [ResponsiveNum] will *not* rebuild when the window changes —
  /// it keeps the numbers from whenever it last built. The app is locked to
  /// portrait on phones, where the window does not change after startup, so
  /// this costs nothing today. It would show up on a foldable or in Android
  /// split-screen.
  ///
  /// A screen that must survive a resize should depend on the window itself
  /// (`MediaQuery.sizeOf(context)`) so that it is rebuilt, at which point the
  /// helpers below read the fresh value.
  static void update(Size size) {
    if (size == _size && _isInitialized) return;
    _size = size;
    _isInitialized = true;
  }

  /// Restores the untouched state. For tests that need a known baseline.
  @visibleForTesting
  static void reset() {
    _size = designSize;
    _isInitialized = false;
  }
}

/// Screen-proportional sizing, as a percentage of the window.
///
/// Reads from [ScreenMetrics], so it needs no [BuildContext] and can be used
/// anywhere: `20.h`, `50.w`, `12.5.w`.
extension ResponsiveNum on num {
  /// This many percent of the window height.
  double get h => ScreenMetrics.height * this / 100;

  /// This many percent of the window width.
  double get w => ScreenMetrics.width * this / 100;
}

/// Values taken straight from the design frame, as a share of the window.
///
/// Everything dimensional in this app is responsive — gaps, insets, paddings,
/// heights, widths. The design is drawn on a 375×812 frame
/// ([ScreenMetrics.designSize]), so these do the division that turns one of
/// its numbers into the equivalent share of the window the app is actually
/// running on.
///
/// They are thin wrappers over [ResponsiveNum.h] and [ResponsiveNum.w] — the
/// same percentage, with the arithmetic done here instead of by hand at the
/// call site. `AppSpacing.md.dw` says what it means; the `4.2667` it replaces
/// did not, and was one fat finger away from being wrong.
///
/// Reach past these to [ResponsiveNum] directly only when a value is a true
/// proportion rather than a design measurement — "half the width", not "the
/// 16pt gap".
extension DesignNum on num {
  /// This many design pixels as a share of the window **height**. For vertical
  /// gaps, vertical insets and heights.
  double get dh => (this / ScreenMetrics.designSize.height * 100).h;

  /// This many design pixels as a share of the window **width**. For
  /// horizontal gaps, horizontal insets, widths — and for anything square,
  /// where both axes must come from one of them to stay square.
  double get dw => (this / ScreenMetrics.designSize.width * 100).w;
}

/// The colours the design publishes.
///
/// The design file says it plainly: *"design against the semantic layer
/// only"*. The raw ramp is private for that reason — a screen asks for
/// [bgBrand] or [textSecondary], never for "navy 900", so a palette change
/// lands in one place instead of across the widget tree.
///
/// The scheme is white surfaces, purple chrome, gold reserved for accent.
abstract final class AppColors {
  // The primitive ramp. Private on purpose — see the class comment.
  static const Color _navy50 = Color(0xFFF5EEFB);
  static const Color _navy900 = Color(0xFF2B075D);
  static const Color _purple300 = Color(0xFFAE70D2);
  static const Color _gold400 = Color(0xFFCD963A);
  static const Color _gold700 = Color(0xFF9A6C1D);
  static const Color _neutral0 = Color(0xFFFFFFFF);
  static const Color _neutral200 = Color(0xFFD3C4DE);
  static const Color _neutral600 = Color(0xFF5D476E);
  static const Color _amber700 = Color(0xFFB45309);
  static const Color _green700 = Color(0xFF15803D);
  static const Color _red700 = Color(0xFFB91C1C);

  /// The brand colour, and the seed the Material scheme is derived from.
  ///
  /// It sits at 16.3:1 on white, so brand text and brand fills never have a
  /// contrast question to answer.
  static const Color brand = _navy900;

  // Backgrounds.
  /// The tint behind a screen. The only tint in the system.
  static const Color bgCanvas = _navy50;

  /// Cards, sheets and anything raised off [bgCanvas].
  static const Color bgSurface = _neutral0;
  static const Color bgBrand = _navy900;
  static const Color bgAccent = _gold700;
  static const Color bgDisabled = _neutral200;

  /// Ground for a modal barrier or a photo scrim. Used at partial opacity.
  static const Color bgOverlay = _navy900;

  /// The warm end of the *brand* photo scrim.
  ///
  /// The splash fades from this at the top to [bgOverlay] at the bottom, which
  /// keeps the image readable through the lighter part of the gradient instead
  /// of flattening it to purple.
  static const Color scrimHighlight = _neutral600;

  /// The deep end of the *neutral* photo scrim.
  ///
  /// A near-black plum, and the one colour in the app outside the published
  /// ramp — the design uses it only to darken photographs. Every photographic
  /// screen except the splash uses this rather than [bgOverlay]: the splash is
  /// about the brand, so it is tinted purple, while the rest are about the
  /// copy over the image, and purple would fight the photograph.
  static const Color scrimDeep = Color(0xFF1B1221);

  /// The light wash across the top of a neutral-scrimmed photograph.
  ///
  /// Lifts the status bar area off the image so white chrome reads against it.
  static const Color scrimLift = Color(0xFFF5F5F5);

  // Text.
  static const Color textPrimary = _navy900;
  static const Color textSecondary = _neutral600;
  static const Color textBrand = _navy900;
  static const Color textAccent = _gold700;
  static const Color textDisabled = _neutral200;

  /// Text on a [bgBrand] fill.
  static const Color textOnBrand = _neutral0;

  /// The accent as it appears *on* a brand fill.
  ///
  /// A lighter gold than [textAccent] because one value cannot clear AA
  /// against both white and the brand purple — the pair is deliberate.
  static const Color textOnBrandAccent = _gold400;

  /// Text on a [bgAccent] fill.
  static const Color textOnAccent = _neutral0;

  // Borders.
  static const Color borderDefault = _neutral200;

  /// Borders, dividers and icon strokes that should read as brand without
  /// shouting. 3.5:1 on white.
  static const Color borderBrandSubtle = _purple300;
  static const Color borderBrand = _navy900;
  static const Color borderAccent = _gold700;

  /// Outline for a control sitting on a brand fill or a scrimmed photograph,
  /// where [borderDefault] would disappear.
  static const Color borderOnBrand = _neutral0;

  // Icons.
  static const Color iconDefault = _neutral600;
  static const Color iconBrand = _navy900;
  static const Color iconOnBrand = _neutral0;
  static const Color iconAccent = _gold700;

  // Booking status. Named for the state, not the colour, so the mapping is
  // the design's to change.
  static const Color statusPending = _amber700;
  static const Color statusAccepted = _green700;
  static const Color statusDeclined = _red700;
  static const Color statusCompleted = _neutral600;

  // Ratings.
  static const Color ratingFilled = _navy900;
  static const Color ratingEmpty = _neutral200;
}

/// Gaps between elements, in logical pixels.
///
/// A 4pt grid of ten steps. The design is explicit that a gap should only ever
/// come from this list — *"an arbitrary 18px is how a layout starts
/// drifting"*.
///
/// The names carry the Figma suffix: [xs2] is `spacing/2xs`, [xl2] is
/// `spacing/2xl`.
abstract final class AppSpacing {
  /// `spacing/2xs` — 4
  static const double xs2 = 4;

  /// `spacing/xs` — 8
  static const double xs = 8;

  /// `spacing/sm` — 12
  static const double sm = 12;

  /// `spacing/md` — 16
  static const double md = 16;

  /// `spacing/lg` — 20
  static const double lg = 20;

  /// `spacing/xl` — 24
  static const double xl = 24;

  /// `spacing/2xl` — 32
  static const double xl2 = 32;

  /// `spacing/3xl` — 40
  static const double xl3 = 40;

  /// `spacing/4xl` — 48
  static const double xl4 = 48;

  /// `spacing/5xl` — 64
  static const double xl5 = 64;

  /// Space between two controls in the same group.
  static const double fieldGap = md;

  /// Space between groups of controls.
  static const double sectionGap = xl;

  /// Inset between a screen's content and its edges. Every screen frame in
  /// the design insets its content by 16.
  static const double screenPadding = md;

  /// The screen inset as padding, which is what call sites usually want.
  ///
  /// Already converted: horizontal from the window's width, vertical from its
  /// height, so it does not need `.dw` / `.dh` at the call site.
  static EdgeInsetsDirectional get screenPaddingAll =>
      EdgeInsetsDirectional.symmetric(
        horizontal: screenPadding.dw,
        vertical: screenPadding.dh,
      );
}

/// Corner radii, in logical pixels.
abstract final class AppRadii {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// A pill. Large enough that any control it is applied to ends up fully
  /// rounded on its short axis.
  static const double full = 999;

  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
}

/// Fixed sizes that are neither spacing nor type.
abstract final class AppSizes {
  // Icons.
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;

  // Controls — the height of a button or a field.
  static const double controlSm = 36;
  static const double controlMd = 44;
  static const double controlLg = 52;

  /// Minimum tap target. An accessibility floor rather than a proportion, so
  /// it never scales with the screen.
  static const double touchTarget = 48;

  // Avatars.
  static const double avatarSm = 32;
  static const double avatarMd = 40;
  static const double avatarLg = 56;
  static const double avatarXl = 80;

  /// Widest the main content column is allowed to get.
  ///
  /// The design is drawn for phones. This stops it from stretching into an
  /// unreadable line length if the app is opened on a tablet, which is not a
  /// designed case but is a reachable one.
  static const double maxContentWidth = 600;

  /// Above this width the window is a tablet rather than a phone.
  static const double tabletBreakpoint = 600;
}

/// The typefaces the design is set in, matching the families declared in
/// `pubspec.yaml`.
///
/// The two scripts get their own family because Latin and Arabic rarely share
/// a typeface well. `AppFonts` is what picks between them by locale; these are
/// just the names.
abstract final class AppFontFamilies {
  /// Latin copy.
  static const String latin = 'Inter';

  /// Arabic copy.
  static const String arabic = 'Cairo';
}

/// The type ramp, in fixed logical pixels.
///
/// The design ships **two** ramps, not one. Cairo needs about a point more
/// than Inter to read at the same size, and its line heights are looser, so
/// every Arabic role is its own value rather than the Latin value in a
/// different font. [forLocale] picks the pair; `AppTheme` feeds the result
/// into [ThemeData], so a widget reads
/// `Theme.of(context).textTheme.bodyLarge` and gets the right one without
/// knowing which language it is in.
///
/// Colours are deliberately absent — they belong to the [ColorScheme].
///
/// One rule the Arabic ramp encodes: **letter spacing is 0 throughout**.
/// Tracking breaks the cursive joins between Arabic letters, so a value that
/// merely looks tight in Latin is a rendering bug in Arabic.
///
/// A trap worth knowing about: Figma reports tracking as a **percentage of the
/// font size**, while Flutter's `letterSpacing` is in logical pixels. The
/// design's "-2" on a 32pt display line is -2%, which is -0.64px — taking it
/// literally would set the type about three times too tight. Every value below
/// is the converted one, with the design's percentage in a comment.
abstract final class AppTextStyles {
  /// Latin (Inter). Figma role names in the comments.
  static const TextTheme latin = TextTheme(
    // Display/L
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 40 / 32,
      letterSpacing: -0.64, // -2% of 32
    ),
    // Heading/XL
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 32 / 24,
      letterSpacing: -0.24, // -1% of 24
    ),
    // Heading/L
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 28 / 20,
      letterSpacing: -0.2,  // -1% of 20
    ),
    // Heading/M
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 26 / 18,
    ),
    // Heading/S
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 24 / 16,
    ),
    // Body/M Strong
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 22 / 14,
    ),
    // Body/L
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 24 / 16,
    ),
    // Body/M
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 22 / 14,
    ),
    // Body/S
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 20 / 13,
    ),
    // Label/L
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 20 / 15,
    ),
    // Label/M
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 16 / 13,
    ),
    // Caption
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 16 / 12,
    ),
  );

  /// Arabic (Cairo). Larger and looser than [latin] at every step, and never
  /// tracked.
  static const TextTheme arabic = TextTheme(
    // Display/L
    displayLarge: TextStyle(
      fontSize: 33,
      fontWeight: FontWeight.w700,
      height: 42 / 33,
    ),
    // Heading/XL
    headlineMedium: TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w700,
      height: 34 / 25,
    ),
    // Heading/L
    headlineSmall: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      height: 30 / 21,
    ),
    // Heading/M
    titleLarge: TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      height: 28 / 19,
    ),
    // Heading/S
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 26 / 17,
    ),
    // Body/M Strong
    titleSmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 24 / 15,
    ),
    // Body/L
    bodyLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      height: 26 / 17,
    ),
    // Body/M
    bodyMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 24 / 15,
    ),
    // Body/S
    bodySmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 22 / 14,
    ),
    // Label/L
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 22 / 16,
    ),
    // Label/M
    labelMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 18 / 14,
    ),
    // Caption
    labelSmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 18 / 13,
    ),
  );

  /// `Overline` — an eyebrow above a heading.
  ///
  /// Material 3 has no slot for it, so it is not part of the themed ramp and
  /// call sites reach for it directly. The Latin cut is heavily tracked; the
  /// Arabic one is not, for the reason in the class comment.
  static const TextStyle overlineLatin = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 16 / 11,
    letterSpacing: 0.66, // 6% of 11
  );

  static const TextStyle overlineArabic = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 18 / 12,
  );

  static const String _arabicLanguageCode = 'ar';

  /// The ramp for [locale]. Anything that is not Arabic gets [latin].
  static TextTheme forLocale(Locale? locale) =>
      locale?.languageCode == _arabicLanguageCode ? arabic : latin;

  /// The overline for [locale]. Kept beside [forLocale] so the two cannot
  /// drift apart.
  static TextStyle overlineForLocale(Locale? locale) =>
      locale?.languageCode == _arabicLanguageCode
          ? overlineArabic
          : overlineLatin;
}

/// Drop shadows, tinted with the brand purple rather than with black so that
/// a raised surface reads as part of the same palette.
///
/// Each level is two layers: a tight contact shadow and a wider ambient one.
abstract final class AppElevation {
  static const List<BoxShadow> sm = <BoxShadow>[
    BoxShadow(color: Color(0x0F2B075D), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x1A2B075D), offset: Offset(0, 1), blurRadius: 3),
  ];

  static const List<BoxShadow> md = <BoxShadow>[
    BoxShadow(color: Color(0x0F2B075D), offset: Offset(0, 2), blurRadius: 4),
    BoxShadow(color: Color(0x142B075D), offset: Offset(0, 4), blurRadius: 8),
  ];

  static const List<BoxShadow> lg = <BoxShadow>[
    BoxShadow(color: Color(0x0F2B075D), offset: Offset(0, 4), blurRadius: 8),
    BoxShadow(color: Color(0x1F2B075D), offset: Offset(0, 12), blurRadius: 24),
  ];

  /// The ring drawn around a focused control. A spread with no blur and no
  /// offset, so it reads as an outline rather than as a shadow.
  static const List<BoxShadow> focusRing = <BoxShadow>[
    BoxShadow(color: Color(0x5963149F), spreadRadius: 3),
  ];
}

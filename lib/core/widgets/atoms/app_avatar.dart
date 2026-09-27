import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import 'app_network_image.dart';
import 'app_icon.dart';

/// The avatar sizes the design draws.
enum AppAvatarSize {
  /// 32 — dense lists.
  small(AppSizes.avatarSm, AppSizes.iconSm),

  /// 36 — the chat thread's header (15).
  chatHeader(AppSizes.avatarChatHeader, AppSizes.iconMd),

  /// 40 — booking and request cards.
  medium(AppSizes.avatarMd, AppSizes.iconMd),

  /// 48 — the conversation list row (14).
  list(AppSizes.avatarList, 24),

  /// 56 — provider cards and profile headers.
  large(AppSizes.avatarLg, 28);

  const AppAvatarSize(this.diameter, this.placeholderIconSize);

  final double diameter;

  /// The person glyph drawn while a photo is missing or loading.
  final double placeholderIconSize;
}

/// A person or business, as a circle: their photo when there is one, their
/// initials when there is not.
///
/// The design's two types — `Initials` and `Photo` — are chosen by whether a
/// [photoUrl] is given, so a call site never has to decide. A photo that is
/// still loading or fails to load shows the design's grey placeholder with a
/// person glyph rather than a broken image.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.name,
    this.photoUrl,
    this.size = AppAvatarSize.medium,
    super.key,
  }) : _anonymous = false;

  /// A conversation row or chat header with nobody to show — a deleted
  /// account. Draws the person-glyph placeholder rather than empty initials,
  /// since there is no name to derive them from.
  const AppAvatar.anonymous({this.size = AppAvatarSize.medium, super.key})
      : name = '',
        photoUrl = null,
        _anonymous = true;

  /// Used for the initials, and as the avatar's label for screen readers.
  /// Empty for [AppAvatar.anonymous], which has nobody to name.
  final String name;
  final String? photoUrl;
  final AppAvatarSize size;

  /// Whether this is [AppAvatar.anonymous] — no photo and no name, so the
  /// placeholder is the person glyph rather than a blank initials label.
  final bool _anonymous;

  /// Up to two initials: first and last word, so "Amina Benali" is "AB" and
  /// "Studio Lumière" is "SL". Works on any script — Arabic names keep their
  /// first letters just the same.
  static String initialsOf(String name) {
    final List<String> words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    final String first = words.first.characters.first;
    if (words.length == 1) return first.toUpperCase();
    return (first + words.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final double diameter = size.diameter.dw;
    final String? url = photoUrl;

    return Semantics(
      image: true,
      label: name.isEmpty ? null : name,
      child: Container(
        width: diameter,
        height: diameter,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: url == null ? AppColors.bgCanvas : AppColors.bgDisabled,
          border: Border.all(color: AppColors.borderDefault),
        ),
        alignment: Alignment.center,
        child: url == null
            ? (_anonymous
                ? _PhotoPlaceholder(size: size)
                : _Initials(name: name, size: size))
            // A bundled mock photo, or a signed catalog URL cached without its
            // signature — the same rules as every other catalog image.
            : url.startsWith('asset:')
                ? Image.asset(
                    url.substring('asset:'.length),
                    width: diameter,
                    height: diameter,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _PhotoPlaceholder(size: size),
                  )
                : CachedNetworkImage(
                    imageUrl: url,
                    cacheKey: AppNetworkImage.stableKey(url),
                    width: diameter,
                    height: diameter,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => _PhotoPlaceholder(size: size),
                    errorWidget: (_, _, _) => _PhotoPlaceholder(size: size),
                  ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.size});

  final String name;
  final AppAvatarSize size;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    // The large avatar steps up to Heading/S; the others use Label/M.
    final TextStyle? style = size == AppAvatarSize.large
        ? textTheme.titleMedium
        : textTheme.labelMedium;

    return ExcludeSemantics(
      child: Text(
        AppAvatar.initialsOf(name),
        style: style?.copyWith(color: AppColors.textBrand),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.size});

  final AppAvatarSize size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppIcon(
        AppIcons.user,
        size: size.placeholderIconSize,
        color: AppColors.iconDefault,
      ),
    );
  }
}

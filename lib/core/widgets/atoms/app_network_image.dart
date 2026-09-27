import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import 'app_icon.dart';
import 'skeleton.dart';

/// A photo from the catalog, cached, with the design's placeholder when there
/// is none.
///
/// The server signs every photo URL for 15 minutes, so the same photo comes
/// back under a new URL on every response. Cached by that URL, it would be
/// downloaded again on every screen — and photo downloads count toward the
/// API's rate limit. The cache is keyed on [stableKey] instead: the URL
/// without its signature.
///
/// An `asset:` URL — the mock backend's photos — is read from the bundle.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.url,
    this.width,
    this.height,
    this.radius,
    this.fit = BoxFit.cover,
    this.placeholderIcon = AppIcons.camera,
    super.key,
  });

  final String? url;

  /// Logical pixels, already converted by the caller. `null` fills.
  final double? width;
  final double? height;
  final BorderRadius? radius;
  final BoxFit fit;

  /// Shown on the brand tile when there is no photo — the category's glyph.
  final AppIcons placeholderIcon;

  static const String _assetScheme = 'asset:';

  /// [url] without the `exp` and `sig` parameters that change on every
  /// response. Everything else — the file id, the size variant — stays.
  static String stableKey(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !uri.hasQuery) return url;
    final Map<String, List<String>> params =
        Map<String, List<String>>.of(uri.queryParametersAll)
          ..remove('exp')
          ..remove('sig');
    final String base = url.split('?').first;
    if (params.isEmpty) return base;
    return Uri.parse(base).replace(queryParameters: params).toString();
  }

  @override
  Widget build(BuildContext context) {
    final String? source = url;
    final Widget image;
    if (source == null || source.isEmpty) {
      image = _placeholder();
    } else if (source.startsWith(_assetScheme)) {
      image = Image.asset(
        source.substring(_assetScheme.length),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: source,
        cacheKey: stableKey(source),
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, _) => Skeleton(
          width: width,
          height: height ?? double.infinity,
          radius: BorderRadius.zero,
        ),
        errorWidget: (_, _, _) => _placeholder(),
      );
    }

    final BorderRadius? corners = radius;
    return corners == null
        ? image
        : ClipRRect(borderRadius: corners, child: image);
  }

  /// The design's gradient tile with the glyph centred — the same look as a
  /// `Service Thumb` without a photo.
  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: <Color>[
            AppColors.tileGradientStart,
            AppColors.tileGradientEnd,
          ],
        ),
      ),
      child: AppIcon(placeholderIcon, color: AppColors.iconBrand),
    );
  }
}

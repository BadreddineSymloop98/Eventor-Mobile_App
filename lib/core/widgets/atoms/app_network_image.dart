import 'dart:typed_data';

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
    this.errorBuilder,
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

  /// Replaces [_placeholder] when a load fails, rather than a missing URL —
  /// 15's tap-to-reload tile (D15) wants a distinct affordance for the two.
  final Widget Function()? errorBuilder;

  static const String _assetScheme = 'asset:';

  /// The mock's sent photos come back embedded rather than hosted.
  static const String _dataScheme = 'data:';

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
    } else if (source.startsWith(_dataScheme)) {
      image = _memoryImage(source);
    } else if (source.startsWith(_assetScheme)) {
      image = Image.asset(
        source.substring(_assetScheme.length),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _onError(),
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
        errorWidget: (_, _, _) => _onError(),
      );
    }

    final BorderRadius? corners = radius;
    return corners == null
        ? image
        : ClipRRect(borderRadius: corners, child: image);
  }

  /// A `data:` URI, decoded straight to bytes — the mock's sent photos,
  /// which never go over the network so they never earn a real URL.
  /// Decoding can throw on a malformed payload, so a bad one fails the same
  /// way a bad network image does.
  Widget _memoryImage(String source) {
    try {
      final Uint8List bytes = UriData.parse(source).contentAsBytes();
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _onError(),
      );
    } on FormatException {
      return _onError();
    }
  }

  /// [errorBuilder] when the caller gave one, else the plain placeholder.
  Widget _onError() {
    final Widget Function()? builder = errorBuilder;
    return builder == null ? _placeholder() : builder();
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

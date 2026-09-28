import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../constants/ui_helpers.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_network_image.dart';
import '../atoms/app_spinner.dart';

/// P8's and P13's gallery: two tiles a row, 12pt apart both ways. Built as
/// rows rather than a `GridView` so it sits inside the screen's own scroll
/// and mirrors by itself in Arabic — the cover ends up top-right.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({required this.children, super.key});

  static const int columns = 2;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int start = 0; start < children.length; start += columns) {
      if (start > 0) rows.add(SizedBox(height: AppSpacing.sm.dh));
      rows.add(
        Row(
          children: <Widget>[
            for (int column = 0; column < columns; column++) ...<Widget>[
              if (column > 0) SizedBox(width: AppSpacing.sm.dw),
              Expanded(
                child: start + column < children.length
                    ? children[start + column]
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

/// The shared frame of a tile: 120 high, 12pt corners, a hairline.
class _TileFrame extends StatelessWidget {
  const _TileFrame({required this.child, this.color});

  static const double height = 120;

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height.dh,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: child,
    );
  }
}

/// A stored photo, with an optional badge at its top start ("Cover",
/// "Processing") and a spinner while something runs on it.
class PhotoGridTile extends StatelessWidget {
  const PhotoGridTile({
    required this.url,
    required this.semanticLabel,
    this.badge,
    this.isBusy = false,
    this.isProcessing = false,
    this.onTap,
    super.key,
  });

  final String url;
  final String semanticLabel;

  /// Usually an `OutlinedStatusPill(compact: true)`.
  final Widget? badge;

  /// A remove or a move is running on it.
  final bool isBusy;

  /// The server is still making its variants — a spinner over the image.
  final bool isProcessing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget? pill = badge;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      image: true,
      child: GestureDetector(
        onTap: isBusy ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: _TileFrame(
          color: AppColors.bgBrandSubtle,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              AppNetworkImage(url: url),
              if (isBusy || isProcessing)
                ColoredBox(
                  color: AppColors.bgSurface.withValues(alpha: 0.6),
                  child: const Center(child: AppSpinner()),
                ),
              if (pill != null)
                PositionedDirectional(
                  top: AppSpacing.xs.dh,
                  start: AppSpacing.xs.dw,
                  child: pill,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A photo on its way up, from the picked bytes: its progress while it
/// goes, and Retry / Remove once it failed.
class PhotoUploadTile extends StatelessWidget {
  const PhotoUploadTile({
    required this.bytes,
    required this.progress,
    required this.statusLabel,
    this.hasFailed = false,
    this.retryLabel,
    this.removeLabel,
    this.onRetry,
    this.onRemove,
    super.key,
  });

  final Uint8List bytes;

  /// 0 to 1.
  final double progress;

  /// "Uploading" / "Not sent".
  final String statusLabel;
  final bool hasFailed;
  final String? retryLabel;
  final String? removeLabel;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? retry = retryLabel;
    final String? remove = removeLabel;

    Widget action(String label, VoidCallback? onTap, Color color) => Semantics(
          button: true,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: AppSizes.touchTarget.dh),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.xs.dw),
                child: Center(
                  widthFactor: 1,
                  child: Text(label, style: textTheme.labelMedium?.copyWith(color: color)),
                ),
              ),
            ),
          ),
        );

    return Semantics(
      label: statusLabel,
      liveRegion: hasFailed,
      container: true,
      child: _TileFrame(
        color: AppColors.bgBrandSubtle,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Center(
                child: AppIcon(AppIcons.image, color: AppColors.iconBrand),
              ),
            ),
            ColoredBox(
              color: AppColors.bgSurface.withValues(alpha: hasFailed ? 0.85 : 0.6),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.xs.dw),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (hasFailed)
                      const AppIcon(AppIcons.alertTriangle, color: AppColors.iconDanger)
                    else
                      SizedBox.square(
                        dimension: AppSizes.iconLg.dw,
                        child: CircularProgressIndicator(
                          value: progress <= 0 ? null : progress,
                          strokeWidth: 2.5,
                          color: AppColors.brand,
                          backgroundColor: AppColors.bgDisabled,
                        ),
                      ),
                    SizedBox(height: AppSpacing.xs2.dh),
                    Text(
                      statusLabel,
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: hasFailed ? AppColors.textDanger : AppColors.textPrimary,
                      ),
                    ),
                    if (hasFailed && (retry != null || remove != null))
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (retry != null) action(retry, onRetry, AppColors.textBrand),
                          if (remove != null) action(remove, onRemove, AppColors.textDanger),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The last tile: `+` and "Add photo". `onTap: null` greys it out.
class PhotoAddTile extends StatelessWidget {
  const PhotoAddTile({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    final Color color = enabled ? AppColors.textSecondary : AppColors.textDisabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: _TileFrame(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AppIcon(AppIcons.plus, size: 28, color: enabled ? AppColors.iconDefault : color),
              SizedBox(height: AppSpacing.xs2.dh),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

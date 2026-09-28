import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ui_helpers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/provider_catalog/provider_catalog_repository.dart';
import '../../../core/services/photo_picker.dart';
import '../../../core/widgets/atoms/app_icon.dart';
import '../../../core/widgets/atoms/outlined_status_pill.dart';
import '../../../core/widgets/atoms/skeleton.dart';
import '../../../core/widgets/molecules/app_toast.dart';
import '../../../core/widgets/molecules/inline_banner.dart';
import '../../../core/widgets/molecules/main_button.dart';
import '../../../core/widgets/molecules/state_card.dart';
import '../../../core/widgets/organisms/bottom_action_bar.dart';
import '../../../core/widgets/organisms/brand_top_bar.dart';
import '../../../core/widgets/organisms/confirm_sheet.dart';
import '../../../core/widgets/organisms/photo_grid.dart';
import '../../../l10n/app_localizations.dart';
import '../view_model/catalog_photos_view_model.dart';
import 'widgets/catalog_sheets.dart';

/// P8 Service photos and P13 Pack photos.
class CatalogPhotosView extends StatefulWidget {
  const CatalogPhotosView({this.pickPhoto = pickChatPhoto, super.key});

  /// The gallery picker — a fake one in tests.
  final PhotoPicker pickPhoto;

  @override
  State<CatalogPhotosView> createState() => _CatalogPhotosViewState();
}

class _CatalogPhotosViewState extends State<CatalogPhotosView> {
  bool _isPicking = false;

  CatalogPhotosViewModel get _viewModel => context.read<CatalogPhotosViewModel>();

  void _error(Failure failure) =>
      showAppToast(context, context.l10n.forFailure(failure), tone: AppToastTone.error);

  Future<void> _add() async {
    if (_isPicking) return;
    final AppLocalizations l10n = context.l10n;
    _isPicking = true;
    final PickedImage? image;
    try {
      image = await widget.pickPhoto();
    } finally {
      _isPicking = false;
    }
    if (image == null || !mounted) return;
    final CatalogPhotosViewModel viewModel = _viewModel;
    switch (viewModel.add(image)) {
      case null:
        break;
      case AddPhotoProblem.tooLarge:
        showAppToast(
          context,
          l10n.photoTooLarge(viewModel.maxMb),
          tone: AppToastTone.error,
        );
      case AddPhotoProblem.wrongType:
        showAppToast(context, l10n.photoWrongType, tone: AppToastTone.error);
      case AddPhotoProblem.limitReached:
        showAppToast(context, l10n.providerServicePhotosFull(viewModel.limit), tone: AppToastTone.error);
    }
  }

  Future<void> _actions(CatalogPhoto photo) async {
    final CatalogPhotosViewModel viewModel = _viewModel;
    final PhotoAction? action = await showPhotoActionsSheet(
      context,
      canMakeCover: viewModel.canMoveEarlier(photo),
      canMoveEarlier: viewModel.canMoveEarlier(photo),
      canMoveLater: viewModel.canMoveLater(photo),
    );
    if (action == null || !mounted) return;
    final Failure? failure = switch (action) {
      PhotoAction.makeCover => await viewModel.makeCover(photo),
      PhotoAction.moveEarlier => await viewModel.moveEarlier(photo),
      PhotoAction.moveLater => await viewModel.moveLater(photo),
      PhotoAction.remove => await _remove(photo),
    };
    if (failure == null || !mounted) return;
    if (CatalogPhotosViewModel.isLastPhotoRefusal(failure)) {
      showAppToast(context, context.l10n.providerServicePhotoLastRefused, tone: AppToastTone.error);
    } else {
      _error(failure);
    }
  }

  Future<Failure?> _remove(CatalogPhoto photo) async {
    final AppLocalizations l10n = context.l10n;
    final bool confirmed = await showConfirmSheet(
      context,
      title: l10n.providerServicePhotoRemoveTitle,
      message: l10n.providerServicePhotoRemoveBody,
      confirmLabel: l10n.providerServiceRemove,
      cancelLabel: l10n.providerServiceDeleteKeep,
      destructive: true,
    );
    if (!confirmed || !mounted) return null;
    return _viewModel.remove(photo);
  }

  @override
  Widget build(BuildContext context) {
    final CatalogPhotosViewModel viewModel = context.watch<CatalogPhotosViewModel>();
    final AppLocalizations l10n = context.l10n;
    final bool isPack = viewModel.owner == PhotoOwner.pack;

    final Widget body;
    if (viewModel.isFirstLoad) {
      body = ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: AppSpacing.screenPaddingAll,
        children: <Widget>[
          Skeleton(height: 32.dh),
          SizedBox(height: AppSpacing.md.dh),
          PhotoGrid(
            children: <Widget>[
              for (int i = 0; i < 4; i++) Skeleton(height: 120.dh, radius: AppRadii.mdAll),
            ],
          ),
        ],
      );
    } else if (viewModel.loadFailed) {
      body = Padding(
        padding: AppSpacing.screenPaddingAll,
        child: viewModel.isGone
            ? StateCard.empty(
                icon: AppIcons.alertTriangle,
                title: l10n.detailGoneTitle,
                body: l10n.detailGoneBody,
                actionLabel: l10n.detailGoneBack,
                onAction: () => Navigator.of(context).pop(),
              )
            : StateCard.error(onRetry: viewModel.load),
      );
    } else {
      body = _gallery(viewModel, isPack);
    }

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BrandTopBar(title: isPack ? l10n.providerPackPhotosTitle : l10n.providerServicePhotos),
          Expanded(child: body),
          BottomActionBar(
            child: MainButton(
              label: l10n.selectionDone,
              // Leaving mid-upload would lose sight of it; the tiles say
              // how far along it is.
              isLoading: viewModel.hasPendingUploads,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gallery(CatalogPhotosViewModel viewModel, bool isPack) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<CatalogPhoto> photos = viewModel.photos;
    return ListView(
      padding: AppSpacing.screenPaddingAll,
      children: <Widget>[
        Text(
          isPack ? l10n.providerPackPhotosHelper : l10n.providerServicePhotosHelper,
          style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: AppSpacing.xs.dh),
        Text(
          l10n.providerServicePhotosCounter(viewModel.count, viewModel.limit),
          style: textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
        ),
        SizedBox(height: AppSpacing.md.dh),
        if (photos.isEmpty && viewModel.uploads.isEmpty) ...<Widget>[
          Text(
            l10n.providerServicePhotosEmpty,
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.sm.dh),
        ],
        PhotoGrid(
          children: <Widget>[
            for (int i = 0; i < photos.length; i++)
              PhotoGridTile(
                key: ValueKey<String>(photos[i].id),
                url: photos[i].thumbUrl,
                semanticLabel: l10n.providerServicePhotoLabel(i + 1),
                isBusy: viewModel.busyPhotoId == photos[i].id,
                isProcessing: photos[i].processing == PhotoProcessing.pending,
                badge: _badge(l10n, photos[i], isCover: i == 0),
                onTap: viewModel.busyPhotoId == null ? () => _actions(photos[i]) : null,
              ),
            for (final PhotoUpload upload in viewModel.uploads)
              PhotoUploadTile(
                key: ValueKey<String>(upload.key),
                bytes: upload.bytes,
                progress: upload.progress,
                hasFailed: upload.hasFailed,
                statusLabel: upload.hasFailed
                    ? l10n.providerServicePhotoUploadFailed
                    : l10n.providerServicePhotoUploading,
                retryLabel: l10n.providerServicePhotoRetry,
                removeLabel: l10n.providerServiceRemove,
                onRetry: () => viewModel.retry(upload),
                onRemove: () => viewModel.discard(upload),
              ),
            if (!viewModel.isFull)
              PhotoAddTile(label: l10n.providerServiceAddPhoto, onTap: _add),
          ],
        ),
        if (viewModel.isFull) ...<Widget>[
          SizedBox(height: AppSpacing.md.dh),
          InlineBanner(
            tone: InlineBannerTone.info,
            title: l10n.providerServicePhotosFull(viewModel.limit),
          ),
        ],
      ],
    );
  }

  Widget? _badge(AppLocalizations l10n, CatalogPhoto photo, {required bool isCover}) {
    if (photo.processing == PhotoProcessing.failed) {
      return OutlinedStatusPill(
        label: l10n.providerServicePhotoFailed,
        color: AppColors.statusDeclined,
        compact: true,
      );
    }
    if (photo.processing == PhotoProcessing.pending) {
      return OutlinedStatusPill(
        label: l10n.providerServicePhotoProcessing,
        color: AppColors.statusPending,
        compact: true,
      );
    }
    if (isCover) {
      return OutlinedStatusPill(
        label: l10n.providerServicePhotoCover,
        color: AppColors.statusAccepted,
        compact: true,
      );
    }
    return null;
  }
}

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/provider_catalog/provider_catalog_repository.dart';
import '../../core/reference/reference_repository.dart';
import '../../core/routing/app_routes.dart';
import 'view/catalog_photos_view.dart';
import 'view/choose_services_view.dart';
import 'view/pack_form_view.dart';
import 'view/provider_services_view.dart';
import 'view/service_form_view.dart';
import 'view_model/catalog_photos_view_model.dart';
import 'view_model/choose_services_view_model.dart';
import 'view_model/pack_form_view_model.dart';
import 'view_model/provider_services_view_model.dart';
import 'view_model/service_form_view_model.dart';

/// The provider shell's third branch (`/provider/services`): P6 My services
/// and P10 My packs. `?view=packs` opens the Packs chip.
///
/// Needs `ProviderCatalogRepository` in the tree.
Widget buildProviderServicesTab(BuildContext context, GoRouterState state) {
  final bool openPacks = state.uri.queryParameters['view'] == 'packs';
  return ChangeNotifierProvider<ProviderServicesViewModel>(
    create: (BuildContext c) => ProviderServicesViewModel(
      catalog: c.read<ProviderCatalogRepository>(),
      openPacks: openPacks,
    ),
    child: ProviderServicesView(openPacks: openPacks),
  );
}

/// P7, P7a, P8, P11, P11a, P12 and P13 — full screen over the provider's
/// tabs (P9, P14 and P7b are sheets). Literal segments come before `:id`.
///
/// Needs `ProviderCatalogRepository`, `ReferenceRepository` and
/// `AppConfigRepository` in the tree.
List<RouteBase> providerServicesRoutes() => <RouteBase>[
      GoRoute(
        path: AppRoutes.providerNewService,
        builder: (_, _) => _serviceForm(),
      ),
      GoRoute(
        path: AppRoutes.providerServicePhotosFor(':id'),
        builder: (_, GoRouterState state) => _photos(
          owner: PhotoOwner.service,
          id: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.providerEditServiceFor(':id'),
        builder: (_, GoRouterState state) => _serviceForm(
          id: state.pathParameters['id'],
          // P9's "Add the Arabic" from P6 opens the form on that field.
          fix: state.extra is ServiceChecklistItem ? state.extra! as ServiceChecklistItem : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.providerNewPack,
        builder: (_, _) => _packForm(),
      ),
      GoRoute(
        path: AppRoutes.providerChooseServices,
        // Opened from P11/P12 with what the pack holds; without it (a cold
        // start on the path) there is no pack to choose for.
        redirect: (_, GoRouterState state) =>
            state.extra is ChooseServicesArgs ? null : AppRoutes.providerPacksTab,
        builder: (_, GoRouterState state) => ChangeNotifierProvider<ChooseServicesViewModel>(
          create: (BuildContext c) => ChooseServicesViewModel(
            catalog: c.read<ProviderCatalogRepository>(),
            reference: c.read<ReferenceRepository>(),
            args: state.extra! as ChooseServicesArgs,
          ),
          child: const ChooseServicesView(),
        ),
      ),
      GoRoute(
        path: AppRoutes.providerPackPhotosFor(':id'),
        builder: (_, GoRouterState state) => _photos(
          owner: PhotoOwner.pack,
          id: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.providerEditPackFor(':id'),
        builder: (_, GoRouterState state) => _packForm(
          id: state.pathParameters['id'],
          fix: state.extra is PackChecklistItem ? state.extra! as PackChecklistItem : null,
        ),
      ),
    ];

Widget _serviceForm({String? id, ServiceChecklistItem? fix}) =>
    ChangeNotifierProvider<ServiceFormViewModel>(
      create: (BuildContext c) => ServiceFormViewModel(
        catalog: c.read<ProviderCatalogRepository>(),
        reference: c.read<ReferenceRepository>(),
        serviceId: id,
        fix: fix,
      ),
      child: const ServiceFormView(),
    );

Widget _packForm({String? id, PackChecklistItem? fix}) =>
    ChangeNotifierProvider<PackFormViewModel>(
      create: (BuildContext c) => PackFormViewModel(
        catalog: c.read<ProviderCatalogRepository>(),
        reference: c.read<ReferenceRepository>(),
        packId: id,
        fix: fix,
      ),
      child: const PackFormView(),
    );

Widget _photos({required PhotoOwner owner, required String id}) =>
    ChangeNotifierProvider<CatalogPhotosViewModel>(
      create: (BuildContext c) {
        final AppConfig config = c.read<AppConfigRepository>().current;
        return CatalogPhotosViewModel(
          catalog: c.read<ProviderCatalogRepository>(),
          owner: owner,
          ownerId: id,
          limit: owner == PhotoOwner.service ? config.photosPerService : config.photosPerPack,
          maxMb: config.maxPhotoMb,
          types: config.imageTypes,
        );
      },
      child: const CatalogPhotosView(),
    );

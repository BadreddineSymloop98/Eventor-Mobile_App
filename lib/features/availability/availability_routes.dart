import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/availability/availability_repository.dart';
import '../../core/config/app_config.dart';
import '../../core/provider/models/provider_home.dart' show ProviderServiceRow;
import '../../core/routing/app_routes.dart';
import 'view/availability_view.dart';
import 'view_model/availability_view_model.dart';

/// P15 Availability, a full-screen route pushed from the provider's home.
///
/// [loadServices] lists the provider's services for the block sheets'
/// "Which services" — passed in by the router, which reads them from the
/// services module, so the calendar does not depend on it.
List<RouteBase> availabilityRoutes({
  required Future<List<ProviderServiceRow>> Function(BuildContext context) loadServices,
}) =>
    <RouteBase>[
      GoRoute(
        path: AppRoutes.providerAvailability,
        builder: (_, _) => ChangeNotifierProvider<AvailabilityViewModel>(
          create: (BuildContext context) => AvailabilityViewModel(
            availability: context.read<AvailabilityRepository>(),
            loadServices: () => loadServices(context),
            config: context.read<AppConfigRepository>().current,
          ),
          child: const AvailabilityView(),
        ),
      ),
    ];

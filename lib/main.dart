import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_services.dart';
import 'app/eventor_app.dart';

Future<void> main() async {
  // Required before touching platform channels — SharedPreferences and the
  // secure store are read below, before the first frame.
  WidgetsFlutterBinding.ensureInitialized();

  // The app is designed for portrait only. Locking it here means the layouts
  // never have to answer for a landscape they were not drawn for — including
  // on a tablet, which would otherwise start in it.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final AppServices services = await AppServices.create();

  runApp(EventorApp(services: services));

  // Not awaited: the splash is on screen while this runs, and the router
  // moves on by itself once it is done.
  services.startup.run();
}

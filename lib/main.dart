import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/eventor_app.dart';
import 'core/services/preferences_service.dart';

Future<void> main() async {
  // Required before touching platform channels — SharedPreferences is loaded
  // below, before the first frame.
  WidgetsFlutterBinding.ensureInitialized();

  // The app is designed for portrait only. Locking it here means the layouts
  // never have to answer for a landscape they were not drawn for — including
  // on a tablet, which would otherwise start in it.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final PreferencesService preferences = await PreferencesService.load();

  runApp(EventorApp(preferences: preferences));
}

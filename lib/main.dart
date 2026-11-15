import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    await _configureWindow();
    await configureDependencies();

    runApp(const HmiApp());
  }, (error, stack) => debugPrint('Error no capturado: $error\n$stack'));
}

/// Configura la ventana en escritorio (tamaño, mínimo, título).
/// Para modo kiosco: agrega `await windowManager.setFullScreen(true);`
/// dentro del callback de `waitUntilReadyToShow`.
Future<void> _configureWindow() async {
  if (kIsWeb || !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    return;
  }

  await windowManager.ensureInitialized();

  const options = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(960, 600),
    center: true,
    title: 'HMI Arduino',
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

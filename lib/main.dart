import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    await configureDependencies();

    runApp(const HmiApp());
  }, (error, stack) => debugPrint('Error no capturado: $error\n$stack'));
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/mqtt/data/mqtt_connection_service.dart';
import 'features/mqtt/domain/entities/mqtt_connection_state.dart';
import 'features/mqtt/presentation/pages/mqtt_landing_page.dart';
import 'features/serial_connection/domain/repositories/serial_repository.dart';
import 'features/serial_connection/presentation/bloc/connection_bloc.dart';
import 'features/system/data/database/system_database_manager.dart';
import 'features/system/domain/services/system_configuration_service.dart';
import 'features/system/presentation/pages/system_shell_page.dart';
import 'features/telemetry/presentation/cubit/telemetry_cubit.dart';

class HmiApp extends StatefulWidget {
  const HmiApp({super.key});

  @override
  State<HmiApp> createState() => _HmiAppState();
}

class _HmiAppState extends State<HmiApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Cierra las conexiones al cerrar la aplicación.
    _lifecycle = AppLifecycleListener(
      onDetach: () {
        unawaited(sl<MqttConnectionService>().disconnect());
        unawaited(sl<SystemConfigurationService>().dispose());
        unawaited(sl<SystemDatabaseManager>().dispose());
        sl<SerialRepository>().dispose();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConnectionBloc>.value(value: sl<ConnectionBloc>()),
        BlocProvider<TelemetryCubit>.value(value: sl<TelemetryCubit>()),
      ],
      child: MaterialApp(
        title: 'HMI Arduino',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _RootGate(),
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final mqtt = sl<MqttConnectionService>();
    return StreamBuilder<BrokerConnectionState>(
      stream: mqtt.states,
      initialData: mqtt.state,
      builder: (context, connectionSnapshot) {
        if (connectionSnapshot.data?.isConnected != true) {
          return MqttLandingPage(
            key: const ValueKey('mqtt-connection'),
            service: mqtt,
          );
        }
        return const SystemShellPage(key: ValueKey('system-shell'));
      },
    );
  }
}

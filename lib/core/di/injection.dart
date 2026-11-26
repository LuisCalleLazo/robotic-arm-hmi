import 'package:get_it/get_it.dart';

import '../../features/serial_connection/data/datasources/serial_datasource.dart';
import '../../features/serial_connection/data/repositories/serial_repository_impl.dart';
import '../../features/serial_connection/domain/repositories/serial_repository.dart';
import '../../features/serial_connection/presentation/bloc/connection_bloc.dart';
import '../../features/system/system_injection.dart';
import '../../features/system/domain/services/system_configuration_service.dart';
import '../../features/telemetry/data/parsers/telemetry_parser.dart';
import '../../features/telemetry/presentation/cubit/telemetry_cubit.dart';
import '../../features/mqtt/data/mqtt_connection_service.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl
    // Data
    ..registerLazySingleton<SerialDatasource>(SerialDatasource.new)
    ..registerLazySingleton<SerialRepository>(
      () => SerialRepositoryImpl(sl<SerialDatasource>()),
    )
    ..registerLazySingleton<TelemetryParser>(TelemetryParser.new)
    ..registerLazySingleton<MqttConnectionService>(MqttConnectionService.new)
    // Presentation (singletons: el historial sobrevive al cambio de pantalla)
    ..registerLazySingleton<ConnectionBloc>(
      () => ConnectionBloc(
        sl<SerialRepository>(),
        onCommandSent: sl<TelemetryCubit>().recordSent,
      ),
    )
    ..registerLazySingleton<TelemetryCubit>(
      () => TelemetryCubit(
        repository: sl<SerialRepository>(),
        parser: sl<TelemetryParser>(),
      ),
    );

  registerSystem(sl);
  sl<SystemConfigurationService>();
}

import 'package:get_it/get_it.dart';

import 'data/datasources/peer_client_datasource.dart';
import 'data/datasources/peer_discovery_datasource.dart';
import 'data/datasources/peer_discovery_datasource_factory.dart';
import 'data/datasources/peer_server_datasource.dart';
import 'data/datasources/peer_server_datasource_factory.dart';
import 'data/repositories/peer_repository_impl.dart';
import 'domain/repositories/peer_repository.dart';
import 'domain/usecases/connect_as_slave_usecase.dart';
import 'domain/usecases/disconnect_peer_usecase.dart';
import 'domain/usecases/discover_masters_usecase.dart';
import 'domain/usecases/kick_client_usecase.dart';
import 'domain/usecases/send_peer_message_usecase.dart';
import 'domain/usecases/set_client_permission_usecase.dart';
import 'domain/usecases/start_master_usecase.dart';
import 'domain/usecases/verify_master_password_usecase.dart';
import 'domain/usecases/watch_peer_messages_usecase.dart';
import 'domain/usecases/watch_peer_session_usecase.dart';
import 'presentation/cubit/peer_cubit.dart';

/// Llamar una vez al arrancar: `registerPeerToPeer(GetIt.I);`
void registerPeerToPeer(GetIt sl) {
  sl
    ..registerLazySingleton<PeerServerDataSource>(createPeerServerDataSource)
    ..registerLazySingleton<PeerDiscoveryDataSource>(createPeerDiscoveryDataSource)
    ..registerLazySingleton<PeerClientDataSource>(PeerClientDataSource.new)
    ..registerLazySingleton<PeerRepository>(
      () => PeerRepositoryImpl(
        server: sl<PeerServerDataSource>(),
        client: sl<PeerClientDataSource>(),
        discovery: sl<PeerDiscoveryDataSource>(),
      ),
    )
    ..registerLazySingleton(() => VerifyMasterPasswordUseCase(sl()))
    ..registerLazySingleton(() => StartMasterUseCase(sl()))
    ..registerLazySingleton(() => ConnectAsSlaveUseCase(sl()))
    ..registerLazySingleton(() => DiscoverMastersUseCase(sl()))
    ..registerLazySingleton(() => DisconnectPeerUseCase(sl()))
    ..registerLazySingleton(() => SendPeerMessageUseCase(sl()))
    ..registerLazySingleton(() => SetClientPermissionUseCase(sl()))
    ..registerLazySingleton(() => KickClientUseCase(sl()))
    ..registerLazySingleton(() => WatchPeerSessionUseCase(sl()))
    ..registerLazySingleton(() => WatchPeerMessagesUseCase(sl()))
    // Singleton: la conexión debe sobrevivir a la navegación entre pantallas.
    ..registerLazySingleton(
      () => PeerCubit(
        watchSession: sl(),
        verifyMasterPassword: sl(),
        startMaster: sl(),
        connectAsSlave: sl(),
        discoverMasters: sl(),
        disconnect: sl(),
        sendMessage: sl(),
        setClientPermission: sl(),
        kickClient: sl(),
        isMasterSupported: sl<PeerRepository>().isMasterSupported,
        isDiscoverySupported: sl<PeerRepository>().isDiscoverySupported,
      ),
    );
}

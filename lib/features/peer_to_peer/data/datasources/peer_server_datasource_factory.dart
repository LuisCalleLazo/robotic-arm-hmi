// Selección por plataforma: en web `dart:io` no existe, se usa el stub.
export 'peer_server_datasource_stub.dart'
    if (dart.library.io) 'peer_server_datasource_io.dart';

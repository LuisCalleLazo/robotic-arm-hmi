# peer_to_peer

Conexión **maestro ↔ esclavos** por WebSocket para el HMI. Cada esclavo es **una máquina** (brazo, cinta pequeña, cinta grande) y solo el maestro ve qué máquina es cada uno.

| Rol | Qué hace | Web | Desktop | Mobile |
|---|---|:-:|:-:|:-:|
| Maestro | Entra con contraseña, abre un servidor local, ve las máquinas conectadas y administra permisos | ❌ | ✅ | ✅ |
| Esclavo | Elige su máquina y su nombre, busca al maestro por nombre y se conecta | ✅ | ✅ | ✅ |

> En web no existe `dart:io`: ahí solo se puede ser esclavo y no hay búsqueda por nombre (se escribe la IP del maestro).

---

## 1. Instalación

Copia la carpeta a `lib/features/peer_to_peer/`. Dependencias (ya instaladas): `flutter_bloc`, `get_it`, `shelf`, `shelf_web_socket`, `web_socket_channel`.

```dart
import 'features/peer_to_peer/peer_to_peer.dart';

void main() {
  registerPeerToPeer(GetIt.I);   // una sola vez
  runApp(const MyApp());
}
```

Todo se importa con `import '.../peer_to_peer/peer_to_peer.dart';`

---

## 2. Flujo de la pantalla grande: `PeerConnectionScreen`

```
¿Cómo vas a entrar?
 ├─ Maestro → contraseña → nombre del maestro + puerto → servidor activo ──► onMasterReady
 └─ Esclavo → máquina + nombre → buscar maestro por nombre → conectar ─────► onSlaveReady
```

**Maestro**
- La contraseña es obligatoria y única (sin usuario). Está en `domain/entities/peer_config.dart` → `PeerConfig.masterPassword`; cámbiala ahí.
- Pone un **nombre** al maestro: así lo encuentran los esclavos.
- Al iniciar ve la lista de **máquinas conectadas** (nombre + tipo) y puede dar permiso de control o expulsar a cada una.

**Esclavo**
- Elige su **máquina** (obligatorio) y escribe el **nombre** de su dispositivo (obligatorio).
- Busca al maestro **por nombre**: la lista aparece sola, hay un filtro de texto y un botón para volver a buscar. Con Enter conecta si queda un solo resultado.
- Alternativa: "Conectar por IP" (único método en web).
- Los esclavos **no** ven las máquinas de los demás; solo el maestro.

### Los dos métodos de destino (por parámetro)

La pantalla no sabe a dónde ir: se lo pasas tú con dos callbacks. Ambos son opcionales y valen `null` por ahora.

```dart
PeerConnectionScreen(
  // Se llama cuando el servidor del maestro queda escuchando.
  onMasterReady: (context, session) {
    // session.deviceName = nombre del maestro
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => const MiPaginaMaestro(),
    ));
  },
  // Se llama cuando el esclavo queda conectado al maestro.
  onSlaveReady: (context, session) {
    // session.machine = PeerMachineType.brazo / cintaPequena / cintaGrande
    // session.deviceName, session.masterName, session.permission
    final page = switch (session.machine!) {
      PeerMachineType.brazo => const PaginaBrazo(),
      PeerMachineType.cintaPequena => const PaginaCintaPequena(),
      PeerMachineType.cintaGrande => const PaginaCintaGrande(),
    };
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  },
)
```

- Firma: `void Function(BuildContext context, PeerSession session)` (`PeerReadyCallback`).
- Se dispara **una vez** al pasar a "listo". Mientras la sesión esté activa también aparece un botón **Continuar** que vuelve a llamarlo (útil si abres la pantalla con la sesión ya conectada).
- Con `null` la pantalla solo muestra el estado de la conexión.

---

## 3. Usar la UI en cualquier parte

La conexión vive en un `PeerCubit` **singleton**; todos estos widgets comparten la misma sesión. Son embebibles: sin `Scaffold`, sin scroll, sin navegación. Dales un ancho acotado (`SizedBox`, `Card`, `Expanded`). Todos aceptan `cubit:` opcional (por defecto `GetIt.I<PeerCubit>()`).

| Widget | Para qué |
|---|---|
| `PeerConnectionScreen` | Pantalla completa con todo el flujo |
| `PeerConnectionPanel` | El mismo flujo, embebible (acepta `onMasterReady` / `onSlaveReady`) |
| `PeerMasterPanel` | Solo maestro: contraseña → config → máquinas conectadas (`onReady`) |
| `PeerSlavePanel` | Solo esclavo: máquina, nombre, búsqueda por nombre (`onReady`) |
| `PeerRoleSelectionPanel` | Solo la elección de rol (`onRoleSelected`) |
| `PeerStatusBadge` | Chip `Rol · Estado · Permiso` para AppBar; abre un diálogo |
| `showPeerConnectionDialog(context)` | Panel completo en un diálogo |

```dart
// Chip en el AppBar
AppBar(actions: const [PeerStatusBadge(), SizedBox(width: 12)])

// Panel dentro de una tarjeta
SizedBox(width: 360, child: Card(child: Padding(
  padding: const EdgeInsets.all(16),
  child: SingleChildScrollView(child: PeerConnectionPanel(onSlaveReady: ...)),
)))

// Solo esclavo con valores iniciales
PeerSlavePanel(defaultName: 'Tablet taller', defaultMachine: PeerMachineType.brazo)
```

---

## 4. Enviar y recibir datos

```dart
final peer = GetIt.I<PeerCubit>();

await peer.sendTelemetry({'x': 10.5, 'y': 3.2});       // maestro → todos los esclavos
final ok = await peer.sendCommand({'move': 'home'});   // esclavo → maestro (false si no hay permiso)

GetIt.I<WatchPeerMessagesUseCase>()().listen((msg) {
  // maestro: msg.type == command, msg.senderId = id del esclavo
  // esclavo: msg.type == telemetry
});
```

Estado: `BlocBuilder<PeerCubit, PeerState>` → `state.session` (`role`, `status`, `deviceName`, `machine`, `masterName`, `permission`, `clients`, `addresses`, `error`).

| Método del `PeerCubit` | Rol | Descripción |
|---|---|---|
| `verifyMasterPassword(pass)` | Maestro | Comprueba la contraseña |
| `startMaster({password, name, port})` | Maestro | Abre el servidor (revalida la contraseña) |
| `connectSlave({host, port, name, machine})` | Esclavo | Conecta a `ws://host:port/ws` |
| `discoverMasters()` | Esclavo | `Stream<PeerMasterInfo>` con los maestros encontrados |
| `setPermission(id, permission)` / `kick(id)` | Maestro | Permiso de control / expulsar |
| `sendCommand` / `sendTelemetry` | Esclavo / Maestro | Envío de datos |
| `disconnect()` | Ambos | Cierra la sesión |

---

## 5. Conceptos

- **`PeerMachineType`**: `brazo`, `cintaPequena` (`cinta_transportadora_pequena`), `cintaGrande` (`cinta_transportadora_grande`). Para agregar una máquina: nuevo valor en `peer_machine_type.dart` + etiqueta e icono en `presentation/widgets/peer_labels.dart`.
- **`PeerPermission`**: `viewOnly` (por defecto) y `control`. Es independiente de la máquina: el maestro decide quién puede enviar comandos.
- **`PeerConnectionStatus`**: `disconnected`, `connecting`, `listening` (maestro activo), `connected` (esclavo), `error`.

### Cómo se encuentra al maestro (por nombre)

El maestro responde por **UDP (puerto 8766)** a las búsquedas de la red local con su nombre y el puerto del servidor; el esclavo envía un broadcast y lista las respuestas. El servidor WebSocket usa el **8765** (configurable en el panel).

### Protocolo (JSON por WebSocket)

El esclavo conecta a `ws://host:puerto/ws?name=<nombre>&machine=<id>`. Sin una máquina válida el maestro lo rechaza.

| `type` | Dirección | Uso |
|---|---|---|
| `welcome` | maestro → esclavo | `clientId`, permiso inicial, nombre del maestro |
| `permission` | maestro → esclavo | Cambio de permiso |
| `command` | esclavo → maestro | Comando (descartado sin permiso `control`) |
| `telemetry` | maestro → esclavos | Datos |
| `kicked` / `error` | maestro → esclavo | Expulsión / errores (`permission_denied`, `machine_required`) |

---

## 6. Arquitectura

```
peer_to_peer/
├── peer_injection.dart            registerPeerToPeer(GetIt)
├── peer_to_peer.dart              barrel
├── domain/
│   ├── entities/                  roles, máquinas, permisos, sesión, mensajes, PeerConfig
│   ├── repositories/              PeerRepository
│   └── usecases/
├── data/
│   ├── datasources/               server y discovery (io | stub | factory), client
│   ├── model/                     JSON de mensajes
│   └── repositories/              PeerRepositoryImpl
└── presentation/
    ├── cubit/                     PeerCubit
    ├── screens/                   PeerConnectionScreen
    └── widgets/                   paneles y piezas embebibles
```

---

## 7. Configuración por plataforma

- **Android**: `<uses-permission android:name="android.permission.INTERNET"/>` en el `AndroidManifest.xml` principal.
- **iOS**: `NSLocalNetworkUsageDescription` en `Info.plist` (la búsqueda por red local pide permiso al usuario).
- **macOS**: entitlements `com.apple.security.network.server` y `com.apple.security.network.client`.
- **Windows / Linux**: permitir en el firewall el puerto TCP 8765 y el UDP 8766.
- **Web**: servir la app por `http`; desde `https` el navegador bloquea `ws://`.

---

## 8. Limitaciones

- **La contraseña del maestro está en el código**: sirve para que no cualquiera use la app como maestro, pero no es seguridad real (se puede extraer del binario). Los esclavos entran sin contraseña por diseño.
- No hay cifrado (`ws://`): pensado para red local de confianza.
- La búsqueda por nombre usa UDP broadcast: algunas redes (Wi‑Fi de invitados, VLANs, AP con aislamiento de clientes) lo bloquean; ahí usa "Conectar por IP".
- Si dos maestros tienen el mismo nombre y puerto aparecen como uno solo: usa nombres distintos.
- En mobile el servidor se detiene si el sistema suspende la app en segundo plano.
- Una sesión activa por dispositivo (maestro **o** esclavo).

## 9. Problemas comunes

| Síntoma | Causa probable |
|---|---|
| No aparece el maestro en la lista | Redes distintas, firewall (UDP 8766) o red que bloquea broadcast: usa "Conectar por IP" |
| "Contraseña incorrecta." | Revisa `PeerConfig.masterPassword` |
| "El maestro rechazó la conexión." | El esclavo no indicó máquina válida |
| "No se pudo abrir el puerto" | Puerto ocupado: cambia el puerto en el panel del maestro |
| `sendCommand` devuelve `false` | Sin permiso `control` o sin conexión activa |

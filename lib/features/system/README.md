# System data

`SystemDatabase` stores the system catalog and process history: machines,
motors, servos, sensors, processes, process steps, process runs, motor run
history, and system positions. `SystemRepository`,
`SystemHistoryRepository`, and `SystemPositionRepository` are registered with
the application dependencies.

The system database is local to this installation and starts independently of
any communication role. MQTT connection state is managed separately by the
`mqtt` feature.

On native platforms Drift stores the database file in the application
documents directory. For web, Drift requires `sqlite3.wasm` and
`drift_worker.js` in `web/`; it chooses a supported persistent browser storage
backend (IndexedDB is used when available storage support requires it).

The repositories provide the system catalog and process persistence layer.
Processes start either when the serial device is ready after connection or
when the MQTT connection receives the configured exact topic and text payload.
They can also be started manually from the process list. Activations are queued
FIFO while a process is running, including repeated MQTT messages; sensor
signals do not activate processes.

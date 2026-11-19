# System data

`SystemDatabase` stores the system catalog and process history: machines,
motors, servos, sensors, processes, process steps, process runs, motor run
history, and system positions. `SystemRepository`,
`SystemHistoryRepository`, and `SystemPositionRepository` are registered with
the application dependencies.

The database manager follows `PeerRepository`'s current session. It opens the
database only while this device is the active master (`listening`) and closes
it when the master session ends. Every local datasource operation checks that
same condition, so a slave cannot initialize or read the local database.

On native platforms Drift stores the database file in the application
documents directory. For web, Drift requires `sqlite3.wasm` and
`drift_worker.js` in `web/`; it chooses a supported persistent browser storage
backend (IndexedDB is used when available storage support requires it). The
current peer-to-peer feature does not support web as master, so web slaves do
not open a database.

The repositories are the master's local persistence layer. Slave-side
registration still needs a peer-to-peer request/response flow to send machine
and process changes to the master; slaves must not write a separate local
copy.

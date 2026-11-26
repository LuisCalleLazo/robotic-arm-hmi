import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'system_database.g.dart';

@DataClassName('SystemMachineRow')
class SystemMachines extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  IntColumn get parentMachineId =>
      integer().nullable().references(SystemMachines, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MotorRow')
class Motors extends Table {
  IntColumn get id => integer()();
  IntColumn get systemMachineId => integer().references(SystemMachines, #id)();
  TextColumn get key => text()();
  TextColumn get keySensorRight => text().nullable()();
  TextColumn get keySensorLeft => text().nullable()();
  RealColumn get speed => real()();
  TextColumn get maxStepsRight => text().nullable()();
  TextColumn get maxStepsLeft => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ServoRow')
class Servos extends Table {
  IntColumn get id => integer()();
  IntColumn get machineId => integer().references(SystemMachines, #id)();
  TextColumn get key => text()();
  RealColumn get maxOpen => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SensorRow')
class Sensors extends Table {
  IntColumn get id => integer()();
  IntColumn get machineId =>
      integer().nullable().references(SystemMachines, #id)();
  TextColumn get key => text()();
  TextColumn get name => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProcessRow')
class Processes extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get order => integer()();
  IntColumn get machineId =>
      integer().nullable().references(SystemMachines, #id)();
  IntColumn get activationSensorId =>
      integer().nullable().references(Sensors, #id)();
  TextColumn get mqttTopic => text().nullable()();
  TextColumn get mqttExpectedMessage => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProcessMotorRow')
class ProcessMotors extends Table {
  IntColumn get id => integer()();
  IntColumn get processId => integer().references(Processes, #id)();
  IntColumn get motorId => integer().references(Motors, #id)();
  TextColumn get name => text()();
  IntColumn get order => integer()();
  RealColumn get steps => real()();
  RealColumn get speed => real().withDefault(const Constant(5000))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProcessServoRow')
class ProcessServos extends Table {
  IntColumn get id => integer()();
  IntColumn get processId => integer().references(Processes, #id)();
  IntColumn get servoId => integer().references(Servos, #id)();
  TextColumn get name => text()();
  IntColumn get order => integer()();
  RealColumn get openValue => real()();
  RealColumn get speed => real().withDefault(const Constant(60))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProcessHistoricRow')
class ProcessHistorics extends Table {
  IntColumn get id => integer()();
  IntColumn get processId => integer().references(Processes, #id)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  DateTimeColumn get stopProcess => dateTime().nullable()();
  TextColumn get stopKey => text().nullable()();
  BoolColumn get finishProcess => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProcessHistoricMotorRow')
class ProcessHistoricMotors extends Table {
  IntColumn get id => integer()();
  IntColumn get processMotorId => integer().references(ProcessMotors, #id)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  RealColumn get steps => real()();
  RealColumn get speed => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SystemPositionRow')
class SystemPositions extends Table {
  IntColumn get id => integer()();
  IntColumn get number => integer()();
  TextColumn get type => text()();
  IntColumn get systemMachineId => integer().references(SystemMachines, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    SystemMachines,
    Motors,
    Servos,
    Sensors,
    Processes,
    ProcessMotors,
    ProcessServos,
    ProcessHistorics,
    ProcessHistoricMotors,
    SystemPositions,
  ],
)
class SystemDatabase extends _$SystemDatabase {
  SystemDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'robotic_arm_system',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(systemMachines, systemMachines.parentMachineId);
      }
      if (from < 3) {
        await m.addColumn(sensors, sensors.machineId);
        await m.addColumn(processMotors, processMotors.speed);
        await m.addColumn(processServos, processServos.speed);
        await customStatement(
          'UPDATE process_motors '
          'SET speed = (SELECT speed FROM motors '
          'WHERE motors.id = process_motors.motor_id) '
          'WHERE EXISTS (SELECT 1 FROM motors '
          'WHERE motors.id = process_motors.motor_id)',
        );
      }
      if (from < 4) {
        await m.addColumn(processes, processes.machineId);
      }
      if (from < 5) {
        await m.addColumn(processes, processes.mqttTopic);
        await m.addColumn(processes, processes.mqttExpectedMessage);
      }
    },
  );
}

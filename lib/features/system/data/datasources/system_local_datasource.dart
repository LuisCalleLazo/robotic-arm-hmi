import 'package:drift/drift.dart';

import '../../domain/entities/motor.dart';
import '../../domain/entities/process.dart' as system;
import '../../domain/entities/process_historic.dart';
import '../../domain/entities/process_historic_motors.dart';
import '../../domain/entities/process_motors.dart' as system;
import '../../domain/entities/process_servo.dart';
import '../../domain/entities/sensor.dart';
import '../../domain/entities/servo.dart';
import '../../domain/entities/system_machine.dart';
import '../../domain/entities/system_position.dart';
import '../database/system_database.dart' hide ProcessHistoricMotors;
import '../database/system_database_manager.dart';

class SystemLocalDataSource {
  SystemLocalDataSource(this._databaseManager);

  final SystemDatabaseManager _databaseManager;

  Future<SystemMachine?> getMachine(int id) async {
    final db = await _databaseManager.getDatabase();
    final row = await (db.select(
      db.systemMachines,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null
        ? null
        : SystemMachine(
            id: row.id,
            name: row.name,
            type: row.type,
            parentMachineId: row.parentMachineId,
          );
  }

  Future<List<SystemMachine>> getMachines() async {
    final db = await _databaseManager.getDatabase();
    final rows = await db.select(db.systemMachines).get();
    return rows
        .map(
          (row) => SystemMachine(
            id: row.id,
            name: row.name,
            type: row.type,
            parentMachineId: row.parentMachineId,
          ),
        )
        .toList();
  }

  Future<void> saveMachine(SystemMachine machine) async {
    final db = await _databaseManager.getDatabase();
    await db
        .into(db.systemMachines)
        .insertOnConflictUpdate(
          SystemMachinesCompanion.insert(
            id: Value(machine.id),
            name: machine.name,
            type: machine.type,
            parentMachineId: Value(machine.parentMachineId),
          ),
        );
  }

  Future<void> deleteMachine(int id) async {
    final db = await _databaseManager.getDatabase();
    await (db.delete(
      db.systemMachines,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<void> deleteMachineTree(int id) async {
    final db = await _databaseManager.getDatabase();
    await db.transaction(() async {
      final children = await (db.select(
        db.systemMachines,
      )..where((table) => table.parentMachineId.equals(id))).get();
      final machineIds = [id, ...children.map((machine) => machine.id)];
      await (db.delete(
        db.motors,
      )..where((table) => table.systemMachineId.isIn(machineIds))).go();
      await (db.delete(
        db.servos,
      )..where((table) => table.machineId.isIn(machineIds))).go();
      await (db.delete(
        db.systemMachines,
      )..where((table) => table.parentMachineId.equals(id))).go();
      await (db.delete(
        db.systemMachines,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  Future<List<system.Process>> getProcesses() async {
    final db = await _databaseManager.getDatabase();
    final rows = await db.select(db.processes).get();
    return rows
        .map(
          (row) => system.Process(
            id: row.id,
            name: row.name,
            order: row.order,
            activationSensorId: row.activationSensorId,
          ),
        )
        .toList();
  }

  Future<void> saveProcess(system.Process process) async {
    final db = await _databaseManager.getDatabase();
    await db
        .into(db.processes)
        .insertOnConflictUpdate(
          ProcessesCompanion.insert(
            id: Value(process.id),
            name: process.name,
            order: process.order,
            activationSensorId: Value(process.activationSensorId),
          ),
        );
  }

  Future<void> deleteProcess(int id) async {
    final db = await _databaseManager.getDatabase();
    await (db.delete(db.processes)..where((table) => table.id.equals(id))).go();
  }

  Future<List<Sensor>> getSensors() async {
    final db = await _databaseManager.getDatabase();
    final rows = await db.select(db.sensors).get();
    return rows
        .map((row) => Sensor(id: row.id, key: row.key, name: row.name))
        .toList();
  }

  Future<void> saveSensor(Sensor sensor) async {
    final db = await _databaseManager.getDatabase();
    await db
        .into(db.sensors)
        .insertOnConflictUpdate(
          SensorsCompanion.insert(
            id: Value(sensor.id),
            key: sensor.key,
            name: sensor.name,
          ),
        );
  }

  Future<void> deleteSensor(int id) async {
    final db = await _databaseManager.getDatabase();
    await (db.delete(db.sensors)..where((table) => table.id.equals(id))).go();
  }

  Future<List<Motor>> getMotors() async {
    final db = await _databaseManager.getDatabase();
    final rows = await db.select(db.motors).get();
    return rows
        .map(
          (row) => Motor(
            id: row.id,
            systemMachineId: row.systemMachineId,
            key: row.key,
            keySensorRight: row.keySensorRight,
            keySensorLeft: row.keySensorLeft,
            speed: row.speed,
            maxStepsRight: row.maxStepsRight,
            maxStepsLeft: row.maxStepsLeft,
          ),
        )
        .toList();
  }

  Future<void> saveMotor(Motor motor) async {
    final db = await _databaseManager.getDatabase();
    await db
        .into(db.motors)
        .insertOnConflictUpdate(
          MotorsCompanion.insert(
            id: Value(motor.id),
            systemMachineId: motor.systemMachineId,
            key: motor.key,
            keySensorRight: Value(motor.keySensorRight),
            keySensorLeft: Value(motor.keySensorLeft),
            speed: motor.speed,
            maxStepsRight: Value(motor.maxStepsRight),
            maxStepsLeft: Value(motor.maxStepsLeft),
          ),
        );
  }

  Future<List<Servo>> getServos() async {
    final db = await _databaseManager.getDatabase();
    final rows = await db.select(db.servos).get();
    return rows
        .map(
          (row) => Servo(
            id: row.id,
            machineId: row.machineId,
            key: row.key,
            maxOpen: row.maxOpen,
          ),
        )
        .toList();
  }

  Future<void> saveServo(Servo servo) async {
    final db = await _databaseManager.getDatabase();
    await db
        .into(db.servos)
        .insertOnConflictUpdate(
          ServosCompanion.insert(
            id: Value(servo.id),
            machineId: servo.machineId,
            key: servo.key,
            maxOpen: servo.maxOpen,
          ),
        );
  }

  Future<List<system.ProcessMotors>> getProcessMotors(int processId) async {
    final db = await _databaseManager.getDatabase();
    final rows =
        await (db.select(db.processMotors)
              ..where((table) => table.processId.equals(processId))
              ..orderBy([(table) => OrderingTerm.asc(table.order)]))
            .get();
    return rows
        .map(
          (row) => system.ProcessMotors(
            id: row.id,
            processId: row.processId,
            motorId: row.motorId,
            name: row.name,
            order: row.order,
            steps: row.steps,
          ),
        )
        .toList();
  }

  Future<void> saveProcessMotor(system.ProcessMotors processMotor) async {
    final db = await _databaseManager.getDatabase();
    await db
        .into(db.processMotors)
        .insertOnConflictUpdate(
          ProcessMotorsCompanion.insert(
            id: Value(processMotor.id),
            processId: processMotor.processId,
            motorId: processMotor.motorId,
            name: processMotor.name,
            order: processMotor.order,
            steps: processMotor.steps,
          ),
        );
  }

  Future<List<ProcessServo>> getProcessServos(int processId) async {
    final db = await _databaseManager.getDatabase();
    final rows =
        await (db.select(db.processServos)
              ..where((table) => table.processId.equals(processId))
              ..orderBy([(table) => OrderingTerm.asc(table.order)]))
            .get();
    return rows
        .map(
          (row) => ProcessServo(
            id: row.id,
            processId: row.processId,
            servoId: row.servoId,
            name: row.name,
            order: row.order,
            openValue: row.openValue,
          ),
        )
        .toList();
  }

  Future<void> saveProcessServo(ProcessServo processServo) async {
    final db = await _databaseManager.getDatabase();
    await db
        .into(db.processServos)
        .insertOnConflictUpdate(
          ProcessServosCompanion.insert(
            id: Value(processServo.id),
            processId: processServo.processId,
            servoId: processServo.servoId,
            name: processServo.name,
            order: processServo.order,
            openValue: processServo.openValue,
          ),
        );
  }

  Future<List<SystemPosition>> getSystemPositions() async {
    final db = await _databaseManager.getDatabase();
    final rows = await db.select(db.systemPositions).get();
    return rows
        .map(
          (row) => SystemPosition(
            id: row.id,
            number: row.number,
            type: row.type,
            systemMachineId: row.systemMachineId,
          ),
        )
        .toList();
  }

  Future<void> saveSystemPosition(SystemPosition position) async {
    final db = await _databaseManager.getDatabase();
    await db
        .into(db.systemPositions)
        .insertOnConflictUpdate(
          SystemPositionsCompanion.insert(
            id: Value(position.id),
            number: position.number,
            type: position.type,
            systemMachineId: position.systemMachineId,
          ),
        );
  }

  Future<List<ProcessHistoric>> getProcessHistorics(int processId) async {
    final db = await _databaseManager.getDatabase();
    final rows =
        await (db.select(db.processHistorics)
              ..where((table) => table.processId.equals(processId))
              ..orderBy([(table) => OrderingTerm.desc(table.startTime)]))
            .get();
    return rows
        .map(
          (row) => ProcessHistoric(
            id: row.id,
            processId: row.processId,
            startTime: row.startTime,
            endTime: row.endTime,
            stopProcess: row.stopProcess,
            stopKey: row.stopKey,
            finishProcess: row.finishProcess,
          ),
        )
        .toList();
  }

  Future<void> saveProcessHistoric(ProcessHistoric historic) async {
    final db = await _databaseManager.getDatabase();
    await db
        .into(db.processHistorics)
        .insertOnConflictUpdate(
          ProcessHistoricsCompanion.insert(
            id: Value(historic.id),
            processId: historic.processId,
            startTime: historic.startTime,
            endTime: Value(historic.endTime),
            stopProcess: Value(historic.stopProcess),
            stopKey: Value(historic.stopKey),
            finishProcess: historic.finishProcess,
          ),
        );
  }

  Future<List<ProcessHistoricMotors>> getProcessHistoricMotors(
    int processMotorId,
  ) async {
    final db = await _databaseManager.getDatabase();
    final rows =
        await (db.select(db.processHistoricMotors)
              ..where((table) => table.processMotorId.equals(processMotorId))
              ..orderBy([(table) => OrderingTerm.desc(table.startTime)]))
            .get();
    return rows
        .map(
          (row) => ProcessHistoricMotors(
            id: row.id,
            processMotorId: row.processMotorId,
            startTime: row.startTime,
            endTime: row.endTime,
            steps: row.steps,
            speed: row.speed,
          ),
        )
        .toList();
  }

  Future<void> saveProcessHistoricMotor(
    ProcessHistoricMotors historicMotor,
  ) async {
    final db = await _databaseManager.getDatabase();
    await db
        .into(db.processHistoricMotors)
        .insertOnConflictUpdate(
          ProcessHistoricMotorsCompanion.insert(
            id: Value(historicMotor.id),
            processMotorId: historicMotor.processMotorId,
            startTime: historicMotor.startTime,
            endTime: Value(historicMotor.endTime),
            steps: historicMotor.steps,
            speed: historicMotor.speed,
          ),
        );
  }
}

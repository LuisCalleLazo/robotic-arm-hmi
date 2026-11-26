// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_database.dart';

// ignore_for_file: type=lint
class $SystemMachinesTable extends SystemMachines
    with TableInfo<$SystemMachinesTable, SystemMachineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SystemMachinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentMachineIdMeta = const VerificationMeta(
    'parentMachineId',
  );
  @override
  late final GeneratedColumn<int> parentMachineId = GeneratedColumn<int>(
    'parent_machine_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES system_machines (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, type, parentMachineId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'system_machines';
  @override
  VerificationContext validateIntegrity(
    Insertable<SystemMachineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('parent_machine_id')) {
      context.handle(
        _parentMachineIdMeta,
        parentMachineId.isAcceptableOrUnknown(
          data['parent_machine_id']!,
          _parentMachineIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SystemMachineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SystemMachineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      parentMachineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_machine_id'],
      ),
    );
  }

  @override
  $SystemMachinesTable createAlias(String alias) {
    return $SystemMachinesTable(attachedDatabase, alias);
  }
}

class SystemMachineRow extends DataClass
    implements Insertable<SystemMachineRow> {
  final int id;
  final String name;
  final String type;
  final int? parentMachineId;
  const SystemMachineRow({
    required this.id,
    required this.name,
    required this.type,
    this.parentMachineId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || parentMachineId != null) {
      map['parent_machine_id'] = Variable<int>(parentMachineId);
    }
    return map;
  }

  SystemMachinesCompanion toCompanion(bool nullToAbsent) {
    return SystemMachinesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      parentMachineId: parentMachineId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentMachineId),
    );
  }

  factory SystemMachineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SystemMachineRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      parentMachineId: serializer.fromJson<int?>(json['parentMachineId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'parentMachineId': serializer.toJson<int?>(parentMachineId),
    };
  }

  SystemMachineRow copyWith({
    int? id,
    String? name,
    String? type,
    Value<int?> parentMachineId = const Value.absent(),
  }) => SystemMachineRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    parentMachineId: parentMachineId.present
        ? parentMachineId.value
        : this.parentMachineId,
  );
  SystemMachineRow copyWithCompanion(SystemMachinesCompanion data) {
    return SystemMachineRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      parentMachineId: data.parentMachineId.present
          ? data.parentMachineId.value
          : this.parentMachineId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SystemMachineRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('parentMachineId: $parentMachineId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, parentMachineId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SystemMachineRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.parentMachineId == this.parentMachineId);
}

class SystemMachinesCompanion extends UpdateCompanion<SystemMachineRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<int?> parentMachineId;
  const SystemMachinesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.parentMachineId = const Value.absent(),
  });
  SystemMachinesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String type,
    this.parentMachineId = const Value.absent(),
  }) : name = Value(name),
       type = Value(type);
  static Insertable<SystemMachineRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? parentMachineId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (parentMachineId != null) 'parent_machine_id': parentMachineId,
    });
  }

  SystemMachinesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? type,
    Value<int?>? parentMachineId,
  }) {
    return SystemMachinesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentMachineId: parentMachineId ?? this.parentMachineId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (parentMachineId.present) {
      map['parent_machine_id'] = Variable<int>(parentMachineId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SystemMachinesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('parentMachineId: $parentMachineId')
          ..write(')'))
        .toString();
  }
}

class $MotorsTable extends Motors with TableInfo<$MotorsTable, MotorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MotorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _systemMachineIdMeta = const VerificationMeta(
    'systemMachineId',
  );
  @override
  late final GeneratedColumn<int> systemMachineId = GeneratedColumn<int>(
    'system_machine_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES system_machines (id)',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keySensorRightMeta = const VerificationMeta(
    'keySensorRight',
  );
  @override
  late final GeneratedColumn<String> keySensorRight = GeneratedColumn<String>(
    'key_sensor_right',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keySensorLeftMeta = const VerificationMeta(
    'keySensorLeft',
  );
  @override
  late final GeneratedColumn<String> keySensorLeft = GeneratedColumn<String>(
    'key_sensor_left',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxStepsRightMeta = const VerificationMeta(
    'maxStepsRight',
  );
  @override
  late final GeneratedColumn<String> maxStepsRight = GeneratedColumn<String>(
    'max_steps_right',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxStepsLeftMeta = const VerificationMeta(
    'maxStepsLeft',
  );
  @override
  late final GeneratedColumn<String> maxStepsLeft = GeneratedColumn<String>(
    'max_steps_left',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    systemMachineId,
    key,
    keySensorRight,
    keySensorLeft,
    speed,
    maxStepsRight,
    maxStepsLeft,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'motors';
  @override
  VerificationContext validateIntegrity(
    Insertable<MotorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('system_machine_id')) {
      context.handle(
        _systemMachineIdMeta,
        systemMachineId.isAcceptableOrUnknown(
          data['system_machine_id']!,
          _systemMachineIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_systemMachineIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('key_sensor_right')) {
      context.handle(
        _keySensorRightMeta,
        keySensorRight.isAcceptableOrUnknown(
          data['key_sensor_right']!,
          _keySensorRightMeta,
        ),
      );
    }
    if (data.containsKey('key_sensor_left')) {
      context.handle(
        _keySensorLeftMeta,
        keySensorLeft.isAcceptableOrUnknown(
          data['key_sensor_left']!,
          _keySensorLeftMeta,
        ),
      );
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    } else if (isInserting) {
      context.missing(_speedMeta);
    }
    if (data.containsKey('max_steps_right')) {
      context.handle(
        _maxStepsRightMeta,
        maxStepsRight.isAcceptableOrUnknown(
          data['max_steps_right']!,
          _maxStepsRightMeta,
        ),
      );
    }
    if (data.containsKey('max_steps_left')) {
      context.handle(
        _maxStepsLeftMeta,
        maxStepsLeft.isAcceptableOrUnknown(
          data['max_steps_left']!,
          _maxStepsLeftMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MotorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MotorRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      systemMachineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}system_machine_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      keySensorRight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_sensor_right'],
      ),
      keySensorLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_sensor_left'],
      ),
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      )!,
      maxStepsRight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}max_steps_right'],
      ),
      maxStepsLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}max_steps_left'],
      ),
    );
  }

  @override
  $MotorsTable createAlias(String alias) {
    return $MotorsTable(attachedDatabase, alias);
  }
}

class MotorRow extends DataClass implements Insertable<MotorRow> {
  final int id;
  final int systemMachineId;
  final String key;
  final String? keySensorRight;
  final String? keySensorLeft;
  final double speed;
  final String? maxStepsRight;
  final String? maxStepsLeft;
  const MotorRow({
    required this.id,
    required this.systemMachineId,
    required this.key,
    this.keySensorRight,
    this.keySensorLeft,
    required this.speed,
    this.maxStepsRight,
    this.maxStepsLeft,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['system_machine_id'] = Variable<int>(systemMachineId);
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || keySensorRight != null) {
      map['key_sensor_right'] = Variable<String>(keySensorRight);
    }
    if (!nullToAbsent || keySensorLeft != null) {
      map['key_sensor_left'] = Variable<String>(keySensorLeft);
    }
    map['speed'] = Variable<double>(speed);
    if (!nullToAbsent || maxStepsRight != null) {
      map['max_steps_right'] = Variable<String>(maxStepsRight);
    }
    if (!nullToAbsent || maxStepsLeft != null) {
      map['max_steps_left'] = Variable<String>(maxStepsLeft);
    }
    return map;
  }

  MotorsCompanion toCompanion(bool nullToAbsent) {
    return MotorsCompanion(
      id: Value(id),
      systemMachineId: Value(systemMachineId),
      key: Value(key),
      keySensorRight: keySensorRight == null && nullToAbsent
          ? const Value.absent()
          : Value(keySensorRight),
      keySensorLeft: keySensorLeft == null && nullToAbsent
          ? const Value.absent()
          : Value(keySensorLeft),
      speed: Value(speed),
      maxStepsRight: maxStepsRight == null && nullToAbsent
          ? const Value.absent()
          : Value(maxStepsRight),
      maxStepsLeft: maxStepsLeft == null && nullToAbsent
          ? const Value.absent()
          : Value(maxStepsLeft),
    );
  }

  factory MotorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MotorRow(
      id: serializer.fromJson<int>(json['id']),
      systemMachineId: serializer.fromJson<int>(json['systemMachineId']),
      key: serializer.fromJson<String>(json['key']),
      keySensorRight: serializer.fromJson<String?>(json['keySensorRight']),
      keySensorLeft: serializer.fromJson<String?>(json['keySensorLeft']),
      speed: serializer.fromJson<double>(json['speed']),
      maxStepsRight: serializer.fromJson<String?>(json['maxStepsRight']),
      maxStepsLeft: serializer.fromJson<String?>(json['maxStepsLeft']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'systemMachineId': serializer.toJson<int>(systemMachineId),
      'key': serializer.toJson<String>(key),
      'keySensorRight': serializer.toJson<String?>(keySensorRight),
      'keySensorLeft': serializer.toJson<String?>(keySensorLeft),
      'speed': serializer.toJson<double>(speed),
      'maxStepsRight': serializer.toJson<String?>(maxStepsRight),
      'maxStepsLeft': serializer.toJson<String?>(maxStepsLeft),
    };
  }

  MotorRow copyWith({
    int? id,
    int? systemMachineId,
    String? key,
    Value<String?> keySensorRight = const Value.absent(),
    Value<String?> keySensorLeft = const Value.absent(),
    double? speed,
    Value<String?> maxStepsRight = const Value.absent(),
    Value<String?> maxStepsLeft = const Value.absent(),
  }) => MotorRow(
    id: id ?? this.id,
    systemMachineId: systemMachineId ?? this.systemMachineId,
    key: key ?? this.key,
    keySensorRight: keySensorRight.present
        ? keySensorRight.value
        : this.keySensorRight,
    keySensorLeft: keySensorLeft.present
        ? keySensorLeft.value
        : this.keySensorLeft,
    speed: speed ?? this.speed,
    maxStepsRight: maxStepsRight.present
        ? maxStepsRight.value
        : this.maxStepsRight,
    maxStepsLeft: maxStepsLeft.present ? maxStepsLeft.value : this.maxStepsLeft,
  );
  MotorRow copyWithCompanion(MotorsCompanion data) {
    return MotorRow(
      id: data.id.present ? data.id.value : this.id,
      systemMachineId: data.systemMachineId.present
          ? data.systemMachineId.value
          : this.systemMachineId,
      key: data.key.present ? data.key.value : this.key,
      keySensorRight: data.keySensorRight.present
          ? data.keySensorRight.value
          : this.keySensorRight,
      keySensorLeft: data.keySensorLeft.present
          ? data.keySensorLeft.value
          : this.keySensorLeft,
      speed: data.speed.present ? data.speed.value : this.speed,
      maxStepsRight: data.maxStepsRight.present
          ? data.maxStepsRight.value
          : this.maxStepsRight,
      maxStepsLeft: data.maxStepsLeft.present
          ? data.maxStepsLeft.value
          : this.maxStepsLeft,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MotorRow(')
          ..write('id: $id, ')
          ..write('systemMachineId: $systemMachineId, ')
          ..write('key: $key, ')
          ..write('keySensorRight: $keySensorRight, ')
          ..write('keySensorLeft: $keySensorLeft, ')
          ..write('speed: $speed, ')
          ..write('maxStepsRight: $maxStepsRight, ')
          ..write('maxStepsLeft: $maxStepsLeft')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    systemMachineId,
    key,
    keySensorRight,
    keySensorLeft,
    speed,
    maxStepsRight,
    maxStepsLeft,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MotorRow &&
          other.id == this.id &&
          other.systemMachineId == this.systemMachineId &&
          other.key == this.key &&
          other.keySensorRight == this.keySensorRight &&
          other.keySensorLeft == this.keySensorLeft &&
          other.speed == this.speed &&
          other.maxStepsRight == this.maxStepsRight &&
          other.maxStepsLeft == this.maxStepsLeft);
}

class MotorsCompanion extends UpdateCompanion<MotorRow> {
  final Value<int> id;
  final Value<int> systemMachineId;
  final Value<String> key;
  final Value<String?> keySensorRight;
  final Value<String?> keySensorLeft;
  final Value<double> speed;
  final Value<String?> maxStepsRight;
  final Value<String?> maxStepsLeft;
  const MotorsCompanion({
    this.id = const Value.absent(),
    this.systemMachineId = const Value.absent(),
    this.key = const Value.absent(),
    this.keySensorRight = const Value.absent(),
    this.keySensorLeft = const Value.absent(),
    this.speed = const Value.absent(),
    this.maxStepsRight = const Value.absent(),
    this.maxStepsLeft = const Value.absent(),
  });
  MotorsCompanion.insert({
    this.id = const Value.absent(),
    required int systemMachineId,
    required String key,
    this.keySensorRight = const Value.absent(),
    this.keySensorLeft = const Value.absent(),
    required double speed,
    this.maxStepsRight = const Value.absent(),
    this.maxStepsLeft = const Value.absent(),
  }) : systemMachineId = Value(systemMachineId),
       key = Value(key),
       speed = Value(speed);
  static Insertable<MotorRow> custom({
    Expression<int>? id,
    Expression<int>? systemMachineId,
    Expression<String>? key,
    Expression<String>? keySensorRight,
    Expression<String>? keySensorLeft,
    Expression<double>? speed,
    Expression<String>? maxStepsRight,
    Expression<String>? maxStepsLeft,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (systemMachineId != null) 'system_machine_id': systemMachineId,
      if (key != null) 'key': key,
      if (keySensorRight != null) 'key_sensor_right': keySensorRight,
      if (keySensorLeft != null) 'key_sensor_left': keySensorLeft,
      if (speed != null) 'speed': speed,
      if (maxStepsRight != null) 'max_steps_right': maxStepsRight,
      if (maxStepsLeft != null) 'max_steps_left': maxStepsLeft,
    });
  }

  MotorsCompanion copyWith({
    Value<int>? id,
    Value<int>? systemMachineId,
    Value<String>? key,
    Value<String?>? keySensorRight,
    Value<String?>? keySensorLeft,
    Value<double>? speed,
    Value<String?>? maxStepsRight,
    Value<String?>? maxStepsLeft,
  }) {
    return MotorsCompanion(
      id: id ?? this.id,
      systemMachineId: systemMachineId ?? this.systemMachineId,
      key: key ?? this.key,
      keySensorRight: keySensorRight ?? this.keySensorRight,
      keySensorLeft: keySensorLeft ?? this.keySensorLeft,
      speed: speed ?? this.speed,
      maxStepsRight: maxStepsRight ?? this.maxStepsRight,
      maxStepsLeft: maxStepsLeft ?? this.maxStepsLeft,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (systemMachineId.present) {
      map['system_machine_id'] = Variable<int>(systemMachineId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (keySensorRight.present) {
      map['key_sensor_right'] = Variable<String>(keySensorRight.value);
    }
    if (keySensorLeft.present) {
      map['key_sensor_left'] = Variable<String>(keySensorLeft.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (maxStepsRight.present) {
      map['max_steps_right'] = Variable<String>(maxStepsRight.value);
    }
    if (maxStepsLeft.present) {
      map['max_steps_left'] = Variable<String>(maxStepsLeft.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MotorsCompanion(')
          ..write('id: $id, ')
          ..write('systemMachineId: $systemMachineId, ')
          ..write('key: $key, ')
          ..write('keySensorRight: $keySensorRight, ')
          ..write('keySensorLeft: $keySensorLeft, ')
          ..write('speed: $speed, ')
          ..write('maxStepsRight: $maxStepsRight, ')
          ..write('maxStepsLeft: $maxStepsLeft')
          ..write(')'))
        .toString();
  }
}

class $ServosTable extends Servos with TableInfo<$ServosTable, ServoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _machineIdMeta = const VerificationMeta(
    'machineId',
  );
  @override
  late final GeneratedColumn<int> machineId = GeneratedColumn<int>(
    'machine_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES system_machines (id)',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxOpenMeta = const VerificationMeta(
    'maxOpen',
  );
  @override
  late final GeneratedColumn<double> maxOpen = GeneratedColumn<double>(
    'max_open',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, machineId, key, maxOpen];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'servos';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('machine_id')) {
      context.handle(
        _machineIdMeta,
        machineId.isAcceptableOrUnknown(data['machine_id']!, _machineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_machineIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('max_open')) {
      context.handle(
        _maxOpenMeta,
        maxOpen.isAcceptableOrUnknown(data['max_open']!, _maxOpenMeta),
      );
    } else if (isInserting) {
      context.missing(_maxOpenMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      machineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}machine_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      maxOpen: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_open'],
      )!,
    );
  }

  @override
  $ServosTable createAlias(String alias) {
    return $ServosTable(attachedDatabase, alias);
  }
}

class ServoRow extends DataClass implements Insertable<ServoRow> {
  final int id;
  final int machineId;
  final String key;
  final double maxOpen;
  const ServoRow({
    required this.id,
    required this.machineId,
    required this.key,
    required this.maxOpen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['machine_id'] = Variable<int>(machineId);
    map['key'] = Variable<String>(key);
    map['max_open'] = Variable<double>(maxOpen);
    return map;
  }

  ServosCompanion toCompanion(bool nullToAbsent) {
    return ServosCompanion(
      id: Value(id),
      machineId: Value(machineId),
      key: Value(key),
      maxOpen: Value(maxOpen),
    );
  }

  factory ServoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServoRow(
      id: serializer.fromJson<int>(json['id']),
      machineId: serializer.fromJson<int>(json['machineId']),
      key: serializer.fromJson<String>(json['key']),
      maxOpen: serializer.fromJson<double>(json['maxOpen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'machineId': serializer.toJson<int>(machineId),
      'key': serializer.toJson<String>(key),
      'maxOpen': serializer.toJson<double>(maxOpen),
    };
  }

  ServoRow copyWith({int? id, int? machineId, String? key, double? maxOpen}) =>
      ServoRow(
        id: id ?? this.id,
        machineId: machineId ?? this.machineId,
        key: key ?? this.key,
        maxOpen: maxOpen ?? this.maxOpen,
      );
  ServoRow copyWithCompanion(ServosCompanion data) {
    return ServoRow(
      id: data.id.present ? data.id.value : this.id,
      machineId: data.machineId.present ? data.machineId.value : this.machineId,
      key: data.key.present ? data.key.value : this.key,
      maxOpen: data.maxOpen.present ? data.maxOpen.value : this.maxOpen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServoRow(')
          ..write('id: $id, ')
          ..write('machineId: $machineId, ')
          ..write('key: $key, ')
          ..write('maxOpen: $maxOpen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, machineId, key, maxOpen);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServoRow &&
          other.id == this.id &&
          other.machineId == this.machineId &&
          other.key == this.key &&
          other.maxOpen == this.maxOpen);
}

class ServosCompanion extends UpdateCompanion<ServoRow> {
  final Value<int> id;
  final Value<int> machineId;
  final Value<String> key;
  final Value<double> maxOpen;
  const ServosCompanion({
    this.id = const Value.absent(),
    this.machineId = const Value.absent(),
    this.key = const Value.absent(),
    this.maxOpen = const Value.absent(),
  });
  ServosCompanion.insert({
    this.id = const Value.absent(),
    required int machineId,
    required String key,
    required double maxOpen,
  }) : machineId = Value(machineId),
       key = Value(key),
       maxOpen = Value(maxOpen);
  static Insertable<ServoRow> custom({
    Expression<int>? id,
    Expression<int>? machineId,
    Expression<String>? key,
    Expression<double>? maxOpen,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (machineId != null) 'machine_id': machineId,
      if (key != null) 'key': key,
      if (maxOpen != null) 'max_open': maxOpen,
    });
  }

  ServosCompanion copyWith({
    Value<int>? id,
    Value<int>? machineId,
    Value<String>? key,
    Value<double>? maxOpen,
  }) {
    return ServosCompanion(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      key: key ?? this.key,
      maxOpen: maxOpen ?? this.maxOpen,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (machineId.present) {
      map['machine_id'] = Variable<int>(machineId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (maxOpen.present) {
      map['max_open'] = Variable<double>(maxOpen.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServosCompanion(')
          ..write('id: $id, ')
          ..write('machineId: $machineId, ')
          ..write('key: $key, ')
          ..write('maxOpen: $maxOpen')
          ..write(')'))
        .toString();
  }
}

class $SensorsTable extends Sensors with TableInfo<$SensorsTable, SensorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SensorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _machineIdMeta = const VerificationMeta(
    'machineId',
  );
  @override
  late final GeneratedColumn<int> machineId = GeneratedColumn<int>(
    'machine_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES system_machines (id)',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, machineId, key, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sensors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SensorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('machine_id')) {
      context.handle(
        _machineIdMeta,
        machineId.isAcceptableOrUnknown(data['machine_id']!, _machineIdMeta),
      );
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SensorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SensorRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      machineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}machine_id'],
      ),
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $SensorsTable createAlias(String alias) {
    return $SensorsTable(attachedDatabase, alias);
  }
}

class SensorRow extends DataClass implements Insertable<SensorRow> {
  final int id;
  final int? machineId;
  final String key;
  final String name;
  const SensorRow({
    required this.id,
    this.machineId,
    required this.key,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || machineId != null) {
      map['machine_id'] = Variable<int>(machineId);
    }
    map['key'] = Variable<String>(key);
    map['name'] = Variable<String>(name);
    return map;
  }

  SensorsCompanion toCompanion(bool nullToAbsent) {
    return SensorsCompanion(
      id: Value(id),
      machineId: machineId == null && nullToAbsent
          ? const Value.absent()
          : Value(machineId),
      key: Value(key),
      name: Value(name),
    );
  }

  factory SensorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SensorRow(
      id: serializer.fromJson<int>(json['id']),
      machineId: serializer.fromJson<int?>(json['machineId']),
      key: serializer.fromJson<String>(json['key']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'machineId': serializer.toJson<int?>(machineId),
      'key': serializer.toJson<String>(key),
      'name': serializer.toJson<String>(name),
    };
  }

  SensorRow copyWith({
    int? id,
    Value<int?> machineId = const Value.absent(),
    String? key,
    String? name,
  }) => SensorRow(
    id: id ?? this.id,
    machineId: machineId.present ? machineId.value : this.machineId,
    key: key ?? this.key,
    name: name ?? this.name,
  );
  SensorRow copyWithCompanion(SensorsCompanion data) {
    return SensorRow(
      id: data.id.present ? data.id.value : this.id,
      machineId: data.machineId.present ? data.machineId.value : this.machineId,
      key: data.key.present ? data.key.value : this.key,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SensorRow(')
          ..write('id: $id, ')
          ..write('machineId: $machineId, ')
          ..write('key: $key, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, machineId, key, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SensorRow &&
          other.id == this.id &&
          other.machineId == this.machineId &&
          other.key == this.key &&
          other.name == this.name);
}

class SensorsCompanion extends UpdateCompanion<SensorRow> {
  final Value<int> id;
  final Value<int?> machineId;
  final Value<String> key;
  final Value<String> name;
  const SensorsCompanion({
    this.id = const Value.absent(),
    this.machineId = const Value.absent(),
    this.key = const Value.absent(),
    this.name = const Value.absent(),
  });
  SensorsCompanion.insert({
    this.id = const Value.absent(),
    this.machineId = const Value.absent(),
    required String key,
    required String name,
  }) : key = Value(key),
       name = Value(name);
  static Insertable<SensorRow> custom({
    Expression<int>? id,
    Expression<int>? machineId,
    Expression<String>? key,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (machineId != null) 'machine_id': machineId,
      if (key != null) 'key': key,
      if (name != null) 'name': name,
    });
  }

  SensorsCompanion copyWith({
    Value<int>? id,
    Value<int?>? machineId,
    Value<String>? key,
    Value<String>? name,
  }) {
    return SensorsCompanion(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      key: key ?? this.key,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (machineId.present) {
      map['machine_id'] = Variable<int>(machineId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SensorsCompanion(')
          ..write('id: $id, ')
          ..write('machineId: $machineId, ')
          ..write('key: $key, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $ProcessesTable extends Processes
    with TableInfo<$ProcessesTable, ProcessRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProcessesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _machineIdMeta = const VerificationMeta(
    'machineId',
  );
  @override
  late final GeneratedColumn<int> machineId = GeneratedColumn<int>(
    'machine_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES system_machines (id)',
    ),
  );
  static const VerificationMeta _activationSensorIdMeta =
      const VerificationMeta('activationSensorId');
  @override
  late final GeneratedColumn<int> activationSensorId = GeneratedColumn<int>(
    'activation_sensor_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sensors (id)',
    ),
  );
  static const VerificationMeta _mqttTopicMeta = const VerificationMeta(
    'mqttTopic',
  );
  @override
  late final GeneratedColumn<String> mqttTopic = GeneratedColumn<String>(
    'mqtt_topic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mqttExpectedMessageMeta =
      const VerificationMeta('mqttExpectedMessage');
  @override
  late final GeneratedColumn<String> mqttExpectedMessage =
      GeneratedColumn<String>(
        'mqtt_expected_message',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _mqttCompletionTopicMeta =
      const VerificationMeta('mqttCompletionTopic');
  @override
  late final GeneratedColumn<String> mqttCompletionTopic =
      GeneratedColumn<String>(
        'mqtt_completion_topic',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _mqttCompletionMessageMeta =
      const VerificationMeta('mqttCompletionMessage');
  @override
  late final GeneratedColumn<String> mqttCompletionMessage =
      GeneratedColumn<String>(
        'mqtt_completion_message',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    order,
    machineId,
    activationSensorId,
    mqttTopic,
    mqttExpectedMessage,
    mqttCompletionTopic,
    mqttCompletionMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'processes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProcessRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('machine_id')) {
      context.handle(
        _machineIdMeta,
        machineId.isAcceptableOrUnknown(data['machine_id']!, _machineIdMeta),
      );
    }
    if (data.containsKey('activation_sensor_id')) {
      context.handle(
        _activationSensorIdMeta,
        activationSensorId.isAcceptableOrUnknown(
          data['activation_sensor_id']!,
          _activationSensorIdMeta,
        ),
      );
    }
    if (data.containsKey('mqtt_topic')) {
      context.handle(
        _mqttTopicMeta,
        mqttTopic.isAcceptableOrUnknown(data['mqtt_topic']!, _mqttTopicMeta),
      );
    }
    if (data.containsKey('mqtt_expected_message')) {
      context.handle(
        _mqttExpectedMessageMeta,
        mqttExpectedMessage.isAcceptableOrUnknown(
          data['mqtt_expected_message']!,
          _mqttExpectedMessageMeta,
        ),
      );
    }
    if (data.containsKey('mqtt_completion_topic')) {
      context.handle(
        _mqttCompletionTopicMeta,
        mqttCompletionTopic.isAcceptableOrUnknown(
          data['mqtt_completion_topic']!,
          _mqttCompletionTopicMeta,
        ),
      );
    }
    if (data.containsKey('mqtt_completion_message')) {
      context.handle(
        _mqttCompletionMessageMeta,
        mqttCompletionMessage.isAcceptableOrUnknown(
          data['mqtt_completion_message']!,
          _mqttCompletionMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProcessRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcessRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      machineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}machine_id'],
      ),
      activationSensorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activation_sensor_id'],
      ),
      mqttTopic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mqtt_topic'],
      ),
      mqttExpectedMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mqtt_expected_message'],
      ),
      mqttCompletionTopic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mqtt_completion_topic'],
      ),
      mqttCompletionMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mqtt_completion_message'],
      ),
    );
  }

  @override
  $ProcessesTable createAlias(String alias) {
    return $ProcessesTable(attachedDatabase, alias);
  }
}

class ProcessRow extends DataClass implements Insertable<ProcessRow> {
  final int id;
  final String name;
  final int order;
  final int? machineId;
  final int? activationSensorId;
  final String? mqttTopic;
  final String? mqttExpectedMessage;
  final String? mqttCompletionTopic;
  final String? mqttCompletionMessage;
  const ProcessRow({
    required this.id,
    required this.name,
    required this.order,
    this.machineId,
    this.activationSensorId,
    this.mqttTopic,
    this.mqttExpectedMessage,
    this.mqttCompletionTopic,
    this.mqttCompletionMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['order'] = Variable<int>(order);
    if (!nullToAbsent || machineId != null) {
      map['machine_id'] = Variable<int>(machineId);
    }
    if (!nullToAbsent || activationSensorId != null) {
      map['activation_sensor_id'] = Variable<int>(activationSensorId);
    }
    if (!nullToAbsent || mqttTopic != null) {
      map['mqtt_topic'] = Variable<String>(mqttTopic);
    }
    if (!nullToAbsent || mqttExpectedMessage != null) {
      map['mqtt_expected_message'] = Variable<String>(mqttExpectedMessage);
    }
    if (!nullToAbsent || mqttCompletionTopic != null) {
      map['mqtt_completion_topic'] = Variable<String>(mqttCompletionTopic);
    }
    if (!nullToAbsent || mqttCompletionMessage != null) {
      map['mqtt_completion_message'] = Variable<String>(mqttCompletionMessage);
    }
    return map;
  }

  ProcessesCompanion toCompanion(bool nullToAbsent) {
    return ProcessesCompanion(
      id: Value(id),
      name: Value(name),
      order: Value(order),
      machineId: machineId == null && nullToAbsent
          ? const Value.absent()
          : Value(machineId),
      activationSensorId: activationSensorId == null && nullToAbsent
          ? const Value.absent()
          : Value(activationSensorId),
      mqttTopic: mqttTopic == null && nullToAbsent
          ? const Value.absent()
          : Value(mqttTopic),
      mqttExpectedMessage: mqttExpectedMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(mqttExpectedMessage),
      mqttCompletionTopic: mqttCompletionTopic == null && nullToAbsent
          ? const Value.absent()
          : Value(mqttCompletionTopic),
      mqttCompletionMessage: mqttCompletionMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(mqttCompletionMessage),
    );
  }

  factory ProcessRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcessRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      order: serializer.fromJson<int>(json['order']),
      machineId: serializer.fromJson<int?>(json['machineId']),
      activationSensorId: serializer.fromJson<int?>(json['activationSensorId']),
      mqttTopic: serializer.fromJson<String?>(json['mqttTopic']),
      mqttExpectedMessage: serializer.fromJson<String?>(
        json['mqttExpectedMessage'],
      ),
      mqttCompletionTopic: serializer.fromJson<String?>(
        json['mqttCompletionTopic'],
      ),
      mqttCompletionMessage: serializer.fromJson<String?>(
        json['mqttCompletionMessage'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'order': serializer.toJson<int>(order),
      'machineId': serializer.toJson<int?>(machineId),
      'activationSensorId': serializer.toJson<int?>(activationSensorId),
      'mqttTopic': serializer.toJson<String?>(mqttTopic),
      'mqttExpectedMessage': serializer.toJson<String?>(mqttExpectedMessage),
      'mqttCompletionTopic': serializer.toJson<String?>(mqttCompletionTopic),
      'mqttCompletionMessage': serializer.toJson<String?>(
        mqttCompletionMessage,
      ),
    };
  }

  ProcessRow copyWith({
    int? id,
    String? name,
    int? order,
    Value<int?> machineId = const Value.absent(),
    Value<int?> activationSensorId = const Value.absent(),
    Value<String?> mqttTopic = const Value.absent(),
    Value<String?> mqttExpectedMessage = const Value.absent(),
    Value<String?> mqttCompletionTopic = const Value.absent(),
    Value<String?> mqttCompletionMessage = const Value.absent(),
  }) => ProcessRow(
    id: id ?? this.id,
    name: name ?? this.name,
    order: order ?? this.order,
    machineId: machineId.present ? machineId.value : this.machineId,
    activationSensorId: activationSensorId.present
        ? activationSensorId.value
        : this.activationSensorId,
    mqttTopic: mqttTopic.present ? mqttTopic.value : this.mqttTopic,
    mqttExpectedMessage: mqttExpectedMessage.present
        ? mqttExpectedMessage.value
        : this.mqttExpectedMessage,
    mqttCompletionTopic: mqttCompletionTopic.present
        ? mqttCompletionTopic.value
        : this.mqttCompletionTopic,
    mqttCompletionMessage: mqttCompletionMessage.present
        ? mqttCompletionMessage.value
        : this.mqttCompletionMessage,
  );
  ProcessRow copyWithCompanion(ProcessesCompanion data) {
    return ProcessRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      order: data.order.present ? data.order.value : this.order,
      machineId: data.machineId.present ? data.machineId.value : this.machineId,
      activationSensorId: data.activationSensorId.present
          ? data.activationSensorId.value
          : this.activationSensorId,
      mqttTopic: data.mqttTopic.present ? data.mqttTopic.value : this.mqttTopic,
      mqttExpectedMessage: data.mqttExpectedMessage.present
          ? data.mqttExpectedMessage.value
          : this.mqttExpectedMessage,
      mqttCompletionTopic: data.mqttCompletionTopic.present
          ? data.mqttCompletionTopic.value
          : this.mqttCompletionTopic,
      mqttCompletionMessage: data.mqttCompletionMessage.present
          ? data.mqttCompletionMessage.value
          : this.mqttCompletionMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcessRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('order: $order, ')
          ..write('machineId: $machineId, ')
          ..write('activationSensorId: $activationSensorId, ')
          ..write('mqttTopic: $mqttTopic, ')
          ..write('mqttExpectedMessage: $mqttExpectedMessage, ')
          ..write('mqttCompletionTopic: $mqttCompletionTopic, ')
          ..write('mqttCompletionMessage: $mqttCompletionMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    order,
    machineId,
    activationSensorId,
    mqttTopic,
    mqttExpectedMessage,
    mqttCompletionTopic,
    mqttCompletionMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcessRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.order == this.order &&
          other.machineId == this.machineId &&
          other.activationSensorId == this.activationSensorId &&
          other.mqttTopic == this.mqttTopic &&
          other.mqttExpectedMessage == this.mqttExpectedMessage &&
          other.mqttCompletionTopic == this.mqttCompletionTopic &&
          other.mqttCompletionMessage == this.mqttCompletionMessage);
}

class ProcessesCompanion extends UpdateCompanion<ProcessRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> order;
  final Value<int?> machineId;
  final Value<int?> activationSensorId;
  final Value<String?> mqttTopic;
  final Value<String?> mqttExpectedMessage;
  final Value<String?> mqttCompletionTopic;
  final Value<String?> mqttCompletionMessage;
  const ProcessesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.order = const Value.absent(),
    this.machineId = const Value.absent(),
    this.activationSensorId = const Value.absent(),
    this.mqttTopic = const Value.absent(),
    this.mqttExpectedMessage = const Value.absent(),
    this.mqttCompletionTopic = const Value.absent(),
    this.mqttCompletionMessage = const Value.absent(),
  });
  ProcessesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int order,
    this.machineId = const Value.absent(),
    this.activationSensorId = const Value.absent(),
    this.mqttTopic = const Value.absent(),
    this.mqttExpectedMessage = const Value.absent(),
    this.mqttCompletionTopic = const Value.absent(),
    this.mqttCompletionMessage = const Value.absent(),
  }) : name = Value(name),
       order = Value(order);
  static Insertable<ProcessRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? order,
    Expression<int>? machineId,
    Expression<int>? activationSensorId,
    Expression<String>? mqttTopic,
    Expression<String>? mqttExpectedMessage,
    Expression<String>? mqttCompletionTopic,
    Expression<String>? mqttCompletionMessage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (order != null) 'order': order,
      if (machineId != null) 'machine_id': machineId,
      if (activationSensorId != null)
        'activation_sensor_id': activationSensorId,
      if (mqttTopic != null) 'mqtt_topic': mqttTopic,
      if (mqttExpectedMessage != null)
        'mqtt_expected_message': mqttExpectedMessage,
      if (mqttCompletionTopic != null)
        'mqtt_completion_topic': mqttCompletionTopic,
      if (mqttCompletionMessage != null)
        'mqtt_completion_message': mqttCompletionMessage,
    });
  }

  ProcessesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? order,
    Value<int?>? machineId,
    Value<int?>? activationSensorId,
    Value<String?>? mqttTopic,
    Value<String?>? mqttExpectedMessage,
    Value<String?>? mqttCompletionTopic,
    Value<String?>? mqttCompletionMessage,
  }) {
    return ProcessesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      machineId: machineId ?? this.machineId,
      activationSensorId: activationSensorId ?? this.activationSensorId,
      mqttTopic: mqttTopic ?? this.mqttTopic,
      mqttExpectedMessage: mqttExpectedMessage ?? this.mqttExpectedMessage,
      mqttCompletionTopic: mqttCompletionTopic ?? this.mqttCompletionTopic,
      mqttCompletionMessage:
          mqttCompletionMessage ?? this.mqttCompletionMessage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (machineId.present) {
      map['machine_id'] = Variable<int>(machineId.value);
    }
    if (activationSensorId.present) {
      map['activation_sensor_id'] = Variable<int>(activationSensorId.value);
    }
    if (mqttTopic.present) {
      map['mqtt_topic'] = Variable<String>(mqttTopic.value);
    }
    if (mqttExpectedMessage.present) {
      map['mqtt_expected_message'] = Variable<String>(
        mqttExpectedMessage.value,
      );
    }
    if (mqttCompletionTopic.present) {
      map['mqtt_completion_topic'] = Variable<String>(
        mqttCompletionTopic.value,
      );
    }
    if (mqttCompletionMessage.present) {
      map['mqtt_completion_message'] = Variable<String>(
        mqttCompletionMessage.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProcessesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('order: $order, ')
          ..write('machineId: $machineId, ')
          ..write('activationSensorId: $activationSensorId, ')
          ..write('mqttTopic: $mqttTopic, ')
          ..write('mqttExpectedMessage: $mqttExpectedMessage, ')
          ..write('mqttCompletionTopic: $mqttCompletionTopic, ')
          ..write('mqttCompletionMessage: $mqttCompletionMessage')
          ..write(')'))
        .toString();
  }
}

class $ProcessMotorsTable extends ProcessMotors
    with TableInfo<$ProcessMotorsTable, ProcessMotorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProcessMotorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processIdMeta = const VerificationMeta(
    'processId',
  );
  @override
  late final GeneratedColumn<int> processId = GeneratedColumn<int>(
    'process_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES processes (id)',
    ),
  );
  static const VerificationMeta _motorIdMeta = const VerificationMeta(
    'motorId',
  );
  @override
  late final GeneratedColumn<int> motorId = GeneratedColumn<int>(
    'motor_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES motors (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<double> steps = GeneratedColumn<double>(
    'steps',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(5000),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    processId,
    motorId,
    name,
    order,
    steps,
    speed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'process_motors';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProcessMotorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('process_id')) {
      context.handle(
        _processIdMeta,
        processId.isAcceptableOrUnknown(data['process_id']!, _processIdMeta),
      );
    } else if (isInserting) {
      context.missing(_processIdMeta);
    }
    if (data.containsKey('motor_id')) {
      context.handle(
        _motorIdMeta,
        motorId.isAcceptableOrUnknown(data['motor_id']!, _motorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_motorIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    } else if (isInserting) {
      context.missing(_stepsMeta);
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProcessMotorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcessMotorRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      processId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}process_id'],
      )!,
      motorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}motor_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}steps'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      )!,
    );
  }

  @override
  $ProcessMotorsTable createAlias(String alias) {
    return $ProcessMotorsTable(attachedDatabase, alias);
  }
}

class ProcessMotorRow extends DataClass implements Insertable<ProcessMotorRow> {
  final int id;
  final int processId;
  final int motorId;
  final String name;
  final int order;
  final double steps;
  final double speed;
  const ProcessMotorRow({
    required this.id,
    required this.processId,
    required this.motorId,
    required this.name,
    required this.order,
    required this.steps,
    required this.speed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['process_id'] = Variable<int>(processId);
    map['motor_id'] = Variable<int>(motorId);
    map['name'] = Variable<String>(name);
    map['order'] = Variable<int>(order);
    map['steps'] = Variable<double>(steps);
    map['speed'] = Variable<double>(speed);
    return map;
  }

  ProcessMotorsCompanion toCompanion(bool nullToAbsent) {
    return ProcessMotorsCompanion(
      id: Value(id),
      processId: Value(processId),
      motorId: Value(motorId),
      name: Value(name),
      order: Value(order),
      steps: Value(steps),
      speed: Value(speed),
    );
  }

  factory ProcessMotorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcessMotorRow(
      id: serializer.fromJson<int>(json['id']),
      processId: serializer.fromJson<int>(json['processId']),
      motorId: serializer.fromJson<int>(json['motorId']),
      name: serializer.fromJson<String>(json['name']),
      order: serializer.fromJson<int>(json['order']),
      steps: serializer.fromJson<double>(json['steps']),
      speed: serializer.fromJson<double>(json['speed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'processId': serializer.toJson<int>(processId),
      'motorId': serializer.toJson<int>(motorId),
      'name': serializer.toJson<String>(name),
      'order': serializer.toJson<int>(order),
      'steps': serializer.toJson<double>(steps),
      'speed': serializer.toJson<double>(speed),
    };
  }

  ProcessMotorRow copyWith({
    int? id,
    int? processId,
    int? motorId,
    String? name,
    int? order,
    double? steps,
    double? speed,
  }) => ProcessMotorRow(
    id: id ?? this.id,
    processId: processId ?? this.processId,
    motorId: motorId ?? this.motorId,
    name: name ?? this.name,
    order: order ?? this.order,
    steps: steps ?? this.steps,
    speed: speed ?? this.speed,
  );
  ProcessMotorRow copyWithCompanion(ProcessMotorsCompanion data) {
    return ProcessMotorRow(
      id: data.id.present ? data.id.value : this.id,
      processId: data.processId.present ? data.processId.value : this.processId,
      motorId: data.motorId.present ? data.motorId.value : this.motorId,
      name: data.name.present ? data.name.value : this.name,
      order: data.order.present ? data.order.value : this.order,
      steps: data.steps.present ? data.steps.value : this.steps,
      speed: data.speed.present ? data.speed.value : this.speed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcessMotorRow(')
          ..write('id: $id, ')
          ..write('processId: $processId, ')
          ..write('motorId: $motorId, ')
          ..write('name: $name, ')
          ..write('order: $order, ')
          ..write('steps: $steps, ')
          ..write('speed: $speed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, processId, motorId, name, order, steps, speed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcessMotorRow &&
          other.id == this.id &&
          other.processId == this.processId &&
          other.motorId == this.motorId &&
          other.name == this.name &&
          other.order == this.order &&
          other.steps == this.steps &&
          other.speed == this.speed);
}

class ProcessMotorsCompanion extends UpdateCompanion<ProcessMotorRow> {
  final Value<int> id;
  final Value<int> processId;
  final Value<int> motorId;
  final Value<String> name;
  final Value<int> order;
  final Value<double> steps;
  final Value<double> speed;
  const ProcessMotorsCompanion({
    this.id = const Value.absent(),
    this.processId = const Value.absent(),
    this.motorId = const Value.absent(),
    this.name = const Value.absent(),
    this.order = const Value.absent(),
    this.steps = const Value.absent(),
    this.speed = const Value.absent(),
  });
  ProcessMotorsCompanion.insert({
    this.id = const Value.absent(),
    required int processId,
    required int motorId,
    required String name,
    required int order,
    required double steps,
    this.speed = const Value.absent(),
  }) : processId = Value(processId),
       motorId = Value(motorId),
       name = Value(name),
       order = Value(order),
       steps = Value(steps);
  static Insertable<ProcessMotorRow> custom({
    Expression<int>? id,
    Expression<int>? processId,
    Expression<int>? motorId,
    Expression<String>? name,
    Expression<int>? order,
    Expression<double>? steps,
    Expression<double>? speed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (processId != null) 'process_id': processId,
      if (motorId != null) 'motor_id': motorId,
      if (name != null) 'name': name,
      if (order != null) 'order': order,
      if (steps != null) 'steps': steps,
      if (speed != null) 'speed': speed,
    });
  }

  ProcessMotorsCompanion copyWith({
    Value<int>? id,
    Value<int>? processId,
    Value<int>? motorId,
    Value<String>? name,
    Value<int>? order,
    Value<double>? steps,
    Value<double>? speed,
  }) {
    return ProcessMotorsCompanion(
      id: id ?? this.id,
      processId: processId ?? this.processId,
      motorId: motorId ?? this.motorId,
      name: name ?? this.name,
      order: order ?? this.order,
      steps: steps ?? this.steps,
      speed: speed ?? this.speed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (processId.present) {
      map['process_id'] = Variable<int>(processId.value);
    }
    if (motorId.present) {
      map['motor_id'] = Variable<int>(motorId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (steps.present) {
      map['steps'] = Variable<double>(steps.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProcessMotorsCompanion(')
          ..write('id: $id, ')
          ..write('processId: $processId, ')
          ..write('motorId: $motorId, ')
          ..write('name: $name, ')
          ..write('order: $order, ')
          ..write('steps: $steps, ')
          ..write('speed: $speed')
          ..write(')'))
        .toString();
  }
}

class $ProcessServosTable extends ProcessServos
    with TableInfo<$ProcessServosTable, ProcessServoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProcessServosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processIdMeta = const VerificationMeta(
    'processId',
  );
  @override
  late final GeneratedColumn<int> processId = GeneratedColumn<int>(
    'process_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES processes (id)',
    ),
  );
  static const VerificationMeta _servoIdMeta = const VerificationMeta(
    'servoId',
  );
  @override
  late final GeneratedColumn<int> servoId = GeneratedColumn<int>(
    'servo_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES servos (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openValueMeta = const VerificationMeta(
    'openValue',
  );
  @override
  late final GeneratedColumn<double> openValue = GeneratedColumn<double>(
    'open_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    processId,
    servoId,
    name,
    order,
    openValue,
    speed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'process_servos';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProcessServoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('process_id')) {
      context.handle(
        _processIdMeta,
        processId.isAcceptableOrUnknown(data['process_id']!, _processIdMeta),
      );
    } else if (isInserting) {
      context.missing(_processIdMeta);
    }
    if (data.containsKey('servo_id')) {
      context.handle(
        _servoIdMeta,
        servoId.isAcceptableOrUnknown(data['servo_id']!, _servoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_servoIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('open_value')) {
      context.handle(
        _openValueMeta,
        openValue.isAcceptableOrUnknown(data['open_value']!, _openValueMeta),
      );
    } else if (isInserting) {
      context.missing(_openValueMeta);
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProcessServoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcessServoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      processId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}process_id'],
      )!,
      servoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}servo_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      openValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}open_value'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      )!,
    );
  }

  @override
  $ProcessServosTable createAlias(String alias) {
    return $ProcessServosTable(attachedDatabase, alias);
  }
}

class ProcessServoRow extends DataClass implements Insertable<ProcessServoRow> {
  final int id;
  final int processId;
  final int servoId;
  final String name;
  final int order;
  final double openValue;
  final double speed;
  const ProcessServoRow({
    required this.id,
    required this.processId,
    required this.servoId,
    required this.name,
    required this.order,
    required this.openValue,
    required this.speed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['process_id'] = Variable<int>(processId);
    map['servo_id'] = Variable<int>(servoId);
    map['name'] = Variable<String>(name);
    map['order'] = Variable<int>(order);
    map['open_value'] = Variable<double>(openValue);
    map['speed'] = Variable<double>(speed);
    return map;
  }

  ProcessServosCompanion toCompanion(bool nullToAbsent) {
    return ProcessServosCompanion(
      id: Value(id),
      processId: Value(processId),
      servoId: Value(servoId),
      name: Value(name),
      order: Value(order),
      openValue: Value(openValue),
      speed: Value(speed),
    );
  }

  factory ProcessServoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcessServoRow(
      id: serializer.fromJson<int>(json['id']),
      processId: serializer.fromJson<int>(json['processId']),
      servoId: serializer.fromJson<int>(json['servoId']),
      name: serializer.fromJson<String>(json['name']),
      order: serializer.fromJson<int>(json['order']),
      openValue: serializer.fromJson<double>(json['openValue']),
      speed: serializer.fromJson<double>(json['speed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'processId': serializer.toJson<int>(processId),
      'servoId': serializer.toJson<int>(servoId),
      'name': serializer.toJson<String>(name),
      'order': serializer.toJson<int>(order),
      'openValue': serializer.toJson<double>(openValue),
      'speed': serializer.toJson<double>(speed),
    };
  }

  ProcessServoRow copyWith({
    int? id,
    int? processId,
    int? servoId,
    String? name,
    int? order,
    double? openValue,
    double? speed,
  }) => ProcessServoRow(
    id: id ?? this.id,
    processId: processId ?? this.processId,
    servoId: servoId ?? this.servoId,
    name: name ?? this.name,
    order: order ?? this.order,
    openValue: openValue ?? this.openValue,
    speed: speed ?? this.speed,
  );
  ProcessServoRow copyWithCompanion(ProcessServosCompanion data) {
    return ProcessServoRow(
      id: data.id.present ? data.id.value : this.id,
      processId: data.processId.present ? data.processId.value : this.processId,
      servoId: data.servoId.present ? data.servoId.value : this.servoId,
      name: data.name.present ? data.name.value : this.name,
      order: data.order.present ? data.order.value : this.order,
      openValue: data.openValue.present ? data.openValue.value : this.openValue,
      speed: data.speed.present ? data.speed.value : this.speed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcessServoRow(')
          ..write('id: $id, ')
          ..write('processId: $processId, ')
          ..write('servoId: $servoId, ')
          ..write('name: $name, ')
          ..write('order: $order, ')
          ..write('openValue: $openValue, ')
          ..write('speed: $speed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, processId, servoId, name, order, openValue, speed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcessServoRow &&
          other.id == this.id &&
          other.processId == this.processId &&
          other.servoId == this.servoId &&
          other.name == this.name &&
          other.order == this.order &&
          other.openValue == this.openValue &&
          other.speed == this.speed);
}

class ProcessServosCompanion extends UpdateCompanion<ProcessServoRow> {
  final Value<int> id;
  final Value<int> processId;
  final Value<int> servoId;
  final Value<String> name;
  final Value<int> order;
  final Value<double> openValue;
  final Value<double> speed;
  const ProcessServosCompanion({
    this.id = const Value.absent(),
    this.processId = const Value.absent(),
    this.servoId = const Value.absent(),
    this.name = const Value.absent(),
    this.order = const Value.absent(),
    this.openValue = const Value.absent(),
    this.speed = const Value.absent(),
  });
  ProcessServosCompanion.insert({
    this.id = const Value.absent(),
    required int processId,
    required int servoId,
    required String name,
    required int order,
    required double openValue,
    this.speed = const Value.absent(),
  }) : processId = Value(processId),
       servoId = Value(servoId),
       name = Value(name),
       order = Value(order),
       openValue = Value(openValue);
  static Insertable<ProcessServoRow> custom({
    Expression<int>? id,
    Expression<int>? processId,
    Expression<int>? servoId,
    Expression<String>? name,
    Expression<int>? order,
    Expression<double>? openValue,
    Expression<double>? speed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (processId != null) 'process_id': processId,
      if (servoId != null) 'servo_id': servoId,
      if (name != null) 'name': name,
      if (order != null) 'order': order,
      if (openValue != null) 'open_value': openValue,
      if (speed != null) 'speed': speed,
    });
  }

  ProcessServosCompanion copyWith({
    Value<int>? id,
    Value<int>? processId,
    Value<int>? servoId,
    Value<String>? name,
    Value<int>? order,
    Value<double>? openValue,
    Value<double>? speed,
  }) {
    return ProcessServosCompanion(
      id: id ?? this.id,
      processId: processId ?? this.processId,
      servoId: servoId ?? this.servoId,
      name: name ?? this.name,
      order: order ?? this.order,
      openValue: openValue ?? this.openValue,
      speed: speed ?? this.speed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (processId.present) {
      map['process_id'] = Variable<int>(processId.value);
    }
    if (servoId.present) {
      map['servo_id'] = Variable<int>(servoId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (openValue.present) {
      map['open_value'] = Variable<double>(openValue.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProcessServosCompanion(')
          ..write('id: $id, ')
          ..write('processId: $processId, ')
          ..write('servoId: $servoId, ')
          ..write('name: $name, ')
          ..write('order: $order, ')
          ..write('openValue: $openValue, ')
          ..write('speed: $speed')
          ..write(')'))
        .toString();
  }
}

class $ProcessHistoricsTable extends ProcessHistorics
    with TableInfo<$ProcessHistoricsTable, ProcessHistoricRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProcessHistoricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processIdMeta = const VerificationMeta(
    'processId',
  );
  @override
  late final GeneratedColumn<int> processId = GeneratedColumn<int>(
    'process_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES processes (id)',
    ),
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stopProcessMeta = const VerificationMeta(
    'stopProcess',
  );
  @override
  late final GeneratedColumn<DateTime> stopProcess = GeneratedColumn<DateTime>(
    'stop_process',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stopKeyMeta = const VerificationMeta(
    'stopKey',
  );
  @override
  late final GeneratedColumn<String> stopKey = GeneratedColumn<String>(
    'stop_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finishProcessMeta = const VerificationMeta(
    'finishProcess',
  );
  @override
  late final GeneratedColumn<bool> finishProcess = GeneratedColumn<bool>(
    'finish_process',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("finish_process" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    processId,
    startTime,
    endTime,
    stopProcess,
    stopKey,
    finishProcess,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'process_historics';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProcessHistoricRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('process_id')) {
      context.handle(
        _processIdMeta,
        processId.isAcceptableOrUnknown(data['process_id']!, _processIdMeta),
      );
    } else if (isInserting) {
      context.missing(_processIdMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('stop_process')) {
      context.handle(
        _stopProcessMeta,
        stopProcess.isAcceptableOrUnknown(
          data['stop_process']!,
          _stopProcessMeta,
        ),
      );
    }
    if (data.containsKey('stop_key')) {
      context.handle(
        _stopKeyMeta,
        stopKey.isAcceptableOrUnknown(data['stop_key']!, _stopKeyMeta),
      );
    }
    if (data.containsKey('finish_process')) {
      context.handle(
        _finishProcessMeta,
        finishProcess.isAcceptableOrUnknown(
          data['finish_process']!,
          _finishProcessMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_finishProcessMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProcessHistoricRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcessHistoricRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      processId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}process_id'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      stopProcess: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}stop_process'],
      ),
      stopKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stop_key'],
      ),
      finishProcess: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}finish_process'],
      )!,
    );
  }

  @override
  $ProcessHistoricsTable createAlias(String alias) {
    return $ProcessHistoricsTable(attachedDatabase, alias);
  }
}

class ProcessHistoricRow extends DataClass
    implements Insertable<ProcessHistoricRow> {
  final int id;
  final int processId;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? stopProcess;
  final String? stopKey;
  final bool finishProcess;
  const ProcessHistoricRow({
    required this.id,
    required this.processId,
    required this.startTime,
    this.endTime,
    this.stopProcess,
    this.stopKey,
    required this.finishProcess,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['process_id'] = Variable<int>(processId);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    if (!nullToAbsent || stopProcess != null) {
      map['stop_process'] = Variable<DateTime>(stopProcess);
    }
    if (!nullToAbsent || stopKey != null) {
      map['stop_key'] = Variable<String>(stopKey);
    }
    map['finish_process'] = Variable<bool>(finishProcess);
    return map;
  }

  ProcessHistoricsCompanion toCompanion(bool nullToAbsent) {
    return ProcessHistoricsCompanion(
      id: Value(id),
      processId: Value(processId),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      stopProcess: stopProcess == null && nullToAbsent
          ? const Value.absent()
          : Value(stopProcess),
      stopKey: stopKey == null && nullToAbsent
          ? const Value.absent()
          : Value(stopKey),
      finishProcess: Value(finishProcess),
    );
  }

  factory ProcessHistoricRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcessHistoricRow(
      id: serializer.fromJson<int>(json['id']),
      processId: serializer.fromJson<int>(json['processId']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      stopProcess: serializer.fromJson<DateTime?>(json['stopProcess']),
      stopKey: serializer.fromJson<String?>(json['stopKey']),
      finishProcess: serializer.fromJson<bool>(json['finishProcess']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'processId': serializer.toJson<int>(processId),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'stopProcess': serializer.toJson<DateTime?>(stopProcess),
      'stopKey': serializer.toJson<String?>(stopKey),
      'finishProcess': serializer.toJson<bool>(finishProcess),
    };
  }

  ProcessHistoricRow copyWith({
    int? id,
    int? processId,
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    Value<DateTime?> stopProcess = const Value.absent(),
    Value<String?> stopKey = const Value.absent(),
    bool? finishProcess,
  }) => ProcessHistoricRow(
    id: id ?? this.id,
    processId: processId ?? this.processId,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    stopProcess: stopProcess.present ? stopProcess.value : this.stopProcess,
    stopKey: stopKey.present ? stopKey.value : this.stopKey,
    finishProcess: finishProcess ?? this.finishProcess,
  );
  ProcessHistoricRow copyWithCompanion(ProcessHistoricsCompanion data) {
    return ProcessHistoricRow(
      id: data.id.present ? data.id.value : this.id,
      processId: data.processId.present ? data.processId.value : this.processId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      stopProcess: data.stopProcess.present
          ? data.stopProcess.value
          : this.stopProcess,
      stopKey: data.stopKey.present ? data.stopKey.value : this.stopKey,
      finishProcess: data.finishProcess.present
          ? data.finishProcess.value
          : this.finishProcess,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcessHistoricRow(')
          ..write('id: $id, ')
          ..write('processId: $processId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('stopProcess: $stopProcess, ')
          ..write('stopKey: $stopKey, ')
          ..write('finishProcess: $finishProcess')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    processId,
    startTime,
    endTime,
    stopProcess,
    stopKey,
    finishProcess,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcessHistoricRow &&
          other.id == this.id &&
          other.processId == this.processId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.stopProcess == this.stopProcess &&
          other.stopKey == this.stopKey &&
          other.finishProcess == this.finishProcess);
}

class ProcessHistoricsCompanion extends UpdateCompanion<ProcessHistoricRow> {
  final Value<int> id;
  final Value<int> processId;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<DateTime?> stopProcess;
  final Value<String?> stopKey;
  final Value<bool> finishProcess;
  const ProcessHistoricsCompanion({
    this.id = const Value.absent(),
    this.processId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.stopProcess = const Value.absent(),
    this.stopKey = const Value.absent(),
    this.finishProcess = const Value.absent(),
  });
  ProcessHistoricsCompanion.insert({
    this.id = const Value.absent(),
    required int processId,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.stopProcess = const Value.absent(),
    this.stopKey = const Value.absent(),
    required bool finishProcess,
  }) : processId = Value(processId),
       startTime = Value(startTime),
       finishProcess = Value(finishProcess);
  static Insertable<ProcessHistoricRow> custom({
    Expression<int>? id,
    Expression<int>? processId,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<DateTime>? stopProcess,
    Expression<String>? stopKey,
    Expression<bool>? finishProcess,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (processId != null) 'process_id': processId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (stopProcess != null) 'stop_process': stopProcess,
      if (stopKey != null) 'stop_key': stopKey,
      if (finishProcess != null) 'finish_process': finishProcess,
    });
  }

  ProcessHistoricsCompanion copyWith({
    Value<int>? id,
    Value<int>? processId,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<DateTime?>? stopProcess,
    Value<String?>? stopKey,
    Value<bool>? finishProcess,
  }) {
    return ProcessHistoricsCompanion(
      id: id ?? this.id,
      processId: processId ?? this.processId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      stopProcess: stopProcess ?? this.stopProcess,
      stopKey: stopKey ?? this.stopKey,
      finishProcess: finishProcess ?? this.finishProcess,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (processId.present) {
      map['process_id'] = Variable<int>(processId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (stopProcess.present) {
      map['stop_process'] = Variable<DateTime>(stopProcess.value);
    }
    if (stopKey.present) {
      map['stop_key'] = Variable<String>(stopKey.value);
    }
    if (finishProcess.present) {
      map['finish_process'] = Variable<bool>(finishProcess.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProcessHistoricsCompanion(')
          ..write('id: $id, ')
          ..write('processId: $processId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('stopProcess: $stopProcess, ')
          ..write('stopKey: $stopKey, ')
          ..write('finishProcess: $finishProcess')
          ..write(')'))
        .toString();
  }
}

class $ProcessHistoricMotorsTable extends ProcessHistoricMotors
    with TableInfo<$ProcessHistoricMotorsTable, ProcessHistoricMotorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProcessHistoricMotorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processMotorIdMeta = const VerificationMeta(
    'processMotorId',
  );
  @override
  late final GeneratedColumn<int> processMotorId = GeneratedColumn<int>(
    'process_motor_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES process_motors (id)',
    ),
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<double> steps = GeneratedColumn<double>(
    'steps',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    processMotorId,
    startTime,
    endTime,
    steps,
    speed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'process_historic_motors';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProcessHistoricMotorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('process_motor_id')) {
      context.handle(
        _processMotorIdMeta,
        processMotorId.isAcceptableOrUnknown(
          data['process_motor_id']!,
          _processMotorIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processMotorIdMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    } else if (isInserting) {
      context.missing(_stepsMeta);
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    } else if (isInserting) {
      context.missing(_speedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProcessHistoricMotorRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcessHistoricMotorRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      processMotorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}process_motor_id'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}steps'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      )!,
    );
  }

  @override
  $ProcessHistoricMotorsTable createAlias(String alias) {
    return $ProcessHistoricMotorsTable(attachedDatabase, alias);
  }
}

class ProcessHistoricMotorRow extends DataClass
    implements Insertable<ProcessHistoricMotorRow> {
  final int id;
  final int processMotorId;
  final DateTime startTime;
  final DateTime? endTime;
  final double steps;
  final double speed;
  const ProcessHistoricMotorRow({
    required this.id,
    required this.processMotorId,
    required this.startTime,
    this.endTime,
    required this.steps,
    required this.speed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['process_motor_id'] = Variable<int>(processMotorId);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['steps'] = Variable<double>(steps);
    map['speed'] = Variable<double>(speed);
    return map;
  }

  ProcessHistoricMotorsCompanion toCompanion(bool nullToAbsent) {
    return ProcessHistoricMotorsCompanion(
      id: Value(id),
      processMotorId: Value(processMotorId),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      steps: Value(steps),
      speed: Value(speed),
    );
  }

  factory ProcessHistoricMotorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcessHistoricMotorRow(
      id: serializer.fromJson<int>(json['id']),
      processMotorId: serializer.fromJson<int>(json['processMotorId']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      steps: serializer.fromJson<double>(json['steps']),
      speed: serializer.fromJson<double>(json['speed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'processMotorId': serializer.toJson<int>(processMotorId),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'steps': serializer.toJson<double>(steps),
      'speed': serializer.toJson<double>(speed),
    };
  }

  ProcessHistoricMotorRow copyWith({
    int? id,
    int? processMotorId,
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    double? steps,
    double? speed,
  }) => ProcessHistoricMotorRow(
    id: id ?? this.id,
    processMotorId: processMotorId ?? this.processMotorId,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    steps: steps ?? this.steps,
    speed: speed ?? this.speed,
  );
  ProcessHistoricMotorRow copyWithCompanion(
    ProcessHistoricMotorsCompanion data,
  ) {
    return ProcessHistoricMotorRow(
      id: data.id.present ? data.id.value : this.id,
      processMotorId: data.processMotorId.present
          ? data.processMotorId.value
          : this.processMotorId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      steps: data.steps.present ? data.steps.value : this.steps,
      speed: data.speed.present ? data.speed.value : this.speed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcessHistoricMotorRow(')
          ..write('id: $id, ')
          ..write('processMotorId: $processMotorId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('steps: $steps, ')
          ..write('speed: $speed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, processMotorId, startTime, endTime, steps, speed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcessHistoricMotorRow &&
          other.id == this.id &&
          other.processMotorId == this.processMotorId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.steps == this.steps &&
          other.speed == this.speed);
}

class ProcessHistoricMotorsCompanion
    extends UpdateCompanion<ProcessHistoricMotorRow> {
  final Value<int> id;
  final Value<int> processMotorId;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<double> steps;
  final Value<double> speed;
  const ProcessHistoricMotorsCompanion({
    this.id = const Value.absent(),
    this.processMotorId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.steps = const Value.absent(),
    this.speed = const Value.absent(),
  });
  ProcessHistoricMotorsCompanion.insert({
    this.id = const Value.absent(),
    required int processMotorId,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    required double steps,
    required double speed,
  }) : processMotorId = Value(processMotorId),
       startTime = Value(startTime),
       steps = Value(steps),
       speed = Value(speed);
  static Insertable<ProcessHistoricMotorRow> custom({
    Expression<int>? id,
    Expression<int>? processMotorId,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<double>? steps,
    Expression<double>? speed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (processMotorId != null) 'process_motor_id': processMotorId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (steps != null) 'steps': steps,
      if (speed != null) 'speed': speed,
    });
  }

  ProcessHistoricMotorsCompanion copyWith({
    Value<int>? id,
    Value<int>? processMotorId,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<double>? steps,
    Value<double>? speed,
  }) {
    return ProcessHistoricMotorsCompanion(
      id: id ?? this.id,
      processMotorId: processMotorId ?? this.processMotorId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      steps: steps ?? this.steps,
      speed: speed ?? this.speed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (processMotorId.present) {
      map['process_motor_id'] = Variable<int>(processMotorId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (steps.present) {
      map['steps'] = Variable<double>(steps.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProcessHistoricMotorsCompanion(')
          ..write('id: $id, ')
          ..write('processMotorId: $processMotorId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('steps: $steps, ')
          ..write('speed: $speed')
          ..write(')'))
        .toString();
  }
}

class $SystemPositionsTable extends SystemPositions
    with TableInfo<$SystemPositionsTable, SystemPositionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SystemPositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _systemMachineIdMeta = const VerificationMeta(
    'systemMachineId',
  );
  @override
  late final GeneratedColumn<int> systemMachineId = GeneratedColumn<int>(
    'system_machine_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES system_machines (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, number, type, systemMachineId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'system_positions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SystemPositionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('system_machine_id')) {
      context.handle(
        _systemMachineIdMeta,
        systemMachineId.isAcceptableOrUnknown(
          data['system_machine_id']!,
          _systemMachineIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_systemMachineIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SystemPositionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SystemPositionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      systemMachineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}system_machine_id'],
      )!,
    );
  }

  @override
  $SystemPositionsTable createAlias(String alias) {
    return $SystemPositionsTable(attachedDatabase, alias);
  }
}

class SystemPositionRow extends DataClass
    implements Insertable<SystemPositionRow> {
  final int id;
  final int number;
  final String type;
  final int systemMachineId;
  const SystemPositionRow({
    required this.id,
    required this.number,
    required this.type,
    required this.systemMachineId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['number'] = Variable<int>(number);
    map['type'] = Variable<String>(type);
    map['system_machine_id'] = Variable<int>(systemMachineId);
    return map;
  }

  SystemPositionsCompanion toCompanion(bool nullToAbsent) {
    return SystemPositionsCompanion(
      id: Value(id),
      number: Value(number),
      type: Value(type),
      systemMachineId: Value(systemMachineId),
    );
  }

  factory SystemPositionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SystemPositionRow(
      id: serializer.fromJson<int>(json['id']),
      number: serializer.fromJson<int>(json['number']),
      type: serializer.fromJson<String>(json['type']),
      systemMachineId: serializer.fromJson<int>(json['systemMachineId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'number': serializer.toJson<int>(number),
      'type': serializer.toJson<String>(type),
      'systemMachineId': serializer.toJson<int>(systemMachineId),
    };
  }

  SystemPositionRow copyWith({
    int? id,
    int? number,
    String? type,
    int? systemMachineId,
  }) => SystemPositionRow(
    id: id ?? this.id,
    number: number ?? this.number,
    type: type ?? this.type,
    systemMachineId: systemMachineId ?? this.systemMachineId,
  );
  SystemPositionRow copyWithCompanion(SystemPositionsCompanion data) {
    return SystemPositionRow(
      id: data.id.present ? data.id.value : this.id,
      number: data.number.present ? data.number.value : this.number,
      type: data.type.present ? data.type.value : this.type,
      systemMachineId: data.systemMachineId.present
          ? data.systemMachineId.value
          : this.systemMachineId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SystemPositionRow(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('type: $type, ')
          ..write('systemMachineId: $systemMachineId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, number, type, systemMachineId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SystemPositionRow &&
          other.id == this.id &&
          other.number == this.number &&
          other.type == this.type &&
          other.systemMachineId == this.systemMachineId);
}

class SystemPositionsCompanion extends UpdateCompanion<SystemPositionRow> {
  final Value<int> id;
  final Value<int> number;
  final Value<String> type;
  final Value<int> systemMachineId;
  const SystemPositionsCompanion({
    this.id = const Value.absent(),
    this.number = const Value.absent(),
    this.type = const Value.absent(),
    this.systemMachineId = const Value.absent(),
  });
  SystemPositionsCompanion.insert({
    this.id = const Value.absent(),
    required int number,
    required String type,
    required int systemMachineId,
  }) : number = Value(number),
       type = Value(type),
       systemMachineId = Value(systemMachineId);
  static Insertable<SystemPositionRow> custom({
    Expression<int>? id,
    Expression<int>? number,
    Expression<String>? type,
    Expression<int>? systemMachineId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (number != null) 'number': number,
      if (type != null) 'type': type,
      if (systemMachineId != null) 'system_machine_id': systemMachineId,
    });
  }

  SystemPositionsCompanion copyWith({
    Value<int>? id,
    Value<int>? number,
    Value<String>? type,
    Value<int>? systemMachineId,
  }) {
    return SystemPositionsCompanion(
      id: id ?? this.id,
      number: number ?? this.number,
      type: type ?? this.type,
      systemMachineId: systemMachineId ?? this.systemMachineId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (systemMachineId.present) {
      map['system_machine_id'] = Variable<int>(systemMachineId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SystemPositionsCompanion(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('type: $type, ')
          ..write('systemMachineId: $systemMachineId')
          ..write(')'))
        .toString();
  }
}

abstract class _$SystemDatabase extends GeneratedDatabase {
  _$SystemDatabase(QueryExecutor e) : super(e);
  $SystemDatabaseManager get managers => $SystemDatabaseManager(this);
  late final $SystemMachinesTable systemMachines = $SystemMachinesTable(this);
  late final $MotorsTable motors = $MotorsTable(this);
  late final $ServosTable servos = $ServosTable(this);
  late final $SensorsTable sensors = $SensorsTable(this);
  late final $ProcessesTable processes = $ProcessesTable(this);
  late final $ProcessMotorsTable processMotors = $ProcessMotorsTable(this);
  late final $ProcessServosTable processServos = $ProcessServosTable(this);
  late final $ProcessHistoricsTable processHistorics = $ProcessHistoricsTable(
    this,
  );
  late final $ProcessHistoricMotorsTable processHistoricMotors =
      $ProcessHistoricMotorsTable(this);
  late final $SystemPositionsTable systemPositions = $SystemPositionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    systemMachines,
    motors,
    servos,
    sensors,
    processes,
    processMotors,
    processServos,
    processHistorics,
    processHistoricMotors,
    systemPositions,
  ];
}

typedef $$SystemMachinesTableCreateCompanionBuilder =
    SystemMachinesCompanion Function({
      Value<int> id,
      required String name,
      required String type,
      Value<int?> parentMachineId,
    });
typedef $$SystemMachinesTableUpdateCompanionBuilder =
    SystemMachinesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> type,
      Value<int?> parentMachineId,
    });

final class $$SystemMachinesTableReferences
    extends
        BaseReferences<
          _$SystemDatabase,
          $SystemMachinesTable,
          SystemMachineRow
        > {
  $$SystemMachinesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SystemMachinesTable _parentMachineIdTable(_$SystemDatabase db) => db
      .systemMachines
      .createAlias('system_machines__parent_machine_id__system_machines__id');

  $$SystemMachinesTableProcessedTableManager? get parentMachineId {
    final $_column = $_itemColumn<int>('parent_machine_id');
    if ($_column == null) return null;
    final manager = $$SystemMachinesTableTableManager(
      $_db,
      $_db.systemMachines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentMachineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MotorsTable, List<MotorRow>> _motorsRefsTable(
    _$SystemDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.motors,
    aliasName: 'system_machines__id__motors__system_machine_id',
  );

  $$MotorsTableProcessedTableManager get motorsRefs {
    final manager = $$MotorsTableTableManager(
      $_db,
      $_db.motors,
    ).filter((f) => f.systemMachineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_motorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ServosTable, List<ServoRow>> _servosRefsTable(
    _$SystemDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.servos,
    aliasName: 'system_machines__id__servos__machine_id',
  );

  $$ServosTableProcessedTableManager get servosRefs {
    final manager = $$ServosTableTableManager(
      $_db,
      $_db.servos,
    ).filter((f) => f.machineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_servosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SensorsTable, List<SensorRow>> _sensorsRefsTable(
    _$SystemDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sensors,
    aliasName: 'system_machines__id__sensors__machine_id',
  );

  $$SensorsTableProcessedTableManager get sensorsRefs {
    final manager = $$SensorsTableTableManager(
      $_db,
      $_db.sensors,
    ).filter((f) => f.machineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sensorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProcessesTable, List<ProcessRow>>
  _processesRefsTable(_$SystemDatabase db) => MultiTypedResultKey.fromTable(
    db.processes,
    aliasName: 'system_machines__id__processes__machine_id',
  );

  $$ProcessesTableProcessedTableManager get processesRefs {
    final manager = $$ProcessesTableTableManager(
      $_db,
      $_db.processes,
    ).filter((f) => f.machineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_processesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SystemPositionsTable, List<SystemPositionRow>>
  _systemPositionsRefsTable(_$SystemDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.systemPositions,
        aliasName: 'system_machines__id__system_positions__system_machine_id',
      );

  $$SystemPositionsTableProcessedTableManager get systemPositionsRefs {
    final manager = $$SystemPositionsTableTableManager(
      $_db,
      $_db.systemPositions,
    ).filter((f) => f.systemMachineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _systemPositionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SystemMachinesTableFilterComposer
    extends Composer<_$SystemDatabase, $SystemMachinesTable> {
  $$SystemMachinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  $$SystemMachinesTableFilterComposer get parentMachineId {
    final $$SystemMachinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentMachineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableFilterComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> motorsRefs(
    Expression<bool> Function($$MotorsTableFilterComposer f) f,
  ) {
    final $$MotorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.motors,
      getReferencedColumn: (t) => t.systemMachineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MotorsTableFilterComposer(
            $db: $db,
            $table: $db.motors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> servosRefs(
    Expression<bool> Function($$ServosTableFilterComposer f) f,
  ) {
    final $$ServosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.servos,
      getReferencedColumn: (t) => t.machineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServosTableFilterComposer(
            $db: $db,
            $table: $db.servos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sensorsRefs(
    Expression<bool> Function($$SensorsTableFilterComposer f) f,
  ) {
    final $$SensorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sensors,
      getReferencedColumn: (t) => t.machineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SensorsTableFilterComposer(
            $db: $db,
            $table: $db.sensors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> processesRefs(
    Expression<bool> Function($$ProcessesTableFilterComposer f) f,
  ) {
    final $$ProcessesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processes,
      getReferencedColumn: (t) => t.machineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessesTableFilterComposer(
            $db: $db,
            $table: $db.processes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> systemPositionsRefs(
    Expression<bool> Function($$SystemPositionsTableFilterComposer f) f,
  ) {
    final $$SystemPositionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.systemPositions,
      getReferencedColumn: (t) => t.systemMachineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemPositionsTableFilterComposer(
            $db: $db,
            $table: $db.systemPositions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SystemMachinesTableOrderingComposer
    extends Composer<_$SystemDatabase, $SystemMachinesTable> {
  $$SystemMachinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  $$SystemMachinesTableOrderingComposer get parentMachineId {
    final $$SystemMachinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentMachineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableOrderingComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SystemMachinesTableAnnotationComposer
    extends Composer<_$SystemDatabase, $SystemMachinesTable> {
  $$SystemMachinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  $$SystemMachinesTableAnnotationComposer get parentMachineId {
    final $$SystemMachinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentMachineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableAnnotationComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> motorsRefs<T extends Object>(
    Expression<T> Function($$MotorsTableAnnotationComposer a) f,
  ) {
    final $$MotorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.motors,
      getReferencedColumn: (t) => t.systemMachineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MotorsTableAnnotationComposer(
            $db: $db,
            $table: $db.motors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> servosRefs<T extends Object>(
    Expression<T> Function($$ServosTableAnnotationComposer a) f,
  ) {
    final $$ServosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.servos,
      getReferencedColumn: (t) => t.machineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServosTableAnnotationComposer(
            $db: $db,
            $table: $db.servos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sensorsRefs<T extends Object>(
    Expression<T> Function($$SensorsTableAnnotationComposer a) f,
  ) {
    final $$SensorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sensors,
      getReferencedColumn: (t) => t.machineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SensorsTableAnnotationComposer(
            $db: $db,
            $table: $db.sensors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> processesRefs<T extends Object>(
    Expression<T> Function($$ProcessesTableAnnotationComposer a) f,
  ) {
    final $$ProcessesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processes,
      getReferencedColumn: (t) => t.machineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessesTableAnnotationComposer(
            $db: $db,
            $table: $db.processes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> systemPositionsRefs<T extends Object>(
    Expression<T> Function($$SystemPositionsTableAnnotationComposer a) f,
  ) {
    final $$SystemPositionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.systemPositions,
      getReferencedColumn: (t) => t.systemMachineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemPositionsTableAnnotationComposer(
            $db: $db,
            $table: $db.systemPositions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SystemMachinesTableTableManager
    extends
        RootTableManager<
          _$SystemDatabase,
          $SystemMachinesTable,
          SystemMachineRow,
          $$SystemMachinesTableFilterComposer,
          $$SystemMachinesTableOrderingComposer,
          $$SystemMachinesTableAnnotationComposer,
          $$SystemMachinesTableCreateCompanionBuilder,
          $$SystemMachinesTableUpdateCompanionBuilder,
          (SystemMachineRow, $$SystemMachinesTableReferences),
          SystemMachineRow,
          PrefetchHooks Function({
            bool parentMachineId,
            bool motorsRefs,
            bool servosRefs,
            bool sensorsRefs,
            bool processesRefs,
            bool systemPositionsRefs,
          })
        > {
  $$SystemMachinesTableTableManager(
    _$SystemDatabase db,
    $SystemMachinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SystemMachinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SystemMachinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SystemMachinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int?> parentMachineId = const Value.absent(),
              }) => SystemMachinesCompanion(
                id: id,
                name: name,
                type: type,
                parentMachineId: parentMachineId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String type,
                Value<int?> parentMachineId = const Value.absent(),
              }) => SystemMachinesCompanion.insert(
                id: id,
                name: name,
                type: type,
                parentMachineId: parentMachineId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SystemMachinesTable, SystemMachineRow>(table),
                  $$SystemMachinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                parentMachineId = false,
                motorsRefs = false,
                servosRefs = false,
                sensorsRefs = false,
                processesRefs = false,
                systemPositionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (motorsRefs) db.motors,
                    if (servosRefs) db.servos,
                    if (sensorsRefs) db.sensors,
                    if (processesRefs) db.processes,
                    if (systemPositionsRefs) db.systemPositions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentMachineId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentMachineId,
                                    referencedTable:
                                        $$SystemMachinesTableReferences
                                            ._parentMachineIdTable(db),
                                    referencedColumn:
                                        $$SystemMachinesTableReferences
                                            ._parentMachineIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (motorsRefs)
                        await $_getPrefetchedDataByColumns<
                          SystemMachineRow,
                          $SystemMachinesTable,
                          MotorRow,
                          $MotorsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SystemMachinesTableReferences
                              ._motorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SystemMachinesTableReferences(
                                db,
                                table,
                                p0,
                              ).motorsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'system_machine_id',
                          typedResults: items,
                        ),
                      if (servosRefs)
                        await $_getPrefetchedDataByColumns<
                          SystemMachineRow,
                          $SystemMachinesTable,
                          ServoRow,
                          $ServosTable
                        >(
                          currentTable: table,
                          referencedTable: $$SystemMachinesTableReferences
                              ._servosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SystemMachinesTableReferences(
                                db,
                                table,
                                p0,
                              ).servosRefs,
                          currentColumn: 'id',
                          referencedColumn: 'machine_id',
                          typedResults: items,
                        ),
                      if (sensorsRefs)
                        await $_getPrefetchedDataByColumns<
                          SystemMachineRow,
                          $SystemMachinesTable,
                          SensorRow,
                          $SensorsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SystemMachinesTableReferences
                              ._sensorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SystemMachinesTableReferences(
                                db,
                                table,
                                p0,
                              ).sensorsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'machine_id',
                          typedResults: items,
                        ),
                      if (processesRefs)
                        await $_getPrefetchedDataByColumns<
                          SystemMachineRow,
                          $SystemMachinesTable,
                          ProcessRow,
                          $ProcessesTable
                        >(
                          currentTable: table,
                          referencedTable: $$SystemMachinesTableReferences
                              ._processesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SystemMachinesTableReferences(
                                db,
                                table,
                                p0,
                              ).processesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'machine_id',
                          typedResults: items,
                        ),
                      if (systemPositionsRefs)
                        await $_getPrefetchedDataByColumns<
                          SystemMachineRow,
                          $SystemMachinesTable,
                          SystemPositionRow,
                          $SystemPositionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SystemMachinesTableReferences
                              ._systemPositionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SystemMachinesTableReferences(
                                db,
                                table,
                                p0,
                              ).systemPositionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'system_machine_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SystemMachinesTableProcessedTableManager =
    ProcessedTableManager<
      _$SystemDatabase,
      $SystemMachinesTable,
      SystemMachineRow,
      $$SystemMachinesTableFilterComposer,
      $$SystemMachinesTableOrderingComposer,
      $$SystemMachinesTableAnnotationComposer,
      $$SystemMachinesTableCreateCompanionBuilder,
      $$SystemMachinesTableUpdateCompanionBuilder,
      (SystemMachineRow, $$SystemMachinesTableReferences),
      SystemMachineRow,
      PrefetchHooks Function({
        bool parentMachineId,
        bool motorsRefs,
        bool servosRefs,
        bool sensorsRefs,
        bool processesRefs,
        bool systemPositionsRefs,
      })
    >;
typedef $$MotorsTableCreateCompanionBuilder =
    MotorsCompanion Function({
      Value<int> id,
      required int systemMachineId,
      required String key,
      Value<String?> keySensorRight,
      Value<String?> keySensorLeft,
      required double speed,
      Value<String?> maxStepsRight,
      Value<String?> maxStepsLeft,
    });
typedef $$MotorsTableUpdateCompanionBuilder =
    MotorsCompanion Function({
      Value<int> id,
      Value<int> systemMachineId,
      Value<String> key,
      Value<String?> keySensorRight,
      Value<String?> keySensorLeft,
      Value<double> speed,
      Value<String?> maxStepsRight,
      Value<String?> maxStepsLeft,
    });

final class $$MotorsTableReferences
    extends BaseReferences<_$SystemDatabase, $MotorsTable, MotorRow> {
  $$MotorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SystemMachinesTable _systemMachineIdTable(_$SystemDatabase db) => db
      .systemMachines
      .createAlias('motors__system_machine_id__system_machines__id');

  $$SystemMachinesTableProcessedTableManager get systemMachineId {
    final $_column = $_itemColumn<int>('system_machine_id')!;

    final manager = $$SystemMachinesTableTableManager(
      $_db,
      $_db.systemMachines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_systemMachineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ProcessMotorsTable, List<ProcessMotorRow>>
  _processMotorsRefsTable(_$SystemDatabase db) => MultiTypedResultKey.fromTable(
    db.processMotors,
    aliasName: 'motors__id__process_motors__motor_id',
  );

  $$ProcessMotorsTableProcessedTableManager get processMotorsRefs {
    final manager = $$ProcessMotorsTableTableManager(
      $_db,
      $_db.processMotors,
    ).filter((f) => f.motorId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_processMotorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MotorsTableFilterComposer
    extends Composer<_$SystemDatabase, $MotorsTable> {
  $$MotorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keySensorRight => $composableBuilder(
    column: $table.keySensorRight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keySensorLeft => $composableBuilder(
    column: $table.keySensorLeft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get maxStepsRight => $composableBuilder(
    column: $table.maxStepsRight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get maxStepsLeft => $composableBuilder(
    column: $table.maxStepsLeft,
    builder: (column) => ColumnFilters(column),
  );

  $$SystemMachinesTableFilterComposer get systemMachineId {
    final $$SystemMachinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemMachineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableFilterComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> processMotorsRefs(
    Expression<bool> Function($$ProcessMotorsTableFilterComposer f) f,
  ) {
    final $$ProcessMotorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processMotors,
      getReferencedColumn: (t) => t.motorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessMotorsTableFilterComposer(
            $db: $db,
            $table: $db.processMotors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MotorsTableOrderingComposer
    extends Composer<_$SystemDatabase, $MotorsTable> {
  $$MotorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keySensorRight => $composableBuilder(
    column: $table.keySensorRight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keySensorLeft => $composableBuilder(
    column: $table.keySensorLeft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get maxStepsRight => $composableBuilder(
    column: $table.maxStepsRight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get maxStepsLeft => $composableBuilder(
    column: $table.maxStepsLeft,
    builder: (column) => ColumnOrderings(column),
  );

  $$SystemMachinesTableOrderingComposer get systemMachineId {
    final $$SystemMachinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemMachineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableOrderingComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MotorsTableAnnotationComposer
    extends Composer<_$SystemDatabase, $MotorsTable> {
  $$MotorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get keySensorRight => $composableBuilder(
    column: $table.keySensorRight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keySensorLeft => $composableBuilder(
    column: $table.keySensorLeft,
    builder: (column) => column,
  );

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<String> get maxStepsRight => $composableBuilder(
    column: $table.maxStepsRight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get maxStepsLeft => $composableBuilder(
    column: $table.maxStepsLeft,
    builder: (column) => column,
  );

  $$SystemMachinesTableAnnotationComposer get systemMachineId {
    final $$SystemMachinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemMachineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableAnnotationComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> processMotorsRefs<T extends Object>(
    Expression<T> Function($$ProcessMotorsTableAnnotationComposer a) f,
  ) {
    final $$ProcessMotorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processMotors,
      getReferencedColumn: (t) => t.motorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessMotorsTableAnnotationComposer(
            $db: $db,
            $table: $db.processMotors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MotorsTableTableManager
    extends
        RootTableManager<
          _$SystemDatabase,
          $MotorsTable,
          MotorRow,
          $$MotorsTableFilterComposer,
          $$MotorsTableOrderingComposer,
          $$MotorsTableAnnotationComposer,
          $$MotorsTableCreateCompanionBuilder,
          $$MotorsTableUpdateCompanionBuilder,
          (MotorRow, $$MotorsTableReferences),
          MotorRow,
          PrefetchHooks Function({bool systemMachineId, bool processMotorsRefs})
        > {
  $$MotorsTableTableManager(_$SystemDatabase db, $MotorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MotorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MotorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MotorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> systemMachineId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String?> keySensorRight = const Value.absent(),
                Value<String?> keySensorLeft = const Value.absent(),
                Value<double> speed = const Value.absent(),
                Value<String?> maxStepsRight = const Value.absent(),
                Value<String?> maxStepsLeft = const Value.absent(),
              }) => MotorsCompanion(
                id: id,
                systemMachineId: systemMachineId,
                key: key,
                keySensorRight: keySensorRight,
                keySensorLeft: keySensorLeft,
                speed: speed,
                maxStepsRight: maxStepsRight,
                maxStepsLeft: maxStepsLeft,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int systemMachineId,
                required String key,
                Value<String?> keySensorRight = const Value.absent(),
                Value<String?> keySensorLeft = const Value.absent(),
                required double speed,
                Value<String?> maxStepsRight = const Value.absent(),
                Value<String?> maxStepsLeft = const Value.absent(),
              }) => MotorsCompanion.insert(
                id: id,
                systemMachineId: systemMachineId,
                key: key,
                keySensorRight: keySensorRight,
                keySensorLeft: keySensorLeft,
                speed: speed,
                maxStepsRight: maxStepsRight,
                maxStepsLeft: maxStepsLeft,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MotorsTable, MotorRow>(table),
                  $$MotorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({systemMachineId = false, processMotorsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (processMotorsRefs) db.processMotors,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (systemMachineId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.systemMachineId,
                                    referencedTable: $$MotorsTableReferences
                                        ._systemMachineIdTable(db),
                                    referencedColumn: $$MotorsTableReferences
                                        ._systemMachineIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (processMotorsRefs)
                        await $_getPrefetchedDataByColumns<
                          MotorRow,
                          $MotorsTable,
                          ProcessMotorRow,
                          $ProcessMotorsTable
                        >(
                          currentTable: table,
                          referencedTable: $$MotorsTableReferences
                              ._processMotorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MotorsTableReferences(
                                db,
                                table,
                                p0,
                              ).processMotorsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'motor_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MotorsTableProcessedTableManager =
    ProcessedTableManager<
      _$SystemDatabase,
      $MotorsTable,
      MotorRow,
      $$MotorsTableFilterComposer,
      $$MotorsTableOrderingComposer,
      $$MotorsTableAnnotationComposer,
      $$MotorsTableCreateCompanionBuilder,
      $$MotorsTableUpdateCompanionBuilder,
      (MotorRow, $$MotorsTableReferences),
      MotorRow,
      PrefetchHooks Function({bool systemMachineId, bool processMotorsRefs})
    >;
typedef $$ServosTableCreateCompanionBuilder =
    ServosCompanion Function({
      Value<int> id,
      required int machineId,
      required String key,
      required double maxOpen,
    });
typedef $$ServosTableUpdateCompanionBuilder =
    ServosCompanion Function({
      Value<int> id,
      Value<int> machineId,
      Value<String> key,
      Value<double> maxOpen,
    });

final class $$ServosTableReferences
    extends BaseReferences<_$SystemDatabase, $ServosTable, ServoRow> {
  $$ServosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SystemMachinesTable _machineIdTable(_$SystemDatabase db) =>
      db.systemMachines.createAlias('servos__machine_id__system_machines__id');

  $$SystemMachinesTableProcessedTableManager get machineId {
    final $_column = $_itemColumn<int>('machine_id')!;

    final manager = $$SystemMachinesTableTableManager(
      $_db,
      $_db.systemMachines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_machineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ProcessServosTable, List<ProcessServoRow>>
  _processServosRefsTable(_$SystemDatabase db) => MultiTypedResultKey.fromTable(
    db.processServos,
    aliasName: 'servos__id__process_servos__servo_id',
  );

  $$ProcessServosTableProcessedTableManager get processServosRefs {
    final manager = $$ProcessServosTableTableManager(
      $_db,
      $_db.processServos,
    ).filter((f) => f.servoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_processServosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ServosTableFilterComposer
    extends Composer<_$SystemDatabase, $ServosTable> {
  $$ServosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxOpen => $composableBuilder(
    column: $table.maxOpen,
    builder: (column) => ColumnFilters(column),
  );

  $$SystemMachinesTableFilterComposer get machineId {
    final $$SystemMachinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableFilterComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> processServosRefs(
    Expression<bool> Function($$ProcessServosTableFilterComposer f) f,
  ) {
    final $$ProcessServosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processServos,
      getReferencedColumn: (t) => t.servoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessServosTableFilterComposer(
            $db: $db,
            $table: $db.processServos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ServosTableOrderingComposer
    extends Composer<_$SystemDatabase, $ServosTable> {
  $$ServosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxOpen => $composableBuilder(
    column: $table.maxOpen,
    builder: (column) => ColumnOrderings(column),
  );

  $$SystemMachinesTableOrderingComposer get machineId {
    final $$SystemMachinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableOrderingComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ServosTableAnnotationComposer
    extends Composer<_$SystemDatabase, $ServosTable> {
  $$ServosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<double> get maxOpen =>
      $composableBuilder(column: $table.maxOpen, builder: (column) => column);

  $$SystemMachinesTableAnnotationComposer get machineId {
    final $$SystemMachinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableAnnotationComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> processServosRefs<T extends Object>(
    Expression<T> Function($$ProcessServosTableAnnotationComposer a) f,
  ) {
    final $$ProcessServosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processServos,
      getReferencedColumn: (t) => t.servoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessServosTableAnnotationComposer(
            $db: $db,
            $table: $db.processServos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ServosTableTableManager
    extends
        RootTableManager<
          _$SystemDatabase,
          $ServosTable,
          ServoRow,
          $$ServosTableFilterComposer,
          $$ServosTableOrderingComposer,
          $$ServosTableAnnotationComposer,
          $$ServosTableCreateCompanionBuilder,
          $$ServosTableUpdateCompanionBuilder,
          (ServoRow, $$ServosTableReferences),
          ServoRow,
          PrefetchHooks Function({bool machineId, bool processServosRefs})
        > {
  $$ServosTableTableManager(_$SystemDatabase db, $ServosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> machineId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<double> maxOpen = const Value.absent(),
              }) => ServosCompanion(
                id: id,
                machineId: machineId,
                key: key,
                maxOpen: maxOpen,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int machineId,
                required String key,
                required double maxOpen,
              }) => ServosCompanion.insert(
                id: id,
                machineId: machineId,
                key: key,
                maxOpen: maxOpen,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ServosTable, ServoRow>(table),
                  $$ServosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({machineId = false, processServosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (processServosRefs) db.processServos,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (machineId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.machineId,
                                    referencedTable: $$ServosTableReferences
                                        ._machineIdTable(db),
                                    referencedColumn: $$ServosTableReferences
                                        ._machineIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (processServosRefs)
                        await $_getPrefetchedDataByColumns<
                          ServoRow,
                          $ServosTable,
                          ProcessServoRow,
                          $ProcessServosTable
                        >(
                          currentTable: table,
                          referencedTable: $$ServosTableReferences
                              ._processServosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ServosTableReferences(
                                db,
                                table,
                                p0,
                              ).processServosRefs,
                          currentColumn: 'id',
                          referencedColumn: 'servo_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ServosTableProcessedTableManager =
    ProcessedTableManager<
      _$SystemDatabase,
      $ServosTable,
      ServoRow,
      $$ServosTableFilterComposer,
      $$ServosTableOrderingComposer,
      $$ServosTableAnnotationComposer,
      $$ServosTableCreateCompanionBuilder,
      $$ServosTableUpdateCompanionBuilder,
      (ServoRow, $$ServosTableReferences),
      ServoRow,
      PrefetchHooks Function({bool machineId, bool processServosRefs})
    >;
typedef $$SensorsTableCreateCompanionBuilder =
    SensorsCompanion Function({
      Value<int> id,
      Value<int?> machineId,
      required String key,
      required String name,
    });
typedef $$SensorsTableUpdateCompanionBuilder =
    SensorsCompanion Function({
      Value<int> id,
      Value<int?> machineId,
      Value<String> key,
      Value<String> name,
    });

final class $$SensorsTableReferences
    extends BaseReferences<_$SystemDatabase, $SensorsTable, SensorRow> {
  $$SensorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SystemMachinesTable _machineIdTable(_$SystemDatabase db) =>
      db.systemMachines.createAlias('sensors__machine_id__system_machines__id');

  $$SystemMachinesTableProcessedTableManager? get machineId {
    final $_column = $_itemColumn<int>('machine_id');
    if ($_column == null) return null;
    final manager = $$SystemMachinesTableTableManager(
      $_db,
      $_db.systemMachines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_machineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ProcessesTable, List<ProcessRow>>
  _processesRefsTable(_$SystemDatabase db) => MultiTypedResultKey.fromTable(
    db.processes,
    aliasName: 'sensors__id__processes__activation_sensor_id',
  );

  $$ProcessesTableProcessedTableManager get processesRefs {
    final manager = $$ProcessesTableTableManager($_db, $_db.processes).filter(
      (f) => f.activationSensorId.id.sqlEquals($_itemColumn<int>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_processesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SensorsTableFilterComposer
    extends Composer<_$SystemDatabase, $SensorsTable> {
  $$SensorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$SystemMachinesTableFilterComposer get machineId {
    final $$SystemMachinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableFilterComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> processesRefs(
    Expression<bool> Function($$ProcessesTableFilterComposer f) f,
  ) {
    final $$ProcessesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processes,
      getReferencedColumn: (t) => t.activationSensorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessesTableFilterComposer(
            $db: $db,
            $table: $db.processes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SensorsTableOrderingComposer
    extends Composer<_$SystemDatabase, $SensorsTable> {
  $$SensorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$SystemMachinesTableOrderingComposer get machineId {
    final $$SystemMachinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableOrderingComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SensorsTableAnnotationComposer
    extends Composer<_$SystemDatabase, $SensorsTable> {
  $$SensorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$SystemMachinesTableAnnotationComposer get machineId {
    final $$SystemMachinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableAnnotationComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> processesRefs<T extends Object>(
    Expression<T> Function($$ProcessesTableAnnotationComposer a) f,
  ) {
    final $$ProcessesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processes,
      getReferencedColumn: (t) => t.activationSensorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessesTableAnnotationComposer(
            $db: $db,
            $table: $db.processes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SensorsTableTableManager
    extends
        RootTableManager<
          _$SystemDatabase,
          $SensorsTable,
          SensorRow,
          $$SensorsTableFilterComposer,
          $$SensorsTableOrderingComposer,
          $$SensorsTableAnnotationComposer,
          $$SensorsTableCreateCompanionBuilder,
          $$SensorsTableUpdateCompanionBuilder,
          (SensorRow, $$SensorsTableReferences),
          SensorRow,
          PrefetchHooks Function({bool machineId, bool processesRefs})
        > {
  $$SensorsTableTableManager(_$SystemDatabase db, $SensorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SensorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SensorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SensorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> machineId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => SensorsCompanion(
                id: id,
                machineId: machineId,
                key: key,
                name: name,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> machineId = const Value.absent(),
                required String key,
                required String name,
              }) => SensorsCompanion.insert(
                id: id,
                machineId: machineId,
                key: key,
                name: name,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SensorsTable, SensorRow>(table),
                  $$SensorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({machineId = false, processesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (processesRefs) db.processes],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (machineId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.machineId,
                                referencedTable: $$SensorsTableReferences
                                    ._machineIdTable(db),
                                referencedColumn: $$SensorsTableReferences
                                    ._machineIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (processesRefs)
                    await $_getPrefetchedDataByColumns<
                      SensorRow,
                      $SensorsTable,
                      ProcessRow,
                      $ProcessesTable
                    >(
                      currentTable: table,
                      referencedTable: $$SensorsTableReferences
                          ._processesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SensorsTableReferences(db, table, p0).processesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'activation_sensor_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SensorsTableProcessedTableManager =
    ProcessedTableManager<
      _$SystemDatabase,
      $SensorsTable,
      SensorRow,
      $$SensorsTableFilterComposer,
      $$SensorsTableOrderingComposer,
      $$SensorsTableAnnotationComposer,
      $$SensorsTableCreateCompanionBuilder,
      $$SensorsTableUpdateCompanionBuilder,
      (SensorRow, $$SensorsTableReferences),
      SensorRow,
      PrefetchHooks Function({bool machineId, bool processesRefs})
    >;
typedef $$ProcessesTableCreateCompanionBuilder =
    ProcessesCompanion Function({
      Value<int> id,
      required String name,
      required int order,
      Value<int?> machineId,
      Value<int?> activationSensorId,
      Value<String?> mqttTopic,
      Value<String?> mqttExpectedMessage,
      Value<String?> mqttCompletionTopic,
      Value<String?> mqttCompletionMessage,
    });
typedef $$ProcessesTableUpdateCompanionBuilder =
    ProcessesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> order,
      Value<int?> machineId,
      Value<int?> activationSensorId,
      Value<String?> mqttTopic,
      Value<String?> mqttExpectedMessage,
      Value<String?> mqttCompletionTopic,
      Value<String?> mqttCompletionMessage,
    });

final class $$ProcessesTableReferences
    extends BaseReferences<_$SystemDatabase, $ProcessesTable, ProcessRow> {
  $$ProcessesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SystemMachinesTable _machineIdTable(_$SystemDatabase db) => db
      .systemMachines
      .createAlias('processes__machine_id__system_machines__id');

  $$SystemMachinesTableProcessedTableManager? get machineId {
    final $_column = $_itemColumn<int>('machine_id');
    if ($_column == null) return null;
    final manager = $$SystemMachinesTableTableManager(
      $_db,
      $_db.systemMachines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_machineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SensorsTable _activationSensorIdTable(_$SystemDatabase db) =>
      db.sensors.createAlias('processes__activation_sensor_id__sensors__id');

  $$SensorsTableProcessedTableManager? get activationSensorId {
    final $_column = $_itemColumn<int>('activation_sensor_id');
    if ($_column == null) return null;
    final manager = $$SensorsTableTableManager(
      $_db,
      $_db.sensors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activationSensorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ProcessMotorsTable, List<ProcessMotorRow>>
  _processMotorsRefsTable(_$SystemDatabase db) => MultiTypedResultKey.fromTable(
    db.processMotors,
    aliasName: 'processes__id__process_motors__process_id',
  );

  $$ProcessMotorsTableProcessedTableManager get processMotorsRefs {
    final manager = $$ProcessMotorsTableTableManager(
      $_db,
      $_db.processMotors,
    ).filter((f) => f.processId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_processMotorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProcessServosTable, List<ProcessServoRow>>
  _processServosRefsTable(_$SystemDatabase db) => MultiTypedResultKey.fromTable(
    db.processServos,
    aliasName: 'processes__id__process_servos__process_id',
  );

  $$ProcessServosTableProcessedTableManager get processServosRefs {
    final manager = $$ProcessServosTableTableManager(
      $_db,
      $_db.processServos,
    ).filter((f) => f.processId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_processServosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProcessHistoricsTable, List<ProcessHistoricRow>>
  _processHistoricsRefsTable(_$SystemDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.processHistorics,
        aliasName: 'processes__id__process_historics__process_id',
      );

  $$ProcessHistoricsTableProcessedTableManager get processHistoricsRefs {
    final manager = $$ProcessHistoricsTableTableManager(
      $_db,
      $_db.processHistorics,
    ).filter((f) => f.processId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _processHistoricsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProcessesTableFilterComposer
    extends Composer<_$SystemDatabase, $ProcessesTable> {
  $$ProcessesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mqttTopic => $composableBuilder(
    column: $table.mqttTopic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mqttExpectedMessage => $composableBuilder(
    column: $table.mqttExpectedMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mqttCompletionTopic => $composableBuilder(
    column: $table.mqttCompletionTopic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mqttCompletionMessage => $composableBuilder(
    column: $table.mqttCompletionMessage,
    builder: (column) => ColumnFilters(column),
  );

  $$SystemMachinesTableFilterComposer get machineId {
    final $$SystemMachinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableFilterComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SensorsTableFilterComposer get activationSensorId {
    final $$SensorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activationSensorId,
      referencedTable: $db.sensors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SensorsTableFilterComposer(
            $db: $db,
            $table: $db.sensors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> processMotorsRefs(
    Expression<bool> Function($$ProcessMotorsTableFilterComposer f) f,
  ) {
    final $$ProcessMotorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processMotors,
      getReferencedColumn: (t) => t.processId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessMotorsTableFilterComposer(
            $db: $db,
            $table: $db.processMotors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> processServosRefs(
    Expression<bool> Function($$ProcessServosTableFilterComposer f) f,
  ) {
    final $$ProcessServosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processServos,
      getReferencedColumn: (t) => t.processId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessServosTableFilterComposer(
            $db: $db,
            $table: $db.processServos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> processHistoricsRefs(
    Expression<bool> Function($$ProcessHistoricsTableFilterComposer f) f,
  ) {
    final $$ProcessHistoricsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processHistorics,
      getReferencedColumn: (t) => t.processId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessHistoricsTableFilterComposer(
            $db: $db,
            $table: $db.processHistorics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProcessesTableOrderingComposer
    extends Composer<_$SystemDatabase, $ProcessesTable> {
  $$ProcessesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mqttTopic => $composableBuilder(
    column: $table.mqttTopic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mqttExpectedMessage => $composableBuilder(
    column: $table.mqttExpectedMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mqttCompletionTopic => $composableBuilder(
    column: $table.mqttCompletionTopic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mqttCompletionMessage => $composableBuilder(
    column: $table.mqttCompletionMessage,
    builder: (column) => ColumnOrderings(column),
  );

  $$SystemMachinesTableOrderingComposer get machineId {
    final $$SystemMachinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableOrderingComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SensorsTableOrderingComposer get activationSensorId {
    final $$SensorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activationSensorId,
      referencedTable: $db.sensors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SensorsTableOrderingComposer(
            $db: $db,
            $table: $db.sensors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProcessesTableAnnotationComposer
    extends Composer<_$SystemDatabase, $ProcessesTable> {
  $$ProcessesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<String> get mqttTopic =>
      $composableBuilder(column: $table.mqttTopic, builder: (column) => column);

  GeneratedColumn<String> get mqttExpectedMessage => $composableBuilder(
    column: $table.mqttExpectedMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mqttCompletionTopic => $composableBuilder(
    column: $table.mqttCompletionTopic,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mqttCompletionMessage => $composableBuilder(
    column: $table.mqttCompletionMessage,
    builder: (column) => column,
  );

  $$SystemMachinesTableAnnotationComposer get machineId {
    final $$SystemMachinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.machineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableAnnotationComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SensorsTableAnnotationComposer get activationSensorId {
    final $$SensorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activationSensorId,
      referencedTable: $db.sensors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SensorsTableAnnotationComposer(
            $db: $db,
            $table: $db.sensors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> processMotorsRefs<T extends Object>(
    Expression<T> Function($$ProcessMotorsTableAnnotationComposer a) f,
  ) {
    final $$ProcessMotorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processMotors,
      getReferencedColumn: (t) => t.processId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessMotorsTableAnnotationComposer(
            $db: $db,
            $table: $db.processMotors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> processServosRefs<T extends Object>(
    Expression<T> Function($$ProcessServosTableAnnotationComposer a) f,
  ) {
    final $$ProcessServosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processServos,
      getReferencedColumn: (t) => t.processId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessServosTableAnnotationComposer(
            $db: $db,
            $table: $db.processServos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> processHistoricsRefs<T extends Object>(
    Expression<T> Function($$ProcessHistoricsTableAnnotationComposer a) f,
  ) {
    final $$ProcessHistoricsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processHistorics,
      getReferencedColumn: (t) => t.processId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessHistoricsTableAnnotationComposer(
            $db: $db,
            $table: $db.processHistorics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProcessesTableTableManager
    extends
        RootTableManager<
          _$SystemDatabase,
          $ProcessesTable,
          ProcessRow,
          $$ProcessesTableFilterComposer,
          $$ProcessesTableOrderingComposer,
          $$ProcessesTableAnnotationComposer,
          $$ProcessesTableCreateCompanionBuilder,
          $$ProcessesTableUpdateCompanionBuilder,
          (ProcessRow, $$ProcessesTableReferences),
          ProcessRow,
          PrefetchHooks Function({
            bool machineId,
            bool activationSensorId,
            bool processMotorsRefs,
            bool processServosRefs,
            bool processHistoricsRefs,
          })
        > {
  $$ProcessesTableTableManager(_$SystemDatabase db, $ProcessesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProcessesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProcessesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProcessesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<int?> machineId = const Value.absent(),
                Value<int?> activationSensorId = const Value.absent(),
                Value<String?> mqttTopic = const Value.absent(),
                Value<String?> mqttExpectedMessage = const Value.absent(),
                Value<String?> mqttCompletionTopic = const Value.absent(),
                Value<String?> mqttCompletionMessage = const Value.absent(),
              }) => ProcessesCompanion(
                id: id,
                name: name,
                order: order,
                machineId: machineId,
                activationSensorId: activationSensorId,
                mqttTopic: mqttTopic,
                mqttExpectedMessage: mqttExpectedMessage,
                mqttCompletionTopic: mqttCompletionTopic,
                mqttCompletionMessage: mqttCompletionMessage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int order,
                Value<int?> machineId = const Value.absent(),
                Value<int?> activationSensorId = const Value.absent(),
                Value<String?> mqttTopic = const Value.absent(),
                Value<String?> mqttExpectedMessage = const Value.absent(),
                Value<String?> mqttCompletionTopic = const Value.absent(),
                Value<String?> mqttCompletionMessage = const Value.absent(),
              }) => ProcessesCompanion.insert(
                id: id,
                name: name,
                order: order,
                machineId: machineId,
                activationSensorId: activationSensorId,
                mqttTopic: mqttTopic,
                mqttExpectedMessage: mqttExpectedMessage,
                mqttCompletionTopic: mqttCompletionTopic,
                mqttCompletionMessage: mqttCompletionMessage,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProcessesTable, ProcessRow>(table),
                  $$ProcessesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                machineId = false,
                activationSensorId = false,
                processMotorsRefs = false,
                processServosRefs = false,
                processHistoricsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (processMotorsRefs) db.processMotors,
                    if (processServosRefs) db.processServos,
                    if (processHistoricsRefs) db.processHistorics,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (machineId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.machineId,
                                    referencedTable: $$ProcessesTableReferences
                                        ._machineIdTable(db),
                                    referencedColumn: $$ProcessesTableReferences
                                        ._machineIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (activationSensorId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.activationSensorId,
                                    referencedTable: $$ProcessesTableReferences
                                        ._activationSensorIdTable(db),
                                    referencedColumn: $$ProcessesTableReferences
                                        ._activationSensorIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (processMotorsRefs)
                        await $_getPrefetchedDataByColumns<
                          ProcessRow,
                          $ProcessesTable,
                          ProcessMotorRow,
                          $ProcessMotorsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProcessesTableReferences
                              ._processMotorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProcessesTableReferences(
                                db,
                                table,
                                p0,
                              ).processMotorsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'process_id',
                          typedResults: items,
                        ),
                      if (processServosRefs)
                        await $_getPrefetchedDataByColumns<
                          ProcessRow,
                          $ProcessesTable,
                          ProcessServoRow,
                          $ProcessServosTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProcessesTableReferences
                              ._processServosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProcessesTableReferences(
                                db,
                                table,
                                p0,
                              ).processServosRefs,
                          currentColumn: 'id',
                          referencedColumn: 'process_id',
                          typedResults: items,
                        ),
                      if (processHistoricsRefs)
                        await $_getPrefetchedDataByColumns<
                          ProcessRow,
                          $ProcessesTable,
                          ProcessHistoricRow,
                          $ProcessHistoricsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProcessesTableReferences
                              ._processHistoricsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProcessesTableReferences(
                                db,
                                table,
                                p0,
                              ).processHistoricsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'process_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProcessesTableProcessedTableManager =
    ProcessedTableManager<
      _$SystemDatabase,
      $ProcessesTable,
      ProcessRow,
      $$ProcessesTableFilterComposer,
      $$ProcessesTableOrderingComposer,
      $$ProcessesTableAnnotationComposer,
      $$ProcessesTableCreateCompanionBuilder,
      $$ProcessesTableUpdateCompanionBuilder,
      (ProcessRow, $$ProcessesTableReferences),
      ProcessRow,
      PrefetchHooks Function({
        bool machineId,
        bool activationSensorId,
        bool processMotorsRefs,
        bool processServosRefs,
        bool processHistoricsRefs,
      })
    >;
typedef $$ProcessMotorsTableCreateCompanionBuilder =
    ProcessMotorsCompanion Function({
      Value<int> id,
      required int processId,
      required int motorId,
      required String name,
      required int order,
      required double steps,
      Value<double> speed,
    });
typedef $$ProcessMotorsTableUpdateCompanionBuilder =
    ProcessMotorsCompanion Function({
      Value<int> id,
      Value<int> processId,
      Value<int> motorId,
      Value<String> name,
      Value<int> order,
      Value<double> steps,
      Value<double> speed,
    });

final class $$ProcessMotorsTableReferences
    extends
        BaseReferences<_$SystemDatabase, $ProcessMotorsTable, ProcessMotorRow> {
  $$ProcessMotorsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProcessesTable _processIdTable(_$SystemDatabase db) =>
      db.processes.createAlias('process_motors__process_id__processes__id');

  $$ProcessesTableProcessedTableManager get processId {
    final $_column = $_itemColumn<int>('process_id')!;

    final manager = $$ProcessesTableTableManager(
      $_db,
      $_db.processes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_processIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MotorsTable _motorIdTable(_$SystemDatabase db) =>
      db.motors.createAlias('process_motors__motor_id__motors__id');

  $$MotorsTableProcessedTableManager get motorId {
    final $_column = $_itemColumn<int>('motor_id')!;

    final manager = $$MotorsTableTableManager(
      $_db,
      $_db.motors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_motorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ProcessHistoricMotorsTable,
    List<ProcessHistoricMotorRow>
  >
  _processHistoricMotorsRefsTable(_$SystemDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.processHistoricMotors,
        aliasName:
            'process_motors__id__process_historic_motors__process_motor_id',
      );

  $$ProcessHistoricMotorsTableProcessedTableManager
  get processHistoricMotorsRefs {
    final manager = $$ProcessHistoricMotorsTableTableManager(
      $_db,
      $_db.processHistoricMotors,
    ).filter((f) => f.processMotorId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _processHistoricMotorsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProcessMotorsTableFilterComposer
    extends Composer<_$SystemDatabase, $ProcessMotorsTable> {
  $$ProcessMotorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  $$ProcessesTableFilterComposer get processId {
    final $$ProcessesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.processId,
      referencedTable: $db.processes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessesTableFilterComposer(
            $db: $db,
            $table: $db.processes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MotorsTableFilterComposer get motorId {
    final $$MotorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.motorId,
      referencedTable: $db.motors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MotorsTableFilterComposer(
            $db: $db,
            $table: $db.motors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> processHistoricMotorsRefs(
    Expression<bool> Function($$ProcessHistoricMotorsTableFilterComposer f) f,
  ) {
    final $$ProcessHistoricMotorsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.processHistoricMotors,
          getReferencedColumn: (t) => t.processMotorId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProcessHistoricMotorsTableFilterComposer(
                $db: $db,
                $table: $db.processHistoricMotors,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProcessMotorsTableOrderingComposer
    extends Composer<_$SystemDatabase, $ProcessMotorsTable> {
  $$ProcessMotorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProcessesTableOrderingComposer get processId {
    final $$ProcessesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.processId,
      referencedTable: $db.processes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessesTableOrderingComposer(
            $db: $db,
            $table: $db.processes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MotorsTableOrderingComposer get motorId {
    final $$MotorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.motorId,
      referencedTable: $db.motors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MotorsTableOrderingComposer(
            $db: $db,
            $table: $db.motors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProcessMotorsTableAnnotationComposer
    extends Composer<_$SystemDatabase, $ProcessMotorsTable> {
  $$ProcessMotorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<double> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  $$ProcessesTableAnnotationComposer get processId {
    final $$ProcessesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.processId,
      referencedTable: $db.processes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessesTableAnnotationComposer(
            $db: $db,
            $table: $db.processes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MotorsTableAnnotationComposer get motorId {
    final $$MotorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.motorId,
      referencedTable: $db.motors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MotorsTableAnnotationComposer(
            $db: $db,
            $table: $db.motors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> processHistoricMotorsRefs<T extends Object>(
    Expression<T> Function($$ProcessHistoricMotorsTableAnnotationComposer a) f,
  ) {
    final $$ProcessHistoricMotorsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.processHistoricMotors,
          getReferencedColumn: (t) => t.processMotorId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProcessHistoricMotorsTableAnnotationComposer(
                $db: $db,
                $table: $db.processHistoricMotors,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProcessMotorsTableTableManager
    extends
        RootTableManager<
          _$SystemDatabase,
          $ProcessMotorsTable,
          ProcessMotorRow,
          $$ProcessMotorsTableFilterComposer,
          $$ProcessMotorsTableOrderingComposer,
          $$ProcessMotorsTableAnnotationComposer,
          $$ProcessMotorsTableCreateCompanionBuilder,
          $$ProcessMotorsTableUpdateCompanionBuilder,
          (ProcessMotorRow, $$ProcessMotorsTableReferences),
          ProcessMotorRow,
          PrefetchHooks Function({
            bool processId,
            bool motorId,
            bool processHistoricMotorsRefs,
          })
        > {
  $$ProcessMotorsTableTableManager(
    _$SystemDatabase db,
    $ProcessMotorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProcessMotorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProcessMotorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProcessMotorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> processId = const Value.absent(),
                Value<int> motorId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<double> steps = const Value.absent(),
                Value<double> speed = const Value.absent(),
              }) => ProcessMotorsCompanion(
                id: id,
                processId: processId,
                motorId: motorId,
                name: name,
                order: order,
                steps: steps,
                speed: speed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int processId,
                required int motorId,
                required String name,
                required int order,
                required double steps,
                Value<double> speed = const Value.absent(),
              }) => ProcessMotorsCompanion.insert(
                id: id,
                processId: processId,
                motorId: motorId,
                name: name,
                order: order,
                steps: steps,
                speed: speed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProcessMotorsTable, ProcessMotorRow>(table),
                  $$ProcessMotorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                processId = false,
                motorId = false,
                processHistoricMotorsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (processHistoricMotorsRefs) db.processHistoricMotors,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (processId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.processId,
                                    referencedTable:
                                        $$ProcessMotorsTableReferences
                                            ._processIdTable(db),
                                    referencedColumn:
                                        $$ProcessMotorsTableReferences
                                            ._processIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (motorId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.motorId,
                                    referencedTable:
                                        $$ProcessMotorsTableReferences
                                            ._motorIdTable(db),
                                    referencedColumn:
                                        $$ProcessMotorsTableReferences
                                            ._motorIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (processHistoricMotorsRefs)
                        await $_getPrefetchedDataByColumns<
                          ProcessMotorRow,
                          $ProcessMotorsTable,
                          ProcessHistoricMotorRow,
                          $ProcessHistoricMotorsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProcessMotorsTableReferences
                              ._processHistoricMotorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProcessMotorsTableReferences(
                                db,
                                table,
                                p0,
                              ).processHistoricMotorsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'process_motor_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProcessMotorsTableProcessedTableManager =
    ProcessedTableManager<
      _$SystemDatabase,
      $ProcessMotorsTable,
      ProcessMotorRow,
      $$ProcessMotorsTableFilterComposer,
      $$ProcessMotorsTableOrderingComposer,
      $$ProcessMotorsTableAnnotationComposer,
      $$ProcessMotorsTableCreateCompanionBuilder,
      $$ProcessMotorsTableUpdateCompanionBuilder,
      (ProcessMotorRow, $$ProcessMotorsTableReferences),
      ProcessMotorRow,
      PrefetchHooks Function({
        bool processId,
        bool motorId,
        bool processHistoricMotorsRefs,
      })
    >;
typedef $$ProcessServosTableCreateCompanionBuilder =
    ProcessServosCompanion Function({
      Value<int> id,
      required int processId,
      required int servoId,
      required String name,
      required int order,
      required double openValue,
      Value<double> speed,
    });
typedef $$ProcessServosTableUpdateCompanionBuilder =
    ProcessServosCompanion Function({
      Value<int> id,
      Value<int> processId,
      Value<int> servoId,
      Value<String> name,
      Value<int> order,
      Value<double> openValue,
      Value<double> speed,
    });

final class $$ProcessServosTableReferences
    extends
        BaseReferences<_$SystemDatabase, $ProcessServosTable, ProcessServoRow> {
  $$ProcessServosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProcessesTable _processIdTable(_$SystemDatabase db) =>
      db.processes.createAlias('process_servos__process_id__processes__id');

  $$ProcessesTableProcessedTableManager get processId {
    final $_column = $_itemColumn<int>('process_id')!;

    final manager = $$ProcessesTableTableManager(
      $_db,
      $_db.processes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_processIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ServosTable _servoIdTable(_$SystemDatabase db) =>
      db.servos.createAlias('process_servos__servo_id__servos__id');

  $$ServosTableProcessedTableManager get servoId {
    final $_column = $_itemColumn<int>('servo_id')!;

    final manager = $$ServosTableTableManager(
      $_db,
      $_db.servos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_servoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProcessServosTableFilterComposer
    extends Composer<_$SystemDatabase, $ProcessServosTable> {
  $$ProcessServosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get openValue => $composableBuilder(
    column: $table.openValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  $$ProcessesTableFilterComposer get processId {
    final $$ProcessesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.processId,
      referencedTable: $db.processes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessesTableFilterComposer(
            $db: $db,
            $table: $db.processes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ServosTableFilterComposer get servoId {
    final $$ServosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.servoId,
      referencedTable: $db.servos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServosTableFilterComposer(
            $db: $db,
            $table: $db.servos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProcessServosTableOrderingComposer
    extends Composer<_$SystemDatabase, $ProcessServosTable> {
  $$ProcessServosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get openValue => $composableBuilder(
    column: $table.openValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProcessesTableOrderingComposer get processId {
    final $$ProcessesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.processId,
      referencedTable: $db.processes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessesTableOrderingComposer(
            $db: $db,
            $table: $db.processes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ServosTableOrderingComposer get servoId {
    final $$ServosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.servoId,
      referencedTable: $db.servos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServosTableOrderingComposer(
            $db: $db,
            $table: $db.servos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProcessServosTableAnnotationComposer
    extends Composer<_$SystemDatabase, $ProcessServosTable> {
  $$ProcessServosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<double> get openValue =>
      $composableBuilder(column: $table.openValue, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  $$ProcessesTableAnnotationComposer get processId {
    final $$ProcessesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.processId,
      referencedTable: $db.processes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessesTableAnnotationComposer(
            $db: $db,
            $table: $db.processes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ServosTableAnnotationComposer get servoId {
    final $$ServosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.servoId,
      referencedTable: $db.servos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServosTableAnnotationComposer(
            $db: $db,
            $table: $db.servos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProcessServosTableTableManager
    extends
        RootTableManager<
          _$SystemDatabase,
          $ProcessServosTable,
          ProcessServoRow,
          $$ProcessServosTableFilterComposer,
          $$ProcessServosTableOrderingComposer,
          $$ProcessServosTableAnnotationComposer,
          $$ProcessServosTableCreateCompanionBuilder,
          $$ProcessServosTableUpdateCompanionBuilder,
          (ProcessServoRow, $$ProcessServosTableReferences),
          ProcessServoRow,
          PrefetchHooks Function({bool processId, bool servoId})
        > {
  $$ProcessServosTableTableManager(
    _$SystemDatabase db,
    $ProcessServosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProcessServosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProcessServosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProcessServosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> processId = const Value.absent(),
                Value<int> servoId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<double> openValue = const Value.absent(),
                Value<double> speed = const Value.absent(),
              }) => ProcessServosCompanion(
                id: id,
                processId: processId,
                servoId: servoId,
                name: name,
                order: order,
                openValue: openValue,
                speed: speed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int processId,
                required int servoId,
                required String name,
                required int order,
                required double openValue,
                Value<double> speed = const Value.absent(),
              }) => ProcessServosCompanion.insert(
                id: id,
                processId: processId,
                servoId: servoId,
                name: name,
                order: order,
                openValue: openValue,
                speed: speed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProcessServosTable, ProcessServoRow>(table),
                  $$ProcessServosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({processId = false, servoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (processId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.processId,
                                referencedTable: $$ProcessServosTableReferences
                                    ._processIdTable(db),
                                referencedColumn: $$ProcessServosTableReferences
                                    ._processIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (servoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.servoId,
                                referencedTable: $$ProcessServosTableReferences
                                    ._servoIdTable(db),
                                referencedColumn: $$ProcessServosTableReferences
                                    ._servoIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProcessServosTableProcessedTableManager =
    ProcessedTableManager<
      _$SystemDatabase,
      $ProcessServosTable,
      ProcessServoRow,
      $$ProcessServosTableFilterComposer,
      $$ProcessServosTableOrderingComposer,
      $$ProcessServosTableAnnotationComposer,
      $$ProcessServosTableCreateCompanionBuilder,
      $$ProcessServosTableUpdateCompanionBuilder,
      (ProcessServoRow, $$ProcessServosTableReferences),
      ProcessServoRow,
      PrefetchHooks Function({bool processId, bool servoId})
    >;
typedef $$ProcessHistoricsTableCreateCompanionBuilder =
    ProcessHistoricsCompanion Function({
      Value<int> id,
      required int processId,
      required DateTime startTime,
      Value<DateTime?> endTime,
      Value<DateTime?> stopProcess,
      Value<String?> stopKey,
      required bool finishProcess,
    });
typedef $$ProcessHistoricsTableUpdateCompanionBuilder =
    ProcessHistoricsCompanion Function({
      Value<int> id,
      Value<int> processId,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<DateTime?> stopProcess,
      Value<String?> stopKey,
      Value<bool> finishProcess,
    });

final class $$ProcessHistoricsTableReferences
    extends
        BaseReferences<
          _$SystemDatabase,
          $ProcessHistoricsTable,
          ProcessHistoricRow
        > {
  $$ProcessHistoricsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProcessesTable _processIdTable(_$SystemDatabase db) =>
      db.processes.createAlias('process_historics__process_id__processes__id');

  $$ProcessesTableProcessedTableManager get processId {
    final $_column = $_itemColumn<int>('process_id')!;

    final manager = $$ProcessesTableTableManager(
      $_db,
      $_db.processes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_processIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProcessHistoricsTableFilterComposer
    extends Composer<_$SystemDatabase, $ProcessHistoricsTable> {
  $$ProcessHistoricsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get stopProcess => $composableBuilder(
    column: $table.stopProcess,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stopKey => $composableBuilder(
    column: $table.stopKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get finishProcess => $composableBuilder(
    column: $table.finishProcess,
    builder: (column) => ColumnFilters(column),
  );

  $$ProcessesTableFilterComposer get processId {
    final $$ProcessesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.processId,
      referencedTable: $db.processes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessesTableFilterComposer(
            $db: $db,
            $table: $db.processes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProcessHistoricsTableOrderingComposer
    extends Composer<_$SystemDatabase, $ProcessHistoricsTable> {
  $$ProcessHistoricsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get stopProcess => $composableBuilder(
    column: $table.stopProcess,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stopKey => $composableBuilder(
    column: $table.stopKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get finishProcess => $composableBuilder(
    column: $table.finishProcess,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProcessesTableOrderingComposer get processId {
    final $$ProcessesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.processId,
      referencedTable: $db.processes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessesTableOrderingComposer(
            $db: $db,
            $table: $db.processes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProcessHistoricsTableAnnotationComposer
    extends Composer<_$SystemDatabase, $ProcessHistoricsTable> {
  $$ProcessHistoricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<DateTime> get stopProcess => $composableBuilder(
    column: $table.stopProcess,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stopKey =>
      $composableBuilder(column: $table.stopKey, builder: (column) => column);

  GeneratedColumn<bool> get finishProcess => $composableBuilder(
    column: $table.finishProcess,
    builder: (column) => column,
  );

  $$ProcessesTableAnnotationComposer get processId {
    final $$ProcessesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.processId,
      referencedTable: $db.processes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessesTableAnnotationComposer(
            $db: $db,
            $table: $db.processes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProcessHistoricsTableTableManager
    extends
        RootTableManager<
          _$SystemDatabase,
          $ProcessHistoricsTable,
          ProcessHistoricRow,
          $$ProcessHistoricsTableFilterComposer,
          $$ProcessHistoricsTableOrderingComposer,
          $$ProcessHistoricsTableAnnotationComposer,
          $$ProcessHistoricsTableCreateCompanionBuilder,
          $$ProcessHistoricsTableUpdateCompanionBuilder,
          (ProcessHistoricRow, $$ProcessHistoricsTableReferences),
          ProcessHistoricRow,
          PrefetchHooks Function({bool processId})
        > {
  $$ProcessHistoricsTableTableManager(
    _$SystemDatabase db,
    $ProcessHistoricsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProcessHistoricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProcessHistoricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProcessHistoricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> processId = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<DateTime?> stopProcess = const Value.absent(),
                Value<String?> stopKey = const Value.absent(),
                Value<bool> finishProcess = const Value.absent(),
              }) => ProcessHistoricsCompanion(
                id: id,
                processId: processId,
                startTime: startTime,
                endTime: endTime,
                stopProcess: stopProcess,
                stopKey: stopKey,
                finishProcess: finishProcess,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int processId,
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                Value<DateTime?> stopProcess = const Value.absent(),
                Value<String?> stopKey = const Value.absent(),
                required bool finishProcess,
              }) => ProcessHistoricsCompanion.insert(
                id: id,
                processId: processId,
                startTime: startTime,
                endTime: endTime,
                stopProcess: stopProcess,
                stopKey: stopKey,
                finishProcess: finishProcess,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProcessHistoricsTable, ProcessHistoricRow>(
                    table,
                  ),
                  $$ProcessHistoricsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({processId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (processId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.processId,
                                referencedTable:
                                    $$ProcessHistoricsTableReferences
                                        ._processIdTable(db),
                                referencedColumn:
                                    $$ProcessHistoricsTableReferences
                                        ._processIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProcessHistoricsTableProcessedTableManager =
    ProcessedTableManager<
      _$SystemDatabase,
      $ProcessHistoricsTable,
      ProcessHistoricRow,
      $$ProcessHistoricsTableFilterComposer,
      $$ProcessHistoricsTableOrderingComposer,
      $$ProcessHistoricsTableAnnotationComposer,
      $$ProcessHistoricsTableCreateCompanionBuilder,
      $$ProcessHistoricsTableUpdateCompanionBuilder,
      (ProcessHistoricRow, $$ProcessHistoricsTableReferences),
      ProcessHistoricRow,
      PrefetchHooks Function({bool processId})
    >;
typedef $$ProcessHistoricMotorsTableCreateCompanionBuilder =
    ProcessHistoricMotorsCompanion Function({
      Value<int> id,
      required int processMotorId,
      required DateTime startTime,
      Value<DateTime?> endTime,
      required double steps,
      required double speed,
    });
typedef $$ProcessHistoricMotorsTableUpdateCompanionBuilder =
    ProcessHistoricMotorsCompanion Function({
      Value<int> id,
      Value<int> processMotorId,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<double> steps,
      Value<double> speed,
    });

final class $$ProcessHistoricMotorsTableReferences
    extends
        BaseReferences<
          _$SystemDatabase,
          $ProcessHistoricMotorsTable,
          ProcessHistoricMotorRow
        > {
  $$ProcessHistoricMotorsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProcessMotorsTable _processMotorIdTable(_$SystemDatabase db) =>
      db.processMotors.createAlias(
        'process_historic_motors__process_motor_id__process_motors__id',
      );

  $$ProcessMotorsTableProcessedTableManager get processMotorId {
    final $_column = $_itemColumn<int>('process_motor_id')!;

    final manager = $$ProcessMotorsTableTableManager(
      $_db,
      $_db.processMotors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_processMotorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProcessHistoricMotorsTableFilterComposer
    extends Composer<_$SystemDatabase, $ProcessHistoricMotorsTable> {
  $$ProcessHistoricMotorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  $$ProcessMotorsTableFilterComposer get processMotorId {
    final $$ProcessMotorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.processMotorId,
      referencedTable: $db.processMotors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessMotorsTableFilterComposer(
            $db: $db,
            $table: $db.processMotors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProcessHistoricMotorsTableOrderingComposer
    extends Composer<_$SystemDatabase, $ProcessHistoricMotorsTable> {
  $$ProcessHistoricMotorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProcessMotorsTableOrderingComposer get processMotorId {
    final $$ProcessMotorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.processMotorId,
      referencedTable: $db.processMotors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessMotorsTableOrderingComposer(
            $db: $db,
            $table: $db.processMotors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProcessHistoricMotorsTableAnnotationComposer
    extends Composer<_$SystemDatabase, $ProcessHistoricMotorsTable> {
  $$ProcessHistoricMotorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<double> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  $$ProcessMotorsTableAnnotationComposer get processMotorId {
    final $$ProcessMotorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.processMotorId,
      referencedTable: $db.processMotors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessMotorsTableAnnotationComposer(
            $db: $db,
            $table: $db.processMotors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProcessHistoricMotorsTableTableManager
    extends
        RootTableManager<
          _$SystemDatabase,
          $ProcessHistoricMotorsTable,
          ProcessHistoricMotorRow,
          $$ProcessHistoricMotorsTableFilterComposer,
          $$ProcessHistoricMotorsTableOrderingComposer,
          $$ProcessHistoricMotorsTableAnnotationComposer,
          $$ProcessHistoricMotorsTableCreateCompanionBuilder,
          $$ProcessHistoricMotorsTableUpdateCompanionBuilder,
          (ProcessHistoricMotorRow, $$ProcessHistoricMotorsTableReferences),
          ProcessHistoricMotorRow,
          PrefetchHooks Function({bool processMotorId})
        > {
  $$ProcessHistoricMotorsTableTableManager(
    _$SystemDatabase db,
    $ProcessHistoricMotorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProcessHistoricMotorsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ProcessHistoricMotorsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProcessHistoricMotorsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> processMotorId = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<double> steps = const Value.absent(),
                Value<double> speed = const Value.absent(),
              }) => ProcessHistoricMotorsCompanion(
                id: id,
                processMotorId: processMotorId,
                startTime: startTime,
                endTime: endTime,
                steps: steps,
                speed: speed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int processMotorId,
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                required double steps,
                required double speed,
              }) => ProcessHistoricMotorsCompanion.insert(
                id: id,
                processMotorId: processMotorId,
                startTime: startTime,
                endTime: endTime,
                steps: steps,
                speed: speed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ProcessHistoricMotorsTable,
                    ProcessHistoricMotorRow
                  >(table),
                  $$ProcessHistoricMotorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({processMotorId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (processMotorId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.processMotorId,
                                referencedTable:
                                    $$ProcessHistoricMotorsTableReferences
                                        ._processMotorIdTable(db),
                                referencedColumn:
                                    $$ProcessHistoricMotorsTableReferences
                                        ._processMotorIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProcessHistoricMotorsTableProcessedTableManager =
    ProcessedTableManager<
      _$SystemDatabase,
      $ProcessHistoricMotorsTable,
      ProcessHistoricMotorRow,
      $$ProcessHistoricMotorsTableFilterComposer,
      $$ProcessHistoricMotorsTableOrderingComposer,
      $$ProcessHistoricMotorsTableAnnotationComposer,
      $$ProcessHistoricMotorsTableCreateCompanionBuilder,
      $$ProcessHistoricMotorsTableUpdateCompanionBuilder,
      (ProcessHistoricMotorRow, $$ProcessHistoricMotorsTableReferences),
      ProcessHistoricMotorRow,
      PrefetchHooks Function({bool processMotorId})
    >;
typedef $$SystemPositionsTableCreateCompanionBuilder =
    SystemPositionsCompanion Function({
      Value<int> id,
      required int number,
      required String type,
      required int systemMachineId,
    });
typedef $$SystemPositionsTableUpdateCompanionBuilder =
    SystemPositionsCompanion Function({
      Value<int> id,
      Value<int> number,
      Value<String> type,
      Value<int> systemMachineId,
    });

final class $$SystemPositionsTableReferences
    extends
        BaseReferences<
          _$SystemDatabase,
          $SystemPositionsTable,
          SystemPositionRow
        > {
  $$SystemPositionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SystemMachinesTable _systemMachineIdTable(_$SystemDatabase db) => db
      .systemMachines
      .createAlias('system_positions__system_machine_id__system_machines__id');

  $$SystemMachinesTableProcessedTableManager get systemMachineId {
    final $_column = $_itemColumn<int>('system_machine_id')!;

    final manager = $$SystemMachinesTableTableManager(
      $_db,
      $_db.systemMachines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_systemMachineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SystemPositionsTableFilterComposer
    extends Composer<_$SystemDatabase, $SystemPositionsTable> {
  $$SystemPositionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  $$SystemMachinesTableFilterComposer get systemMachineId {
    final $$SystemMachinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemMachineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableFilterComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SystemPositionsTableOrderingComposer
    extends Composer<_$SystemDatabase, $SystemPositionsTable> {
  $$SystemPositionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  $$SystemMachinesTableOrderingComposer get systemMachineId {
    final $$SystemMachinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemMachineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableOrderingComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SystemPositionsTableAnnotationComposer
    extends Composer<_$SystemDatabase, $SystemPositionsTable> {
  $$SystemPositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  $$SystemMachinesTableAnnotationComposer get systemMachineId {
    final $$SystemMachinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.systemMachineId,
      referencedTable: $db.systemMachines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SystemMachinesTableAnnotationComposer(
            $db: $db,
            $table: $db.systemMachines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SystemPositionsTableTableManager
    extends
        RootTableManager<
          _$SystemDatabase,
          $SystemPositionsTable,
          SystemPositionRow,
          $$SystemPositionsTableFilterComposer,
          $$SystemPositionsTableOrderingComposer,
          $$SystemPositionsTableAnnotationComposer,
          $$SystemPositionsTableCreateCompanionBuilder,
          $$SystemPositionsTableUpdateCompanionBuilder,
          (SystemPositionRow, $$SystemPositionsTableReferences),
          SystemPositionRow,
          PrefetchHooks Function({bool systemMachineId})
        > {
  $$SystemPositionsTableTableManager(
    _$SystemDatabase db,
    $SystemPositionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SystemPositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SystemPositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SystemPositionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> systemMachineId = const Value.absent(),
              }) => SystemPositionsCompanion(
                id: id,
                number: number,
                type: type,
                systemMachineId: systemMachineId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int number,
                required String type,
                required int systemMachineId,
              }) => SystemPositionsCompanion.insert(
                id: id,
                number: number,
                type: type,
                systemMachineId: systemMachineId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SystemPositionsTable, SystemPositionRow>(table),
                  $$SystemPositionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({systemMachineId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (systemMachineId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.systemMachineId,
                                referencedTable:
                                    $$SystemPositionsTableReferences
                                        ._systemMachineIdTable(db),
                                referencedColumn:
                                    $$SystemPositionsTableReferences
                                        ._systemMachineIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SystemPositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SystemDatabase,
      $SystemPositionsTable,
      SystemPositionRow,
      $$SystemPositionsTableFilterComposer,
      $$SystemPositionsTableOrderingComposer,
      $$SystemPositionsTableAnnotationComposer,
      $$SystemPositionsTableCreateCompanionBuilder,
      $$SystemPositionsTableUpdateCompanionBuilder,
      (SystemPositionRow, $$SystemPositionsTableReferences),
      SystemPositionRow,
      PrefetchHooks Function({bool systemMachineId})
    >;

class $SystemDatabaseManager {
  final _$SystemDatabase _db;
  $SystemDatabaseManager(this._db);
  $$SystemMachinesTableTableManager get systemMachines =>
      $$SystemMachinesTableTableManager(_db, _db.systemMachines);
  $$MotorsTableTableManager get motors =>
      $$MotorsTableTableManager(_db, _db.motors);
  $$ServosTableTableManager get servos =>
      $$ServosTableTableManager(_db, _db.servos);
  $$SensorsTableTableManager get sensors =>
      $$SensorsTableTableManager(_db, _db.sensors);
  $$ProcessesTableTableManager get processes =>
      $$ProcessesTableTableManager(_db, _db.processes);
  $$ProcessMotorsTableTableManager get processMotors =>
      $$ProcessMotorsTableTableManager(_db, _db.processMotors);
  $$ProcessServosTableTableManager get processServos =>
      $$ProcessServosTableTableManager(_db, _db.processServos);
  $$ProcessHistoricsTableTableManager get processHistorics =>
      $$ProcessHistoricsTableTableManager(_db, _db.processHistorics);
  $$ProcessHistoricMotorsTableTableManager get processHistoricMotors =>
      $$ProcessHistoricMotorsTableTableManager(_db, _db.processHistoricMotors);
  $$SystemPositionsTableTableManager get systemPositions =>
      $$SystemPositionsTableTableManager(_db, _db.systemPositions);
}

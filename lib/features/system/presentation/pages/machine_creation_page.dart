import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../peer_to_peer/domain/repositories/peer_repository.dart';
import '../../../peer_to_peer/domain/entities/peer_role.dart';
import '../../../peer_to_peer/domain/entities/peer_session.dart';
import '../../domain/entities/machine_configuration.dart';
import '../../domain/entities/motor.dart';
import '../../domain/entities/process.dart';
import '../../domain/entities/process_motors.dart';
import '../../domain/entities/process_servo.dart';
import '../../domain/entities/sensor.dart';
import '../../domain/entities/servo.dart';
import '../../domain/entities/system_machine.dart';
import '../../domain/repositories/system_repository.dart';
import '../../domain/services/system_configuration_service.dart';

class MachineCreationPage extends StatefulWidget {
  const MachineCreationPage({super.key});

  @override
  State<MachineCreationPage> createState() => _MachineCreationPageState();
}

class _MachineCreationPageState extends State<MachineCreationPage> {
  List<SystemMachine> _allMachines = const [];
  List<SystemMachine> _machines = const [];
  List<Motor> _motors = const [];
  List<Servo> _servos = const [];
  List<Sensor> _sensors = const [];
  List<ProcessMotors> _processMotors = const [];
  List<ProcessServo> _processServos = const [];
  List<Process> _processes = const [];
  SystemMachine? _selected;
  bool _loading = true;
  StreamSubscription<PeerSession>? _peerSubscription;
  PeerRole? _loadedRole;

  SystemRepository get _repository => GetIt.I<SystemRepository>();
  bool get _isSlave => GetIt.I<PeerRepository>().session.isSlave;

  @override
  void initState() {
    super.initState();
    final peer = GetIt.I<PeerRepository>();
    _loadedRole = peer.session.role;
    _peerSubscription = peer.sessionStream.listen((session) {
      if (session.role == _loadedRole) return;
      _loadedRole = session.role;
      _reload();
    });
    _reload();
  }

  @override
  void dispose() {
    _peerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    if (_isSlave) {
      _applySlaveConfiguration(
        GetIt.I<SystemConfigurationService>().localSlaveConfiguration,
      );
      return;
    }
    try {
      final machines = await _repository.getMachines();
      final motors = await _repository.getMotors();
      final servos = await _repository.getServos();
      final sensors = await _repository.getSensors();
      final processes = await _repository.getProcesses();
      final processMotors = <ProcessMotors>[];
      final processServos = <ProcessServo>[];
      for (final process in processes) {
        processMotors.addAll(await _repository.getProcessMotors(process.id));
        processServos.addAll(await _repository.getProcessServos(process.id));
      }
      if (!mounted) return;
      setState(() {
        _allMachines = machines;
        _machines = machines
            .where((machine) => machine.parentMachineId == null)
            .toList();
        _motors = motors;
        _servos = servos;
        _sensors = sensors;
        _processMotors = processMotors;
        _processServos = processServos;
        _processes = processes;
        _selected = _selected == null
            ? (_machines.isEmpty ? null : _machines.first)
            : _machines.where((item) => item.id == _selected!.id).firstOrNull;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        _message('$error');
      }
    }
  }

  void _applySlaveConfiguration(MachineConfiguration? configuration) {
    if (!mounted) return;
    final machine = configuration?.machine;
    setState(() {
      _allMachines = configuration == null
          ? const []
          : [configuration.machine, ...configuration.components];
      _machines = machine == null ? const [] : [machine];
      _motors = configuration?.motors ?? const [];
      _servos = configuration?.servos ?? const [];
      _sensors = configuration?.sensors ?? const [];
      _processMotors = const [];
      _processServos = const [];
      _processes = const [];
      _selected = machine;
      _loading = false;
    });
  }

  Future<void> _openEditor([SystemMachine? machine]) async {
    final slaveConfiguration = _isSlave
        ? GetIt.I<SystemConfigurationService>().localSlaveConfiguration
        : null;
    final components = machine == null
        ? <SystemMachine>[]
        : (slaveConfiguration?.components ??
              (await _repository.getMachines())
                  .where((item) => item.parentMachineId == machine.id)
                  .toList());
    final result = await showDialog<MachineConfiguration>(
      context: context,
      builder: (_) => _MachineEditorDialog(
        machine: machine,
        components: components,
        motors: machine == null
            ? const []
            : (slaveConfiguration?.motors ??
                  _motors
                      .where((item) => item.systemMachineId == machine.id)
                      .toList()),
        servos: machine == null
            ? const []
            : (slaveConfiguration?.servos ??
                  _servos
                      .where((item) => item.machineId == machine.id)
                      .toList()),
        sensors: machine == null
            ? const []
            : (slaveConfiguration?.sensors ??
                  _sensors
                      .where(
                        (sensor) =>
                            sensor.machineId == machine.id ||
                            sensor.machineId == null,
                      )
                      .toList()),
        allowDelete: !_isSlave,
      ),
    );
    if (result == null) return;
    try {
      await GetIt.I<SystemConfigurationService>().saveMachine(result);
      _message('Máquina guardada correctamente.');
      if (_isSlave) {
        _applySlaveConfiguration(result);
      } else {
        await _reload();
      }
    } catch (error) {
      _message('$error');
    }
  }

  bool _isLinked(SystemMachine machine) {
    final ids = {
      machine.id,
      ..._allMachines
          .where((item) => item.parentMachineId == machine.id)
          .map((item) => item.id),
    };
    return _processes.any(
          (process) =>
              process.machineId != null && ids.contains(process.machineId),
        ) ||
        _motors.any((item) => ids.contains(item.systemMachineId)) &&
            _processMotors.any(
              (item) => _motors
                  .where((motor) => motor.id == item.motorId)
                  .any((motor) => ids.contains(motor.systemMachineId)),
            ) ||
        _servos.any((item) => ids.contains(item.machineId)) &&
            _processServos.any(
              (item) => _servos
                  .where((servo) => servo.id == item.servoId)
                  .any((servo) => ids.contains(servo.machineId)),
            ) ||
        _sensors.any((item) => ids.contains(item.machineId)) &&
            _processes.any(
              (process) => _sensors
                  .where((sensor) => sensor.id == process.activationSensorId)
                  .any((sensor) => ids.contains(sensor.machineId)),
            );
  }

  Future<void> _delete(SystemMachine machine) async {
    if (_isLinked(machine)) {
      _message('No se puede eliminar: la máquina está enlazada a un proceso.');
      return;
    }
    try {
      await _repository.deleteMachineTree(machine.id);
      _message('Máquina eliminada.');
      await _reload();
    } catch (error) {
      _message('No se pudo eliminar la máquina: $error');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final selected = _selected;
    final children = selected == null
        ? const <SystemMachine>[]
        : _allMachines
              .where((item) => item.parentMachineId == selected.id)
              .toList();
    final selectedMotors = selected == null
        ? const <Motor>[]
        : _motors.where((item) => item.systemMachineId == selected.id).toList();
    final selectedServos = selected == null
        ? const <Servo>[]
        : _servos.where((item) => item.machineId == selected.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Máquinas'),
        actions: [
          FilledButton.icon(
            onPressed: _isSlave && _machines.isNotEmpty
                ? null
                : () => _openEditor(),
            icon: const Icon(Icons.add),
            label: const Text('Nueva máquina'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 300,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text(
                    'Máquinas creadas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_machines.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Aún no hay máquinas.'),
                    ),
                  for (final machine in _machines)
                    ListTile(
                      selected: selected?.id == machine.id,
                      leading: Icon(
                        Icons.precision_manufacturing,
                        color: _componentColor(machine.type),
                      ),
                      title: Text(machine.name),
                      subtitle: Text('${_componentCount(machine)} componentes'),
                      onTap: () => setState(() => _selected = machine),
                    ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: selected == null
                ? const Center(child: Text('Selecciona una máquina.'))
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selected.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Editar',
                            onPressed: () => _openEditor(selected),
                            icon: const Icon(Icons.edit),
                          ),
                          if (!_isSlave)
                            IconButton(
                              tooltip: _isLinked(selected)
                                  ? 'Enlazada a procesos'
                                  : 'Eliminar',
                              onPressed: _isLinked(selected)
                                  ? null
                                  : () => _delete(selected),
                              icon: const Icon(Icons.delete_outline),
                            ),
                        ],
                      ),
                      Text('Componentes de la máquina'),
                      const SizedBox(height: 8),
                      ...children.map(
                        (component) => Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.extension,
                              color: _componentColor(component.type),
                            ),
                            title: Text(component.name),
                            subtitle: Text(component.type),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _detailSection(
                        'Motores',
                        selectedMotors
                            .map(
                              (item) => ListTile(
                                leading: const Icon(
                                  Icons.settings_input_component,
                                  color: Colors.orange,
                                ),
                                title: Text(item.key),
                                subtitle: Text(
                                  'Velocidad: ${item.speed} · '
                                  'Sensores: ${item.keySensorLeft ?? '-'} / ${item.keySensorRight ?? '-'}',
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      _detailSection(
                        'Sensores',
                        _sensors
                            .where(
                              (item) =>
                                  item.machineId == selected.id ||
                                  item.machineId == null,
                            )
                            .map(
                              (item) => ListTile(
                                leading: const Icon(
                                  Icons.sensors,
                                  color: Colors.blue,
                                ),
                                title: Text(item.name),
                                subtitle: Text(item.key),
                              ),
                            )
                            .toList(),
                      ),
                      _detailSection(
                        'Servos',
                        selectedServos
                            .map(
                              (item) => ListTile(
                                leading: const Icon(
                                  Icons.rotate_right,
                                  color: Colors.purple,
                                ),
                                title: Text(item.key),
                                subtitle: Text(
                                  'Apertura máxima: ${item.maxOpen}',
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Color _componentColor(String type) {
    final normalized = type.toUpperCase();
    if (normalized.contains('BRAZO')) return Colors.green;
    if (normalized.contains('GRANDE')) return Colors.red;
    if (normalized.contains('PEQUEÑA')) return Colors.amber;
    return Colors.blueGrey;
  }

  int _componentCount(SystemMachine machine) =>
      _allMachines.where((item) => item.parentMachineId == machine.id).length +
      _motors.where((item) => item.systemMachineId == machine.id).length +
      _servos.where((item) => item.machineId == machine.id).length +
      _sensors
          .where(
            (item) => item.machineId == machine.id || item.machineId == null,
          )
          .length;

  Widget _detailSection(String title, List<Widget> children) => Card(
    child: ExpansionTile(
      title: Text(title),
      subtitle: Text('${children.length} configurados'),
      children: children.isEmpty
          ? [const ListTile(title: Text('Sin elementos configurados.'))]
          : children,
    ),
  );
}

class _MachineEditorDialog extends StatefulWidget {
  const _MachineEditorDialog({
    this.machine,
    required this.components,
    required this.motors,
    required this.servos,
    required this.sensors,
    required this.allowDelete,
  });

  final SystemMachine? machine;
  final List<SystemMachine> components;
  final List<Motor> motors;
  final List<Servo> servos;
  final List<Sensor> sensors;
  final bool allowDelete;

  @override
  State<_MachineEditorDialog> createState() => _MachineEditorDialogState();
}

class _MachineEditorDialogState extends State<_MachineEditorDialog> {
  late final TextEditingController _name;
  late final List<SystemMachine> _components;
  late final List<Motor> _motors;
  late final List<Servo> _servos;
  late final List<Sensor> _sensors;
  String _type = 'BRAZO SCARA';

  int _id() => DateTime.now().microsecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.machine?.name ?? '');
    _components = [...widget.components];
    _motors = [...widget.motors];
    _servos = [...widget.servos];
    _sensors = [...widget.sensors];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<String?> _ask(String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _addComponent() async {
    if (_type == 'CINTA GRANDE' &&
        _components.any(
          (item) => MachineConfigurationValidator.isLargeBelt(item.type),
        )) {
      return;
    }
    final value = await _ask('Nombre del componente');
    if (value == null || value.trim().isEmpty) return;
    setState(
      () => _components.add(
        SystemMachine(
          id: _id(),
          name: value.trim(),
          type: _type,
          parentMachineId: widget.machine?.id,
        ),
      ),
    );
  }

  Future<void> _editMotor([Motor? motor]) async {
    final value = await showDialog<Motor>(
      context: context,
      builder: (_) =>
          _MotorDialog(initial: motor, machineId: widget.machine?.id ?? 0),
    );
    if (value == null || !_keyAvailable(value.key, motor?.id, _motors)) return;
    setState(() {
      if (motor == null) {
        _motors.add(value);
      } else {
        _motors[_motors.indexOf(motor)] = value;
      }
    });
  }

  Future<void> _editServo([Servo? servo]) async {
    final value = await showDialog<Servo>(
      context: context,
      builder: (_) =>
          _ServoDialog(initial: servo, machineId: widget.machine?.id ?? 0),
    );
    if (value == null || !_keyAvailable(value.key, servo?.id, _servos)) return;
    setState(() {
      if (servo == null) {
        _servos.add(value);
      } else {
        _servos[_servos.indexOf(servo)] = value;
      }
    });
  }

  Future<void> _editSensor([Sensor? sensor]) async {
    final value = await showDialog<Sensor>(
      context: context,
      builder: (_) =>
          _SensorDialog(initial: sensor, machineId: widget.machine?.id),
    );
    if (value == null || !_keyAvailable(value.key, sensor?.id, _sensors))
      return;
    setState(() {
      if (sensor == null) {
        _sensors.add(value);
      } else {
        _sensors[_sensors.indexOf(sensor)] = value;
      }
    });
  }

  bool _keyAvailable<T>(String key, int? id, List<T> values) {
    final normalized = key.trim().toUpperCase();
    final duplicate = values.any((item) {
      final itemId = switch (item) {
        Motor value => value.id,
        Servo value => value.id,
        Sensor value => value.id,
        _ => null,
      };
      final itemKey = switch (item) {
        Motor value => value.key,
        Servo value => value.key,
        Sensor value => value.key,
        _ => '',
      };
      return itemId != id && itemKey.trim().toUpperCase() == normalized;
    });
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La clave ya está siendo utilizada.')),
      );
    }
    return !duplicate;
  }

  void _save() {
    final id = widget.machine?.id ?? _id();
    final configuration = MachineConfiguration(
      machine: SystemMachine(id: id, name: _name.text.trim(), type: 'SISTEMA'),
      components: _components
          .map(
            (item) => SystemMachine(
              id: item.id,
              name: item.name,
              type: item.type,
              parentMachineId: id,
            ),
          )
          .toList(),
      motors: _motors
          .map(
            (item) => Motor(
              id: item.id,
              systemMachineId: id,
              key: item.key,
              keySensorRight: item.keySensorRight,
              keySensorLeft: item.keySensorLeft,
              speed: item.speed,
              maxStepsRight: item.maxStepsRight,
              maxStepsLeft: item.maxStepsLeft,
            ),
          )
          .toList(),
      sensors: _sensors
          .map(
            (item) => Sensor(
              id: item.id,
              machineId: id,
              key: item.key,
              name: item.name,
            ),
          )
          .toList(),
      servos: _servos
          .map(
            (item) => Servo(
              id: item.id,
              machineId: id,
              key: item.key,
              maxOpen: item.maxOpen,
            ),
          )
          .toList(),
    );
    final error = MachineConfigurationValidator.validate(configuration);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context, configuration);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.machine == null ? 'Nueva máquina' : 'Editar máquina'),
    content: SizedBox(
      width: 680,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de componente',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'BRAZO SCARA',
                        child: Text('Brazo'),
                      ),
                      DropdownMenuItem(
                        value: 'CINTA PEQUEÑA',
                        child: Text('Cinta pequeña'),
                      ),
                      DropdownMenuItem(
                        value: 'CINTA GRANDE',
                        child: Text('Cinta grande'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _type = value!),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addComponent,
                  child: const Text('Componente'),
                ),
              ],
            ),
            for (final item in _components)
              ListTile(
                leading: Icon(
                  Icons.extension,
                  color: _componentColor(item.type),
                ),
                title: Text(item.name),
                subtitle: Text(item.type),
                trailing: widget.allowDelete
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => _components.remove(item)),
                      )
                    : null,
              ),
            const Divider(),
            _addRow('Motores', _motors.length, _editMotor),
            ..._motors.map(
              (item) => _editableTile(
                color: Colors.orange,
                icon: Icons.settings_input_component,
                title: item.key,
                subtitle:
                    'Sensores: ${item.keySensorLeft ?? '-'} / ${item.keySensorRight ?? '-'} · Velocidad: ${item.speed}',
                onEdit: () => _editMotor(item),
                onDelete: widget.allowDelete
                    ? () => setState(() => _motors.remove(item))
                    : null,
              ),
            ),
            _addRow('Sensores', _sensors.length, _editSensor),
            ..._sensors.map(
              (item) => _editableTile(
                color: Colors.blue,
                icon: Icons.sensors,
                title: item.key,
                subtitle: item.name,
                onEdit: () => _editSensor(item),
                onDelete: widget.allowDelete
                    ? () => setState(() => _sensors.remove(item))
                    : null,
              ),
            ),
            _addRow('Servos', _servos.length, _editServo),
            ..._servos.map(
              (item) => _editableTile(
                color: Colors.purple,
                icon: Icons.rotate_right,
                title: item.key,
                subtitle: 'Apertura máxima: ${item.maxOpen}',
                onEdit: () => _editServo(item),
                onDelete: widget.allowDelete
                    ? () => setState(() => _servos.remove(item))
                    : null,
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Guardar')),
    ],
  );

  Widget _addRow(String label, int count, VoidCallback action) => ListTile(
    title: Text(label),
    trailing: FilledButton.tonal(
      onPressed: action,
      child: Text('Agregar ($count)'),
    ),
  );

  Color _componentColor(String type) {
    final normalized = type.toUpperCase();
    if (normalized.contains('BRAZO')) return Colors.green;
    if (normalized.contains('GRANDE')) return Colors.red;
    if (normalized.contains('PEQUEÑA')) return Colors.amber;
    return Colors.blueGrey;
  }

  Widget _editableTile({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
    required VoidCallback? onDelete,
  }) => ListTile(
    leading: Icon(icon, color: color),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: Wrap(
      children: [
        IconButton(
          tooltip: 'Editar',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        if (onDelete != null)
          IconButton(
            tooltip: 'Eliminar',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    ),
  );
}

class _MotorDialog extends StatefulWidget {
  const _MotorDialog({required this.machineId, this.initial});

  final int machineId;
  final Motor? initial;

  @override
  State<_MotorDialog> createState() => _MotorDialogState();
}

class _MotorDialogState extends State<_MotorDialog> {
  late final TextEditingController _key;
  late final TextEditingController _right;
  late final TextEditingController _left;
  late final TextEditingController _speed;
  late final TextEditingController _maxRight;
  late final TextEditingController _maxLeft;

  @override
  void initState() {
    super.initState();
    final motor = widget.initial;
    _key = TextEditingController(text: motor?.key ?? '');
    _right = TextEditingController(text: motor?.keySensorRight ?? '');
    _left = TextEditingController(text: motor?.keySensorLeft ?? '');
    _speed = TextEditingController(text: '${motor?.speed ?? 5000}');
    _maxRight = TextEditingController(text: motor?.maxStepsRight ?? '');
    _maxLeft = TextEditingController(text: motor?.maxStepsLeft ?? '');
  }

  @override
  void dispose() {
    for (final controller in [
      _key,
      _right,
      _left,
      _speed,
      _maxRight,
      _maxLeft,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final key = _key.text.trim();
    final speed = double.tryParse(_speed.text.trim());
    final maxRight = _optionalNumber(_maxRight.text);
    final maxLeft = _optionalNumber(_maxLeft.text);
    if (key.isEmpty ||
        speed == null ||
        !speed.isFinite ||
        speed.truncateToDouble() != speed ||
        speed < 100 ||
        speed > 10000 ||
        (_maxRight.text.trim().isNotEmpty && maxRight == null) ||
        (_maxLeft.text.trim().isNotEmpty && maxLeft == null)) {
      _error(
        'Ingresa una clave, velocidad de 100 a 10000 y límites de movimiento '
        'enteros válidos.',
      );
      return;
    }
    Navigator.pop(
      context,
      Motor(
        id: widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch,
        systemMachineId: widget.machineId,
        key: key,
        keySensorRight: _optionalKey(_right.text),
        keySensorLeft: _optionalKey(_left.text),
        speed: speed,
        maxStepsRight: maxRight,
        maxStepsLeft: maxLeft,
      ),
    );
  }

  String? _optionalKey(String value) {
    final text = value.trim();
    if (text.isEmpty || text.length <= 3) return text.isEmpty ? null : text;
    return null;
  }

  String? _optionalNumber(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final number = int.tryParse(text);
    return number == null ? null : text;
  }

  void _error(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Agregar motor' : 'Editar motor'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(_key, 'Key del motor'),
          _field(_right, 'Key sensor derecho (opcional)'),
          _field(_left, 'Key sensor izquierdo (opcional)'),
          _field(_speed, 'Velocidad positiva', number: true),
          _field(
            _maxRight,
            'Máximo de movimiento derecha (opcional)',
            number: true,
            signed: true,
          ),
          _field(
            _maxLeft,
            'Máximo de movimiento izquierda (opcional)',
            number: true,
            signed: true,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Guardar')),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int? maxLength,
    bool number = false,
    bool signed = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: number
          ? TextInputType.numberWithOptions(signed: signed)
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

class _ServoDialog extends StatefulWidget {
  const _ServoDialog({required this.machineId, this.initial});

  final int machineId;
  final Servo? initial;

  @override
  State<_ServoDialog> createState() => _ServoDialogState();
}

class _ServoDialogState extends State<_ServoDialog> {
  late final TextEditingController _key;
  late final TextEditingController _maxOpen;

  @override
  void initState() {
    super.initState();
    _key = TextEditingController(text: widget.initial?.key ?? '');
    _maxOpen = TextEditingController(text: '${widget.initial?.maxOpen ?? 180}');
  }

  @override
  void dispose() {
    _key.dispose();
    _maxOpen.dispose();
    super.dispose();
  }

  void _save() {
    final key = _key.text.trim();
    final maxOpen = double.tryParse(_maxOpen.text.trim());
    if (key.isEmpty || maxOpen == null || !maxOpen.isFinite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una clave y un valor de apertura válido.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      Servo(
        id: widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch,
        machineId: widget.machineId,
        key: key,
        maxOpen: maxOpen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Agregar servo' : 'Editar servo'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _key,
          decoration: const InputDecoration(
            labelText: 'Key del servo',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _maxOpen,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Apertura máxima',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Guardar')),
    ],
  );
}

class _SensorDialog extends StatefulWidget {
  const _SensorDialog({this.initial, this.machineId});

  final Sensor? initial;
  final int? machineId;

  @override
  State<_SensorDialog> createState() => _SensorDialogState();
}

class _SensorDialogState extends State<_SensorDialog> {
  late final TextEditingController _key;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _key = TextEditingController(text: widget.initial?.key ?? '');
    _name = TextEditingController(text: widget.initial?.name ?? '');
  }

  @override
  void dispose() {
    _key.dispose();
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final key = _key.text.trim();
    final name = _name.text.trim();
    if (key.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El sensor requiere una key y un nombre.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      Sensor(
        id: widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch,
        machineId: widget.machineId,
        key: key,
        name: name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Agregar sensor' : 'Editar sensor'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _key,
          decoration: const InputDecoration(
            labelText: 'Key del sensor',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Nombre del sensor',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Guardar')),
    ],
  );
}

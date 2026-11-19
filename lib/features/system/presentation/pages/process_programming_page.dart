import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/process.dart';
import '../../domain/entities/process_motors.dart';
import '../../domain/entities/process_servo.dart';
import '../../domain/entities/sensor.dart';
import '../../domain/entities/motor.dart';
import '../../domain/entities/servo.dart';
import '../../domain/repositories/system_repository.dart';
import '../../domain/services/system_configuration_service.dart';

class ProcessProgrammingPage extends StatefulWidget {
  const ProcessProgrammingPage({super.key});

  @override
  State<ProcessProgrammingPage> createState() => _ProcessProgrammingPageState();
}

class _ProcessProgrammingPageState extends State<ProcessProgrammingPage> {
  final _name = TextEditingController();
  final _actions = <_ActionDraft>[];
  List<Motor> _motors = const [];
  List<Servo> _servos = const [];
  List<Sensor> _sensors = const [];
  Sensor? _sensor;
  String _kind = 'motor';
  Motor? _motor;
  Servo? _servo;
  int _order = 0;
  double _value = 0;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final repository = GetIt.I<SystemRepository>();
      _motors = await repository.getMotors();
      _servos = await repository.getServos();
      _sensors = await repository.getSensors();
    } catch (_) {
      // Los esclavos configuran y envían; el catálogo vive en el maestro.
    }
    if (mounted) setState(() => _loading = false);
  }

  int _id() => DateTime.now().microsecondsSinceEpoch;

  void _addAction() {
    final valid = _kind == 'motor' ? _motor != null : _servo != null;
    if (!valid) {
      _message('Selecciona el actuador.');
      return;
    }
    setState(() {
      _actions.add(
        _ActionDraft(
          kind: _kind,
          motor: _motor,
          servo: _servo,
          order: _order,
          value: _value,
        ),
      );
      _order++;
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _actions.isEmpty) {
      _message('Ingresa un nombre y agrega al menos una acción.');
      return;
    }
    final processId = _id();
    final motors = <ProcessMotors>[];
    final servos = <ProcessServo>[];
    for (final action in _actions) {
      if (action.kind == 'motor' && action.motor != null) {
        motors.add(
          ProcessMotors(
            id: _id(),
            processId: processId,
            motorId: action.motor!.id,
            name: action.motor!.key,
            order: action.order,
            steps: action.value,
          ),
        );
      } else if (action.servo != null) {
        servos.add(
          ProcessServo(
            id: _id(),
            processId: processId,
            servoId: action.servo!.id,
            name: action.servo!.key,
            order: action.order,
            openValue: action.value,
          ),
        );
      }
    }
    setState(() => _saving = true);
    try {
      await GetIt.I<SystemConfigurationService>().saveProcessConfiguration(
        process: Process(
          id: processId,
          name: _name.text.trim(),
          order: 0,
          activationSensorId: _sensor?.id,
        ),
        motors: motors,
        servos: servos,
      );
      if (mounted) {
        _message('Proceso guardado respetando el orden configurado.');
        _name.clear();
        setState(() {
          _actions.clear();
          _order = 0;
        });
      }
    } catch (error) {
      if (mounted) _message('$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Programar procesos',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Los motores y servos forman una sola secuencia ordenada.'),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Nombre del proceso',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<Sensor?>(
          value: _sensor,
          decoration: const InputDecoration(
            labelText: 'Sensor de activación (opcional)',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<Sensor?>(
              value: null,
              child: Text('Sin condición de sensor'),
            ),
            ..._sensors.map(
              (sensor) =>
                  DropdownMenuItem(value: sensor, child: Text(sensor.name)),
            ),
          ],
          onChanged: (value) => setState(() => _sensor = value),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _kind,
                        decoration: const InputDecoration(labelText: 'Acción'),
                        items: const [
                          DropdownMenuItem(
                            value: 'motor',
                            child: Text('Motor'),
                          ),
                          DropdownMenuItem(
                            value: 'servo',
                            child: Text('Servo'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _kind = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _actuatorDropdown()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _order,
                        decoration: const InputDecoration(labelText: 'Orden'),
                        items: [
                          for (var i = 0; i <= _actions.length + 10; i++)
                            DropdownMenuItem(value: i, child: Text('$i')),
                        ],
                        onChanged: (value) => setState(() => _order = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: '0',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: _kind == 'motor' ? 'Pasos' : 'Apertura',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) =>
                            _value = double.tryParse(value) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _addAction,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ..._actions.map(
          (action) => ListTile(
            leading: CircleAvatar(child: Text('${action.order}')),
            title: Text(
              action.kind == 'motor'
                  ? 'Motor · ${action.motor?.key ?? '-'}'
                  : 'Servo · ${action.servo?.key ?? '-'}',
            ),
            subtitle: Text('Valor: ${action.value}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => _actions.remove(action)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_saving ? 'Guardando…' : 'Guardar proceso'),
        ),
      ],
    );
  }

  Widget _actuatorDropdown() {
    if (_kind == 'motor') {
      return DropdownButtonFormField<Motor>(
        value: _motor,
        decoration: const InputDecoration(labelText: 'Motor'),
        items: _motors
            .map(
              (motor) => DropdownMenuItem(value: motor, child: Text(motor.key)),
            )
            .toList(),
        onChanged: (value) => setState(() => _motor = value),
      );
    }
    return DropdownButtonFormField<Servo>(
      value: _servo,
      decoration: const InputDecoration(labelText: 'Servo'),
      items: _servos
          .map(
            (servo) => DropdownMenuItem(value: servo, child: Text(servo.key)),
          )
          .toList(),
      onChanged: (value) => setState(() => _servo = value),
    );
  }
}

class _ActionDraft {
  const _ActionDraft({
    required this.kind,
    required this.order,
    required this.value,
    this.motor,
    this.servo,
  });

  final String kind;
  final Motor? motor;
  final Servo? servo;
  final int order;
  final double value;
}

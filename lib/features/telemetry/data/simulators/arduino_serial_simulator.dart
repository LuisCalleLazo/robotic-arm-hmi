import 'dart:async';

class ArduinoSerialSimulator {
  ArduinoSerialSimulator();

  static const _axes = ['X', 'Y', 'A', 'Z'];
  static const _homingOrder = ['Z', 'X', 'A', 'Y'];
  static const _route = [
    [8000, 5500, 1200, 41000, 140],
    [8000, 5500, 1200, 0, -1],
    [16000, 5500, 1200, 0, -1],
    [16000, 5500, 1200, 41000, 0],
    [16000, 5500, 1200, 0, -1],
  ];

  final StreamController<String> _lines = StreamController<String>.broadcast();
  final List<int> _position = [0, 0, 0, 0];
  final Set<String> _referencedAxes = {};
  Timer? _timer;
  bool _running = false;
  bool _paused = false;
  String _phase = 'idle';
  String _state = 'IDLE';
  String _resumeState = 'IDLE';
  int _servoAngle = 0;
  int _ticks = 0;
  int _homingIndex = 0;
  int _routeStep = 0;
  int _moveAxis = 0;
  int _moveTarget = 0;
  List<int> _moveStart = [];
  final Map<int, int> _moveTargets = {};
  bool _protocolAxisMove = false;

  Stream<String> get lines => _lines.stream;
  bool get isRunning => _running;
  bool get isReady => _running && _state == 'IDLE' && _phase == 'idle';

  void start() {
    if (_running) return;
    _running = true;
    _paused = false;
    _servoAngle = 0;
    _referencedAxes.clear();
    _state = 'IDLE';
    _phase = 'homing';
    _ticks = 0;
    _homingIndex = 0;
    _moveTargets.clear();
    _position.fillRange(0, _position.length, 0);

    _emit('EVT,BOOT');
    _emit('EVT,SERVO_READY');
    _emit('INFO,SCARA X Y A Z');
    _emit('INFO,Commands: X Y A Z | X500 | R | P | POS');
    _startHomingAxis();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _phase = 'idle';
  }

  void sendCommand(String text) {
    if (!_running) return;
    final trimmed = text.trim().toUpperCase();
    final tokens = trimmed.split(RegExp(r'\s+'));
    if (tokens.length > 1 && tokens.every((token) => token.startsWith('BC'))) {
      _emit('CMD,${tokens.join(' ')}');
      _sendBcGroup(tokens);
      return;
    }
    var command = text.replaceAll(RegExp(r'[ \t=]'), '').toUpperCase();
    if (command.isEmpty) return;
    _emit('CMD,$command');

    var relativeMotorCommand = false;
    var protocolStop = false;
    if (command.startsWith('BC')) {
      if (command == 'BCSTOP') {
        command = 'STOP';
        protocolStop = true;
      } else if (command == 'BCPAUSE') {
        command = 'PAUSE';
      } else if (command == 'BCPLAY') {
        command = 'PLAY';
      } else if (command == 'BC?') {
        command = 'POS';
      } else if (command.startsWith('BCS')) {
        command = 'S${command.substring(3)}';
      } else if (command.startsWith('BCVS')) {
        _emit('CFG,VELS,${command.substring(4)}');
        return;
      } else if (command.startsWith('BCV')) {
        _emit('CFG,VEL,${command.substring(3)}');
        return;
      } else if (command.startsWith('BCT')) {
        _emit('CFG,TELEM,${command.substring(3)}');
        return;
      } else {
        command = command.substring(2);
        relativeMotorCommand = true;
      }
    }

    if (command == '?' || command == 'POS' || command == 'POSICION') {
      _emit('STATE,$_state');
      _emitPosition();
      return;
    }
    if (command == 'PAUSE') {
      if (!_paused) {
        _resumeState = _state;
        _paused = true;
        _emit('EVT,PAUSE');
        _emit('STATE,PAUSED');
      }
      return;
    }
    if (command == 'PLAY') {
      if (_paused) {
        _paused = false;
        _state = _resumeState;
        _emit('EVT,PLAY');
        _emit('STATE,$_state');
      }
      return;
    }
    if (command.startsWith('S')) {
      final values = command.substring(1).split(':');
      final angle = int.tryParse(values.first);
      final speed = values.length > 1 ? int.tryParse(values[1]) : null;
      if (angle == null ||
          (values.length > 1 && speed == null) ||
          (speed != null && (speed < 0 || speed > 720))) {
        _emit('ERR,BAD_FORMAT');
      } else {
        _servoAngle = angle.clamp(0, 180);
        _emit('EVT,SERVO,$_servoAngle');
        _emit('BCS,0,$_servoAngle,$_servoAngle');
      }
      return;
    }
    if (_state == 'ERROR') {
      _emit('ERR,RESET_REQUIRED');
      return;
    }
    if (command == 'P' || command == 'STOP') {
      _state = 'IDLE';
      _phase = 'idle';
      _referencedAxes.clear();
      _moveTargets.clear();
      _emit('EVT,STOPPED');
      _emit('STATE,IDLE');
      if (protocolStop) _emit('BC,EVT,STOP');
      return;
    }
    if (command == 'R' || command == 'START' || command == 'INICIAR') {
      if (_state != 'IDLE' || !_homed) {
        _emit('ERR,NOT_READY');
        return;
      }
      _startRoute();
      return;
    }
    if (_state != 'IDLE') {
      _emit('ERR,BUSY');
      return;
    }

    final axisIndex = _axisIndex(command[0]);
    if (axisIndex == null) {
      _emit('ERR,UNKNOWN_COMMAND');
      return;
    }
    if (command.length == 1) {
      _moveAxis = axisIndex;
      _referencedAxes.remove(_axes[axisIndex]);
      _state = 'HOMING';
      _setPhase('axisHoming');
      _emit('EVT,HOMING_START,${_axes[axisIndex]},0');
      _emit('STATE,HOMING');
      return;
    }

    final target = int.tryParse(command.substring(1).split(':').first);
    if (target == null) {
      _emit('ERR,BAD_FORMAT');
      return;
    }
    if (!_referencedAxes.contains(_axes[axisIndex])) {
      _emit('ERR,NOT_REFERENCED,${_axes[axisIndex]}');
      return;
    }
    const limits = [30450, 11834, 3426, 47829];
    _moveAxis = axisIndex;
    _moveTarget =
        (relativeMotorCommand ? _position[axisIndex] + target : target).clamp(
          0,
          limits[axisIndex],
        );
    _protocolAxisMove = relativeMotorCommand;
    _moveStart = List<int>.from(_position);
    _state = 'MOVING_AXIS';
    _setPhase('axisMove');
    _emit('EVT,MOVE_START,${_axes[axisIndex]},$_moveTarget');
    if (_protocolAxisMove) {
      _emit('BC,EVT,INICIO,BC${_axes[axisIndex]},$target');
    }
    _emit('STATE,MOVING_AXIS');
  }

  void _sendBcGroup(List<String> tokens) {
    if (_state == 'ERROR') {
      _emit('ERR,RESET_REQUIRED');
      return;
    }
    if (_state != 'IDLE') {
      _emit('BC,ERR,BUSY');
      return;
    }

    final motors = <(int, int)>[];
    final servos = <int>[];
    for (final token in tokens) {
      final servoMatch = RegExp(r'^BCS(-?\d+)(?::(\d+))?$').firstMatch(token);
      if (servoMatch != null) {
        final angle = int.tryParse(servoMatch.group(1)!);
        final speed = int.tryParse(servoMatch.group(2) ?? '0');
        if (angle == null || speed == null || speed < 0 || speed > 720) {
          _emit('BC,ERR,BADSPEED,$token');
          return;
        }
        servos.add(angle.clamp(0, 180));
        continue;
      }

      final motorMatch = RegExp(
        r'^BC([XYAZ])(-?\d+)(?::(\d+))?$',
      ).firstMatch(token);
      if (motorMatch == null) {
        _emit('BC,ERR,UNKNOWN,$token');
        return;
      }
      final axis = motorMatch.group(1)!;
      final axisIndex = _axisIndex(axis);
      final steps = int.tryParse(motorMatch.group(2)!);
      final speed = int.tryParse(motorMatch.group(3) ?? '0');
      if (axisIndex == null || steps == null) {
        _emit('BC,ERR,UNKNOWN,$token');
        return;
      }
      if (speed == null || (speed != 0 && (speed < 100 || speed > 10000))) {
        _emit('BC,ERR,BADSPEED,$token');
        return;
      }
      if (!_referencedAxes.contains(axis)) {
        _emit('ERR,NOT_REFERENCED,$axis');
        return;
      }
      if (motors.any((item) => item.$1 == axisIndex)) {
        _emit('BC,ERR,BUSY,BC$axis');
        return;
      }
      motors.add((axisIndex, steps));
    }

    for (final angle in servos) {
      _servoAngle = angle;
      _emit('EVT,SERVO,$_servoAngle');
      _emit('BCS,0,$_servoAngle,$_servoAngle');
    }
    if (motors.isEmpty) return;

    const limits = [30450, 11834, 3426, 47829];
    _moveStart = List<int>.from(_position);
    _moveTargets
      ..clear()
      ..addEntries(
        motors.map(
          (item) => MapEntry(
            item.$1,
            (_position[item.$1] + item.$2).clamp(0, limits[item.$1]),
          ),
        ),
      );
    _state = 'MOVING_AXIS';
    _emit('EVT,MOVE_START,BATCH,${motors.length}');
    for (final item in motors) {
      _emit('BC,EVT,INICIO,BC${_axes[item.$1]},${item.$2}');
    }
    _emit('STATE,MOVING_AXIS');
    _setPhase('multiMove');
  }

  Future<void> dispose() async {
    stop();
    await _lines.close();
  }

  void _startHomingAxis() {
    _state = 'HOMING';
    _emit('EVT,HOMING_START,${_homingOrder[_homingIndex]},0');
    _emit('STATE,HOMING');
  }

  void _startRoute() {
    _routeStep = 0;
    _emit('EVT,ROUTE_START');
    _startRouteStep();
  }

  void _startRouteStep() {
    if (_routeStep >= _route.length) {
      _emit('EVT,ROUTE_DONE');
      _beginHomePose();
      return;
    }
    _moveStart = List<int>.from(_position);
    _state = 'ROUTE_MOVING';
    _setPhase('routeMove');
    _emit('EVT,ROUTE_STEP,$_routeStep');
    _emit('STATE,ROUTE_MOVING');
  }

  void _tick() {
    if (_paused) return;
    _ticks++;
    switch (_phase) {
      case 'homing':
        if (_ticks < 4) return;
        _emit(
          'EVT,HOMING_DONE,${_homingOrder[_homingIndex]},'
          '${1200 + _homingIndex * 170}',
        );
        _referencedAxes.add(_homingOrder[_homingIndex]);
        _homingIndex++;
        if (_homingIndex < _axes.length) {
          _startHomingAxis();
          _ticks = 0;
          return;
        }
        _emit('EVT,HOMING_COMPLETE');
        _beginHomePose();
      case 'homePose':
        _interpolate([8000, 5500, _position[2], 0], _ticks, 8);
        _emitPosition();
        if (_ticks < 8) return;
        _state = 'WAIT_BEFORE_A';
        _emit('STATE,WAIT_BEFORE_A');
        _setPhase('waitBeforeA');
      case 'waitBeforeA':
        if (_ticks < 3) return;
        _state = 'MOVING_A';
        _emit('STATE,MOVING_A');
        _setPhase('moveHomeA');
      case 'moveHomeA':
        _position[2] = (1200 * _ticks / 4).round();
        _emitPosition();
        if (_ticks < 4) return;
        _emit('EVT,HOME_POSE_REACHED');
        _emitPosition();
        _state = 'IDLE';
        _emit('STATE,IDLE');
        _setPhase('idle');
        _emit('BC,INFO,LISTO');
      case 'routeMove':
        final pose = _route[_routeStep];
        _interpolate(pose.take(4).toList(), _ticks, 6);
        _emitPosition();
        if (_ticks < 6) return;
        if (pose[4] >= 0) _emit('EVT,SERVO,${pose[4]}');
        _emitPosition();
        _state = 'ROUTE_WAIT';
        _emit('STATE,ROUTE_WAIT');
        _setPhase('routeWait');
      case 'routeWait':
        if (_ticks < 3) return;
        _routeStep++;
        _startRouteStep();
      case 'axisHoming':
        if (_ticks < 5) return;
        _position[_moveAxis] = 0;
        _emit('EVT,HOMING_DONE,${_axes[_moveAxis]},1500');
        _referencedAxes.add(_axes[_moveAxis]);
        _state = 'IDLE';
        _emit('STATE,IDLE');
        _setPhase('idle');
      case 'axisMove':
        final target = List<int>.from(_position);
        target[_moveAxis] = _moveTarget;
        _interpolate(target, _ticks, 6);
        _emitPosition();
        if (_ticks < 6) return;
        _emit('EVT,MOVE_DONE,${_axes[_moveAxis]},$_moveTarget');
        if (_protocolAxisMove) {
          _emit('BC,EVT,FIN,BC${_axes[_moveAxis]},${_position[_moveAxis]}');
          _protocolAxisMove = false;
        }
        _state = 'IDLE';
        _emit('STATE,IDLE');
        _setPhase('idle');
      case 'multiMove':
        final target = List<int>.from(_position);
        for (final entry in _moveTargets.entries) {
          target[entry.key] = entry.value;
        }
        _interpolate(target, _ticks, 6);
        _emitPosition();
        if (_ticks < 6) return;
        for (final entry in _moveTargets.entries) {
          _emit('BC,EVT,FIN,BC${_axes[entry.key]},${_position[entry.key]}');
        }
        _moveTargets.clear();
        _state = 'IDLE';
        _emit('STATE,IDLE');
        _setPhase('idle');
      default:
        break;
    }
  }

  void _beginHomePose() {
    _emit('EVT,HOME_POSE_START');
    _state = 'GOTO_HOME_POSE';
    _emit('STATE,GOTO_HOME_POSE');
    _moveStart = List<int>.from(_position);
    _setPhase('homePose');
  }

  void _interpolate(List<int> target, int tick, int duration) {
    for (var i = 0; i < _position.length; i++) {
      _position[i] =
          _moveStart[i] +
          ((target[i] - _moveStart[i]) * tick / duration).round();
    }
  }

  void _emitPosition() {
    _emit(
      'POS,X=${_position[0]},Y=${_position[1]},'
      'A=${_position[2]},Z=${_position[3]}',
    );
  }

  int? _axisIndex(String axis) {
    final index = _axes.indexOf(axis);
    return index < 0 ? null : index;
  }

  bool get _homed => _referencedAxes.length == _axes.length;

  void _setPhase(String phase) {
    _phase = phase;
    _ticks = 0;
  }

  void _emit(String line) => _lines.add(line);
}
